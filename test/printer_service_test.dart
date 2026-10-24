import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/native_printer_bridge.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/printer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'SUNMI printers dispatch receipt bytes through the native bridge',
    () async {
      final bridge = _RecordingNativePrinterBridge();
      final service = PrinterService(nativeBridge: bridge);
      const printer = PrinterConfiguration(
        id: 'sunmi_location-1',
        businessLocationId: 'location-1',
        name: 'Impresora integrada SUNMI',
        connectionType: PrinterConnectionType.sunmiBuiltIn,
        paperWidth: PrinterPaperWidth.mm58,
        supportsCutter: false,
      );

      await service.printBytes(printer, const [27, 64, 10]);

      expect(bridge.printedBytes, [27, 64, 10]);
    },
  );
}

class _RecordingNativePrinterBridge extends NativePrinterBridge {
  List<int>? printedBytes;

  @override
  Future<void> printSunmiBytes(List<int> bytes) async {
    printedBytes = List<int>.of(bytes);
  }
}
