import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('printer storage remains isolated by business location', () async {
    final storage = PrinterStorageService();
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'a',
        businessLocationId: 'location-a',
        name: 'Caja A',
        host: '10.0.0.10',
      ),
    );
    await storage.savePrinter(
      const PrinterConfiguration(
        id: 'b',
        businessLocationId: 'location-b',
        name: 'Caja B',
        host: '10.0.0.11',
      ),
    );

    expect((await storage.readPrinters('location-a')).single.id, 'a');
    expect((await storage.readPrinters('location-b')).single.id, 'b');
  });

  test('interrupted jobs become failed after restart', () async {
    final storage = PrinterStorageService();
    await storage.saveJob(
      PrintJob(
        id: 'job-1',
        businessLocationId: 'location-a',
        orderId: 'order-1',
        printerId: 'printer-1',
        printerName: 'Caja',
        trigger: PrintJobTrigger.automatic,
        status: PrintJobStatus.printing,
        attemptedAt: DateTime.now(),
      ),
    );

    final restored = (await storage.readJobs('location-a')).single;
    expect(restored.status, PrintJobStatus.failed);
    expect(restored.error, contains('interrumpida'));
  });

  test(
    'persists an isolated automatic-print order baseline per location',
    () async {
      final storage = PrinterStorageService();
      await storage.saveOrderBaseline('location-1', {'order-1', 'order-2'});
      await storage.saveOrderBaseline('location-2', {'order-3'});

      expect(await storage.readOrderBaseline('location-1'), {
        'order-1',
        'order-2',
      });
      expect(await storage.readOrderBaseline('location-2'), {'order-3'});
    },
  );
}
