import 'package:mediasis_dashboard_app/infrastructure/models.dart';

class PrinterTransport {
  Future<void> printBytes(PrinterConfiguration printer, List<int> bytes) {
    throw const PrinterConnectionException(
      'La impresion por IP no esta disponible en esta plataforma.',
    );
  }
}
