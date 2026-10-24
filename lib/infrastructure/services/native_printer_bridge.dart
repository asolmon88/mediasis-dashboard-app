import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter/services.dart';

class NativePrinterBridge {
  static const _channel = MethodChannel('com.mediasis.dashboardapp/printing');

  Future<void> synchronize(
    String businessLocationId,
    Iterable<PrinterConfiguration> printers,
  ) async {
    try {
      await _channel.invokeMethod<void>('synchronize', {
        'business_location_id': businessLocationId,
        'printers': printers
            .where((printer) => printer.automaticPrinting && printer.verified)
            .map(
              (printer) => {
                'id': printer.id,
                'name': printer.name,
                'host': printer.host,
                'port': printer.port,
                'connection_type': printer.connectionType.name,
                'receipt_format': printer.receiptFormat.name,
                'paper_width': printer.paperWidth.name,
                'supports_cutter': printer.supportsCutter,
              },
            )
            .toList(),
      });
    } on MissingPluginException {
      // Desktop platforms do not receive OneSignal background pushes.
    }
  }

  Future<SunmiPrinterInfo> detectSunmiPrinter() async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'detectSunmiPrinter',
      );
      if (value == null) {
        return const SunmiPrinterInfo(
          available: false,
          serviceStatus: 'No se pudo consultar el servicio SUNMI.',
        );
      }
      return SunmiPrinterInfo(
        available: value['available'] == true,
        model: '${value['model'] ?? ''}',
        deviceModel: '${value['device_model'] ?? ''}',
        paperWidth: value['paper_width'] == 'mm80'
            ? PrinterPaperWidth.mm80
            : PrinterPaperWidth.mm58,
        printerState: value['printer_state'] is num
            ? (value['printer_state'] as num).toInt()
            : int.tryParse('${value['printer_state'] ?? ''}') ?? 0,
        serviceStatus: '${value['service_status'] ?? ''}',
      );
    } on MissingPluginException {
      return const SunmiPrinterInfo(
        available: false,
        serviceStatus: 'La deteccion SUNMI solo esta disponible en Android.',
      );
    } on PlatformException catch (error) {
      return SunmiPrinterInfo(
        available: false,
        serviceStatus:
            error.message ?? 'No se pudo consultar el servicio SUNMI.',
      );
    }
  }

  Future<void> printSunmiBytes(List<int> bytes) async {
    try {
      await _channel.invokeMethod<void>(
        'printSunmiBytes',
        Uint8List.fromList(bytes),
      );
    } on MissingPluginException {
      throw const PrinterConnectionException(
        'La impresora integrada SUNMI no esta disponible.',
      );
    } on PlatformException catch (error) {
      throw PrinterConnectionException(
        error.message ?? 'No se pudo imprimir en la impresora SUNMI.',
      );
    }
  }

  Future<List<PrintJob>> takeCompletedJobs() async {
    try {
      final values = await _channel.invokeListMethod<dynamic>('takeJobs');
      return (values ?? const [])
          .whereType<Map>()
          .map((value) => PrintJob.fromMap(value.cast<String, dynamic>()))
          .toList();
    } on MissingPluginException {
      return const [];
    }
  }
}
