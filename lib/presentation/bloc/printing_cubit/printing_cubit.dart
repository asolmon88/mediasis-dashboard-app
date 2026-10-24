import 'dart:async';
import 'dart:math';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'printing_state.dart';

class PrintingCubit extends Cubit<PrintingState> {
  PrintingCubit({
    PrinterStorageService? storage,
    PrinterDiscoveryService? discovery,
    PrinterService? printerService,
    ReceiptPrintDataService? receiptService,
    ReceiptEscPosFormatter? formatter,
    NativePrinterBridge? nativeBridge,
    Duration transportRetryDelay = const Duration(seconds: 2),
  }) : _storage = storage ?? PrinterStorageService(),
       _discovery = discovery ?? PrinterDiscoveryService(),
       _printerService = printerService ?? PrinterService(),
       _receiptService = receiptService ?? ReceiptPrintDataService(),
       _formatter = formatter ?? ReceiptEscPosFormatter(),
       _nativeBridge = nativeBridge ?? NativePrinterBridge(),
       _transportRetryDelay = transportRetryDelay,
       super(const PrintingState());

  final PrinterStorageService _storage;
  final PrinterDiscoveryService _discovery;
  final PrinterService _printerService;
  final ReceiptPrintDataService _receiptService;
  final ReceiptEscPosFormatter _formatter;
  final NativePrinterBridge _nativeBridge;
  final Duration _transportRetryDelay;
  final Set<String> _activeAutomaticKeys = <String>{};
  final Map<String, IncomingOrderArrival> _pendingArrivals = {};
  StreamSubscription<IncomingOrderArrival>? _incomingSubscription;
  Timer? _printingProgressTimer;

  bool get isSupported => _discovery.isSupported;

  void bindIncomingOrders(Stream<IncomingOrderArrival> stream) {
    _incomingSubscription?.cancel();
    _incomingSubscription = stream.listen(handleIncomingOrder);
  }

  Future<void> loadLocation(String businessLocationId) async {
    if (businessLocationId.isEmpty) return;
    emit(
      state.copyWith(
        status: PrintingStatus.loading,
        businessLocationId: businessLocationId,
        discoveredPrinters: const [],
        clearTransientMessage: true,
      ),
    );
    var printers = await _storage.readPrinters(businessLocationId);
    printers = await _upsertSunmiPrinter(businessLocationId, printers);
    for (final job in await _nativeBridge.takeCompletedJobs()) {
      await _storage.saveJob(job);
    }
    final jobs = await _storage.readJobs(businessLocationId);
    if (isClosed || state.businessLocationId != businessLocationId) return;
    emit(
      state.copyWith(
        status: PrintingStatus.ready,
        printers: printers,
        jobs: jobs,
      ),
    );
    await _nativeBridge.synchronize(businessLocationId, printers);
    await _drainPendingArrivals();
  }

  void clearActiveLocation() {
    _activeAutomaticKeys.clear();
    _pendingArrivals.clear();
    emit(const PrintingState());
  }

  Future<void> refreshNativeJobs() async {
    if (state.businessLocationId.isEmpty) return;
    final nativeJobs = await _nativeBridge.takeCompletedJobs();
    for (final job in nativeJobs.where(
      (job) => job.businessLocationId == state.businessLocationId,
    )) {
      await _storage.saveJob(job);
    }
    if (nativeJobs.isNotEmpty) await _reloadJobs();
  }

  Future<void> discover({bool scanSubnet = false}) async {
    if (state.businessLocationId.isEmpty) return;
    emit(state.copyWith(status: PrintingStatus.discovering));
    final printers = await _discovery.discover(scanSubnet: scanSubnet);
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PrintingStatus.ready,
        discoveredPrinters: printers,
        transientMessage: printers.isEmpty
            ? 'No se encontraron impresoras. Puedes agregar una manualmente.'
            : 'Se encontraron ${printers.length} impresoras.',
      ),
    );
  }

  Future<void> discoverSunmi() async {
    if (state.businessLocationId.isEmpty) return;
    emit(
      state.copyWith(
        status: PrintingStatus.discovering,
        clearTransientMessage: true,
      ),
    );
    final info = await _nativeBridge.detectSunmiPrinter();
    if (isClosed) return;
    if (!info.available) {
      emit(
        state.copyWith(
          status: PrintingStatus.ready,
          transientMessage: info.serviceStatus.isNotEmpty
              ? info.serviceStatus
              : 'No se encontro una impresora SUNMI integrada.',
        ),
      );
      return;
    }

    final printers = await _upsertSunmiPrinter(
      state.businessLocationId,
      state.printers,
      detectedInfo: info,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PrintingStatus.ready,
        printers: printers,
        transientMessage: _sunmiDiagnostic(info),
      ),
    );
    await _nativeBridge.synchronize(state.businessLocationId, printers);
  }

  Future<PrinterConfiguration> savePrinter({
    String? id,
    required String name,
    required String host,
    int port = 9100,
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
    bool supportsCutter = true,
    PrinterReceiptFormat? receiptFormat,
  }) async {
    final existing = id == null ? null : _printerById(id);
    final networkChanged =
        existing == null ||
        existing.host != host.trim() ||
        existing.port != port ||
        existing.paperWidth != paperWidth;
    final printer = PrinterConfiguration(
      id: id ?? _id('printer'),
      businessLocationId: state.businessLocationId,
      name: name.trim(),
      host: host.trim(),
      port: port,
      paperWidth: paperWidth,
      supportsCutter: supportsCutter,
      receiptFormat:
          receiptFormat ??
          existing?.receiptFormat ??
          PrinterReceiptFormat.escPosText,
      automaticPrinting: networkChanged ? false : existing.automaticPrinting,
      verified: networkChanged ? false : existing.verified,
      lastTestedAt: networkChanged ? null : existing.lastTestedAt,
      lastTestError: networkChanged ? null : existing.lastTestError,
    );
    await _storage.savePrinter(printer);
    await _reloadPrinters();
    return printer;
  }

  Future<void> addDiscoveredPrinter(DiscoveredPrinter discovered) async {
    await savePrinter(
      name: discovered.name,
      host: discovered.host,
      port: discovered.port,
    );
  }

  Future<void> deletePrinter(String printerId) async {
    final printer = _printerById(printerId);
    if (printer?.connectionType == PrinterConnectionType.sunmiBuiltIn) return;
    await _storage.deletePrinter(printerId);
    await _reloadPrinters();
  }

  Future<bool> testPrinter(String printerId) async {
    final printer = _printerById(printerId);
    if (printer == null) return false;
    emit(
      state.copyWith(
        status: PrintingStatus.printing,
        clearPrintingProgress: true,
      ),
    );
    try {
      final bytes = await _formatter.buildTest(printer);
      await _printerService.printBytes(printer, bytes);
      await _storage.savePrinter(
        printer.copyWith(
          verified: true,
          lastTestedAt: DateTime.now(),
          clearLastTestError: true,
        ),
      );
      await _reloadPrinters(
        message: 'La prueba se imprimio correctamente en ${printer.name}.',
      );
      return true;
    } catch (error) {
      await _storage.savePrinter(
        printer.copyWith(
          verified: false,
          automaticPrinting: false,
          lastTestedAt: DateTime.now(),
          lastTestError: _error(error),
        ),
      );
      await _reloadPrinters(
        message: 'No se pudo conectar con ${printer.name}.',
      );
      return false;
    }
  }

  Future<bool> setAutomaticPrinting(String printerId, bool enabled) async {
    final printer = _printerById(printerId);
    if (printer == null) return false;
    if (enabled && !printer.verified) {
      emit(
        state.copyWith(
          transientMessage: 'Primero debes imprimir una prueba correctamente.',
        ),
      );
      return false;
    }
    await _storage.savePrinter(printer.copyWith(automaticPrinting: enabled));
    await _reloadPrinters(
      message: enabled
          ? 'Impresion automatica activada para ${printer.name}.'
          : 'Impresion automatica desactivada para ${printer.name}.',
    );
    return true;
  }

  Future<void> setReceiptFormat(
    String printerId,
    PrinterReceiptFormat receiptFormat,
  ) async {
    final printer = _printerById(printerId);
    if (printer == null || printer.receiptFormat == receiptFormat) return;
    await _storage.savePrinter(printer.copyWith(receiptFormat: receiptFormat));
    await _reloadPrinters(
      message: receiptFormat == PrinterReceiptFormat.visualRaster
          ? 'Formato visual activado para ${printer.name}.'
          : 'Formato de texto rapido activado para ${printer.name}.',
    );
  }

  Future<PrintOperationResult> printOrder({
    required String orderId,
    required List<String> printerIds,
    PrintJobTrigger trigger = PrintJobTrigger.manual,
  }) async {
    final printers = state.printers
        .where((printer) => printerIds.contains(printer.id))
        .toList();
    if (printers.isEmpty || state.businessLocationId.isEmpty) {
      return const PrintOperationResult(successCount: 0, failureCount: 1);
    }
    _startPrintingProgress(
      trigger == PrintJobTrigger.automatic
          ? const Duration(seconds: 12)
          : const Duration(seconds: 30),
      automatic: trigger == PrintJobTrigger.automatic,
    );
    try {
      final receipt = await _receiptService.fetch(
        orderId: orderId,
        businessLocationId: state.businessLocationId,
      );
      final result = await _printReceipt(receipt, printers, trigger);
      await _reloadJobs(
        message: result.failureCount == 0
            ? result.usedTextFallback
                  ? 'Se imprimio en formato de texto porque el diseno visual no estuvo disponible.'
                  : 'Recibo impreso correctamente.'
            : '${result.failureCount} impresora(s) no pudieron imprimir.',
      );
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          status: PrintingStatus.ready,
          transientMessage: _error(error),
        ),
      );
      return PrintOperationResult(
        successCount: 0,
        failureCount: printers.length,
      );
    } finally {
      _stopPrintingProgress();
    }
  }

  Future<void> retryJob(String jobId) async {
    final job = state.jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null) return;
    final result = await printOrder(
      orderId: job.orderId,
      printerIds: [job.printerId],
      trigger: PrintJobTrigger.retry,
    );
    if (!result.success) return;

    // The retry is a separate attempt, but its success resolves only the
    // original failure selected by the user.
    await _storage.saveJob(job.copyWith(status: PrintJobStatus.printed));
    await _reloadJobs(message: 'Recibo reimpreso correctamente.');
  }

  Future<void> handleIncomingOrder(IncomingOrderArrival arrival) async {
    if (state.status == PrintingStatus.initial ||
        state.status == PrintingStatus.loading) {
      _queueArrival(arrival);
      return;
    }
    if (arrival.businessLocationId != state.businessLocationId) return;
    final printers = state.printers
        .where((printer) => printer.automaticPrinting && printer.verified)
        .where((printer) {
          final key = _automaticKey(arrival.orderId, printer.id);
          return !_activeAutomaticKeys.contains(key) &&
              !state.jobs.any(
                (job) =>
                    job.trigger == PrintJobTrigger.automatic &&
                    job.orderId == arrival.orderId &&
                    job.printerId == printer.id,
              );
        })
        .toList();
    if (printers.isEmpty) return;
    for (final printer in printers) {
      _activeAutomaticKeys.add(_automaticKey(arrival.orderId, printer.id));
    }
    _startPrintingProgress(const Duration(seconds: 12), automatic: true);
    try {
      final receipt = await _receiptService.fetch(
        orderId: arrival.orderId,
        businessLocationId: arrival.businessLocationId,
      );
      final result = await _printReceipt(
        receipt,
        printers,
        PrintJobTrigger.automatic,
      );
      await _reloadJobs(
        message: result.failureCount > 0
            ? 'No se pudo imprimir automaticamente en ${result.failureCount} impresora(s).'
            : result.usedTextFallback
            ? 'Se imprimio en formato de texto porque el diseno visual no estuvo disponible.'
            : null,
      );
    } catch (error) {
      for (final printer in printers) {
        await _saveFailedFetchJob(arrival.orderId, printer, error);
      }
      await _reloadJobs(
        message: 'No se pudo cargar el recibo para impresion automatica.',
      );
    } finally {
      _stopPrintingProgress();
      for (final printer in printers) {
        _activeAutomaticKeys.remove(_automaticKey(arrival.orderId, printer.id));
      }
    }
  }

  void _queueArrival(IncomingOrderArrival arrival) {
    final key = '${arrival.businessLocationId}|${arrival.orderId}';
    _pendingArrivals[key] = arrival;
    if (_pendingArrivals.length > 100) {
      _pendingArrivals.remove(_pendingArrivals.keys.first);
    }
  }

  Future<void> _drainPendingArrivals() async {
    final arrivals = _pendingArrivals.values
        .where(
          (arrival) => arrival.businessLocationId == state.businessLocationId,
        )
        .toList();
    for (final arrival in arrivals) {
      _pendingArrivals.remove(
        '${arrival.businessLocationId}|${arrival.orderId}',
      );
      await handleIncomingOrder(arrival);
    }
  }

  Future<PrintOperationResult> _printReceipt(
    ReceiptPrintPayload receipt,
    List<PrinterConfiguration> printers,
    PrintJobTrigger trigger,
  ) async {
    var success = 0;
    var failure = 0;
    final formatsUsed = <PrintReceiptOutputFormat>{};
    final bytesByFormat = <String, List<int>>{};
    final outputFormatByKey = <String, PrintReceiptOutputFormat>{};
    for (final printer in printers) {
      final job = PrintJob(
        id: _id('job'),
        businessLocationId: printer.businessLocationId,
        orderId: receipt.orderId,
        printerId: printer.id,
        printerName: printer.name,
        trigger: trigger,
        status: PrintJobStatus.printing,
        attemptedAt: DateTime.now(),
        humanOrderNumber: receipt.humanOrderNumber,
      );
      await _storage.saveJob(job);
      try {
        final formatKey =
            '${printer.receiptFormat.name}|${printer.paperWidth.name}|${printer.supportsCutter}';
        var outputFormat = PrintReceiptOutputFormat.escPosText;
        var bytes = bytesByFormat[formatKey];
        if (bytes == null) {
          if (printer.receiptFormat == PrinterReceiptFormat.visualRaster) {
            try {
              bytes = await _receiptService.fetchVisualBytes(
                orderId: receipt.orderId,
                businessLocationId: printer.businessLocationId,
                paperWidth: printer.paperWidth,
                supportsCutter: printer.supportsCutter,
                timeout: trigger == PrintJobTrigger.automatic
                    ? const Duration(seconds: 12)
                    : const Duration(seconds: 30),
              );
              if (bytes.isEmpty) {
                throw const FormatException('El recibo visual esta vacio.');
              }
              outputFormat = PrintReceiptOutputFormat.visualRaster;
            } catch (_) {
              bytes = await _formatter.build(receipt, printer);
              outputFormat = PrintReceiptOutputFormat.escPosTextFallback;
            }
          } else {
            bytes = await _formatter.build(receipt, printer);
          }
          bytesByFormat[formatKey] = bytes;
          outputFormatByKey[formatKey] = outputFormat;
        } else {
          outputFormat = outputFormatByKey[formatKey] ?? outputFormat;
        }
        await _printWithRetry(printer, bytes);
        formatsUsed.add(outputFormat);
        await _storage.saveJob(job.copyWith(status: PrintJobStatus.printed));
        success++;
      } catch (error) {
        await _storage.saveJob(
          job.copyWith(status: PrintJobStatus.failed, error: _error(error)),
        );
        failure++;
      }
    }
    return PrintOperationResult(
      successCount: success,
      failureCount: failure,
      formatsUsed: formatsUsed,
    );
  }

  Future<void> _printWithRetry(
    PrinterConfiguration printer,
    List<int> bytes,
  ) async {
    try {
      await _printerService.printBytes(printer, bytes);
    } catch (_) {
      await Future<void>.delayed(_transportRetryDelay);
      await _printerService.printBytes(printer, bytes);
    }
  }

  void _startPrintingProgress(Duration duration, {required bool automatic}) {
    _printingProgressTimer?.cancel();
    final startedAt = DateTime.now();
    emit(
      state.copyWith(
        status: PrintingStatus.printing,
        printingProgress: 0,
        printingSecondsRemaining: duration.inSeconds,
        printingLabel: automatic
            ? 'Preparando impresion automatica'
            : 'Preparando recibo para imprimir',
      ),
    );
    _printingProgressTimer = Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) {
      if (isClosed) return;
      final elapsed = DateTime.now().difference(startedAt);
      final ratio = elapsed.inMilliseconds / duration.inMilliseconds;
      final remaining = duration - elapsed;
      emit(
        state.copyWith(
          printingProgress: ratio.clamp(0.0, 0.98),
          printingSecondsRemaining: max(0, remaining.inSeconds + 1),
        ),
      );
    });
  }

  void _stopPrintingProgress() {
    _printingProgressTimer?.cancel();
    _printingProgressTimer = null;
  }

  Future<void> _saveFailedFetchJob(
    String orderId,
    PrinterConfiguration printer,
    Object error,
  ) => _storage.saveJob(
    PrintJob(
      id: _id('job'),
      businessLocationId: printer.businessLocationId,
      orderId: orderId,
      printerId: printer.id,
      printerName: printer.name,
      trigger: PrintJobTrigger.automatic,
      status: PrintJobStatus.failed,
      attemptedAt: DateTime.now(),
      error: _error(error),
    ),
  );

  Future<void> _reloadPrinters({String? message}) async {
    final printers = await _storage.readPrinters(state.businessLocationId);
    await _nativeBridge.synchronize(state.businessLocationId, printers);
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PrintingStatus.ready,
        printers: printers,
        transientMessage: message,
      ),
    );
  }

  Future<List<PrinterConfiguration>> _upsertSunmiPrinter(
    String businessLocationId,
    List<PrinterConfiguration> printers, {
    SunmiPrinterInfo? detectedInfo,
  }) async {
    final info = detectedInfo ?? await _nativeBridge.detectSunmiPrinter();
    if (!info.available) return printers;

    final printerId = 'sunmi_builtin_$businessLocationId';
    final existing = printers
        .where((printer) => printer.id == printerId)
        .firstOrNull;
    final paperChanged =
        existing != null && existing.paperWidth != info.paperWidth;
    final printer = PrinterConfiguration(
      id: printerId,
      businessLocationId: businessLocationId,
      name: 'Impresora integrada SUNMI',
      connectionType: PrinterConnectionType.sunmiBuiltIn,
      receiptFormat: existing?.receiptFormat ?? PrinterReceiptFormat.escPosText,
      deviceModel: info.model.isEmpty ? existing?.deviceModel : info.model,
      paperWidth: info.paperWidth,
      supportsCutter: false,
      automaticPrinting: paperChanged
          ? false
          : existing?.automaticPrinting ?? false,
      verified: paperChanged ? false : existing?.verified ?? false,
      lastTestedAt: paperChanged ? null : existing?.lastTestedAt,
      lastTestError: paperChanged ? null : existing?.lastTestError,
    );
    await _storage.savePrinter(printer);
    return _storage.readPrinters(businessLocationId);
  }

  String _sunmiDiagnostic(SunmiPrinterInfo info) {
    final details = <String>[
      if (info.model.isNotEmpty) info.model,
      if (info.deviceModel.isNotEmpty && info.deviceModel != info.model)
        'dispositivo ${info.deviceModel}',
      info.paperWidth == PrinterPaperWidth.mm58 ? '58 mm' : '80 mm',
      'estado ${info.printerState}',
    ];
    final status = info.serviceStatus.trim();
    return 'Impresora SUNMI detectada: ${details.join(' | ')}${status.isEmpty ? '.' : ' | $status.'}';
  }

  Future<void> _reloadJobs({String? message}) async {
    final jobs = await _storage.readJobs(state.businessLocationId);
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PrintingStatus.ready,
        jobs: jobs,
        transientMessage: message,
      ),
    );
  }

  PrinterConfiguration? _printerById(String id) =>
      state.printers.where((printer) => printer.id == id).firstOrNull;
  String _automaticKey(String orderId, String printerId) =>
      '${state.businessLocationId}|$orderId|$printerId';
  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
  String _error(Object error) {
    final value = '$error'.replaceFirst('Bad state: ', '').trim();
    return value.length > 220 ? '${value.substring(0, 220)}...' : value;
  }

  void clearTransientMessage() {
    if (state.transientMessage.isEmpty) return;
    emit(state.copyWith(clearTransientMessage: true));
  }

  @override
  Future<void> close() async {
    _printingProgressTimer?.cancel();
    await _incomingSubscription?.cancel();
    return super.close();
  }
}
