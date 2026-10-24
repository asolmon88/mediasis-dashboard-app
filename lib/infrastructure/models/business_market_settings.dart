import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class BusinessMarketSettings extends Equatable {
  const BusinessMarketSettings({
    required this.businessId,
    required this.countryCode,
    required this.countryName,
    required this.timezone,
    required this.currencyCode,
    required this.locale,
    required this.phoneCountryCode,
    this.capabilities = const [],
  });

  final String businessId;
  final String countryCode;
  final String countryName;
  final String timezone;
  final String currencyCode;
  final String locale;
  final String phoneCountryCode;
  final List<String> capabilities;
  static bool _zonesInitialized = false;

  static void initializeTimezones() {
    if (_zonesInitialized) return;
    tz_data.initializeTimeZones();
    _zonesInitialized = true;
  }

  factory BusinessMarketSettings.fromMap(Map<String, dynamic> map) {
    String requiredValue(String key) {
      final value = '${map[key] ?? ''}'.trim();
      if (value.isEmpty) throw FormatException('MARKET_SETTINGS_INVALID: $key');
      return value;
    }

    final settings = BusinessMarketSettings(
      businessId: requiredValue('business_id'),
      countryCode: requiredValue('country_code'),
      countryName: requiredValue('country_name'),
      timezone: requiredValue('timezone'),
      currencyCode: requiredValue('currency_code'),
      locale: requiredValue('locale').replaceAll('-', '_'),
      phoneCountryCode: requiredValue('phone_country_code'),
      capabilities: List<String>.unmodifiable(
        (map['capabilities'] as List? ?? const []).whereType<String>(),
      ),
    );
    initializeTimezones();
    tz.getLocation(settings.timezone);
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(settings.currencyCode)) {
      throw const FormatException('MARKET_SETTINGS_INVALID');
    }
    return settings;
  }

  Map<String, dynamic> toMap() => {
    'business_id': businessId,
    'country_code': countryCode,
    'country_name': countryName,
    'timezone': timezone,
    'currency_code': currencyCode,
    'locale': locale.replaceAll('_', '-'),
    'phone_country_code': phoneCountryCode,
    'capabilities': capabilities,
  };

  String formatMoney(num? value) {
    if (value == null || !value.isFinite) return '-';
    final hasFraction = value != value.round();
    final decimals = currencyCode == 'CRC' && !hasFraction ? 0 : 2;
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimals,
    ).format(value);
    return '$currencyCode $number';
  }

  tz.TZDateTime localTime(DateTime instant) {
    initializeTimezones();
    return tz.TZDateTime.from(instant, tz.getLocation(timezone));
  }

  DateTime startOfDayUtc(DateTime date) {
    initializeTimezones();
    return tz.TZDateTime(
      tz.getLocation(timezone),
      date.year,
      date.month,
      date.day,
    ).toUtc();
  }

  String formatDate(DateTime instant, {String? pattern}) =>
      (pattern == null
              ? DateFormat.yMMMd(locale).add_jm()
              : DateFormat(pattern, locale))
          .format(localTime(instant));

  @override
  List<Object?> get props => [
    businessId,
    countryCode,
    countryName,
    timezone,
    currencyCode,
    locale,
    phoneCountryCode,
    capabilities,
  ];
}
