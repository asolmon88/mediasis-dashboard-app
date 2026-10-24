import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'orders_table_state.dart';

class OrdersTableCubit extends Cubit<OrdersTableState> {
  OrdersTableCubit({SupabaseOrdersService? ordersService})
    : _ordersService = ordersService ?? SupabaseOrdersService(),
      super(const OrdersTableState());

  final SupabaseOrdersService _ordersService;

  Future<void> loadForLocation(
    String businessLocationId, {
    bool force = false,
  }) async {
    if (businessLocationId.isEmpty) {
      emit(
        state.copyWith(
          status: OrdersTableStatus.failure,
          businessLocationId: '',
          errorMessage: 'No hay una ubicación activa.',
          clearData: true,
        ),
      );
      return;
    }

    final isSameLocation = state.businessLocationId == businessLocationId;
    if (!force &&
        isSameLocation &&
        (state.status == OrdersTableStatus.ready ||
            state.status == OrdersTableStatus.empty ||
            state.status == OrdersTableStatus.loading)) {
      return;
    }

    emit(
      state.copyWith(
        status: OrdersTableStatus.loading,
        businessLocationId: businessLocationId,
        page: isSameLocation ? state.page : 1,
        clearErrorMessage: true,
      ),
    );

    await _fetchRows();
  }

  Future<void> refresh() async {
    if (state.businessLocationId.isEmpty) return;
    emit(
      state.copyWith(
        status: OrdersTableStatus.loading,
        clearErrorMessage: true,
      ),
    );
    await _fetchRows();
  }

  void setSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value));
  }

  Future<void> updateSort({
    required OrdersTableSortBy sortBy,
    required OrdersTableSortDirection sortDirection,
  }) async {
    emit(
      state.copyWith(
        sortBy: sortBy,
        sortDirection: sortDirection,
        page: 1,
        clearErrorMessage: true,
      ),
    );
    await _fetchRows();
  }

  Future<void> goToNextPage() async {
    if (!state.hasMore) return;
    emit(state.copyWith(page: state.page + 1, clearErrorMessage: true));
    await _fetchRows();
  }

  Future<void> goToPreviousPage() async {
    if (state.page <= 1) return;
    emit(state.copyWith(page: state.page - 1, clearErrorMessage: true));
    await _fetchRows();
  }

  Future<void> clearFilters() async {
    emit(
      state.copyWith(
        paymentStatusFilters: const ['paid'],
        page: 1,
        clearErrorMessage: true,
      ),
    );
    await _fetchRows();
  }

  Future<OrderActionResult> changeRowStatus({
    required String orderId,
    required String currentStatus,
    required String nextStatus,
  }) async {
    if (currentStatus == nextStatus || state.savingByOrderId[orderId] == true) {
      return const OrderActionResult(success: true);
    }

    emit(
      state.copyWith(
        rows: state.rows
            .map(
              (row) => row.orderId == orderId
                  ? row.copyWith(orderStatus: nextStatus)
                  : row,
            )
            .toList(growable: false),
        savingByOrderId: {...state.savingByOrderId, orderId: true},
        clearTransientMessage: true,
      ),
    );

    try {
      await _ordersService.updateOrderStatus(orderId, nextStatus);

      final nextSaving = {...state.savingByOrderId}..remove(orderId);
      emit(state.copyWith(savingByOrderId: nextSaving));
      return const OrderActionResult(success: true);
    } catch (_) {
      final revertedRows = state.rows
          .map(
            (row) => row.orderId == orderId
                ? row.copyWith(orderStatus: currentStatus)
                : row,
          )
          .toList(growable: false);
      final nextSaving = {...state.savingByOrderId}..remove(orderId);
      emit(
        state.copyWith(
          rows: revertedRows,
          savingByOrderId: nextSaving,
          transientMessage: 'No se pudo actualizar el estado de la orden.',
        ),
      );
      return const OrderActionResult(
        success: false,
        message: 'No se pudo actualizar el estado de la orden.',
      );
    }
  }

  void clearTransientMessage() {
    if (state.transientMessage.isEmpty) return;
    emit(state.copyWith(clearTransientMessage: true));
  }

  void reset() {
    emit(const OrdersTableState());
  }

  Future<void> _fetchRows() async {
    final businessLocationId = state.businessLocationId;
    if (businessLocationId.isEmpty) return;

    try {
      final response = await _ordersService.fetchOrdersTable(
        businessLocationId: businessLocationId,
        limit: state.limit,
        offset: state.offset,
        paymentStatus: state.paymentStatusFilters,
        sortBy: state.sortBy.value,
        sortDirection: state.sortDirection.value,
      );

      if (!response.success || response.data == null) {
        emit(
          state.copyWith(
            status: OrdersTableStatus.failure,
            errorMessage:
                response.message ?? 'No se pudieron cargar las órdenes.',
            clearData: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: response.data!.rows.isEmpty
              ? OrdersTableStatus.empty
              : OrdersTableStatus.ready,
          rows: response.data!.rows,
          hasMore: response.data!.pagination.hasMore,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: OrdersTableStatus.failure,
          errorMessage: 'No se pudieron cargar las órdenes.',
          clearData: true,
        ),
      );
    }
  }
}
