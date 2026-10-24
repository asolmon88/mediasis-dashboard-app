import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';

class SupabaseDeliveryPreparationService {
  SupabaseDeliveryPreparationService({DashboardApiClient? apiClient})
    : _apiClient = apiClient ?? dashboardApiClient;

  final DashboardApiClient _apiClient;

  Future<List<DeliveryMethodTableRow>> fetchDeliveryMethods({
    required String businessLocationId,
  }) async {
    final businessId = supabase.auth.currentUser?.id;
    if (businessId == null || businessId.isEmpty) {
      throw StateError('No se pudo identificar el negocio actual.');
    }
    if (businessLocationId.isEmpty) return const [];

    final responses = await Future.wait([
      supabase
          .schema('mediasis')
          .from('delivery_methods_business')
          .select('uid, name, instructions, visibility, scope')
          .eq('business_id', businessId)
          .order('name'),
      supabase
          .schema('mediasis')
          .from('delivery_methods_business_location')
          .select('delivery_methods_business_id')
          .eq('business_location_id', businessLocationId),
    ]);

    final rows = List<Map<String, dynamic>>.from(
      responses[0] as List,
    ).map(DeliveryMethodTableRow.fromMap);
    final assignedMethodIds =
        List<Map<String, dynamic>>.from(responses[1] as List)
            .map((row) => row['delivery_methods_business_id'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    return filterDeliveryMethodsForLocation(rows, assignedMethodIds);
  }

  Future<Map<String, int>> fetchPickupOffsetsByLocation({
    required String businessLocationId,
    required List<String> deliveryMethodIds,
  }) async {
    final cleanIds = deliveryMethodIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (businessLocationId.isEmpty || cleanIds.isEmpty) {
      return const {};
    }

    final data = await supabase
        .schema('mediasis')
        .from('delivery_method_business_pickup_offset_location')
        .select('business_delivery_method_id, pickup_ready_offset')
        .eq('business_location_id', businessLocationId)
        .inFilter('business_delivery_method_id', cleanIds);

    final rows = List<Map<String, dynamic>>.from(data as List);

    return rows.fold<Map<String, int>>({}, (acc, map) {
      final methodId = map['business_delivery_method_id'] as String? ?? '';
      if (methodId.isEmpty) return acc;
      acc[methodId] = deliveryIntervalToMinutes(
        map['pickup_ready_offset'] as String?,
      );
      return acc;
    });
  }

  Future<OrderActionResult> updatePickupReadyOffsetByLocation({
    required String businessDeliveryMethodId,
    required String businessLocationId,
    required int pickupReadyOffsetMinutes,
  }) async {
    if (businessDeliveryMethodId.isEmpty || businessLocationId.isEmpty) {
      return const OrderActionResult(
        success: false,
        message: 'Datos inválidos para actualizar el tiempo de preparación.',
      );
    }

    final response = await _apiClient.postJson(
      '/api/delivery/preparation-time',
      body: <String, dynamic>{
        'businessDeliveryMethodId': businessDeliveryMethodId,
        'businessLocationId': businessLocationId,
        'preparationMinutes': pickupReadyOffsetMinutes,
      },
    );

    Map<String, dynamic> result = const <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) result = decoded.cast<String, dynamic>();
      } catch (_) {
        return const OrderActionResult(
          success: false,
          message: 'El servidor devolvió una respuesta inválida.',
        );
      }
    }

    return OrderActionResult(
      success: result['success'] == true,
      message:
          result['message'] as String? ??
          (response.statusCode >= 200 && response.statusCode < 300
              ? null
              : 'No se pudo actualizar el tiempo de preparación.'),
    );
  }
}
