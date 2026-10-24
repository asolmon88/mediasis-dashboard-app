import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt payload parses variants, options, and totals', () {
    final payload = ReceiptPrintPayload.fromMap({
      'business': {'name': 'Restaurante'},
      'order': {
        'order_id': 'order-1',
        'human_order_number': 42,
        'products_price': 5500,
      },
      'customer': {'full_name': 'Ana Perez'},
      'items': [
        {
          'name': 'Hamburguesa',
          'variant_name': 'Doble',
          'quantity': 2,
          'display_unit_price': 2750,
          'line_total': 5500,
          'options': {
            'selection': [
              {
                'name': 'Queso',
                'choice': {'choice': 'Cheddar', 'price': 500},
              },
            ],
          },
        },
      ],
      'additional_details': const [],
    });

    expect(payload.orderId, 'order-1');
    expect(payload.humanOrderNumber, '42');
    expect(payload.items.single.variantName, 'Doble');
    expect(payload.items.single.quantity, 2);
    expect(payload.items.single.lineTotal, 5500);
  });

  test('printer configuration round trips all printing settings', () {
    final printer = PrinterConfiguration(
      id: 'printer-1',
      businessLocationId: 'location-1',
      name: 'Caja',
      host: '192.168.1.20',
      port: 9100,
      receiptFormat: PrinterReceiptFormat.escPosText,
      paperWidth: PrinterPaperWidth.mm58,
      supportsCutter: false,
      automaticPrinting: true,
      verified: true,
      lastTestedAt: DateTime.utc(2026, 8, 18),
    );

    final restored = PrinterConfiguration.fromMap(printer.toMap());
    expect(restored.paperWidth, PrinterPaperWidth.mm58);
    expect(restored.receiptFormat, PrinterReceiptFormat.escPosText);
    expect(restored.supportsCutter, isFalse);
    expect(restored.automaticPrinting, isTrue);
    expect(restored.verified, isTrue);
  });

  test('legacy printers remain network printers', () {
    final printer = PrinterConfiguration.fromMap({
      'id': 'legacy',
      'business_location_id': 'location-1',
      'name': 'Caja',
      'host': '192.168.1.20',
    });

    expect(printer.connectionType, PrinterConnectionType.network);
    expect(printer.receiptFormat, PrinterReceiptFormat.escPosText);
  });

  test('SUNMI printer configuration round trips without a network host', () {
    const printer = PrinterConfiguration(
      id: 'sunmi_location-1',
      businessLocationId: 'location-1',
      name: 'Impresora integrada SUNMI',
      connectionType: PrinterConnectionType.sunmiBuiltIn,
      deviceModel: 'V2s',
      paperWidth: PrinterPaperWidth.mm58,
      supportsCutter: false,
    );

    final restored = PrinterConfiguration.fromMap(printer.toMap());
    expect(restored.connectionType, PrinterConnectionType.sunmiBuiltIn);
    expect(restored.host, isEmpty);
    expect(restored.deviceModel, 'V2s');
  });
}
