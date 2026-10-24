import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  SupabaseAuthService({SupabaseSessionManager? sessionManager})
    : _sessionManager = sessionManager ?? supabaseSessionManager;

  final SupabaseSessionManager _sessionManager;

  Future<Session?> getCurrentSession() async {
    return supabase.auth.currentSession;
  }

  Future<Session?> recoverUsableSession() async {
    final current = supabase.auth.currentSession;
    if (current == null) return null;
    try {
      return await _sessionManager.requireSession();
    } on SessionAccessException {
      // Retryable refresh failures keep the persisted session. A terminal
      // refresh failure is reflected by Supabase clearing currentSession.
      return supabase.auth.currentSession;
    }
  }

  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange;
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return supabase.auth.signOut(scope: SignOutScope.local);
  }
}
