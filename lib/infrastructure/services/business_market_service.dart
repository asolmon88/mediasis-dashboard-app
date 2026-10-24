import 'dart:async';
import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';
import 'package:mediasis_dashboard_app/infrastructure/models/location_models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BusinessMarketService {
  BusinessMarketService({DashboardApiClient? apiClient})
    : _apiClient = apiClient ?? dashboardApiClient;

  final DashboardApiClient _apiClient;

  Future<BusinessMarketSettings> load(BusinessLocation location) async {
    if (location.businessId.isEmpty) {
      throw StateError('MARKET_SETTINGS_INVALID');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'business_market_v1:${location.businessId}';
    BusinessMarketSettings? cached() {
      try {
        final raw = prefs.getString(key);
        if (raw == null) return null;
        final market = BusinessMarketSettings.fromMap(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        return market.businessId == location.businessId ? market : null;
      } catch (_) {
        return null;
      }
    }

    http.Response response;
    try {
      response = await _apiClient
          .get(
            '/api/native/market-settings',
            queryParameters: {
              'business_location_id': location.businessLocationId,
            },
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      final fallback = cached();
      return fallback ?? (throw StateError('MARKET_SETTINGS_UNAVAILABLE'));
    } on http.ClientException {
      final fallback = cached();
      return fallback ?? (throw StateError('MARKET_SETTINGS_UNAVAILABLE'));
    } on SessionAccessException catch (error) {
      if (error.failure == SessionAccessFailure.temporarilyUnavailable) {
        final fallback = cached();
        return fallback ?? (throw StateError('MARKET_SETTINGS_UNAVAILABLE'));
      }
      throw StateError('UNAUTHORIZED');
    } on DashboardAuthenticationException {
      throw StateError('UNAUTHORIZED');
    }
    if (response.statusCode >= 500) {
      return cached() ?? (throw StateError('MARKET_SETTINGS_UNAVAILABLE'));
    }
    // Authorization/configuration errors must not be hidden by cached data.
    if (response.statusCode == 403) {
      await prefs.remove(key);
      throw StateError('UNAUTHORIZED');
    }
    if (response.statusCode != 200) {
      throw StateError('MARKET_SETTINGS_UNAVAILABLE');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true || body['data'] is! Map) {
      throw StateError('MARKET_SETTINGS_UNAVAILABLE');
    }
    final marketMap = Map<String, dynamic>.from(body['data'] as Map);
    final market = BusinessMarketSettings.fromMap(marketMap);
    if (market.businessId != location.businessId) {
      throw StateError('MARKET_SETTINGS_INVALID');
    }
    await cache(market);
    return market;
  }

  Future<void> cache(BusinessMarketSettings market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'business_market_v1:${market.businessId}',
      jsonEncode(market.toMap()),
    );
  }
}
