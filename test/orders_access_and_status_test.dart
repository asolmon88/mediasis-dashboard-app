import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pickup confirmation plays only when Uber enters dropoff', () {
    expect(shouldPlayPickupConfirmation('pickup_complete', 'dropoff'), isTrue);
    expect(shouldPlayPickupConfirmation('pickup', 'dropoff'), isTrue);
    expect(shouldPlayPickupConfirmation('dropoff', 'dropoff'), isFalse);
    expect(shouldPlayPickupConfirmation(null, 'pickup'), isFalse);
  });

  test('classifies only the canonical location access failure', () async {
    final denied = _FakeOrdersService(
      const OrderRealtimeResponse(
        success: false,
        message: 'Not allowed for this business location',
      ),
    );
    final deniedCubit = _cubit(denied);
    await deniedCubit.loadOrders('location-1');
    expect(
      deniedCubit.state.failureReason,
      OrdersFailureReason.locationAccessDenied,
    );
    await deniedCubit.close();

    final generic = _FakeOrdersService(
      const OrderRealtimeResponse(success: false, message: 'Network error'),
    );
    final genericCubit = _cubit(generic);
    await genericCubit.loadOrders('location-1');
    expect(genericCubit.state.failureReason, isNull);
    await genericCubit.close();
  });

  test(
    'courier advances to pickup-ready and can return to preparing',
    () async {
      final service = _FakeOrdersService(
        OrderRealtimeResponse(
          success: true,
          data: [_order(status: 'preparing', uberStatus: 'pickup')],
        ),
      );
      final cubit = _cubit(service);
      await cubit.loadOrders('location-1');

      await cubit.moveOrderForward('order-1');
      expect(service.updatedStatuses, ['ready_for_pickup']);
      expect(cubit.state.orders.single.orderStatus, 'ready_for_pickup');

      await cubit.moveOrderBackward('order-1');
      expect(service.updatedStatuses, ['ready_for_pickup', 'preparing']);
      expect(cubit.state.orders.single.orderStatus, 'preparing');
      await cubit.close();
    },
  );

  test(
    'pending courier can prepare and canceled courier can be delivered',
    () async {
      final pendingService = _FakeOrdersService(
        OrderRealtimeResponse(success: true, data: [_order(status: 'pending')]),
      );
      final pendingCubit = _cubit(pendingService);
      await pendingCubit.loadOrders('location-1');
      await pendingCubit.moveOrderForward('order-1');
      expect(pendingService.updatedStatuses, ['preparing']);
      await pendingCubit.close();

      final canceledService = _FakeOrdersService(
        OrderRealtimeResponse(
          success: true,
          data: [_order(status: 'preparing', uberStatus: 'canceled')],
        ),
      );
      final canceledCubit = _cubit(canceledService);
      await canceledCubit.loadOrders('location-1');
      await canceledCubit.moveOrderForward('order-1');
      expect(canceledService.updatedStatuses, ['delivered']);
      await canceledCubit.close();
    },
  );

  test('pickup-ready courier cannot complete but pickup order can', () async {
    final courierService = _FakeOrdersService(
      OrderRealtimeResponse(
        success: true,
        data: [_order(status: 'ready_for_pickup', uberStatus: 'pickup')],
      ),
    );
    final courierCubit = _cubit(courierService);
    await courierCubit.loadOrders('location-1');
    await courierCubit.moveOrderForward('order-1');
    expect(courierService.updatedStatuses, isEmpty);
    await courierCubit.close();

    final pickupService = _FakeOrdersService(
      OrderRealtimeResponse(
        success: true,
        data: [_order(status: 'ready_for_pickup', requiresCourier: false)],
      ),
    );
    final pickupCubit = _cubit(pickupService);
    await pickupCubit.loadOrders('location-1');
    await pickupCubit.moveOrderForward('order-1');
    expect(pickupService.updatedStatuses, ['delivered']);
    await pickupCubit.close();
  });

  test('delivered pickup can return to pickup-ready', () async {
    final service = _FakeOrdersService(
      OrderRealtimeResponse(
        success: true,
        data: [_order(status: 'delivered', requiresCourier: false)],
      ),
    );
    final cubit = _cubit(service);
    await cubit.loadOrders('location-1');

    await cubit.moveOrderBackward('order-1');

    expect(service.updatedStatuses, ['ready_for_pickup']);
    expect(cubit.state.orders.single.orderStatus, 'ready_for_pickup');
    await cubit.close();
  });

  test('pharmacy delivery uses the persisted on-the-way workflow', () async {
    final service = _FakeOrdersService(
      OrderRealtimeResponse(
        success: true,
        data: [
          _order(
            status: 'preparing',
            requiresCourier: false,
            requiresLocation: true,
          ),
        ],
      ),
    );
    final cubit = _cubit(service);
    await cubit.loadOrders('location-1');

    await cubit.moveOrderForward('order-1');
    expect(service.updatedStatuses, ['on_the_way']);
    expect(cubit.state.orders.single.orderStatus, 'on_the_way');

    await cubit.moveOrderForward('order-1');
    expect(service.updatedStatuses, ['on_the_way', 'delivered']);

    await cubit.moveOrderBackward('order-1');
    expect(service.updatedStatuses, ['on_the_way', 'delivered', 'on_the_way']);
    await cubit.close();
  });
}

OrdersCubit _cubit(_FakeOrdersService service) => OrdersCubit(
  ordersService: service,
  realtimeService: _FakeRealtimeService(),
  soundService: _FakeSoundService(),
  printerStorage: _FakePrinterStorage(),
);

OrderRealtimeOrder _order({
  required String status,
  String? uberStatus,
  bool requiresCourier = true,
  bool requiresLocation = false,
}) => OrderRealtimeOrder.fromMap({
  'order_id': 'order-1',
  'created_at': '2026-10-12T12:00:00Z',
  'order_status': status,
  'client': <String, dynamic>{},
  'delivery_method': {
    'uid': 'delivery-1',
    'name': 'Express',
    'require_courier': requiresCourier,
    'require_location': requiresLocation,
  },
  'items': <Map<String, dynamic>>[],
  if (uberStatus != null)
    'uber_delivery': {
      'uber_delivery_pk': 'pk-1',
      'uber_delivery_id': 'del-1',
      'attempt_number': 1,
      'delivery_role': 'forward',
      'status': uberStatus,
    },
});

class _FakeOrdersService extends SupabaseOrdersService {
  _FakeOrdersService(this.response);

  final OrderRealtimeResponse response;
  final List<String> updatedStatuses = [];

  @override
  Future<OrderRealtimeResponse> fetchRealtimeOrders(
    String businessLocationId,
  ) async => response;

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    updatedStatuses.add(nextStatus);
  }
}

class _FakeRealtimeService extends OrdersRealtimeService {
  @override
  Future<void> subscribeToOrderUpdates({
    required String businessLocationId,
    required void Function(OrderRealtimeRowUpdate update) onUpdate,
    void Function(String message)? onError,
    void Function()? onConnected,
  }) async {}

  @override
  Future<void> subscribeToUberDeliveryUpdates({
    required String businessLocationId,
    required void Function(String orderId) onUpdate,
    void Function(String message)? onError,
  }) async {}

  @override
  Future<void> unsubscribe() async {}
}

class _FakeSoundService extends OrderSoundService {
  @override
  Future<void> playPickupConfirmationSound() async {}

  @override
  Future<void> startLoopingIncomingOrderSound() async {}

  @override
  Future<void> stopIncomingOrderSound() async {}

  @override
  Future<void> dispose() async {}
}

class _FakePrinterStorage extends PrinterStorageService {
  @override
  Future<Set<String>> readOrderBaseline(String locationId) async => {};

  @override
  Future<void> saveOrderBaseline(
    String locationId,
    Iterable<String> orderIds,
  ) async {}
}
