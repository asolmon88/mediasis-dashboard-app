import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'orders_state.dart';

const _locationAccessDeniedMessage = 'Not allowed for this business location';

bool shouldPlayPickupConfirmation(String? previousStatus, String? nextStatus) {
  return previousStatus?.toLowerCase() != 'dropoff' &&
      nextStatus?.toLowerCase() == 'dropoff';
}

bool isDeliveredOrderStatus(String? status) =>
    status == 'ready' || status == 'delivered';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({
    SupabaseOrdersService? ordersService,
    OrdersRealtimeService? realtimeService,
    OrderSoundService? soundService,
    PrinterStorageService? printerStorage,
  }) : _ordersService = ordersService ?? SupabaseOrdersService(),
       _realtimeService = realtimeService ?? OrdersRealtimeService(),
       _soundService = soundService ?? OrderSoundService(),
       _printerStorage = printerStorage ?? PrinterStorageService(),
       super(const OrdersState());

  final SupabaseOrdersService _ordersService;
  final OrdersRealtimeService _realtimeService;
  final OrderSoundService _soundService;
  final PrinterStorageService _printerStorage;
  final Set<String> _updatingOrderIds = <String>{};
  final Map<String, Timer> _uberPendingUpdates = <String, Timer>{};
  final StreamController<IncomingOrderArrival> _incomingOrderArrivals =
      StreamController<IncomingOrderArrival>.broadcast();

  Stream<IncomingOrderArrival> get incomingOrderArrivals =>
      _incomingOrderArrivals.stream;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  Timer? _syncTimer;

  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 40),
    Duration(seconds: 60),
  ];

  Future<void> loadOrders(
    String businessLocationId, {
    bool recoverAutomaticPrinting = false,
  }) async {
    await _teardownRealtime();

    if (businessLocationId.isEmpty) {
      emit(
        state.copyWith(
          status: OrdersStatus.failure,
          errorMessage: 'No hay una ubicación activa.',
          clearOrders: true,
        ),
      );
      return;
    }

    _clearTimers();

    emit(
      state.copyWith(
        status: OrdersStatus.loading,
        businessLocationId: businessLocationId,
        clearErrorMessage: true,
        clearFailureReason: true,
      ),
    );

    try {
      final response = await _ordersService.fetchRealtimeOrders(
        businessLocationId,
      );

      if (!response.success) {
        final failureReason =
            response.message?.trim() == _locationAccessDeniedMessage
            ? OrdersFailureReason.locationAccessDenied
            : null;
        emit(
          state.copyWith(
            status: OrdersStatus.failure,
            errorMessage:
                response.message ?? 'No se pudieron cargar los pedidos.',
            failureReason: failureReason,
            clearFailureReason: failureReason == null,
            clearOrders: true,
          ),
        );
        return;
      }

      final summaries = response.data
          .map((order) => _mapOrderToSummary(order))
          .whereType<OrderSummary>()
          .toList();
      final currentOrderIds = response.data
          .map((order) => order.orderId)
          .where((id) => id.isNotEmpty)
          .toSet();
      final baseline = await _printerStorage.readOrderBaseline(
        businessLocationId,
      );
      final nextPendingIncomingAlertCount = state.pendingIncomingAlertCount > 0
          ? _countPendingNewOrders(summaries)
          : state.pendingIncomingAlertCount;

      emit(
        state.copyWith(
          status: summaries.isEmpty ? OrdersStatus.empty : OrdersStatus.ready,
          ordersRaw: response.data,
          orders: summaries,
          businessLocationId: businessLocationId,
          pendingIncomingAlertCount: nextPendingIncomingAlertCount,
          clearErrorMessage: true,
          clearFailureReason: true,
        ),
      );
      _syncIncomingAlertSound(nextPendingIncomingAlertCount);
      await _printerStorage.saveOrderBaseline(
        businessLocationId,
        currentOrderIds,
      );
      if (recoverAutomaticPrinting && baseline.isNotEmpty) {
        for (final orderId in currentOrderIds.difference(baseline)) {
          _emitIncomingOrderArrival(orderId, businessLocationId);
        }
      }
      _startPeriodicSync(businessLocationId);
      await _subscribeToRealtime(businessLocationId);
    } catch (_) {
      emit(
        state.copyWith(
          status: OrdersStatus.failure,
          errorMessage: 'No se pudieron cargar los pedidos.',
          clearFailureReason: true,
          clearOrders: true,
        ),
      );
    }
  }

  Future<void> moveOrderForward(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null) return;

    final stage = orderBoardStage(order);
    if (stage == OrderBoardStage.readyForPickup && order.requiresCourier) {
      return;
    }

    final nextStatus = switch (stage) {
      OrderBoardStage.newOrder => 'preparing',
      OrderBoardStage.preparing =>
        order.requiresLocation && !order.requiresCourier
            ? 'on_the_way'
            : 'ready_for_pickup',
      OrderBoardStage.readyForPickup || OrderBoardStage.canceled => 'delivered',
      OrderBoardStage.onWay =>
        order.orderStatus == 'on_the_way' && !order.requiresCourier
            ? 'delivered'
            : null,
      OrderBoardStage.delivered => null,
    };

    if (nextStatus == null) return;

    await _persistStatusChange(
      order,
      persistedStatus: nextStatus,
      displayStatus: nextStatus,
    );
  }

  Future<void> moveOrderBackward(String orderId) async {
    final order = _findOrder(orderId);
    if (order == null) return;

    if (!orderBoardShowsBack(order)) return;

    final previousStatus = switch (order.orderStatus) {
      'preparing' => 'pending',
      'ready_for_pickup' => 'preparing',
      'on_the_way' => 'preparing',
      'ready' || 'delivered' =>
        order.requiresLocation && !order.requiresCourier
            ? 'on_the_way'
            : 'ready_for_pickup',
      _ => null,
    };

    if (previousStatus == null) return;

    await _persistStatusChange(
      order,
      persistedStatus: previousStatus,
      displayStatus: _normalizeStatus(previousStatus) ?? previousStatus,
    );
  }

  void clearTransientFeedback() {
    if (state.errorMessage.isEmpty) return;

    emit(state.copyWith(clearErrorMessage: true));
  }

  void selectOrder(String? orderId) {
    emit(
      state.copyWith(
        selectedOrderId: orderId,
        clearSelectedOrderDetail: orderId == null,
      ),
    );
  }

  Future<void> acknowledgeIncomingOrders() async {
    if (state.pendingIncomingAlertCount == 0) return;

    emit(state.copyWith(pendingIncomingAlertCount: 0));

    await _soundService.stopIncomingOrderSound();
  }

  Future<OrderActionResult> handleIncomingOrderNotification({
    required String orderId,
    required String businessLocationId,
    bool forceAlert = false,
  }) async {
    if (orderId.isEmpty ||
        businessLocationId.isEmpty ||
        state.businessLocationId != businessLocationId) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo abrir el pedido para esta ubicación.',
      );
    }

    final alreadyVisible = state.ordersRaw.any(
      (order) => order.orderId == orderId,
    );

    try {
      final response = await _ordersService.fetchRealtimeOrder(
        orderId,
        businessLocationId,
      );
      if (!response.success || response.data.isEmpty) {
        return OrderActionResult(
          success: false,
          message: response.message ?? 'No se pudo cargar el pedido nuevo.',
        );
      }

      final updatedSummaries = _upsertRealtimeOrder(
        response.data.first,
        statusStartedAt: DateTime.now().toIso8601String(),
      );

      if (!alreadyVisible || forceAlert) {
        final pendingNewOrdersCount = _countPendingNewOrders(updatedSummaries);
        emit(state.copyWith(pendingIncomingAlertCount: pendingNewOrdersCount));
        _syncIncomingAlertSound(pendingNewOrdersCount);
        _emitIncomingOrderArrival(orderId, businessLocationId);
      }

      return const OrderActionResult(success: true);
    } catch (_) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo cargar el pedido nuevo.',
      );
    }
  }

  Future<OrderActionResult> prepareOrderDetail(
    String orderId, {
    String? knownOrderStatus,
    bool allowReadyOrder = false,
    bool preferOrderDetailRpc = false,
  }) async {
    if (orderId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo abrir el detalle del pedido.',
      );
    }

    if (!allowReadyOrder && isDeliveredOrderStatus(knownOrderStatus)) {
      return const OrderActionResult(
        success: false,
        message: 'Para ver esta orden pasala a preparando.',
      );
    }

    for (final order in state.ordersRaw) {
      if (order.orderId == orderId) {
        emit(
          state.copyWith(
            selectedOrderId: orderId,
            clearSelectedOrderDetail: true,
          ),
        );
        return const OrderActionResult(success: true);
      }
    }

    if (preferOrderDetailRpc) {
      return _prepareOrderDetailFromOrderDetailRpc(orderId);
    }

    final businessLocationId = state.businessLocationId;
    if (businessLocationId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'No hay una ubicación activa para cargar el detalle.',
      );
    }

    try {
      final response = await _ordersService.fetchRealtimeOrder(
        orderId,
        businessLocationId,
      );

      if (!response.success || response.data.isEmpty) {
        if (!allowReadyOrder && isDeliveredOrderStatus(knownOrderStatus)) {
          return const OrderActionResult(
            success: false,
            message: 'Para ver esta orden pasala a preparando.',
          );
        }

        return OrderActionResult(
          success: false,
          message:
              response.message ?? 'No se pudo cargar el detalle del pedido.',
        );
      }

      final rawOrder = response.data.first;
      final summary = _mapOrderToSummary(rawOrder);

      emit(
        state.copyWith(
          selectedOrderId: orderId,
          selectedOrderRaw: rawOrder,
          selectedOrderSummary: summary,
        ),
      );

      return const OrderActionResult(success: true);
    } catch (_) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo cargar el detalle del pedido.',
      );
    }
  }

  Future<OrderActionResult> _prepareOrderDetailFromOrderDetailRpc(
    String orderId,
  ) async {
    try {
      final response = await _ordersService.fetchOrderDetail(orderId);

      if (!response.success || response.data == null) {
        return OrderActionResult(
          success: false,
          message:
              response.message ?? 'No se pudo cargar el detalle del pedido.',
        );
      }

      final rawOrder = response.data!.toRealtimeOrder();
      final summary = _mapOrderToSummary(rawOrder);

      emit(
        state.copyWith(
          selectedOrderId: orderId,
          selectedOrderRaw: rawOrder,
          selectedOrderSummary: summary,
        ),
      );

      return const OrderActionResult(success: true);
    } catch (_) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo cargar el detalle del pedido.',
      );
    }
  }

  Future<OrderActionResult> refreshRealtimeOrder(String orderId) async {
    if (state.businessLocationId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'No hay una ubicacion activa para actualizar el pedido.',
      );
    }

    try {
      final response = await _ordersService.fetchRealtimeOrder(
        orderId,
        state.businessLocationId,
      );
      if (!response.success || response.data.isEmpty) {
        return OrderActionResult(
          success: false,
          message: response.message ?? 'No se pudo actualizar el pedido.',
        );
      }
      _upsertRealtimeOrder(
        response.data.first,
        statusStartedAt: DateTime.now().toIso8601String(),
      );
      return const OrderActionResult(success: true);
    } catch (_) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo actualizar el pedido.',
      );
    }
  }

  Future<OrderActionResult> callUberDelivery(String orderId) async {
    return _ordersService.callUberDelivery(orderId: orderId);
  }

  Future<OrderActionResult> requestPickupNow(String orderId) async {
    if (state.pickupNowOrderIds.contains(orderId)) {
      return const OrderActionResult(
        success: false,
        message: 'La solicitud ya esta en proceso.',
      );
    }

    emit(
      state.copyWith(pickupNowOrderIds: {...state.pickupNowOrderIds, orderId}),
    );
    try {
      final result = await _ordersService.requestPickupNow(orderId: orderId);
      if (!result.success || state.businessLocationId.isEmpty) return result;

      await refreshRealtimeOrder(orderId);
      return result;
    } finally {
      if (!isClosed) {
        final ids = Set<String>.from(state.pickupNowOrderIds)..remove(orderId);
        emit(state.copyWith(pickupNowOrderIds: ids));
      }
    }
  }

  void reset() {
    _clearTimers();
    _updatingOrderIds.clear();
    unawaited(_teardownRealtime());
    unawaited(_soundService.stopIncomingOrderSound());
    emit(const OrdersState());
  }

  @override
  Future<void> close() async {
    _clearTimers();
    _updatingOrderIds.clear();
    await _teardownRealtime();
    await _soundService.dispose();
    await _incomingOrderArrivals.close();
    return super.close();
  }

  Future<void> _persistStatusChange(
    OrderSummary order, {
    required OrderStatus persistedStatus,
    required OrderStatus displayStatus,
  }) async {
    if (_updatingOrderIds.contains(order.orderId)) return;

    final previousRawStatus = _findRawOrder(order.orderId)?.orderStatus;
    final previousDisplayStatus = order.orderStatus;
    final previousStatusStartedAt = order.statusStartedAt;
    final nowIso = DateTime.now().toIso8601String();

    _updatingOrderIds.add(order.orderId);

    _applyOrderState(
      orderId: order.orderId,
      rawStatus: persistedStatus,
      displayStatus: displayStatus,
      nextStatusStartedAt: nowIso,
      clearErrorMessage: true,
    );

    try {
      await _ordersService.updateOrderStatus(order.orderId, persistedStatus);
    } catch (_) {
      _applyOrderState(
        orderId: order.orderId,
        rawStatus: previousRawStatus ?? previousDisplayStatus,
        displayStatus: previousDisplayStatus,
        nextStatusStartedAt: previousStatusStartedAt,
        errorMessage: 'No se pudo actualizar el estado del pedido.',
      );
    } finally {
      _updatingOrderIds.remove(order.orderId);
    }
  }

  Future<void> _subscribeToRealtime(String businessLocationId) async {
    await _realtimeService.subscribeToOrderUpdates(
      businessLocationId: businessLocationId,
      onUpdate: _handleRealtimeUpdate,
      onConnected: _onRealtimeConnected,
      onError: (message) {
        if (isClosed) return;
        emit(
          state.copyWith(errorMessage: 'Tiempo real desconectado: $message'),
        );
        _scheduleReconnect(businessLocationId);
      },
    );
    await _realtimeService.subscribeToUberDeliveryUpdates(
      businessLocationId: businessLocationId,
      onUpdate: (orderId) =>
          _handleUberDeliveryUpdate(orderId, businessLocationId),
      onError: (_) {
        if (isClosed) return;
        _scheduleReconnect(businessLocationId);
      },
    );
  }

  void _onRealtimeConnected() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _scheduleReconnect(String businessLocationId) {
    if (isClosed) return;
    _reconnectTimer?.cancel();

    final delayIndex = _reconnectAttempts.clamp(0, _reconnectDelays.length - 1);
    final delay = _reconnectDelays[delayIndex];
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () async {
      if (isClosed) return;
      await _subscribeToRealtime(businessLocationId);
      await _periodicSync(businessLocationId);
    });
  }

  void _startPeriodicSync(String businessLocationId) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _periodicSync(businessLocationId);
    });
  }

  Future<void> _periodicSync(String businessLocationId) async {
    if (isClosed) return;
    if (businessLocationId.isEmpty) return;

    try {
      final response = await _ordersService.fetchRealtimeOrders(
        businessLocationId,
      );
      if (isClosed) return;
      if (!response.success) return;

      final summaries = response.data
          .map((order) => _mapOrderToSummary(order))
          .whereType<OrderSummary>()
          .toList();

      // Raise alert count if orders arrived that weren't in the previous state
      // (e.g. while realtime was down), but don't re-alert for already-acknowledged ones.
      final prevIds = state.ordersRaw.map((o) => o.orderId).toSet();
      final previousUberStatuses = {
        for (final order in state.ordersRaw)
          order.orderId: order.uberDelivery?.status,
      };
      final hasNewArrivals = response.data.any(
        (o) => !prevIds.contains(o.orderId),
      );
      final freshCount = _countPendingNewOrders(summaries);
      final nextCount = (state.pendingIncomingAlertCount > 0 || hasNewArrivals)
          ? freshCount
          : state.pendingIncomingAlertCount;

      emit(
        state.copyWith(
          status: summaries.isEmpty ? OrdersStatus.empty : OrdersStatus.ready,
          ordersRaw: response.data,
          orders: summaries,
          pendingIncomingAlertCount: nextCount,
          clearErrorMessage: true,
        ),
      );
      _syncIncomingAlertSound(nextCount);
      for (final order in response.data) {
        if (!previousUberStatuses.containsKey(order.orderId)) continue;
        if (shouldPlayPickupConfirmation(
          previousUberStatuses[order.orderId],
          order.uberDelivery?.status,
        )) {
          unawaited(_soundService.playPickupConfirmationSound());
        }
      }
      for (final order in response.data.where(
        (order) => !prevIds.contains(order.orderId),
      )) {
        _emitIncomingOrderArrival(order.orderId, businessLocationId);
      }
    } catch (_) {
      // silent — background sync failures should not surface errors to the user
    }
  }

  void _handleUberDeliveryUpdate(String orderId, String businessLocationId) {
    final isTracked = state.ordersRaw.any((o) => o.orderId == orderId);
    if (!isTracked) return;

    _uberPendingUpdates[orderId]?.cancel();
    _uberPendingUpdates[orderId] = Timer(
      const Duration(milliseconds: 300),
      () async {
        _uberPendingUpdates.remove(orderId);
        try {
          final previousStatus = _findRawOrder(orderId)?.uberDelivery?.status;
          final response = await _ordersService.fetchRealtimeOrder(
            orderId,
            businessLocationId,
          );
          if (!response.success || response.data.isEmpty) return;
          final updatedOrder = response.data.first;
          _upsertRealtimeOrder(
            updatedOrder,
            statusStartedAt: DateTime.now().toIso8601String(),
          );
          if (shouldPlayPickupConfirmation(
            previousStatus,
            updatedOrder.uberDelivery?.status,
          )) {
            unawaited(_soundService.playPickupConfirmationSound());
          }
        } catch (_) {
          // silently ignore — stale data is acceptable for Uber updates
        }
      },
    );
  }

  Future<void> _handleRealtimeUpdate(OrderRealtimeRowUpdate update) async {
    if (isDeliveredOrderStatus(update.orderStatus)) {
      _markOrderDeliveredLocally(
        orderId: update.orderId,
        orderStatus: update.orderStatus,
        statusStartedAt: update.commitTimestamp.toIso8601String(),
      );
      return;
    }

    if (update.productsPaymentStatus != 'paid' &&
        update.deliveryPaymentStatus != 'paid') {
      return;
    }

    final businessLocationId = state.businessLocationId;
    if (businessLocationId.isEmpty) return;

    final alreadyVisible = state.ordersRaw.any(
      (order) => order.orderId == update.orderId,
    );

    try {
      final response = await _ordersService.fetchRealtimeOrder(
        update.orderId,
        businessLocationId,
      );

      if (!response.success || response.data.isEmpty) {
        return;
      }

      final updatedSummaries = _upsertRealtimeOrder(
        response.data.first,
        statusStartedAt: update.commitTimestamp.toIso8601String(),
      );

      if (!alreadyVisible) {
        final pendingNewOrdersCount = _countPendingNewOrders(updatedSummaries);

        emit(state.copyWith(pendingIncomingAlertCount: pendingNewOrdersCount));
        _syncIncomingAlertSound(pendingNewOrdersCount);
        _emitIncomingOrderArrival(update.orderId, businessLocationId);
      }
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'No se pudo actualizar un pedido en tiempo real.',
        ),
      );
    }
  }

  Future<void> _teardownRealtime() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _reconnectAttempts = 0;
    await _realtimeService.unsubscribe();
  }

  void _emitIncomingOrderArrival(String orderId, String locationId) {
    if (_incomingOrderArrivals.isClosed) return;
    _incomingOrderArrivals.add(
      IncomingOrderArrival(orderId: orderId, businessLocationId: locationId),
    );
  }

  void _markOrderDeliveredLocally({
    required String orderId,
    required String orderStatus,
    required String statusStartedAt,
  }) {
    final hasOrder = state.ordersRaw.any((order) => order.orderId == orderId);
    if (!hasOrder) return;

    _applyOrderState(
      orderId: orderId,
      rawStatus: orderStatus,
      displayStatus: orderStatus,
      nextStatusStartedAt: statusStartedAt,
    );
  }

  List<OrderSummary> _upsertRealtimeOrder(
    OrderRealtimeOrder rawOrder, {
    required String statusStartedAt,
  }) {
    final existingSummary = _findOrder(rawOrder.orderId);
    final mappedSummary = _mapOrderToSummary(rawOrder);
    final updatedRaw = _upsertRawOrder(rawOrder);
    final updatedSummaries = _upsertSummaryOrder(
      existingSummary: existingSummary,
      incomingSummary: mappedSummary,
      statusStartedAt: statusStartedAt,
    );

    emit(
      state.copyWith(
        status: updatedSummaries.isEmpty
            ? OrdersStatus.empty
            : OrdersStatus.ready,
        ordersRaw: updatedRaw,
        orders: updatedSummaries,
        selectedOrderRaw: state.selectedOrderId == rawOrder.orderId
            ? rawOrder
            : state.selectedOrderRaw,
        selectedOrderSummary: state.selectedOrderId == rawOrder.orderId
            ? mappedSummary
            : state.selectedOrderSummary,
        clearErrorMessage: true,
      ),
    );

    return updatedSummaries;
  }

  List<OrderRealtimeOrder> _upsertRawOrder(OrderRealtimeOrder rawOrder) {
    final rawOrders = List<OrderRealtimeOrder>.from(state.ordersRaw);
    final index = rawOrders.indexWhere(
      (order) => order.orderId == rawOrder.orderId,
    );

    if (index == -1) {
      rawOrders.add(rawOrder);
    } else {
      rawOrders[index] = rawOrder;
    }

    return rawOrders;
  }

  List<OrderSummary> _upsertSummaryOrder({
    required OrderSummary? existingSummary,
    required OrderSummary? incomingSummary,
    required String statusStartedAt,
  }) {
    final summaries = List<OrderSummary>.from(state.orders);

    if (incomingSummary == null) {
      if (existingSummary != null) {
        summaries.removeWhere(
          (order) => order.orderId == existingSummary.orderId,
        );
      }
      return summaries;
    }

    final resolvedStatusStartedAt = existingSummary == null
        ? statusStartedAt
        : existingSummary.orderStatus == incomingSummary.orderStatus
        ? existingSummary.statusStartedAt
        : statusStartedAt;

    final resolvedSummary = incomingSummary.copyWith(
      statusStartedAt: resolvedStatusStartedAt,
    );

    final index = summaries.indexWhere(
      (order) => order.orderId == resolvedSummary.orderId,
    );

    if (index == -1) {
      summaries.add(resolvedSummary);
    } else {
      summaries[index] = resolvedSummary;
    }

    return summaries;
  }

  void _applyOrderState({
    required String orderId,
    required OrderStatus rawStatus,
    required OrderStatus displayStatus,
    required String nextStatusStartedAt,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    final updatedRaw = state.ordersRaw
        .map(
          (order) => order.orderId == orderId
              ? order.copyWith(orderStatus: rawStatus)
              : order,
        )
        .toList();

    final updatedSummaries = state.orders
        .map(
          (order) => order.orderId == orderId
              ? order.copyWith(
                  orderStatus: displayStatus,
                  statusStartedAt: nextStatusStartedAt,
                )
              : order,
        )
        .toList();

    final nextVisualStatus = updatedSummaries.isEmpty
        ? OrdersStatus.empty
        : OrdersStatus.ready;
    final nextPendingIncomingAlertCount = state.pendingIncomingAlertCount > 0
        ? _countPendingNewOrders(updatedSummaries)
        : state.pendingIncomingAlertCount;

    emit(
      state.copyWith(
        status: nextVisualStatus,
        ordersRaw: updatedRaw,
        orders: updatedSummaries,
        pendingIncomingAlertCount: nextPendingIncomingAlertCount,
        errorMessage: errorMessage,
        clearErrorMessage: clearErrorMessage,
      ),
    );

    _syncIncomingAlertSound(nextPendingIncomingAlertCount);
  }

  OrderSummary? _findOrder(String orderId) {
    for (final order in state.orders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  OrderRealtimeOrder? _findRawOrder(String orderId) {
    for (final order in state.ordersRaw) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  void _clearTimers() {
    for (final timer in _uberPendingUpdates.values) {
      timer.cancel();
    }
    _uberPendingUpdates.clear();
  }

  OrderSummary? _mapOrderToSummary(OrderRealtimeOrder order) {
    final normalizedStatus = _normalizeStatus(order.orderStatus);
    if (normalizedStatus == null) return null;

    final amount = order.productsPrice ?? _sumItemTotals(order.items);

    return OrderSummary(
      orderId: order.orderId,
      humanOrderNumber: order.humanOrderNumber,
      createdAt: order.createdAt,
      amount: amount,
      client: OrderSummaryClient(
        firstName: order.client.firstName,
        lastName: order.client.lastName,
        phoneNumber: order.client.phoneNumber,
      ),
      receiptUrl: order.receiptUrl,
      trackingLink: order.trackingLink,
      orderStatus: normalizedStatus,
      statusStartedAt: order.createdAt,
      pickupReadyDt: order.uberDelivery?.pickupReady ?? order.pickupReadyDt,
      uberDeliveryStatus: order.uberDelivery?.status,
      uberDeliveryId:
          order.uberDelivery?.uberDeliveryId ?? order.uberDeliveryId,
      requiresCourier: order.deliveryMethod.requireCourier,
      requiresLocation: order.deliveryMethod.requireLocation,
    );
  }

  OrderStatus? _normalizeStatus(OrderStatus status) {
    if (status == 'pending') return 'new';
    if (status == 'new' ||
        status == 'preparing' ||
        status == 'ready_for_pickup' ||
        status == 'on_the_way' ||
        status == 'ready' ||
        status == 'delivered') {
      return status;
    }
    return null;
  }

  double _sumItemTotals(List<OrderRealtimeItem> items) {
    return items.fold<double>(0, (total, item) => total + item.totalPrice);
  }

  int _countPendingNewOrders(List<OrderSummary> orders) {
    return orders.where((order) => order.orderStatus == 'new').length;
  }

  void _syncIncomingAlertSound(int pendingIncomingAlertCount) {
    if (pendingIncomingAlertCount > 0) {
      unawaited(_soundService.startLoopingIncomingOrderSound());
      return;
    }

    unawaited(_soundService.stopIncomingOrderSound());
  }
}
