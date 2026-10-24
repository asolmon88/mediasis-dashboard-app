import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/pickup_now_button.dart';
import 'package:mediasis_dashboard_app/presentation/widgets/orders_screen/order_detail_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('courier details are hidden while Uber searches for a replacement', () {
    expect(uberStatusShowsCourier('pending'), isFalse);
    expect(uberStatusShowsCourier('canceled'), isFalse);
    expect(uberStatusShowsCourier(null), isFalse);
    expect(uberStatusShowsCourier('pickup'), isTrue);
    expect(uberStatusShowsCourier('dropoff'), isTrue);
    expect(uberStatusShowsCourier('delivered'), isTrue);
  });

  test(
    'pickup now is available only for active assigned courier deliveries',
    () {
      expect(
        canRequestPickupNow(
          requiresCourier: true,
          deliveryId: 'del_123',
          deliveryStatus: 'pending',
          orderStatus: 'preparing',
        ),
        isTrue,
      );
      expect(
        canRequestPickupNow(
          requiresCourier: false,
          deliveryId: 'del_123',
          deliveryStatus: 'pending',
          orderStatus: 'preparing',
        ),
        isFalse,
      );
      expect(
        canRequestPickupNow(
          requiresCourier: true,
          deliveryId: null,
          deliveryStatus: 'pending',
          orderStatus: 'preparing',
        ),
        isFalse,
      );
    },
  );

  test('tracking link keeps older realtime payloads locally eligible', () {
    expect(
      canRequestPickupNow(
        requiresCourier: false,
        deliveryId: null,
        trackingLink: 'https://tracking.uber.com/example',
        deliveryStatus: 'pending',
        orderStatus: 'preparing',
      ),
      isTrue,
    );
  });

  for (final status in const [
    'pickup',
    'pickup_complete',
    'dropoff',
    'delivered',
    'canceled',
    'returned',
  ]) {
    test('pickup now is unavailable when Uber status is $status', () {
      expect(
        canRequestPickupNow(
          requiresCourier: true,
          deliveryId: 'del_123',
          deliveryStatus: status,
          orderStatus: 'preparing',
        ),
        isFalse,
      );
    });
  }

  for (final status in const ['ready_for_pickup', 'ready', 'delivered']) {
    test('pickup now is unavailable when order status is $status', () {
      expect(
        canRequestPickupNow(
          requiresCourier: true,
          deliveryId: 'del_123',
          deliveryStatus: 'pending',
          orderStatus: status,
        ),
        isFalse,
      );
    });
  }
}
