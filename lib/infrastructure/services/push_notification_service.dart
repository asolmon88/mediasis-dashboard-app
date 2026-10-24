import 'dart:async';

import 'package:mediasis_dashboard_app/config/notifications/onesignal_config.dart';
import 'package:mediasis_dashboard_app/infrastructure/services/supabase_client.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

enum PushNotificationIntentSource { foreground, click }

class PushNotificationIntent extends Equatable {
  const PushNotificationIntent({
    required this.notificationId,
    required this.orderId,
    required this.businessLocationId,
    required this.source,
  });

  final String notificationId;
  final String orderId;
  final String businessLocationId;
  final PushNotificationIntentSource source;

  @override
  List<Object> get props => [
    notificationId,
    orderId,
    businessLocationId,
    source,
  ];
}

class PushSubscriptionSnapshot extends Equatable {
  const PushSubscriptionSnapshot({
    required this.permissionGranted,
    required this.canRequestPermission,
    required this.optedIn,
    this.subscriptionId,
    this.token,
  });

  const PushSubscriptionSnapshot.unavailable()
    : permissionGranted = false,
      canRequestPermission = false,
      optedIn = false,
      subscriptionId = null,
      token = null;

  final bool permissionGranted;
  final bool canRequestPermission;
  final bool optedIn;
  final String? subscriptionId;
  final String? token;

  @override
  List<Object?> get props => [
    permissionGranted,
    canRequestPermission,
    optedIn,
    subscriptionId,
    token,
  ];
}

class PushSubscriptionRegistrationStatus extends Equatable {
  const PushSubscriptionRegistrationStatus({
    required this.exists,
    required this.enabled,
    this.businessLocationId,
  });

  final bool exists;
  final bool enabled;
  final String? businessLocationId;

  @override
  List<Object?> get props => [exists, enabled, businessLocationId];
}

abstract class PushNotificationGateway {
  bool get isSupported;
  Stream<PushSubscriptionSnapshot> get subscriptionChanges;
  Stream<PushNotificationIntent> get notificationIntents;

  Future<PushSubscriptionSnapshot> initialize();
  Future<PushSubscriptionSnapshot> activate(String externalUserId);
  Future<PushSubscriptionSnapshot> deactivate();
  Future<PushSubscriptionSnapshot> refreshSnapshot();
  Future<PushSubscriptionSnapshot> requestPermission({
    required bool fallbackToSettings,
  });
  Future<PushSubscriptionSnapshot> optIn();
  Future<PushSubscriptionSnapshot> optOut();
  Future<void> registerSubscription({
    required String subscriptionId,
    required String businessLocationId,
  });
  Future<void> disableSubscription(String subscriptionId);
  Future<PushSubscriptionRegistrationStatus> getRegistrationStatus(
    String subscriptionId,
  );
  Future<void> close();
}

class PushNotificationService implements PushNotificationGateway {
  PushNotificationService();

  final _subscriptionController =
      StreamController<PushSubscriptionSnapshot>.broadcast();
  final _intentController =
      StreamController<PushNotificationIntent>.broadcast();

  bool _initialized = false;

  @override
  bool get isSupported {
    if (kIsWeb) return false;
    return OneSignalConfig.appId.isNotEmpty &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  Stream<PushSubscriptionSnapshot> get subscriptionChanges =>
      _subscriptionController.stream;

  @override
  Stream<PushNotificationIntent> get notificationIntents =>
      _intentController.stream;

  @override
  Future<PushSubscriptionSnapshot> initialize() async {
    if (!isSupported) return const PushSubscriptionSnapshot.unavailable();
    if (_initialized) return refreshSnapshot();

    await OneSignal.consentRequired(true);
    await OneSignal.consentGiven(false);

    OneSignal.Notifications.addPermissionObserver(_handlePermissionChange);
    OneSignal.User.pushSubscription.addObserver(_handleSubscriptionChange);
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _handleForegroundNotification,
    );
    OneSignal.Notifications.addClickListener(_handleNotificationClick);

    await OneSignal.initialize(OneSignalConfig.appId);
    _initialized = true;
    return refreshSnapshot();
  }

  @override
  Future<PushSubscriptionSnapshot> activate(String externalUserId) async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }
    await OneSignal.login(externalUserId);
    await OneSignal.consentGiven(true);
    return refreshSnapshot();
  }

  @override
  Future<PushSubscriptionSnapshot> deactivate() async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }
    await OneSignal.User.pushSubscription.optOut();
    await OneSignal.consentGiven(false);
    await OneSignal.logout();
    return refreshSnapshot();
  }

  @override
  Future<PushSubscriptionSnapshot> refreshSnapshot() async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }

    final snapshot = PushSubscriptionSnapshot(
      permissionGranted: OneSignal.Notifications.permission,
      canRequestPermission: await OneSignal.Notifications.canRequest(),
      optedIn: OneSignal.User.pushSubscription.optedIn == true,
      subscriptionId: OneSignal.User.pushSubscription.id,
      token: OneSignal.User.pushSubscription.token,
    );
    _subscriptionController.add(snapshot);
    return snapshot;
  }

  @override
  Future<PushSubscriptionSnapshot> requestPermission({
    required bool fallbackToSettings,
  }) async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }
    await OneSignal.Notifications.requestPermission(fallbackToSettings);
    return refreshSnapshot();
  }

  @override
  Future<PushSubscriptionSnapshot> optIn() async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }
    await OneSignal.User.pushSubscription.optIn();
    return refreshSnapshot();
  }

  @override
  Future<PushSubscriptionSnapshot> optOut() async {
    if (!isSupported || !_initialized) {
      return const PushSubscriptionSnapshot.unavailable();
    }
    await OneSignal.User.pushSubscription.optOut();
    return refreshSnapshot();
  }

  @override
  Future<void> registerSubscription({
    required String subscriptionId,
    required String businessLocationId,
  }) async {
    await supabase
        .schema('mediasis')
        .rpc(
          'register_new_order_push_subscription',
          params: {
            'p_subscription_id': subscriptionId,
            'p_business_location_id': businessLocationId,
            'p_platform': defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          },
        );
  }

  @override
  Future<void> disableSubscription(String subscriptionId) async {
    await supabase
        .schema('mediasis')
        .rpc(
          'disable_new_order_push_subscription',
          params: {'p_subscription_id': subscriptionId},
        );
  }

  @override
  Future<PushSubscriptionRegistrationStatus> getRegistrationStatus(
    String subscriptionId,
  ) async {
    final response = await supabase
        .schema('mediasis')
        .rpc(
          'get_new_order_push_subscription_status',
          params: {'p_subscription_id': subscriptionId},
        );
    final data = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    return PushSubscriptionRegistrationStatus(
      exists: data['exists'] == true,
      enabled: data['enabled'] == true,
      businessLocationId: data['business_location_id']?.toString(),
    );
  }

  void _handlePermissionChange(bool _) {
    unawaited(refreshSnapshot());
  }

  void _handleSubscriptionChange(OSPushSubscriptionChangedState _) {
    unawaited(refreshSnapshot());
  }

  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    event.preventDefault();
    _emitIntent(
      notificationId: event.notification.notificationId,
      additionalData: event.notification.additionalData,
      source: PushNotificationIntentSource.foreground,
    );
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    _emitIntent(
      notificationId: event.notification.notificationId,
      additionalData: event.notification.additionalData,
      source: PushNotificationIntentSource.click,
    );
  }

  void _emitIntent({
    required String notificationId,
    required Map<String, dynamic>? additionalData,
    required PushNotificationIntentSource source,
  }) {
    if (additionalData?['type'] != 'new_order') return;

    final orderId = '${additionalData?['order_id'] ?? ''}'.trim();
    final businessLocationId =
        '${additionalData?['business_location_id'] ?? ''}'.trim();
    if (orderId.isEmpty || businessLocationId.isEmpty) return;

    _intentController.add(
      PushNotificationIntent(
        notificationId: notificationId,
        orderId: orderId,
        businessLocationId: businessLocationId,
        source: source,
      ),
    );
  }

  @override
  Future<void> close() async {
    if (_initialized) {
      OneSignal.Notifications.removePermissionObserver(_handlePermissionChange);
      OneSignal.User.pushSubscription.removeObserver(_handleSubscriptionChange);
      OneSignal.Notifications.removeForegroundWillDisplayListener(
        _handleForegroundNotification,
      );
      OneSignal.Notifications.removeClickListener(_handleNotificationClick);
    }
    await _subscriptionController.close();
    await _intentController.close();
  }
}
