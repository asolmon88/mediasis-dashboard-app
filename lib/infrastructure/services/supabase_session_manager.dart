import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SessionAccessFailure { missing, temporarilyUnavailable, rejected }

class SessionAccessException implements Exception {
  const SessionAccessException(this.failure, this.message, [this.cause]);

  final SessionAccessFailure failure;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

typedef CurrentSessionReader = Session? Function();
typedef SessionRefresher = Future<AuthResponse> Function();

class SupabaseSessionManager {
  SupabaseSessionManager({
    CurrentSessionReader? currentSession,
    SessionRefresher? refreshSession,
  }) : _currentSession = currentSession ?? (() => supabase.auth.currentSession),
       _refreshSession =
           refreshSession ?? (() => supabase.auth.refreshSession());

  final CurrentSessionReader _currentSession;
  final SessionRefresher _refreshSession;
  Future<Session>? _refreshInFlight;

  Session? get currentSession => _currentSession();

  Future<Session> requireSession({bool forceRefresh = false}) async {
    final current = _currentSession();
    if (current == null) {
      throw const SessionAccessException(
        SessionAccessFailure.missing,
        'No hay una sesion activa.',
      );
    }
    if (!forceRefresh && !current.isExpired) return current;

    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final refresh = _refresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
    }
  }

  Future<Session> _refresh() async {
    try {
      final response = await _refreshSession();
      final session = response.session ?? _currentSession();
      if (session == null) {
        throw const SessionAccessException(
          SessionAccessFailure.missing,
          'La sesion ya no esta disponible.',
        );
      }
      return session;
    } on AuthRetryableFetchException catch (error) {
      throw SessionAccessException(
        SessionAccessFailure.temporarilyUnavailable,
        'No se pudo renovar la sesion por un problema temporal de conexion.',
        error,
      );
    } on SessionAccessException {
      rethrow;
    } on AuthException catch (error) {
      final session = _currentSession();
      throw SessionAccessException(
        session == null
            ? SessionAccessFailure.missing
            : SessionAccessFailure.temporarilyUnavailable,
        session == null
            ? 'La sesion expiro. Inicia sesion nuevamente.'
            : 'No se pudo renovar la sesion en este momento.',
        error,
      );
    } catch (error) {
      throw SessionAccessException(
        SessionAccessFailure.temporarilyUnavailable,
        'No se pudo renovar la sesion en este momento.',
        error,
      );
    }
  }
}

final supabaseSessionManager = SupabaseSessionManager();
