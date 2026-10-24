import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    BusinessMarketSettings.initializeTimezones();
  });

  test('formats Panama USD with cents and its regional separators', () {
    final market = BusinessMarketSettings.fromMap({
      'business_id': 'business-pa',
      'country_code': 'PA',
      'country_name': 'Panama',
      'timezone': 'America/Panama',
      'currency_code': 'USD',
      'locale': 'es-PA',
      'phone_country_code': 'PA',
      'capabilities': <String>[],
    });

    expect(market.formatMoney(1234.5), 'USD 1.234,50');
    expect(
      market.formatDate(
        DateTime.parse('2026-09-09T18:30:00Z'),
        pattern: 'HH:mm',
      ),
      '13:30',
    );
  });

  test('keeps integer CRC concise while preserving fractional values', () {
    final market = BusinessMarketSettings.fromMap({
      'business_id': 'business-cr',
      'country_code': 'CR',
      'country_name': 'Costa Rica',
      'timezone': 'America/Costa_Rica',
      'currency_code': 'CRC',
      'locale': 'es-CR',
      'phone_country_code': 'CR',
      'capabilities': <String>['invoicing.electronic'],
    });

    expect(market.formatMoney(1234), 'CRC 1.234');
    expect(market.formatMoney(1234.5), 'CRC 1.234,50');
  });

  test('rejects incomplete settings instead of falling back to CRC', () {
    expect(
      () => BusinessMarketSettings.fromMap({
        'business_id': 'business-pa',
        'currency_code': 'USD',
      }),
      throwsFormatException,
    );
  });
}
