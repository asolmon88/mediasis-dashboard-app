import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models/business_market_settings.dart';

class BusinessLocation {
  const BusinessLocation({
    required this.businessLocationId,
    required this.shortName,
    required this.phoneNumber,
    required this.lat,
    required this.lng,
    this.businessId = '',
  });

  final String businessLocationId;
  final String shortName;
  final String phoneNumber;
  final String lat;
  final String lng;
  final String businessId;

  factory BusinessLocation.fromMap(Map<String, dynamic> map) {
    return BusinessLocation(
      businessLocationId: map['business_location_id'] as String? ?? '',
      shortName: map['short_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      lat: '${map['lat'] ?? ''}',
      lng: '${map['lng'] ?? ''}',
      businessId: '${map['business_uid'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_location_id': businessLocationId,
      'short_name': shortName,
      'phone_number': phoneNumber,
      'lat': lat,
      'lng': lng,
      'business_uid': businessId,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BusinessLocation.fromJson(String source) {
    return BusinessLocation.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}

typedef BusinessLocations = List<BusinessLocation>;

class NativeLocationContext {
  const NativeLocationContext({
    required this.locations,
    required this.activeBusinessId,
    required this.authorizationMode,
    this.market,
  });

  final BusinessLocations locations;
  final String activeBusinessId;
  final String authorizationMode;
  final BusinessMarketSettings? market;

  factory NativeLocationContext.fromMap(Map<String, dynamic> map) {
    if (map['success'] != true) {
      throw StateError(
        '${map['code'] ?? map['message'] ?? 'LOCATION_CONTEXT_UNAVAILABLE'}',
      );
    }

    final businessId = '${map['active_business_id'] ?? ''}';
    final locations = (map['locations'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final location = Map<String, dynamic>.from(item);
          location['business_uid'] = businessId;
          return BusinessLocation.fromMap(location);
        })
        .where((location) => location.businessLocationId.isNotEmpty)
        .toList(growable: false);
    final marketValue = map['market'];

    return NativeLocationContext(
      locations: locations,
      activeBusinessId: businessId,
      authorizationMode: '${map['mode'] ?? ''}',
      market: marketValue is Map
          ? BusinessMarketSettings.fromMap(
              Map<String, dynamic>.from(marketValue),
            )
          : null,
    );
  }
}

class ActiveLocation {
  const ActiveLocation({required this.activeLocation});

  final BusinessLocation activeLocation;

  Map<String, dynamic> toMap() {
    return {'activeLocation': activeLocation.toMap()};
  }

  String toJson() => jsonEncode(toMap());

  factory ActiveLocation.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return ActiveLocation(
      activeLocation: BusinessLocation.fromMap(
        map['activeLocation'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
    );
  }
}
