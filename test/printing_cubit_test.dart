import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'deduplicates automatic printing for repeated arrival signals',
    () async {
      final storage = PrinterStorageService();
      await storage.savePrinter(
        const PrinterConfiguration(
          id: 'printer-1',
          businessLocationId: 'location-1',
          name: 'Caja',
          host: '127.0.0.1',
          verified: true,
          automaticPrinting: true,
          receiptFormat: PrinterReceiptFormat.visualRaster,
        ),
      );
      final printer = _FakePrinterService();
      final receiptService = _FakeReceiptService();
      final cubit = PrintingCubit(
        storage: storage,
        printerService: printer,
        receiptService: receiptService,
        formatter: _FakeFormatter(),
      );
      await cubit.loadLocation('location-1');
      const arrival = IncomingOrderArrival(
        orderId: 'order-1',
        businessLocationId: 'location-1',
      );

      await cubit.handleIncomingOrder(arrival);
      await cubit.handleIncomingOrder(arrival);

      expect(printer.printCount, 1);
      expect(cubit.state.jobs.single.status, PrintJobStatus.printed);
      expect(receiptService.lastVisualTimeout, const Duration(seconds: 12));
      await cubit.close();
    },
  );

  test('successful retry resolves only the selected failed job', () async {
    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'printer-1',
        businessLocationId: 'location-1',
        name: 'Caja',
        host: '127.0.0.1',
        verified: true,
      ),
    );
    final selectedFailure = PrintJob(
      id: 'failed-1',
      businessLocationId: 'location-1',
      orderId: 'order-1',
      printerId: 'printer-1',
      printerName: 'Caja',
      trigger: PrintJobTrigger.automatic,
      status: PrintJobStatus.failed,
      attemptedAt: DateTime(2026),
      error: 'Sin conexion',
    );
    final unrelatedFailure = PrintJob(
      id: 'failed-2',
      businessLocationId: 'location-1',
      orderId: 'order-2',
      printerId: 'printer-2',
      printerName: 'Cocina',
      trigger: PrintJobTrigger.automatic,
      status: PrintJobStatus.failed,
      attemptedAt: DateTime(2026, 1, 2),
      error: 'Sin papel',
    );
    await storage.saveJob(selectedFailure);
    await storage.saveJob(unrelatedFailure);
    final cubit = PrintingCubit(
      storage: storage,
      printerService: _FakePrinterService(),
      receiptService: _FakeReceiptService(),
      formatter: _FakeFormatter(),
    );
    await cubit.loadLocation('location-1');

    await cubit.retryJob(selectedFailure.id);

    expect(
      cubit.state.failedJobs.map((job) => job.id),
      contains(unrelatedFailure.id),
    );
    expect(
      cubit.state.failedJobs.map((job) => job.id),
      isNot(contains(selectedFailure.id)),
    );
    await cubit.close();
  });

  test('buffers arrivals until automatic printers finish loading', () async {
    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'printer-1',
        businessLocationId: 'location-1',
        name: 'Caja',
        host: '127.0.0.1',
        verified: true,
        automaticPrinting: true,
      ),
    );
    final printer = _FakePrinterService();
    final cubit = PrintingCubit(
      storage: storage,
      printerService: printer,
      receiptService: _FakeReceiptService(),
      formatter: _FakeFormatter(),
      nativeBridge: _FakeNativePrinterBridge(),
    );

    await cubit.handleIncomingOrder(
      const IncomingOrderArrival(
        orderId: 'order-before-load',
        businessLocationId: 'location-1',
      ),
    );
    await cubit.loadLocation('location-1');

    expect(printer.printCount, 1);
    expect(cubit.state.jobs.single.status, PrintJobStatus.printed);
    await cubit.close();
  });

  test('detects and inserts one location-specific SUNMI printer', () async {
    final storage = PrinterStorageService();
    final bridge = _FakeNativePrinterBridge(
      sunmiInfo: const SunmiPrinterInfo(
        available: true,
        model: 'T5F2A printer',
        deviceModel: 'T5F2A',
        paperWidth: PrinterPaperWidth.mm80,
        printerState: 0,
        serviceStatus: 'Estado no disponible; realiza una impresion de prueba',
      ),
    );
    final cubit = PrintingCubit(storage: storage, nativeBridge: bridge);

    await cubit.loadLocation('location-1');
    await cubit.loadLocation('location-1');

    expect(cubit.state.printers, hasLength(1));
    final printer = cubit.state.printers.single;
    expect(printer.id, 'sunmi_builtin_location-1');
    expect(printer.connectionType, PrinterConnectionType.sunmiBuiltIn);
    expect(printer.paperWidth, PrinterPaperWidth.mm80);
    expect(printer.supportsCutter, isFalse);
    expect(printer.automaticPrinting, isFalse);
    expect(printer.verified, isFalse);

    await cubit.discoverSunmi();
    expect(cubit.state.printers, hasLength(1));
    expect(bridge.detectionCount, 3);
    expect(cubit.state.transientMessage, contains('T5F2A'));
    expect(cubit.state.transientMessage, contains('estado 0'));
    await cubit.close();
  });

  test(
    'dispatches visual and text formats independently per printer',
    () async {
      final storage = PrinterStorageService();
      await storage.savePrinter(
        const PrinterConfiguration(
          id: 'visual',
          businessLocationId: 'location-1',
          name: 'Visual',
          host: '127.0.0.1',
          receiptFormat: PrinterReceiptFormat.visualRaster,
        ),
      );
      await storage.savePrinter(
        const PrinterConfiguration(
          id: 'text',
          businessLocationId: 'location-1',
          name: 'Texto',
          host: '127.0.0.2',
          receiptFormat: PrinterReceiptFormat.escPosText,
        ),
      );
      final receiptService = _FakeReceiptService();
      final formatter = _FakeFormatter();
      final printerService = _FakePrinterService();
      final cubit = PrintingCubit(
        storage: storage,
        receiptService: receiptService,
        formatter: formatter,
        printerService: printerService,
        nativeBridge: _FakeNativePrinterBridge(),
      );
      await cubit.loadLocation('location-1');

      final result = await cubit.printOrder(
        orderId: 'order-1',
        printerIds: const ['visual', 'text'],
      );

      expect(result.successCount, 2);
      expect(receiptService.visualFetchCount, 1);
      expect(receiptService.lastVisualTimeout, const Duration(seconds: 30));
      expect(formatter.buildCount, 1);
      expect(printerService.printCount, 2);
      await cubit.close();
    },
  );

  test('falls back to text when visual rendering fails', () async {
    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'visual',
        businessLocationId: 'location-1',
        name: 'Visual',
        host: '127.0.0.1',
        receiptFormat: PrinterReceiptFormat.visualRaster,
      ),
    );
    final receiptService = _FakeReceiptService(failVisual: true);
    final formatter = _FakeFormatter();
    final printerService = _FakePrinterService();
    final cubit = PrintingCubit(
      storage: storage,
      receiptService: receiptService,
      formatter: formatter,
      printerService: printerService,
      nativeBridge: _FakeNativePrinterBridge(),
      transportRetryDelay: Duration.zero,
    );
    await cubit.loadLocation('location-1');

    final result = await cubit.printOrder(
      orderId: 'order-1',
      printerIds: const ['visual'],
    );

    expect(result.success, isTrue);
    expect(result.usedTextFallback, isTrue);
    expect(receiptService.visualFetchCount, 1);
    expect(formatter.buildCount, 1);
    expect(printerService.printCount, 1);
    expect(cubit.state.failedJobs, isEmpty);
    expect(cubit.state.transientMessage, contains('formato de texto'));
    await cubit.close();
  });

  test(
    'retries one transient printer failure without duplicating the job',
    () async {
      final storage = PrinterStorageService();
      await storage.savePrinter(
        const PrinterConfiguration(
          id: 'printer-1',
          businessLocationId: 'location-1',
          name: 'Caja',
          host: '127.0.0.1',
          receiptFormat: PrinterReceiptFormat.escPosText,
        ),
      );
      final printerService = _FakePrinterService(failuresBeforeSuccess: 1);
      final cubit = PrintingCubit(
        storage: storage,
        receiptService: _FakeReceiptService(),
        formatter: _FakeFormatter(),
        printerService: printerService,
        nativeBridge: _FakeNativePrinterBridge(),
        transportRetryDelay: Duration.zero,
      );
      await cubit.loadLocation('location-1');

      final result = await cubit.printOrder(
        orderId: 'order-1',
        printerIds: const ['printer-1'],
      );

      expect(result.success, isTrue);
      expect(printerService.printCount, 2);
      expect(cubit.state.jobs, hasLength(1));
      expect(cubit.state.jobs.single.status, PrintJobStatus.printed);
      await cubit.close();
    },
  );

  test('records one failed job after both printer attempts fail', () async {
    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'printer-1',
        businessLocationId: 'location-1',
        name: 'Caja',
        host: '127.0.0.1',
        receiptFormat: PrinterReceiptFormat.escPosText,
      ),
    );
    final printerService = _FakePrinterService(failuresBeforeSuccess: 2);
    final cubit = PrintingCubit(
      storage: storage,
      receiptService: _FakeReceiptService(),
      formatter: _FakeFormatter(),
      printerService: printerService,
      nativeBridge: _FakeNativePrinterBridge(),
      transportRetryDelay: Duration.zero,
    );
    await cubit.loadLocation('location-1');

    final result = await cubit.printOrder(
      orderId: 'order-1',
      printerIds: const ['printer-1'],
    );

    expect(result.success, isFalse);
    expect(printerService.printCount, 2);
    expect(cubit.state.jobs, hasLength(1));
    expect(cubit.state.failedJobs.single.status, PrintJobStatus.failed);
    await cubit.close();
  });
}

class _FakePrinterService extends PrinterService {
  _FakePrinterService({this.failuresBeforeSuccess = 0});

  int failuresBeforeSuccess;
  int printCount = 0;

  @override
  Future<void> printBytes(PrinterConfiguration printer, List<int> bytes) async {
    printCount++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('Falla transitoria');
    }
  }
}

class _FakeReceiptService extends ReceiptPrintDataService {
  _FakeReceiptService({this.failVisual = false});

  final bool failVisual;
  int visualFetchCount = 0;
  Duration? lastVisualTimeout;

  @override
  Future<ReceiptPrintPayload> fetch({
    required String orderId,
    required String businessLocationId,
  }) async => ReceiptPrintPayload.fromMap({
    'business': {'name': 'Mediasis'},
    'order': {'order_id': orderId, 'human_order_number': 1, 'amount': 1000},
    'customer': const {},
    'items': const [],
    'additional_details': const [],
  });

  @override
  Future<List<int>> fetchVisualBytes({
    required String orderId,
    required String businessLocationId,
    required PrinterPaperWidth paperWidth,
    required bool supportsCutter,
    required Duration timeout,
  }) async {
    visualFetchCount++;
    lastVisualTimeout = timeout;
    if (failVisual) throw StateError('Render no disponible');
    return const [27, 64, 10];
  }
}

class _FakeFormatter extends ReceiptEscPosFormatter {
  int buildCount = 0;

  @override
  Future<List<int>> build(
    ReceiptPrintPayload payload,
    PrinterConfiguration printer,
  ) async {
    buildCount++;
    return const [27, 64, 10];
  }
}

class _FakeNativePrinterBridge extends NativePrinterBridge {
  _FakeNativePrinterBridge({
    this.sunmiInfo = const SunmiPrinterInfo(available: false),
  });

  final SunmiPrinterInfo sunmiInfo;
  int detectionCount = 0;

  @override
  Future<SunmiPrinterInfo> detectSunmiPrinter() async {
    detectionCount++;
    return sunmiInfo;
  }

  @override
  Future<void> synchronize(
    String businessLocationId,
    Iterable<PrinterConfiguration> printers,
  ) async {}

  @override
  Future<List<PrintJob>> takeCompletedJobs() async => const [];
}
