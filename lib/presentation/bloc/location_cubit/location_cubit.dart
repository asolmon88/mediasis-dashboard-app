import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit({
    SupabaseLocationService? locationService,
    LocationStorageService? storageService,
    BusinessMarketService? marketService,
  }) : _locationService = locationService ?? SupabaseLocationService(),
       _storageService = storageService ?? LocationStorageService(),
       _marketService = marketService ?? BusinessMarketService(),
       super(const LocationState());

  static const Duration _silentRetryDelay = Duration(milliseconds: 650);

  final SupabaseLocationService _locationService;
  final LocationStorageService _storageService;
  final BusinessMarketService _marketService;
  int _generation = 0;
  bool _recoveringUnauthorizedLocation = false;

  Future<void> loadLocations() async {
    final generation = ++_generation;
    emit(
      state.copyWith(status: LocationStatus.loading, clearErrorMessage: true),
    );

    try {
      await _loadLocationsAttempt(generation);
    } catch (e) {
      await Future<void>.delayed(_silentRetryDelay);

      try {
        if (generation != _generation || isClosed) return;
        await _loadLocationsAttempt(generation);
      } catch (_) {
        if (generation != _generation || isClosed) return;
        emit(
          state.copyWith(
            status: LocationStatus.failure,
            errorMessage:
                'No se pudieron cargar los locales o su configuracion regional. Intenta de nuevo.',
          ),
        );
      }
    }
  }

  Future<void> selectLocation(BusinessLocation location) async {
    final generation = ++_generation;
    emit(state.copyWith(status: LocationStatus.loading));
    try {
      final market = await _marketForLocation(location, state.market);
      if (generation != _generation || isClosed) return;
      await _storageService.saveActiveLocation(location);
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: LocationStatus.ready,
          selectedLocation: location,
          market: market,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          errorMessage:
              'No se pudo cargar la configuracion regional del local. Intenta de nuevo.',
        ),
      );
    }
  }

  Future<void> refreshMarket() async {
    final location = state.selectedLocation;
    if (location == null || state.status != LocationStatus.ready) return;
    final generation = _generation;
    try {
      final context = await _locationService.fetchLocationContext(
        requestedBusinessId: location.businessId,
      );
      if (generation != _generation || isClosed) return;
      final refreshedLocation = _locationById(
        context.locations,
        location.businessLocationId,
      );
      if (refreshedLocation == null) return;
      final market = await _marketForLocation(
        refreshedLocation,
        context.market,
      );
      if (generation != _generation || isClosed) return;
      await _storageService.saveBusinessLocations(context.locations);
      await _storageService.saveActiveLocation(refreshedLocation);
      emit(
        state.copyWith(
          locations: context.locations,
          selectedLocation: refreshedLocation,
          market: market,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      // Resume refresh is best-effort. Keep the last valid location and market.
    }
  }

  void showLocationSelector() {
    _generation++;
    emit(
      state.copyWith(
        status: LocationStatus.requiresSelection,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> recoverFromUnauthorizedLocation() async {
    final staleLocation = state.selectedLocation;
    if (_recoveringUnauthorizedLocation ||
        staleLocation == null ||
        state.status != LocationStatus.ready) {
      return;
    }

    _recoveringUnauthorizedLocation = true;
    final generation = ++_generation;
    final previousMarket = state.market;
    emit(
      state.copyWith(
        status: LocationStatus.loading,
        locations: const [],
        clearSelectedLocation: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _storageService.clearActiveLocation();
      final context = await _locationService.fetchLocationContext(
        requestedBusinessId: staleLocation.businessId,
      );
      if (generation != _generation || isClosed) return;

      await _storageService.saveBusinessLocations(context.locations);
      if (generation != _generation || isClosed) return;

      final market =
          context.market ??
          (previousMarket?.businessId == context.activeBusinessId
              ? previousMarket
              : null);
      if (market != null) await _marketService.cache(market);
      if (generation != _generation || isClosed) return;

      if (context.locations.isEmpty) {
        emit(
          state.copyWith(
            status: LocationStatus.empty,
            locations: const [],
            clearSelectedLocation: true,
            market: market,
            clearMarket: market == null,
            errorMessage: 'No hay locales disponibles para esta cuenta.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LocationStatus.requiresSelection,
          locations: context.locations,
          clearSelectedLocation: true,
          market: market,
          clearMarket: market == null,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: LocationStatus.failure,
          locations: const [],
          clearSelectedLocation: true,
          errorMessage:
              'No se pudieron cargar los locales o su configuracion regional. Intenta de nuevo.',
        ),
      );
    } finally {
      _recoveringUnauthorizedLocation = false;
    }
  }

  Future<void> reset() async {
    _generation++;
    await _storageService.clear();
    emit(const LocationState());
  }

  Future<void> _loadLocationsAttempt(int generation) async {
    final persistedActiveLocation = await _storageService.readActiveLocation();
    final context = await _locationService.fetchLocationContext(
      requestedBusinessId: persistedActiveLocation?.businessId,
    );
    final locations = context.locations;
    if (generation != _generation || isClosed) return;

    await _storageService.saveBusinessLocations(locations);

    if (locations.isEmpty) {
      emit(
        state.copyWith(
          status: LocationStatus.empty,
          locations: const [],
          clearSelectedLocation: true,
          errorMessage: 'No hay locales disponibles para esta cuenta.',
        ),
      );
      return;
    }

    final selectedLocation = _resolveSelectedLocation(
      locations: locations,
      persistedLocation: persistedActiveLocation,
    );

    final market = selectedLocation == null
        ? context.market
        : await _marketForLocation(selectedLocation, context.market);
    if (generation != _generation || isClosed) return;
    if (selectedLocation != null) {
      await _storageService.saveActiveLocation(selectedLocation);
    }

    emit(
      state.copyWith(
        status: selectedLocation == null
            ? LocationStatus.requiresSelection
            : LocationStatus.ready,
        locations: locations,
        selectedLocation: selectedLocation,
        market: market,
        clearMarket: market == null,
        clearErrorMessage: true,
      ),
    );
  }

  Future<BusinessMarketSettings> _marketForLocation(
    BusinessLocation location,
    BusinessMarketSettings? preferred,
  ) async {
    if (preferred != null && preferred.businessId == location.businessId) {
      await _marketService.cache(preferred);
      return preferred;
    }
    return _marketService.load(location);
  }

  BusinessLocation? _locationById(
    BusinessLocations locations,
    String locationId,
  ) {
    for (final location in locations) {
      if (location.businessLocationId == locationId) return location;
    }
    return null;
  }

  BusinessLocation? _resolveSelectedLocation({
    required BusinessLocations locations,
    required BusinessLocation? persistedLocation,
  }) {
    if (persistedLocation == null) return null;

    for (final location in locations) {
      if (location.businessLocationId == persistedLocation.businessLocationId) {
        return location;
      }
    }

    if (locations.isEmpty) return null;
    return locations.first;
  }
}
