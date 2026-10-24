import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/order_card_widget.dart';
import 'package:flutter_test/flutter_test.dart';

OrderSummary order(
  String id,
  String status,
  String? uberStatus, {
  bool requiresCourier = false,
  bool requiresLocation = false,
}) => OrderSummary(
  orderId: id,
  humanOrderNumber: null,
  createdAt: '2026-09-29T10:00:00Z',
  amount: null,
  client: const OrderSummaryClient(
    firstName: 'Test',
    lastName: 'Customer',
    phoneNumber: '',
  ),
  receiptUrl: null,
  trackingLink: null,
  orderStatus: status,
  statusStartedAt: '2026-09-29T10:00:00Z',
  uberDeliveryStatus: uberStatus,
  requiresCourier: requiresCourier,
  requiresLocation: requiresLocation,
);

void main() {
  test('groups every order once across the five operational stages', () {
    final orders = [
      order('new', 'new', null),
      order('preparing', 'preparing', 'pickup'),
      order('on-way-new', 'new', 'dropoff'),
      order('on-way-preparing', 'preparing', 'dropoff'),
      order('canceled-new', 'new', 'canceled'),
      order('canceled-preparing', 'preparing', 'canceled'),
      order('pickup-ready', 'ready_for_pickup', 'pickup'),
      order('pickup-ready-on-way', 'ready_for_pickup', 'dropoff'),
      order('ready-canceled', 'ready', 'canceled'),
      order('delivered-dropoff', 'delivered', 'dropoff'),
    ];
    final groups = OrderBoardGroups(orders);

    expect(groups[OrderBoardStage.newOrder].length, 1);
    expect(groups[OrderBoardStage.preparing].length, 1);
    expect(groups[OrderBoardStage.readyForPickup].length, 1);
    expect(groups[OrderBoardStage.onWay].length, 3);
    expect(groups[OrderBoardStage.canceled].length, 2);
    expect(groups[OrderBoardStage.delivered].length, 2);
    expect(
      [
        for (final stage in OrderBoardStage.values) ...groups[stage],
      ].map((order) => order.orderId).toSet(),
      orders.map((order) => order.orderId).toSet(),
    );
  });

  test('on-way has no controls and canceled has only mark ready', () {
    final onWay = order('1', 'preparing', 'dropoff');
    final canceled = order('2', 'new', 'canceled');
    expect(orderBoardForwardLabel(onWay), isNull);
    expect(orderBoardShowsBack(onWay), isFalse);
    expect(orderBoardForwardLabel(canceled), 'Marcar entregada');
    expect(orderBoardShowsBack(canceled), isFalse);
    expect(
      orderBoardStage(canceled.copyWith(orderStatus: 'delivered')),
      OrderBoardStage.delivered,
    );
  });

  test('preparing orders advance to pickup-ready', () {
    final courier = order(
      'courier',
      'preparing',
      'pickup',
      requiresCourier: true,
    );
    final pickup = order('pickup', 'preparing', null);

    expect(orderBoardForwardLabel(courier), 'Marcar lista para recoger');
    expect(orderBoardShowsBack(courier), isTrue);
    expect(orderBoardForwardLabel(pickup), 'Marcar lista para recoger');
  });

  test('pharmacy delivery advances from preparing to on the way', () {
    final selfDelivery = order(
      'self-delivery',
      'preparing',
      null,
      requiresLocation: true,
    );
    final persistedOnWay = selfDelivery.copyWith(orderStatus: 'on_the_way');

    expect(orderBoardForwardLabel(selfDelivery), 'Marcar en camino');
    expect(orderBoardStage(persistedOnWay), OrderBoardStage.onWay);
    expect(orderBoardForwardLabel(persistedOnWay), 'Marcar entregada');
    expect(orderBoardShowsBack(persistedOnWay), isTrue);
  });

  test('Uber on the way remains automatic and locked', () {
    final uber = order(
      'uber',
      'preparing',
      'dropoff',
      requiresCourier: true,
      requiresLocation: true,
    );

    expect(orderBoardStage(uber), OrderBoardStage.onWay);
    expect(orderBoardForwardLabel(uber), isNull);
    expect(orderBoardShowsBack(uber), isFalse);
    expect(orderCardShowsElapsedTimer(uber), isFalse);
    expect(orderCardIsOnTheWay(uber), isTrue);
    expect(
      orderCardShowsElapsedTimer(
        order('self-delivery', 'on_the_way', null, requiresLocation: true),
      ),
      isTrue,
    );
  });

  test('pickup-ready courier can only go back while pickup can complete', () {
    final courier = order(
      'courier',
      'ready_for_pickup',
      'pickup',
      requiresCourier: true,
    );
    final pickup = order('pickup', 'ready_for_pickup', null);

    expect(orderBoardForwardLabel(courier), isNull);
    expect(orderBoardShowsBack(courier), isTrue);
    expect(orderBoardForwardLabel(pickup), 'Marcar entregada');
    expect(orderBoardShowsBack(pickup), isTrue);
  });

  test('delivered pickup can go back but delivered courier stays locked', () {
    final courier = order(
      'courier',
      'delivered',
      'delivered',
      requiresCourier: true,
    );
    final pickup = order('pickup', 'delivered', null);

    expect(orderBoardShowsBack(courier), isFalse);
    expect(orderBoardShowsBack(pickup), isTrue);
  });

  test('legacy ready and delivered share the final board stage', () {
    expect(
      orderBoardStage(order('legacy', 'ready', null)),
      OrderBoardStage.delivered,
    );
    expect(
      orderBoardStage(order('current', 'delivered', null)),
      OrderBoardStage.delivered,
    );
  });
}
