import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'deduplicates a push for an order already inserted by push or realtime',
    () async {
      final order = OrderRealtimeOrder.fromMap({
        'order_id': 'order-1',
        'human_order_number': '101',
        'created_at': '2026-07-30T12:00:00Z',
        'order_status': 'pending',
        'products_price': 5000,
        'client': {
          'first_name': 'Ariel',
          'last_name': 'Solis',
          'phone_number': '88888888',
        },
        'delivery_method': {
          'uid': 'delivery-1',
          'name': 'Express',
          'require_courier': true,
        },
        'items': <Map<String, dynamic>>[],
      });
      final ordersService = _FakeOrdersService(order);
      final realtimeService = _FakeRealtimeService();
      final soundService = _FakeSoundService();
      final cubit = OrdersCubit(
        ordersService: ordersService,
        realtimeService: realtimeService,
        soundService: soundService,
      );

      await cubit.loadOrders('location-1');
      final first = await cubit.handleIncomingOrderNotification(
        orderId: 'order-1',
        businessLocationId: 'location-1',
      );
      final duplicate = await cubit.handleIncomingOrderNotification(
        orderId: 'order-1',
        businessLocationId: 'location-1',
      );

      expect(first.success, isTrue);
      expect(duplicate.success, isTrue);
      expect(cubit.state.ordersRaw, hasLength(1));
      expect(cubit.state.pendingIncomingAlertCount, 1);
      expect(soundService.startCalls, 1);

      await cubit.close();
    },
  );
}

class _FakeOrdersService extends SupabaseOrdersService {
  _FakeOrdersService(this.order);

  final OrderRealtimeOrder order;

  @override
  Future<OrderRealtimeResponse> fetchRealtimeOrders(
    String businessLocationId,
  ) async {
    return const OrderRealtimeResponse(success: true);
  }

  @override
  Future<OrderRealtimeResponse> fetchRealtimeOrder(
    String orderId,
    String businessLocationId,
  ) async {
    return OrderRealtimeResponse(success: true, data: [order]);
  }
}

class _FakeRealtimeService extends OrdersRealtimeService {
  @override
  Future<void> subscribeToOrderUpdates({
    required String businessLocationId,
    required void Function(OrderRealtimeRowUpdate update) onUpdate,
    void Function(String message)? onError,
    void Function()? onConnected,
  }) async {
    onConnected?.call();
  }

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
  int startCalls = 0;

  @override
  Future<void> startLoopingIncomingOrderSound() async {
    startCalls++;
  }

  @override
  Future<void> stopIncomingOrderSound() async {}

  @override
  Future<void> dispose() async {}
}
