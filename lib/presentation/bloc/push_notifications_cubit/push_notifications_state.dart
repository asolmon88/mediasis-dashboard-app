part of 'push_notifications_cubit.dart';

enum PushNotificationsStatus {
  initial,
  initializing,
  ready,
  unsupported,
  failure,
}

enum PushNotificationChoice { unknown, enabled, declined }

class PushNotificationsState extends Equatable {
  const PushNotificationsState({
    this.status = PushNotificationsStatus.initial,
    this.permissionGranted = false,
    this.canRequestPermission = false,
    this.optedIn = false,
    this.identityActive = false,
    this.choice = PushNotificationChoice.unknown,
    this.subscriptionId,
    this.token,
    this.registeredLocationId,
    this.shouldShowPermissionExplanation = false,
    this.pendingIntents = const [],
    this.isBusy = false,
    this.errorMessage = '',
  });

  final PushNotificationsStatus status;
  final bool permissionGranted;
  final bool canRequestPermission;
  final bool optedIn;
  final bool identityActive;
  final PushNotificationChoice choice;
  final String? subscriptionId;
  final String? token;
  final String? registeredLocationId;
  final bool shouldShowPermissionExplanation;
  final List<PushNotificationIntent> pendingIntents;
  final bool isBusy;
  final String errorMessage;

  bool get isSupported =>
      status != PushNotificationsStatus.unsupported &&
      status != PushNotificationsStatus.initial;

  bool get isRegistered =>
      permissionGranted &&
      identityActive &&
      optedIn &&
      subscriptionId != null &&
      registeredLocationId != null;

  PushNotificationsState copyWith({
    PushNotificationsStatus? status,
    bool? permissionGranted,
    bool? canRequestPermission,
    bool? optedIn,
    bool? identityActive,
    PushNotificationChoice? choice,
    String? subscriptionId,
    String? token,
    String? registeredLocationId,
    bool? shouldShowPermissionExplanation,
    List<PushNotificationIntent>? pendingIntents,
    bool? isBusy,
    String? errorMessage,
    bool clearSubscriptionId = false,
    bool clearToken = false,
    bool clearRegisteredLocationId = false,
    bool clearErrorMessage = false,
  }) {
    return PushNotificationsState(
      status: status ?? this.status,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      canRequestPermission: canRequestPermission ?? this.canRequestPermission,
      optedIn: optedIn ?? this.optedIn,
      identityActive: identityActive ?? this.identityActive,
      choice: choice ?? this.choice,
      subscriptionId: clearSubscriptionId
          ? null
          : subscriptionId ?? this.subscriptionId,
      token: clearToken ? null : token ?? this.token,
      registeredLocationId: clearRegisteredLocationId
          ? null
          : registeredLocationId ?? this.registeredLocationId,
      shouldShowPermissionExplanation:
          shouldShowPermissionExplanation ??
          this.shouldShowPermissionExplanation,
      pendingIntents: pendingIntents ?? this.pendingIntents,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    permissionGranted,
    canRequestPermission,
    optedIn,
    identityActive,
    choice,
    subscriptionId,
    token,
    registeredLocationId,
    shouldShowPermissionExplanation,
    pendingIntents,
    isBusy,
    errorMessage,
  ];
}
