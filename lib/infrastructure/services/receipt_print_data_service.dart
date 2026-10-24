import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/dashboard_api_client.dart';

class ReceiptPrintDataService {
  ReceiptPrintDataService({DashboardApiClient? apiClient})
    : _apiClient = apiClient ?? dashboardApiClient;

  final DashboardApiClient _apiClient;

  Future<ReceiptPrintPayload> fetch({
    required String orderId,
    required String businessLocationId,
  }) async {
    final response = await _apiClient
        .get(
          '/api/orders/receipt-print-data',
          queryParameters: {
            'order_id': orderId,
            'business_location_id': businessLocationId,
          },
        )
        .timeout(const Duration(seconds: 15));
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw StateError(
          response.statusCode == 404
              ? 'El servicio para imprimir recibos todavia no esta disponible en el servidor.'
              : 'El servidor de recibos devolvio una respuesta no valida. Intenta nuevamente o verifica la configuracion del API.',
        );
      }
    }
    final map = decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        map['success'] != true ||
        map['data'] is! Map) {
      throw StateError(
        map['message'] as String? ?? 'No se pudo cargar el recibo.',
      );
    }
    return ReceiptPrintPayload.fromMap(
      (map['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<List<int>> fetchVisualBytes({
    required String orderId,
    required String businessLocationId,
    required PrinterPaperWidth paperWidth,
    required bool supportsCutter,
    required Duration timeout,
  }) async {
    final response = await _apiClient
        .postJson(
          '/api/orders/receipt-print-bytes',
          body: {
            'order_id': orderId,
            'business_location_id': businessLocationId,
            'paper_width': paperWidth.name,
            'supports_cutter': supportsCutter,
            'render_timeout_ms': timeout.inMilliseconds,
          },
        )
        .timeout(
          timeout + const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'El recibo visual tardo demasiado en generarse. Intenta nuevamente.',
          ),
        );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final bytes = response.bodyBytes;
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/vnd.mediasis.escpos') ||
          bytes.length < 2 ||
          bytes[0] != 0x1b ||
          bytes[1] != 0x40) {
        throw const FormatException(
          'El servidor devolvio un recibo visual no valido.',
        );
      }
      return bytes;
    }
    String message = 'No se pudo renderizar el recibo visual.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {}
    throw StateError(message);
  }
}
