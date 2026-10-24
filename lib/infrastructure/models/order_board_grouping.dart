import 'order_models.dart';

enum OrderBoardStage {
  newOrder,
  preparing,
  canceled,
  readyForPickup,
  onWay,
  delivered,
}

OrderBoardStage orderBoardStage(OrderSummary order) {
  if (order.orderStatus == 'ready' || order.orderStatus == 'delivered') {
    return OrderBoardStage.delivered;
  }
  if (order.orderStatus == 'on_the_way') return OrderBoardStage.onWay;
  if (order.orderStatus == 'new' ||
      order.orderStatus == 'pending' ||
      order.orderStatus == 'preparing' ||
      order.orderStatus == 'ready_for_pickup') {
    if (order.uberDeliveryStatus == 'dropoff') return OrderBoardStage.onWay;
    if (order.uberDeliveryStatus == 'canceled') return OrderBoardStage.canceled;
    if (order.orderStatus == 'ready_for_pickup') {
      return OrderBoardStage.readyForPickup;
    }
    return order.orderStatus == 'preparing'
        ? OrderBoardStage.preparing
        : OrderBoardStage.newOrder;
  }
  throw ArgumentError.value(order.orderStatus, 'orderStatus');
}

String? orderBoardForwardLabel(OrderSummary order) =>
    switch (orderBoardStage(order)) {
      OrderBoardStage.newOrder => 'Preparar',
      OrderBoardStage.preparing =>
        order.requiresLocation && !order.requiresCourier
            ? 'Marcar en camino'
            : 'Marcar lista para recoger',
      OrderBoardStage.readyForPickup =>
        order.requiresCourier ? null : 'Marcar entregada',
      OrderBoardStage.canceled => 'Marcar entregada',
      OrderBoardStage.onWay =>
        order.orderStatus == 'on_the_way' && !order.requiresCourier
            ? 'Marcar entregada'
            : null,
      OrderBoardStage.delivered => null,
    };

bool orderBoardShowsBack(OrderSummary order) =>
    switch (orderBoardStage(order)) {
      OrderBoardStage.preparing || OrderBoardStage.readyForPickup => true,
      OrderBoardStage.onWay =>
        order.orderStatus == 'on_the_way' && !order.requiresCourier,
      OrderBoardStage.delivered => !order.requiresCourier,
      _ => false,
    };

class OrderBoardGroups {
  OrderBoardGroups(List<OrderSummary> orders) {
    for (final order in orders) {
      _byStage[orderBoardStage(order)]!.add(order);
    }
    for (final group in _byStage.values) {
      group.sort((a, b) {
        final aTime = DateTime.tryParse(a.statusStartedAt);
        final bTime = DateTime.tryParse(b.statusStartedAt);
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });
    }
  }

  final Map<OrderBoardStage, List<OrderSummary>> _byStage = {
    for (final stage in OrderBoardStage.values) stage: <OrderSummary>[],
  };

  List<OrderSummary> operator [](OrderBoardStage stage) => _byStage[stage]!;
}
