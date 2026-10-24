import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'delivery_preparation_state.dart';

class DeliveryPreparationCubit extends Cubit<DeliveryPreparationState> {
  DeliveryPreparationCubit({
    SupabaseDeliveryPreparationService? deliveryPreparationService,
  }) : _deliveryPreparationService =
           deliveryPreparationService ?? SupabaseDeliveryPreparationService(),
       super(const DeliveryPreparationState());

  final SupabaseDeliveryPreparationService _deliveryPreparationService;

  Future<void> loadForLocation({
    required String businessLocationId,
    bool force = false,
  }) async {
    final sameLocation = state.businessLocationId == businessLocationId;
    if (!force &&
        sameLocation &&
        (state.status == DeliveryPreparationStatus.ready ||
            state.status == DeliveryPreparationStatus.empty ||
            state.status == DeliveryPreparationStatus.loading)) {
      return;
    }

    emit(
      state.copyWith(
        status: DeliveryPreparationStatus.loading,
        businessLocationId: businessLocationId,
        clearErrorMessage: true,
        clearTransientMessage: true,
      ),
    );

    await _fetchData(businessLocationId);
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: DeliveryPreparationStatus.loading,
        clearErrorMessage: true,
        clearTransientMessage: true,
      ),
    );

    await _fetchData(state.businessLocationId);
  }

  void openQuickEdit(String rowId) {
    if (state.pendingRows[rowId] == true) return;

    emit(
      state.copyWith(
        editingRowId: state.editingRowId == rowId ? null : rowId,
        editingMinutesByRow: {
          ...state.editingMinutesByRow,
          rowId: state.prepMinutesByRow[rowId] ?? 5,
        },
      ),
    );
  }

  void setEditingMinutes(String rowId, int minutes) {
    emit(
      state.copyWith(
        editingMinutesByRow: {...state.editingMinutesByRow, rowId: minutes},
      ),
    );
  }

  void cancelQuickEdit(String rowId) {
    emit(
      state.copyWith(
        editingRowId: null,
        editingMinutesByRow: {
          ...state.editingMinutesByRow,
          rowId: state.prepMinutesByRow[rowId] ?? 5,
        },
      ),
    );
  }

  Future<OrderActionResult> saveQuickEdit(String rowId) async {
    if (state.pendingRows[rowId] == true) {
      return const OrderActionResult(success: true);
    }

    if (state.businessLocationId.isEmpty) {
      const message =
          'Selecciona una ubicación activa para editar tiempo de preparación.';
      emit(state.copyWith(transientMessage: message));
      return const OrderActionResult(success: false, message: message);
    }

    final rawMinutes = state.editingMinutesByRow[rowId];
    if (rawMinutes == null || rawMinutes < 1) {
      const message = 'El tiempo debe ser de al menos 1 minuto.';
      emit(state.copyWith(transientMessage: message));
      return const OrderActionResult(success: false, message: message);
    }

    final previousMinutes = state.prepMinutesByRow[rowId] ?? 5;
    emit(
      state.copyWith(
        prepMinutesByRow: {...state.prepMinutesByRow, rowId: rawMinutes},
        pendingRows: {...state.pendingRows, rowId: true},
        clearTransientMessage: true,
      ),
    );

    try {
      final result = await _deliveryPreparationService
          .updatePickupReadyOffsetByLocation(
            businessDeliveryMethodId: rowId,
            businessLocationId: state.businessLocationId,
            pickupReadyOffsetMinutes: rawMinutes,
          );

      if (!result.success) {
        throw StateError(
          result.message ?? 'No se pudo actualizar el tiempo de preparación.',
        );
      }

      final nextPending = {...state.pendingRows}..remove(rowId);
      emit(
        state.copyWith(
          editingRowId: null,
          pendingRows: nextPending,
          transientMessage: 'Tiempo de preparación actualizado.',
        ),
      );
      return const OrderActionResult(success: true);
    } catch (error) {
      final nextPending = {...state.pendingRows}..remove(rowId);
      final message = '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
          ? 'No se pudo actualizar el tiempo de preparación.'
          : '$error'.replaceFirst('Bad state: ', '').trim();
      emit(
        state.copyWith(
          prepMinutesByRow: {...state.prepMinutesByRow, rowId: previousMinutes},
          pendingRows: nextPending,
          transientMessage: message,
        ),
      );
      return OrderActionResult(success: false, message: message);
    }
  }

  void clearTransientMessage() {
    if (state.transientMessage.isEmpty) return;
    emit(state.copyWith(clearTransientMessage: true));
  }

  void reset() {
    emit(const DeliveryPreparationState());
  }

  Future<void> _fetchData(String businessLocationId) async {
    try {
      final rows = await _deliveryPreparationService.fetchDeliveryMethods(
        businessLocationId: businessLocationId,
      );
      final prepMinutes = <String, int>{for (final row in rows) row.uid: 5};

      if (businessLocationId.isNotEmpty && rows.isNotEmpty) {
        final offsets = await _deliveryPreparationService
            .fetchPickupOffsetsByLocation(
              businessLocationId: businessLocationId,
              deliveryMethodIds: rows
                  .map((row) => row.uid)
                  .toList(growable: false),
            );
        prepMinutes.addAll(offsets);
      }

      emit(
        state.copyWith(
          status: rows.isEmpty
              ? DeliveryPreparationStatus.empty
              : DeliveryPreparationStatus.ready,
          businessLocationId: businessLocationId,
          rows: rows,
          prepMinutesByRow: prepMinutes,
          editingMinutesByRow: prepMinutes,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DeliveryPreparationStatus.failure,
          businessLocationId: businessLocationId,
          errorMessage: '$error'.replaceFirst('Bad state: ', '').trim().isEmpty
              ? 'No se pudieron cargar los métodos de delivery.'
              : '$error'.replaceFirst('Bad state: ', '').trim(),
          clearData: true,
        ),
      );
    }
  }
}
