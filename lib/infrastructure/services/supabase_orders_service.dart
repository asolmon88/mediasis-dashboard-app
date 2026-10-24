import 'dart:convert';
import 'dart:io';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:http/http.dart' as http;

class SupabaseOrdersService {
  SupabaseOrdersService({DashboardApiClient? apiClient})
    : _apiClient = apiClient ?? dashboardApiClient;

  final DashboardApiClient _apiClient;

  Future<OrderRealtimeResponse> fetchRealtimeOrders(
    String businessLocationId,
  ) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'get_orders_for_real_time_v2',
          params: {'p_business_location_id': businessLocationId},
        );

    return OrderRealtimeResponse.fromMap(
      (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Future<OrderRealtimeResponse> fetchRealtimeOrder(
    String orderId,
    String businessLocationId,
  ) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'get_order_for_real_time_v2',
          params: {
            'p_order_id': orderId,
            'p_business_location_id': businessLocationId,
          },
        );

    final map = (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final rawOrder = map['data'];

    if (rawOrder is Map<String, dynamic>) {
      return OrderRealtimeResponse(
        success: map['success'] as bool? ?? false,
        data: [OrderRealtimeOrder.fromMap(rawOrder)],
        message: map['message'] as String?,
      );
    }

    return OrderRealtimeResponse(
      success: map['success'] as bool? ?? false,
      data: const [],
      message: map['message'] as String?,
    );
  }

  Future<OrderDetailResponse> fetchOrderDetail(String orderId) async {
    final data = await supabase
        .schema('mediasis')
        .rpc('get_order_detail', params: {'p_order_id': orderId});

    return OrderDetailResponse.fromMap(
      (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Future<OrdersTableResponse> fetchOrdersTable({
    required String businessLocationId,
    int limit = 50,
    int offset = 0,
    List<String>? paymentStatus,
    List<String>? orderStatus,
    List<String>? paymentMethod,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'created_at',
    String sortDirection = 'desc',
  }) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'get_orders_table',
          params: {
            'p_business_location_id': businessLocationId,
            'p_limit': limit,
            'p_offset': offset,
            'p_payment_status': paymentStatus == null || paymentStatus.isEmpty
                ? null
                : paymentStatus,
            'p_order_status': orderStatus == null || orderStatus.isEmpty
                ? null
                : orderStatus,
            'p_payment_method': paymentMethod == null || paymentMethod.isEmpty
                ? null
                : paymentMethod,
            'p_date_from': dateFrom,
            'p_date_to': dateTo,
            'p_sort_by': sortBy,
            'p_sort_direction': sortDirection,
          },
        );

    return OrdersTableResponse.fromMap(
      (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Future<PaymentMethodsResponse> fetchVisiblePaymentMethods(
    String businessLocationId,
  ) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'get_visible_payment_methods',
          params: {'p_business_location_id': businessLocationId},
        );

    return PaymentMethodsResponse.fromMap(
      (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    await supabase
        .schema('mediasis')
        .from('orders')
        .update({'order_status': nextStatus})
        .eq('order_id', orderId);
  }

  Future<OrderActionResult> updatePickupReadyTime({
    required String orderId,
    required int minutes,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/api/orders/realtime/pickup-window',
        body: <String, dynamic>{'orderId': orderId, 'readyInMinutes': minutes},
      );

      Map<String, dynamic> map = <String, dynamic>{};
      if (response.body.trim().isNotEmpty) {
        try {
          final body = jsonDecode(response.body);
          map = body is Map
              ? body.cast<String, dynamic>()
              : <String, dynamic>{};
        } catch (_) {
          return OrderActionResult(
            success: false,
            message:
                'El endpoint respondio con ${response.statusCode}, pero no devolvio JSON valido.',
          );
        }
      }

      final success = map['success'] == true;
      final message = map['message'] as String?;

      if (success) {
        return const OrderActionResult(success: true);
      }

      return OrderActionResult(
        success: false,
        message:
            message ??
            'No se pudo actualizar la hora de pickup (${response.statusCode}).',
      );
    } on SocketException {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo conectar con el servidor. Revisa la conexion.',
      );
    } on http.ClientException catch (error) {
      return OrderActionResult(
        success: false,
        message: 'Error de red al llamar pickup-window: ${error.message}',
      );
    } catch (error) {
      return OrderActionResult(
        success: false,
        message: 'Fallo inesperado al llamar pickup-window: $error',
      );
    }
  }

  Future<OrderActionResult> callUberDelivery({required String orderId}) async {
    try {
      final response = await _apiClient.postJson(
        '/api/orders/realtime/call-uber',
        body: <String, dynamic>{'orderId': orderId},
      );

      Map<String, dynamic> map = <String, dynamic>{};
      if (response.body.trim().isNotEmpty) {
        try {
          final body = jsonDecode(response.body);
          map = body is Map
              ? body.cast<String, dynamic>()
              : <String, dynamic>{};
        } catch (_) {
          return OrderActionResult(
            success: false,
            message:
                'El endpoint respondio con ${response.statusCode}, pero no devolvio JSON valido.',
          );
        }
      }

      final success = map['success'] == true;
      final message = map['message'] as String?;

      if (success) return const OrderActionResult(success: true);
      return OrderActionResult(
        success: false,
        message:
            message ?? 'No se pudo llamar a Uber (${response.statusCode}).',
      );
    } on SocketException {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo conectar con el servidor. Revisa la conexion.',
      );
    } on http.ClientException catch (error) {
      return OrderActionResult(
        success: false,
        message: 'Error de red al llamar call-uber: ${error.message}',
      );
    } catch (error) {
      return OrderActionResult(
        success: false,
        message: 'Fallo inesperado al llamar call-uber: $error',
      );
    }
  }

  Future<OrderActionResult> requestPickupNow({required String orderId}) async {
    try {
      final response = await _apiClient.postJson(
        '/api/orders/realtime/pickup-now',
        body: <String, dynamic>{'orderId': orderId},
      );
      final decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (decoded is! Map) {
        return const OrderActionResult(
          success: false,
          message: 'El servidor no devolvio una respuesta valida.',
        );
      }
      final map = decoded.cast<String, dynamic>();
      return OrderActionResult(
        success: map['success'] == true,
        changed: map['changed'] as bool?,
        message:
            map['message'] as String? ??
            (response.isSuccessful
                ? null
                : 'No se pudo solicitar la recogida ahora.'),
      );
    } on FormatException {
      return const OrderActionResult(
        success: false,
        message: 'El servidor no devolvio una respuesta valida.',
      );
    } on SocketException {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo conectar con el servidor. Revisa la conexion.',
      );
    } on http.ClientException catch (error) {
      return OrderActionResult(
        success: false,
        message: 'Error de red al solicitar la recogida: ${error.message}',
      );
    } catch (_) {
      return const OrderActionResult(
        success: false,
        message: 'No se pudo solicitar la recogida ahora.',
      );
    }
  }
}

extension on http.Response {
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}
