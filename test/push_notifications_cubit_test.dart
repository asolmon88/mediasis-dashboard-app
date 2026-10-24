import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:mediasis_dashboard_app/presentation/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'registers an authorized existing installation after location restore',
    () async {
      final gateway = _FakePushNotificationGateway(
        snapshot: const PushSubscriptionSnapshot(
          permissionGranted: true,
          canRequestPermission: false,
          optedIn: true,
          subscriptionId: 'subscription-1',
          token: 'token-1',
        ),
      );
      final cubit = PushNotificationsCubit(service: gateway);

      await cubit.initialize();
      cubit.synchronizeAuthenticatedLocation(
        authenticated: true,
        userId: 'user-1',
        businessLocationId: 'location-1',
      );
      await _waitFor(() => gateway.registrations.length == 1);

      expect(gateway.registrations.single, ('subscription-1', 'location-1'));
      expect(cubit.state.isRegistered, isTrue);

      await cubit.close();
    },
  );

  test('waits for a delayed OneSignal subscription ID', () async {
    SharedPreferences.setMockInitialValues({
      'new_order_notification_choice_user-1': 'enabled',
    });
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: true,
        canRequestPermission: false,
        optedIn: true,
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);

    await cubit.initialize();
    cubit.synchronizeAuthenticatedLocation(
      authenticated: true,
      userId: 'user-1',
      businessLocationId: 'location-1',
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.registrations, isEmpty);

    gateway.emitSnapshot(
      const PushSubscriptionSnapshot(
        permissionGranted: true,
        canRequestPermission: false,
        optedIn: true,
        subscriptionId: 'subscription-late',
        token: 'token-late',
      ),
    );
    await _waitFor(() => gateway.registrations.length == 1);

    expect(gateway.registrations.single, ('subscription-late', 'location-1'));

    await cubit.close();
  });

  test('shows the explanation for a restored location only once', () async {
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: false,
        canRequestPermission: true,
        optedIn: false,
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);

    await cubit.initialize();
    cubit.synchronizeAuthenticatedLocation(
      authenticated: true,
      userId: 'user-1',
      businessLocationId: 'location-1',
    );
    await _waitFor(() => cubit.state.shouldShowPermissionExplanation);
    expect(cubit.state.shouldShowPermissionExplanation, isTrue);

    await cubit.dismissPermissionExplanation();
    expect(cubit.state.shouldShowPermissionExplanation, isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('new_order_notification_choice_user-1'),
      'declined',
    );

    await cubit.close();
  });

  test(
    'hides the explanation during the OS prompt and stays gated if denied',
    () async {
      final gateway = _FakePushNotificationGateway(
        snapshot: const PushSubscriptionSnapshot(
          permissionGranted: false,
          canRequestPermission: true,
          optedIn: false,
        ),
        holdPermissionRequests: true,
        grantPermissionOnRequest: false,
      );
      final cubit = PushNotificationsCubit(service: gateway);

      await cubit.initialize();
      cubit.synchronizeAuthenticatedLocation(
        authenticated: true,
        userId: 'user-1',
        businessLocationId: 'location-1',
      );
      await _waitFor(() => cubit.state.shouldShowPermissionExplanation);
      expect(cubit.state.shouldShowPermissionExplanation, isTrue);

      final permissionRequest = cubit.requestPermissionFromExplanation();
      await _waitFor(() => gateway.permissionRequestFallbacks.isNotEmpty);
      expect(cubit.state.shouldShowPermissionExplanation, isFalse);

      gateway.completePermissionRequest();
      await permissionRequest;
      expect(cubit.state.permissionGranted, isFalse);
      expect(cubit.state.shouldShowPermissionExplanation, isFalse);
      expect(gateway.permissionRequestFallbacks, [false]);

      await cubit.close();
    },
  );

  test('disables the registry before opting out on sign out', () async {
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: true,
        canRequestPermission: false,
        optedIn: true,
        subscriptionId: 'subscription-1',
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);

    await cubit.initialize();
    await cubit.disableBeforeSignOut();

    expect(gateway.disabledSubscriptions, ['subscription-1']);
    expect(gateway.optOutCalls, 1);
    expect(cubit.state.optedIn, isFalse);

    await cubit.close();
  });

  test(
    'resynchronizes when the location changes during registration',
    () async {
      final gateway = _FakePushNotificationGateway(
        snapshot: const PushSubscriptionSnapshot(
          permissionGranted: true,
          canRequestPermission: false,
          optedIn: true,
          subscriptionId: 'subscription-1',
        ),
        holdRegistrations: true,
      );
      final cubit = PushNotificationsCubit(service: gateway);

      await cubit.initialize();
      cubit.synchronizeAuthenticatedLocation(
        authenticated: true,
        userId: 'user-1',
        businessLocationId: 'location-1',
      );
      await _waitFor(() => gateway.registrationRequests.length == 1);

      cubit.synchronizeAuthenticatedLocation(
        authenticated: true,
        userId: 'user-1',
        businessLocationId: 'location-2',
      );
      gateway.completeNextRegistration();
      await _waitFor(() => gateway.registrationRequests.length == 2);
      gateway.completeNextRegistration();
      await _waitFor(() => cubit.state.registeredLocationId == 'location-2');

      expect(gateway.registrationRequests, [
        ('subscription-1', 'location-1'),
        ('subscription-1', 'location-2'),
      ]);

      await cubit.close();
    },
  );

  test('retains notification clicks until the UI consumes them', () async {
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: true,
        canRequestPermission: false,
        optedIn: true,
        subscriptionId: 'subscription-1',
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);
    const intent = PushNotificationIntent(
      notificationId: 'notification-1',
      orderId: 'order-1',
      businessLocationId: 'location-1',
      source: PushNotificationIntentSource.click,
    );

    await cubit.initialize();
    gateway.emitIntent(intent);
    await _waitFor(() => cubit.state.pendingIntents.isNotEmpty);

    expect(cubit.state.pendingIntents, [intent]);
    cubit.consumeIntent(intent);
    expect(cubit.state.pendingIntents, isEmpty);

    await cubit.close();
  });

  test('explicit login stays gated until the account confirms', () async {
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: true,
        canRequestPermission: false,
        optedIn: true,
        subscriptionId: 'subscription-1',
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);

    await cubit.initialize();
    cubit.synchronizeAuthenticatedLocation(
      authenticated: true,
      userId: 'user-1',
      businessLocationId: 'location-1',
      explicitSignInVersion: 1,
    );
    await _waitFor(() => cubit.state.shouldShowPermissionExplanation);

    expect(gateway.deactivateCalls, 1);
    expect(gateway.activatedUsers, isEmpty);
    expect(cubit.state.identityActive, isFalse);

    await cubit.close();
  });

  test('a declined restored account never activates OneSignal', () async {
    SharedPreferences.setMockInitialValues({
      'new_order_notification_choice_user-1': 'declined',
    });
    final gateway = _FakePushNotificationGateway(
      snapshot: const PushSubscriptionSnapshot(
        permissionGranted: false,
        canRequestPermission: true,
        optedIn: false,
        subscriptionId: 'subscription-1',
      ),
    );
    final cubit = PushNotificationsCubit(service: gateway);

    await cubit.initialize();
    cubit.synchronizeAuthenticatedLocation(
      authenticated: true,
      userId: 'user-1',
      businessLocationId: 'location-1',
    );
    await _waitFor(() => cubit.state.choice == PushNotificationChoice.declined);

    expect(gateway.activatedUsers, isEmpty);
    expect(cubit.state.shouldShowPermissionExplanation, isFalse);

    await cubit.close();
  });

  test(
    'waits for privacy-gated SDK initialization before restoring identity',
    () async {
      SharedPreferences.setMockInitialValues({
        'new_order_notification_choice_user-1': 'enabled',
      });
      final gateway = _FakePushNotificationGateway(
        snapshot: const PushSubscriptionSnapshot(
          permissionGranted: true,
          canRequestPermission: false,
          optedIn: true,
          subscriptionId: 'subscription-1',
        ),
        holdInitialization: true,
      );
      final cubit = PushNotificationsCubit(service: gateway);

      final initialization = cubit.initialize();
      cubit.synchronizeAuthenticatedLocation(
        authenticated: true,
        userId: 'user-1',
        businessLocationId: 'location-1',
      );
      await Future<void>.delayed(Duration.zero);
      expect(gateway.activatedUsers, isEmpty);

      gateway.completeInitialization();
      await initialization;
      await _waitFor(() => gateway.activatedUsers.isNotEmpty);
      expect(gateway.activatedUsers, ['user-1']);

      await cubit.close();
    },
  );
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met before the timeout.');
}

class _FakePushNotificationGateway implements PushNotificationGateway {
  _FakePushNotificationGateway({
    required this.snapshot,
    this.holdRegistrations = false,
    this.holdPermissionRequests = false,
    this.grantPermissionOnRequest = true,
    this.holdInitialization = false,
  });

  final _snapshotController =
      StreamController<PushSubscriptionSnapshot>.broadcast();
  final _intentController =
      StreamController<PushNotificationIntent>.broadcast();

  PushSubscriptionSnapshot snapshot;
  final bool holdRegistrations;
  final bool holdPermissionRequests;
  final bool grantPermissionOnRequest;
  final bool holdInitialization;
  final registrations = <(String, String)>[];
  final registrationRequests = <(String, String)>[];
  final _registrationCompleters = <Completer<void>>[];
  final permissionRequestFallbacks = <bool>[];
  Completer<void>? _permissionRequestCompleter;
  Completer<void>? _initializationCompleter;
  final disabledSubscriptions = <String>[];
  int optOutCalls = 0;
  int deactivateCalls = 0;
  final activatedUsers = <String>[];

  @override
  bool get isSupported => true;

  @override
  Stream<PushNotificationIntent> get notificationIntents =>
      _intentController.stream;

  @override
  Stream<PushSubscriptionSnapshot> get subscriptionChanges =>
      _snapshotController.stream;

  @override
  Future<PushSubscriptionSnapshot> initialize() async {
    if (holdInitialization) {
      _initializationCompleter = Completer<void>();
      await _initializationCompleter!.future;
    }
    return snapshot;
  }

  @override
  Future<PushSubscriptionSnapshot> activate(String externalUserId) async {
    activatedUsers.add(externalUserId);
    return snapshot;
  }

  @override
  Future<PushSubscriptionSnapshot> deactivate() async {
    deactivateCalls++;
    return optOut();
  }

  @override
  Future<PushSubscriptionSnapshot> refreshSnapshot() async => snapshot;

  @override
  Future<PushSubscriptionSnapshot> requestPermission({
    required bool fallbackToSettings,
  }) async {
    permissionRequestFallbacks.add(fallbackToSettings);
    if (holdPermissionRequests) {
      _permissionRequestCompleter = Completer<void>();
      await _permissionRequestCompleter!.future;
    }
    snapshot = PushSubscriptionSnapshot(
      permissionGranted: grantPermissionOnRequest,
      canRequestPermission: false,
      optedIn: grantPermissionOnRequest,
      subscriptionId: snapshot.subscriptionId,
      token: snapshot.token,
    );
    return snapshot;
  }

  @override
  Future<PushSubscriptionSnapshot> optIn() async {
    snapshot = PushSubscriptionSnapshot(
      permissionGranted: snapshot.permissionGranted,
      canRequestPermission: snapshot.canRequestPermission,
      optedIn: true,
      subscriptionId: snapshot.subscriptionId,
      token: snapshot.token,
    );
    return snapshot;
  }

  @override
  Future<PushSubscriptionSnapshot> optOut() async {
    optOutCalls++;
    snapshot = PushSubscriptionSnapshot(
      permissionGranted: snapshot.permissionGranted,
      canRequestPermission: snapshot.canRequestPermission,
      optedIn: false,
      subscriptionId: snapshot.subscriptionId,
      token: snapshot.token,
    );
    return snapshot;
  }

  @override
  Future<void> registerSubscription({
    required String subscriptionId,
    required String businessLocationId,
  }) async {
    registrationRequests.add((subscriptionId, businessLocationId));
    if (holdRegistrations) {
      final completer = Completer<void>();
      _registrationCompleters.add(completer);
      await completer.future;
    }
    registrations.add((subscriptionId, businessLocationId));
  }

  @override
  Future<void> disableSubscription(String subscriptionId) async {
    disabledSubscriptions.add(subscriptionId);
  }

  @override
  Future<PushSubscriptionRegistrationStatus> getRegistrationStatus(
    String subscriptionId,
  ) async {
    return const PushSubscriptionRegistrationStatus(
      exists: true,
      enabled: true,
      businessLocationId: 'location-1',
    );
  }

  void emitSnapshot(PushSubscriptionSnapshot value) {
    snapshot = value;
    _snapshotController.add(value);
  }

  void emitIntent(PushNotificationIntent intent) {
    _intentController.add(intent);
  }

  void completeNextRegistration() {
    _registrationCompleters.removeAt(0).complete();
  }

  void completePermissionRequest() {
    _permissionRequestCompleter?.complete();
    _permissionRequestCompleter = null;
  }

  void completeInitialization() {
    _initializationCompleter?.complete();
    _initializationCompleter = null;
  }

  @override
  Future<void> close() async {
    await _snapshotController.close();
    await _intentController.close();
  }
}
