import 'package:mediasis_dashboard_app/infrastructure/models.dart';

import 'printer_transport.dart';
import 'native_printer_bridge.dart';

class PrinterService {
  PrinterService({NativePrinterBridge? nativeBridge})
    : _nativeBridge = nativeBridge ?? NativePrinterBridge();

  final NativePrinterBridge _nativeBridge;

  Future<void> printBytes(PrinterConfiguration printer, List<int> bytes) {
    if (printer.connectionType == PrinterConnectionType.sunmiBuiltIn) {
      return _nativeBridge.printSunmiBytes(bytes);
    }
    return PrinterTransport().printBytes(printer, bytes);
  }
}
