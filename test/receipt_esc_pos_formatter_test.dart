import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('es_CR'));

  test('generates non-empty 58mm and 80mm ESC/POS receipts', () async {
    final payload = ReceiptPrintPayload.fromMap({
      'market': {
        'business_id': 'business-1',
        'country_code': 'CR',
        'country_name': 'Costa Rica',
        'timezone': 'America/Costa_Rica',
        'currency_code': 'CRC',
        'locale': 'es-CR',
        'phone_country_code': 'CR',
      },
      'business': {'name': 'Cafetería Internacional Ñandú de Costa Rica'},
      'order': {
        'order_id': 'order-1',
        'human_order_number': 8,
        'created_at': '2026-08-18T12:00:00Z',
        'products_price': 5000,
        'delivery_price': 1500,
        'amount': 6500,
        'discount_amount': 500,
        'cashback_redeemed_minor': 10000,
        'payment_method_name': 'Sinpe movil',
        'delivery_method_name': 'Recoger en el local',
        'order_status': 'Pendiente',
        'tracking_link': 'https://example.com/tracking',
      },
      'customer': {'full_name': 'Jose Solis', 'phone': '8888-8888'},
      'items': [
        {
          'name': 'Café con azúcar',
          'variant_name': 'Grande',
          'quantity': 1,
          'display_unit_price': 5000,
          'line_total': 5000,
          'options': {
            'checkbox': [
              {
                'name': 'Extras',
                'choices': [
                  {'choice': 'Leche deslactosada', 'price': 500},
                ],
              },
            ],
          },
        },
      ],
      'additional_details': [
        {'type': 'short_answer', 'question': 'Mesa', 'value': '12'},
      ],
    });
    final formatter = ReceiptEscPosFormatter();

    for (final width in PrinterPaperWidth.values) {
      final bytes = await formatter.build(
        payload,
        PrinterConfiguration(
          id: 'printer-${width.name}',
          businessLocationId: 'location-1',
          name: 'Caja',
          host: '127.0.0.1',
          paperWidth: width,
          supportsCutter: false,
        ),
      );
      expect(bytes.length, greaterThan(150));
      final printable = String.fromCharCodes(bytes);
      expect(printable, contains('RECIBO'));
      expect(printable, contains('Metodo de pago'));
      expect(printable, contains('Items'));
      expect(printable, contains('1x Cafe con azucar'));
      expect(printable, contains('Grande'));
      expect(printable, contains('Extras: Leche'));
      expect(printable, contains('deslactosada'));
      expect(printable, contains('+CRC 500'));
      expect(printable, contains('Totales'));
      expect(printable, contains('CRC 5.000'));
      expect(printable, contains('Cliente'));
      expect(printable, contains('Detalles adicionales'));
      expect(printable, contains('mediasis'));
      expect(printable, isNot(contains('₡')));
      expect(printable, isNot(contains('�')));
      expect(printable, isNot(contains('Delivery')));
      expect(printable, isNot(contains('Envio gratis')));
      expect(printable, isNot(contains('Cashback utilizado')));
      expect(_containsSequence(bytes, const [0x1b, 0x4d, 0x00]), isTrue);
      if (width == PrinterPaperWidth.mm58) {
        expect(_longestRun(bytes, '-'.codeUnitAt(0)), lessThanOrEqualTo(32));
      }
      if (width == PrinterPaperWidth.mm80) {
        expect(_longestRun(bytes, '-'.codeUnitAt(0)), lessThanOrEqualTo(42));
      }
    }
  });
}

bool _containsSequence(List<int> bytes, List<int> sequence) {
  for (var index = 0; index <= bytes.length - sequence.length; index++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (bytes[index + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

int _longestRun(List<int> bytes, int value) {
  var longest = 0;
  var current = 0;
  for (final byte in bytes) {
    if (byte == value) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }
  return longest;
}
