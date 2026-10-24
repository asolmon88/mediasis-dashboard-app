import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/order_detail_formatters.dart';
import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const market = BusinessMarketSettings(
    businessId: 'business-1',
    countryCode: 'CR',
    countryName: 'Costa Rica',
    timezone: 'America/Costa_Rica',
    currencyCode: 'CRC',
    locale: 'es_CR',
    phoneCountryCode: 'CR',
  );
  group('formatProductOptions', () {
    test('formats checkbox quantities after price when greater than one', () {
      final options = {
        'checkbox': [
          {
            'name': 'Adicionales',
            'choices': [
              {
                'choice': 'Papas + té frío personal',
                'price': 1900,
                'quantity': 3,
              },
            ],
          },
        ],
      };

      final result = formatProductOptions(options, market: market);

      expect(
        result.single.values.single,
        'Papas + té frío personal (CRC 1.900) (3)',
      );
    });

    test('omits checkbox quantity when it is one or missing', () {
      final options = {
        'checkbox': [
          {
            'name': 'Salsas',
            'choices': [
              {'choice': 'Salsa BBQ', 'price': 500, 'quantity': 1},
              {'choice': 'Salsa ranch', 'price': 500},
            ],
          },
        ],
      };

      final result = formatProductOptions(options, market: market);

      expect(result.single.values, [
        'Salsa BBQ (CRC 500)',
        'Salsa ranch (CRC 500)',
      ]);
    });

    test('formats checkbox quantity without price', () {
      final options = {
        'checkbox': [
          {
            'name': 'Extras',
            'choices': [
              {'choice': 'Choice', 'quantity': 2},
            ],
          },
        ],
      };

      final result = formatProductOptions(options, market: market);

      expect(result.single.values.single, 'Choice (2)');
    });

    test('formats a selection quantity from the production order shape', () {
      final options = {
        'selection': [
          {
            'name': 'Deseas agregar un extra?',
            'choice': {
              'choice': 'Torta Smash',
              'price': 950,
              'quantity': 2,
              'product_option_choice_id':
                  '76e7443d-a8cb-4354-b7c8-73b6b3083a3e',
            },
          },
        ],
      };

      final result = formatProductOptions(options, market: market);

      expect(result.single.values.single, 'Torta Smash (CRC 950) (2)');
    });

    test('keeps selection and text options unchanged', () {
      final options = {
        'selection': [
          {
            'name': 'Escoge 1 salsa',
            'choice': {'choice': 'Salsa BBQ', 'price': 0},
          },
        ],
        'text': [
          {'name': 'Nota', 'value': 'Sin cebolla'},
        ],
      };

      final result = formatProductOptions(options, market: market);

      expect(result.map((option) => option.values).toList(), [
        ['Salsa BBQ'],
        ['Sin cebolla'],
      ]);
    });
  });
}
