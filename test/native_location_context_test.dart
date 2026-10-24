import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses one market and assigns its business to every location', () {
    final context = NativeLocationContext.fromMap({
      'success': true,
      'mode': 'clerk',
      'active_business_id': 'business-1',
      'locations': [
        {
          'business_location_id': 'location-1',
          'short_name': 'Central',
          'phone_number': '+50622222222',
          'lat': 9.9,
          'lng': -84.1,
        },
        {
          'business_location_id': 'location-2',
          'short_name': 'West',
          'phone_number': '+50622222223',
          'lat': 9.8,
          'lng': -84.2,
        },
      ],
      'market': {
        'business_id': 'business-1',
        'country_code': 'CR',
        'country_name': 'Costa Rica',
        'timezone': 'America/Costa_Rica',
        'currency_code': 'CRC',
        'locale': 'es-CR',
        'phone_country_code': '+506',
        'capabilities': ['delivery'],
      },
    });

    expect(context.locations, hasLength(2));
    expect(
      context.locations.map((location) => location.businessId),
      everyElement('business-1'),
    );
    expect(context.market?.currencyCode, 'CRC');
    expect(context.authorizationMode, 'clerk');
  });

  test('accepts an older context response without market', () {
    final context = NativeLocationContext.fromMap({
      'success': true,
      'mode': 'legacy',
      'active_business_id': 'business-1',
      'locations': const [],
    });

    expect(context.market, isNull);
  });

  test('preserves a stable backend error code', () {
    expect(
      () => NativeLocationContext.fromMap({
        'success': false,
        'code': 'MARKET_SETTINGS_MISSING',
      }),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'MARKET_SETTINGS_MISSING',
        ),
      ),
    );
  });
}
