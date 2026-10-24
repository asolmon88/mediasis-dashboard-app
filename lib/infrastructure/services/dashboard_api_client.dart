import 'dart:convert';

import 'package:mediasis_dashboard_app/config/supabase/supabase_config.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/supabase_session_manager.dart';
import 'package:http/http.dart' as http;

class DashboardAuthenticationException implements Exception {
  const DashboardAuthenticationException(this.path);

  final String path;

  @override
  String toString() =>
      'La sesion fue rechazada por el servidor. Intenta nuevamente.';
}

class DashboardApiClient {
  DashboardApiClient({
    http.Client? client,
    SupabaseSessionManager? sessionManager,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _sessionManager = sessionManager ?? supabaseSessionManager,
       _baseUrl = baseUrl ?? SupabaseConfig.dashboardApiBaseUrl;

  final http.Client _client;
  final SupabaseSessionManager _sessionManager;
  final String _baseUrl;

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _authenticatedRequest(
      'GET',
      path,
      (uri, authorization) => _client.get(
        uri.replace(queryParameters: queryParameters),
        headers: {...?headers, 'Authorization': authorization},
      ),
    );
  }

  Future<http.Response> postJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) {
    final encodedBody = jsonEncode(body);
    return _authenticatedRequest(
      'POST',
      path,
      (uri, authorization) => _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
          'Authorization': authorization,
        },
        body: encodedBody,
      ),
    );
  }

  Future<http.Response> _authenticatedRequest(
    String _,
    String path,
    Future<http.Response> Function(Uri uri, String authorization) send,
  ) async {
    final baseUrl = _baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw StateError('DASHBOARD_API_BASE_URL no esta configurado.');
    }
    final uri = Uri.parse(baseUrl).resolve(path);
    var session = await _sessionManager.requireSession();
    var response = await send(uri, 'Bearer ${session.accessToken}');
    if (response.statusCode != 401) return response;

    session = await _sessionManager.requireSession(forceRefresh: true);
    response = await send(uri, 'Bearer ${session.accessToken}');
    if (response.statusCode == 401) {
      throw DashboardAuthenticationException(path);
    }
    return response;
  }
}

final dashboardApiClient = DashboardApiClient();
