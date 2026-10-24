import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'store_availability_state.dart';

class StoreAvailabilityCubit extends Cubit<StoreAvailabilityState> {
  StoreAvailabilityCubit({
    SupabaseStoreAvailabilityService? storeAvailabilityService,
  }) : _storeAvailabilityService =
           storeAvailabilityService ?? SupabaseStoreAvailabilityService(),
       super(const StoreAvailabilityState());

  final SupabaseStoreAvailabilityService _storeAvailabilityService;
  BusinessMarketSettings? _market;

  DateTime _marketNow() {
    final market = _market;
    if (market == null) throw StateError('MARKET_SETTINGS_UNAVAILABLE');
    return market.localTime(DateTime.now());
  }

  Future<void> loadForLocation(
    String businessLocationId, {
    bool force = false,
    BusinessMarketSettings? market,
  }) async {
    if (state.businessLocationId != businessLocationId) _market = market;
    if (market != null) _market = market;
    if (businessLocationId.isEmpty) {
      emit(
        state.copyWith(
          status: StoreAvailabilityStatus.failure,
          businessLocationId: '',
          errorMessage: 'No hay una ubicación activa.',
          clearSnapshot: true,
        ),
      );
      return;
    }

    final isSameLocation = state.businessLocationId == businessLocationId;
    if (!force &&
        isSameLocation &&
        (state.status == StoreAvailabilityStatus.ready ||
            state.status == StoreAvailabilityStatus.loading)) {
      return;
    }

    emit(
      state.copyWith(
        status: StoreAvailabilityStatus.loading,
        businessLocationId: businessLocationId,
        clearErrorMessage: true,
        clearTransientMessage: true,
      ),
    );

    await _fetchAvailability(businessLocationId);
  }

  Future<void> refresh() async {
    if (state.businessLocationId.isEmpty) return;
    emit(
      state.copyWith(
        status: StoreAvailabilityStatus.loading,
        clearErrorMessage: true,
        clearTransientMessage: true,
      ),
    );
    await _fetchAvailability(state.businessLocationId);
  }

  Future<OrderActionResult> setClosed(bool closed) async {
    final businessLocationId = state.businessLocationId;
    if (businessLocationId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'No hay una ubicación activa para actualizar este estado.',
      );
    }
    if (state.isSaving) {
      return const OrderActionResult(success: true);
    }

    emit(state.copyWith(isSaving: true, clearTransientMessage: true));

    try {
      final result = await _storeAvailabilityService
          .setManualOrderClosureForDay(
            businessLocationId: businessLocationId,
            localDate: _marketNow(),
            closed: closed,
          );
      if (!result.success) {
        throw StateError(
          result.message ?? 'No se pudo actualizar el estado de la app.',
        );
      }

      emit(state.copyWith(isSaving: false));
      await _fetchAvailability(businessLocationId);
      return const OrderActionResult(success: true);
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          transientMessage:
              '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudo actualizar el estado de la app.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
        ),
      );
      return OrderActionResult(
        success: false,
        message: '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
            ? 'No se pudo actualizar el estado de la app.'
            : '$error'.replaceFirst('Bad state: ', '').trim(),
      );
    }
  }

  void clearTransientMessage() {
    if (state.transientMessage.isEmpty) return;
    emit(state.copyWith(clearTransientMessage: true));
  }

  void reset() {
    _market = null;
    emit(const StoreAvailabilityState());
  }

  Future<void> _fetchAvailability(String businessLocationId) async {
    try {
      final snapshot = await _storeAvailabilityService.fetchStoreAvailability(
        businessLocationId: businessLocationId,
        localNow: _marketNow(),
      );

      emit(
        state.copyWith(
          status: StoreAvailabilityStatus.ready,
          businessLocationId: businessLocationId,
          isOpen: snapshot.isOpen,
          note: snapshot.note,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StoreAvailabilityStatus.failure,
          businessLocationId: businessLocationId,
          errorMessage: '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudo cargar el estado de la app.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
          clearSnapshot: true,
        ),
      );
    }
  }
}
