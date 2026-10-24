part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.userId = '',
    this.email = '',
    this.explicitSignInVersion = 0,
    this.errorMessage = '',
  });

  final AuthStatus status;
  final bool isLoading;
  final String userId;
  final String email;
  final int explicitSignInVersion;
  final String errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? userId,
    String? email,
    int? explicitSignInVersion,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      explicitSignInVersion:
          explicitSignInVersion ?? this.explicitSignInVersion,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [
    status,
    isLoading,
    userId,
    email,
    explicitSignInVersion,
    errorMessage,
  ];
}
