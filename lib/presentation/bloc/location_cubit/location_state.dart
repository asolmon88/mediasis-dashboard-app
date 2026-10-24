part of 'location_cubit.dart';

enum LocationStatus {
  initial,
  loading,
  requiresSelection,
  ready,
  empty,
  failure,
}

class LocationState extends Equatable {
  const LocationState({
    this.status = LocationStatus.initial,
    this.locations = const [],
    this.selectedLocation,
    this.errorMessage = '',
    this.market,
  });

  final LocationStatus status;
  final BusinessLocations locations;
  final BusinessLocation? selectedLocation;
  final String errorMessage;
  final BusinessMarketSettings? market;

  LocationState copyWith({
    LocationStatus? status,
    BusinessLocations? locations,
    BusinessLocation? selectedLocation,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearSelectedLocation = false,
    BusinessMarketSettings? market,
    bool clearMarket = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      market: clearMarket ? null : market ?? this.market,
      locations: locations ?? this.locations,
      selectedLocation: clearSelectedLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    locations,
    selectedLocation,
    errorMessage,
    market,
  ];
}
