import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:http/http.dart' as http;

class SupabaseProductsService {
  SupabaseProductsService({DashboardApiClient? apiClient})
    : _apiClient = apiClient ?? dashboardApiClient;

  final DashboardApiClient _apiClient;

  Future<List<ProductTableRow>> fetchProductsTable({
    required String businessLocationId,
  }) async {
    final data = await supabase
        .schema('mediasis')
        .rpc(
          'get_products_for_app_table',
          params: {'p_business_location_id': businessLocationId},
        );
    final map = (data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final success = map['success'] as bool? ?? false;
    if (!success) {
      throw StateError(
        map['message'] as String? ?? 'No se pudieron cargar los productos.',
      );
    }

    final rows = map['data'] is List ? map['data'] as List : const [];

    return rows
        .whereType<Map>()
        .map((item) => ProductTableRow.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<OrderActionResult> updateProductVisibility({
    required String businessLocationId,
    required String productId,
    required bool visibility,
  }) async {
    final response = await _postDashboardApi(
      path: '/api/products/product-visibility',
      body: <String, dynamic>{
        'business_location_id': businessLocationId,
        'product_id': productId,
        'visible': visibility,
      },
    );
    return OrderActionResult(
      success: response['success'] == true,
      message: response['message'] as String?,
    );
  }

  Future<List<ProductVariantRow>> fetchProductVariants({
    required String productId,
    required String businessLocationId,
  }) async {
    final response = await _getDashboardApi(
      path: '/api/products/variants',
      queryParameters: <String, String>{
        'product_id': productId,
        'business_location_id': businessLocationId,
      },
    );
    if (response['success'] != true) {
      throw StateError(
        response['message'] as String? ??
            'No se pudieron cargar las variantes del producto.',
      );
    }

    final rows = response['data'] is List ? response['data'] as List : const [];
    return rows
        .whereType<Map>()
        .map((item) => ProductVariantRow.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<ProductVariantVisibilityResult> setVariantVisibility({
    required String productVariantId,
    required String businessLocationId,
    required bool visible,
  }) async {
    try {
      final response = await _postDashboardApi(
        path: '/api/products/variant-visibility',
        body: <String, dynamic>{
          'product_variant_id': productVariantId,
          'business_location_id': businessLocationId,
          'visible': visible,
        },
      );
      final data = response['data'] is Map
          ? (response['data'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      return ProductVariantVisibilityResult(
        success: response['success'] == true,
        message: response['message'] as String?,
        productHidden: data['product_hidden'] == true,
        visibleAtLocation: data['visible_at_location'] as bool?,
      );
    } catch (error) {
      return ProductVariantVisibilityResult(
        success: false,
        message: '$error'.replaceFirst('Bad state: ', '').trim(),
      );
    }
  }

  Future<List<ProductOptionRow>> fetchProductOptions({
    required String productId,
    required String businessLocationId,
  }) async {
    final response = await _apiClient.get(
      '/api/products/options',
      queryParameters: {
        'product_id': productId,
        'business_location_id': businessLocationId,
      },
    );

    Map<String, dynamic> map = <String, dynamic>{};
    if (response.body.trim().isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        map = body is Map ? body.cast<String, dynamic>() : <String, dynamic>{};
      } catch (_) {
        throw StateError(
          'El endpoint devolvio ${response.statusCode}, pero no devolvio JSON valido. Body: ${response.body}',
        );
      }
    }

    final success = map['success'] == true;
    if (!success) {
      throw StateError(
        map['message'] as String? ??
            'No se pudieron cargar las opciones del producto.',
      );
    }

    final rows = map['data'] is List ? map['data'] as List : const [];
    return rows
        .whereType<Map>()
        .map((item) => ProductOptionRow.fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<OrderActionResult> setChoiceVisibility({
    required String productOptionChoiceId,
    required String businessLocationId,
    required bool visible,
  }) async {
    try {
      final response = await _apiClient.postJson(
        '/api/products/choice-visibility',
        body: <String, dynamic>{
          'product_option_choice_id': productOptionChoiceId,
          'business_location_id': businessLocationId,
          'visible': visible,
        },
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
      return OrderActionResult(
        success: success,
        message: map['message'] as String?,
      );
    } catch (e) {
      return OrderActionResult(success: false, message: '$e');
    }
  }

  Future<Map<String, dynamic>> _getDashboardApi({
    required String path,
    required Map<String, String> queryParameters,
  }) async {
    final response = await _apiClient.get(
      path,
      queryParameters: queryParameters,
    );
    return _decodeDashboardResponse(response);
  }

  Future<Map<String, dynamic>> _postDashboardApi({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.postJson(path, body: body);
    return _decodeDashboardResponse(response);
  }

  Map<String, dynamic> _decodeDashboardResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw StateError('El endpoint respondio sin contenido.');
    }
    try {
      final body = jsonDecode(response.body);
      if (body is! Map) {
        throw const FormatException();
      }
      return body.cast<String, dynamic>();
    } catch (_) {
      throw StateError(
        'El endpoint respondio con ${response.statusCode}, pero no devolvio JSON valido.',
      );
    }
  }
}
