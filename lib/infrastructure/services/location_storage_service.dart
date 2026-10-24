import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationStorageService {
  static const _activeLocationKey = 'activeLocation';
  static const _businessLocationsKey = 'businessLocations';

  Future<void> saveActiveLocation(BusinessLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activeLocationKey,
      ActiveLocation(activeLocation: location).toJson(),
    );
  }

  Future<BusinessLocation?> readActiveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeLocationKey);
    if (value == null || value.isEmpty) return null;

    try {
      return ActiveLocation.fromJson(value).activeLocation;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeLocationKey);
  }

  Future<void> saveBusinessLocations(BusinessLocations locations) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      locations.map((location) => location.toMap()).toList(),
    );
    await prefs.setString(_businessLocationsKey, payload);
  }

  Future<BusinessLocations> readBusinessLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_businessLocationsKey);
    if (value == null || value.isEmpty) return const [];

    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map((item) => BusinessLocation.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeLocationKey);
    await prefs.remove(_businessLocationsKey);
  }
}
