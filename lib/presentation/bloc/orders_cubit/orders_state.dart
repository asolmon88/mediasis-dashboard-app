part of 'orders_cubit.dart';

enum OrdersStatus { initial, loading, ready, empty, failure }

enum OrdersFailureReason { locationAccessDenied }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.ordersRaw = const [],
    this.orders = const [],
    this.selectedOrderId,
    this.selectedOrderRaw,
    this.selectedOrderSummary,
    this.pendingIncomingAlertCount = 0,
    this.businessLocationId = '',
    this.errorMessage = '',
    this.failureReason,
    this.pickupNowOrderIds = const <String>{},
  });

  final OrdersStatus status;
  final List<OrderRealtimeOrder> ordersRaw;
  final List<OrderSummary> orders;
  final String? selectedOrderId;
  final OrderRealtimeOrder? selectedOrderRaw;
  final OrderSummary? selectedOrderSummary;
  final int pendingIncomingAlertCount;
  final String businessLocationId;
  final String errorMessage;
  final OrdersFailureReason? failureReason;
  final Set<String> pickupNowOrderIds;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderRealtimeOrder>? ordersRaw,
    List<OrderSummary>? orders,
    Object? selectedOrderId = _ordersStateSentinel,
    Object? selectedOrderRaw = _ordersStateSentinel,
    Object? selectedOrderSummary = _ordersStateSentinel,
    int? pendingIncomingAlertCount,
    String? businessLocationId,
    String? errorMessage,
    bool clearErrorMessage = false,
    OrdersFailureReason? failureReason,
    bool clearFailureReason = false,
    bool clearOrders = false,
    bool clearSelectedOrderDetail = false,
    Set<String>? pickupNowOrderIds,
  }) {
    return OrdersState(
      status: status ?? this.status,
      ordersRaw: clearOrders ? const [] : ordersRaw ?? this.ordersRaw,
      orders: clearOrders ? const [] : orders ?? this.orders,
      selectedOrderId: identical(selectedOrderId, _ordersStateSentinel)
          ? this.selectedOrderId
          : selectedOrderId as String?,
      selectedOrderRaw: clearSelectedOrderDetail
          ? null
          : identical(selectedOrderRaw, _ordersStateSentinel)
          ? this.selectedOrderRaw
          : selectedOrderRaw as OrderRealtimeOrder?,
      selectedOrderSummary: clearSelectedOrderDetail
          ? null
          : identical(selectedOrderSummary, _ordersStateSentinel)
          ? this.selectedOrderSummary
          : selectedOrderSummary as OrderSummary?,
      pendingIncomingAlertCount:
          pendingIncomingAlertCount ?? this.pendingIncomingAlertCount,
      businessLocationId: businessLocationId ?? this.businessLocationId,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      failureReason: clearFailureReason
          ? null
          : failureReason ?? this.failureReason,
      pickupNowOrderIds: pickupNowOrderIds ?? this.pickupNowOrderIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ordersRaw,
    orders,
    selectedOrderId,
    selectedOrderRaw,
    selectedOrderSummary,
    pendingIncomingAlertCount,
    businessLocationId,
    errorMessage,
    failureReason,
    pickupNowOrderIds,
  ];
}

const Object _ordersStateSentinel = Object();
