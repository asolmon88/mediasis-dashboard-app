import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({SupabaseAuthService? authService})
    : _authService = authService ?? SupabaseAuthService(),
      super(const AuthState());

  final SupabaseAuthService _authService;
  StreamSubscription<sb.AuthState>? _authStateSubscription;

  Future<void> initialize() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = _authService.authStateChanges().listen(
      (authState) {
        final isUnexpectedSignOut =
            authState.event == sb.AuthChangeEvent.signedOut &&
            authState.session == null &&
            state.status == AuthStatus.authenticated &&
            !state.isLoading;

        if (isUnexpectedSignOut) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              isLoading: false,
              errorMessage: 'Tu sesión ha expirado. Inicia sesión nuevamente.',
            ),
          );
        } else {
          _emitSession(authState.session);
        }
      },
      onError: (_) async {
        // Auth stream errors are often transient (network blip, rate limit, 5xx).
        // The SDK clears the session itself for true expiry and fires signedOut instead.
        // Only sign the user out if the SDK has already confirmed no session exists.
        final session = await _authService.getCurrentSession();
        if (session == null) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              isLoading: false,
              errorMessage: 'Tu sesión ha expirado. Inicia sesión nuevamente.',
            ),
          );
        }
      },
    );

    final session = await _authService.recoverUsableSession();
    _emitSession(session);
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final response = await _authService.signInWithPassword(
        email: email,
        password: password,
      );

      _emitSession(response.session, isLoading: false, explicitSignIn: true);
    } on sb.AuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: 'Unexpected error while signing in.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      await _authService.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on sb.AuthException catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unexpected error while signing out.',
        ),
      );
    }
  }

  void clearError() {
    if (state.errorMessage.isEmpty) return;

    emit(state.copyWith(clearErrorMessage: true));
  }

  void _emitSession(
    sb.Session? session, {
    bool isLoading = false,
    bool explicitSignIn = false,
  }) {
    final userId = session?.user.id ?? '';
    final email = session?.user.email ?? '';

    emit(
      state.copyWith(
        status: session == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        isLoading: isLoading,
        userId: userId,
        email: email,
        explicitSignInVersion: explicitSignIn
            ? state.explicitSignInVersion + 1
            : state.explicitSignInVersion,
        clearErrorMessage: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authStateSubscription?.cancel();
    return super.close();
  }
}
