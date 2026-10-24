import 'package:mediasis_dashboard_app/infrastructure/models.dart';

class PrinterDiscoveryService {
  bool get isSupported => false;

  Future<List<DiscoveredPrinter>> discover({bool scanSubnet = false}) async =>
      const [];
}
