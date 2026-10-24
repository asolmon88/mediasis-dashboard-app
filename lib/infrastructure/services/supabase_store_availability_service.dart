import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:intl/intl.dart';

class SupabaseStoreAvailabilityService {
  Future<StoreAvailabilitySnapshot> fetchStoreAvailability({
    required String businessLocationId,
    required DateTime localNow,
  }) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'is_business_open_for_orders',
          params: {
            'p_business_location_id': businessLocationId,
            'p_local_date': DateFormat('yyyy-MM-dd').format(localNow),
            'p_weekday': localNow.weekday,
            'p_minutes': (localNow.hour * 60) + localNow.minute,
          },
        );

    final row = switch (data) {
      final List<dynamic> list when list.isNotEmpty => list.first,
      final Map<dynamic, dynamic> map => map,
      _ => null,
    };

    final map = row is Map ? row.cast<String, dynamic>() : <String, dynamic>{};

    return StoreAvailabilitySnapshot(
      isOpen: map['is_open'] as bool? ?? true,
      note: map['note'] as String?,
    );
  }

  Future<OrderActionResult> setManualOrderClosureForDay({
    required String businessLocationId,
    required DateTime localDate,
    required bool closed,
    String? note,
  }) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'set_manual_order_closure_for_day',
          params: {
            'p_business_location_id': businessLocationId,
            'p_local_date': DateFormat('yyyy-MM-dd').format(localDate),
            'p_closed': closed,
            'p_note': note,
          },
        );

    final row = switch (data) {
      final List<dynamic> list when list.isNotEmpty => list.first,
      final Map<dynamic, dynamic> map => map,
      _ => null,
    };

    final map = row is Map ? row.cast<String, dynamic>() : <String, dynamic>{};
    final success = map['success'] as bool? ?? false;

    return OrderActionResult(
      success: success,
      message: map['message'] as String?,
    );
  }
}
