import 'dart:async';
import 'dart:convert';

import 'package:mediasis_dashboard_app/infrastructure/services/dashboard_api_client.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/supabase_session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('valid session is returned without refreshing', () async {
    final session = _session('valid', expiresIn: const Duration(hours: 1));
    var refreshCount = 0;
    final manager = SupabaseSessionManager(
      currentSession: () => session,
      refreshSession: () async {
        refreshCount++;
        return AuthResponse(session: session);
      },
    );

    expect(await manager.requireSession(), same(session));
    expect(refreshCount, 0);
  });

  test('concurrent expired-session requests share one refresh', () async {
    final expired = _session('expired', expiresIn: const Duration(minutes: -1));
    final refreshed = _session(
      'refreshed',
      expiresIn: const Duration(hours: 1),
    );
    final completer = Completer<AuthResponse>();
    var current = expired;
    var refreshCount = 0;
    final manager = SupabaseSessionManager(
      currentSession: () => current,
      refreshSession: () {
        refreshCount++;
        return completer.future.then((response) {
          current = response.session!;
          return response;
        });
      },
    );

    final first = manager.requireSession();
    final second = manager.requireSession();
    completer.complete(AuthResponse(session: refreshed));

    expect((await first).accessToken, refreshed.accessToken);
    expect((await second).accessToken, refreshed.accessToken);
    expect(refreshCount, 1);
  });

  test('retryable refresh failure preserves the current session', () async {
    final expired = _session('expired', expiresIn: const Duration(minutes: -1));
    final manager = SupabaseSessionManager(
      currentSession: () => expired,
      refreshSession: () async =>
          throw AuthRetryableFetchException(message: 'offline'),
    );

    await expectLater(
      manager.requireSession(),
      throwsA(
        isA<SessionAccessException>().having(
          (error) => error.failure,
          'failure',
          SessionAccessFailure.temporarilyUnavailable,
        ),
      ),
    );
    expect(manager.currentSession, same(expired));
  });

  test('401 refreshes once and retries POST with the same body', () async {
    final original = _session('old', expiresIn: const Duration(hours: 1));
    var current = original;
    final refreshed = _session('new', expiresIn: const Duration(hours: 1));
    var refreshCount = 0;
    final requests = <http.Request>[];
    final manager = SupabaseSessionManager(
      currentSession: () => current,
      refreshSession: () async {
        refreshCount++;
        current = refreshed;
        return AuthResponse(session: refreshed);
      },
    );
    final api = DashboardApiClient(
      baseUrl: 'https://dashboard.example',
      sessionManager: manager,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          requests.length == 1 ? '{}' : '{"success":true}',
          requests.length == 1 ? 401 : 200,
        );
      }),
    );

    final response = await api.postJson('/api/action', body: {'value': 7});

    expect(response.statusCode, 200);
    expect(refreshCount, 1);
    expect(requests, hasLength(2));
    expect(requests[0].body, requests[1].body);
    expect(
      requests[0].headers['authorization'],
      'Bearer ${original.accessToken}',
    );
    expect(
      requests[1].headers['authorization'],
      'Bearer ${refreshed.accessToken}',
    );
  });

  test('403 does not refresh or discard the session', () async {
    final session = _session('valid', expiresIn: const Duration(hours: 1));
    var refreshCount = 0;
    final manager = SupabaseSessionManager(
      currentSession: () => session,
      refreshSession: () async {
        refreshCount++;
        return AuthResponse(session: session);
      },
    );
    final api = DashboardApiClient(
      baseUrl: 'https://dashboard.example',
      sessionManager: manager,
      client: MockClient((_) async => http.Response('{}', 403)),
    );

    final response = await api.get('/api/forbidden');

    expect(response.statusCode, 403);
    expect(refreshCount, 0);
    expect(manager.currentSession, same(session));
  });

  test('second 401 reports rejection without clearing the session', () async {
    var current = _session('old', expiresIn: const Duration(hours: 1));
    final refreshed = _session('new', expiresIn: const Duration(hours: 1));
    final manager = SupabaseSessionManager(
      currentSession: () => current,
      refreshSession: () async {
        current = refreshed;
        return AuthResponse(session: refreshed);
      },
    );
    final api = DashboardApiClient(
      baseUrl: 'https://dashboard.example',
      sessionManager: manager,
      client: MockClient((_) async => http.Response('{}', 401)),
    );

    await expectLater(
      api.get('/api/rejected'),
      throwsA(isA<DashboardAuthenticationException>()),
    );
    expect(manager.currentSession, same(refreshed));
  });
}

Session _session(String marker, {required Duration expiresIn}) {
  return Session(
    accessToken: _token(marker, expiresIn: expiresIn),
    refreshToken: 'refresh-$marker',
    tokenType: 'bearer',
    expiresIn: expiresIn.inSeconds,
    user: User(
      id: 'user-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.utc(2026).toIso8601String(),
    ),
  );
}

String _token(String marker, {required Duration expiresIn}) {
  String part(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt =
      DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none', 'marker': marker})}.${part({'exp': expiresAt})}.signature';
}
