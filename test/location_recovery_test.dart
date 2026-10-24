import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _market = BusinessMarketSettings(
  businessId: 'business-1',
  countryCode: 'CR',
  countryName: 'Costa Rica',
  timezone: 'America/Costa_Rica',
  currencyCode: 'CRC',
  locale: 'es_CR',
  phoneCountryCode: 'CR',
);

const _staleLocation = BusinessLocation(
  businessLocationId: 'stale-location',
  shortName: 'Old',
  phoneNumber: '',
  lat: '',
  lng: '',
  businessId: 'business-1',
);

const _freshLocation = BusinessLocation(
  businessLocationId: 'fresh-location',
  shortName: 'New',
  phoneNumber: '',
  lat: '',
  lng: '',
  businessId: 'business-1',
);

void main() {
  test(
    'clears stale selection and reloads locations without auto-selecting',
    () async {
      final locationService = _FakeLocationService();
      final storageService = _FakeLocationStorageService();
      final cubit = LocationCubit(
        locationService: locationService,
        storageService: storageService,
        marketService: _FakeMarketService(),
      );

      await cubit.selectLocation(_staleLocation);
      await Future.wait([
        cubit.recoverFromUnauthorizedLocation(),
        cubit.recoverFromUnauthorizedLocation(),
      ]);

      expect(storageService.clearActiveCalls, 1);
      expect(locationService.fetchCalls, 1);
      expect(locationService.requestedBusinessId, 'business-1');
      expect(cubit.state.status, LocationStatus.requiresSelection);
      expect(cubit.state.selectedLocation, isNull);
      expect(cubit.state.locations, [_freshLocation]);
      expect(cubit.state.market, _market);

      await cubit.close();
    },
  );
}

class _FakeLocationService extends SupabaseLocationService {
  int fetchCalls = 0;
  String? requestedBusinessId;

  @override
  Future<NativeLocationContext> fetchLocationContext({
    String? requestedBusinessId,
  }) async {
    fetchCalls++;
    this.requestedBusinessId = requestedBusinessId;
    return const NativeLocationContext(
      locations: [_freshLocation],
      activeBusinessId: 'business-1',
      authorizationMode: 'legacy',
      market: _market,
    );
  }
}

class _FakeLocationStorageService extends LocationStorageService {
  int clearActiveCalls = 0;

  @override
  Future<void> clearActiveLocation() async {
    clearActiveCalls++;
  }

  @override
  Future<void> saveActiveLocation(BusinessLocation location) async {}

  @override
  Future<void> saveBusinessLocations(BusinessLocations locations) async {}
}

class _FakeMarketService extends BusinessMarketService {
  @override
  Future<BusinessMarketSettings> load(BusinessLocation location) async =>
      _market;

  @override
  Future<void> cache(BusinessMarketSettings market) async {}
}
