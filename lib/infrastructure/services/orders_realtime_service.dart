import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersRealtimeService {
  RealtimeChannel? _channel;
  RealtimeChannel? _uberChannel;

  Future<void> subscribeToOrderUpdates({
    required String businessLocationId,
    required void Function(OrderRealtimeRowUpdate update) onUpdate,
    void Function(String message)? onError,
    void Function()? onConnected,
  }) async {
    await unsubscribe();

    final channel = supabase
        .channel('orders-realtime-$businessLocationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'mediasis',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_location_id',
            value: businessLocationId,
          ),
          callback: (payload) {
            final update = OrderRealtimeRowUpdate.fromPayload(payload);
            if (update.orderId.isEmpty) return;
            onUpdate(update);
          },
        );

    _channel = channel;
    channel.subscribe((status, error) {
      if (!identical(_channel, channel)) return;

      if (status == RealtimeSubscribeStatus.subscribed) {
        onConnected?.call();
      }
      if (_isDisconnected(status)) {
        onError?.call(
          error?.toString() ?? 'No se pudo conectar el tiempo real.',
        );
      }
    });
  }

  Future<void> subscribeToUberDeliveryUpdates({
    required String businessLocationId,
    required void Function(String orderId) onUpdate,
    void Function(String message)? onError,
  }) async {
    final previousUberChannel = _uberChannel;
    if (previousUberChannel != null) {
      _uberChannel = null;
      await supabase.removeChannel(previousUberChannel);
    }

    final channel = supabase
        .channel('uber-deliveries-realtime-$businessLocationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'mediasis',
          table: 'uber_deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_location_id',
            value: businessLocationId,
          ),
          callback: (payload) {
            final row = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final orderId = row['order_id'] as String?;
            if (orderId != null && orderId.isNotEmpty) onUpdate(orderId);
          },
        );

    _uberChannel = channel;
    channel.subscribe((status, error) {
      if (!identical(_uberChannel, channel)) return;

      if (_isDisconnected(status)) {
        onError?.call(
          error?.toString() ?? 'No se pudo conectar Uber tiempo real.',
        );
      }
    });
  }

  Future<void> unsubscribe() async {
    final channel = _channel;
    final uberChannel = _uberChannel;
    _channel = null;
    _uberChannel = null;

    if (channel != null) {
      await supabase.removeChannel(channel);
    }
    if (uberChannel != null) {
      await supabase.removeChannel(uberChannel);
    }
  }

  bool _isDisconnected(RealtimeSubscribeStatus status) {
    return status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut ||
        status == RealtimeSubscribeStatus.closed;
  }
}
