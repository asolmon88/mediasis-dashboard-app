import 'dart:async';

import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'push_notifications_state.dart';

class PushNotificationsCubit extends Cubit<PushNotificationsState> {
  PushNotificationsCubit({PushNotificationGateway? service})
    : _service = service ?? PushNotificationService(),
      super(const PushNotificationsState());

  static const _choiceKeyPrefix = 'new_order_notification_choice_';

  final PushNotificationGateway _service;
  StreamSubscription<PushSubscriptionSnapshot>? _subscriptionChanges;
  StreamSubscription<PushNotificationIntent>? _notificationIntents;
  bool _authenticated = false;
  bool _initialized = false;
  bool _syncing = false;
  String? _userId;
  String? _activeLocationId;
  String? _lastRegisteredKey;
  int _handledExplicitSignInVersion = 0;
  int _latestExplicitSignInVersion = 0;
  Future<void>? _activeRegistration;
  Future<void>? _identityPreparation;

  Future<void> initialize() async {
    if (!_service.isSupported) {
      emit(state.copyWith(status: PushNotificationsStatus.unsupported));
      return;
    }
    emit(state.copyWith(status: PushNotificationsStatus.initializing));
    _subscriptionChanges = _service.subscriptionChanges.listen(_applySnapshot);
    _notificationIntents = _service.notificationIntents.listen(_queueIntent);
    try {
      _applySnapshot(await _service.initialize());
      _initialized = true;
      if (_authenticated && _userId != null && _activeLocationId != null) {
        synchronizeAuthenticatedLocation(
          authenticated: true,
          userId: _userId,
          businessLocationId: _activeLocationId,
          explicitSignInVersion: _latestExplicitSignInVersion,
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: PushNotificationsStatus.failure,
          errorMessage: '$error'.replaceFirst('Bad state: ', ''),
        ),
      );
    }
  }

  void synchronizeAuthenticatedLocation({
    required bool authenticated,
    String? userId,
    String? businessLocationId,
    int explicitSignInVersion = 0,
  }) {
    _authenticated = authenticated;
    _latestExplicitSignInVersion = explicitSignInVersion;
    _userId = authenticated && userId?.isNotEmpty == true ? userId : null;
    _activeLocationId = businessLocationId;
    if (businessLocationId != state.registeredLocationId) {
      emit(state.copyWith(clearRegisteredLocationId: true));
    }
    if (!_initialized ||
        !_authenticated ||
        _userId == null ||
        _activeLocationId == null) {
      _emitReadiness();
      return;
    }
    final explicitLogin = explicitSignInVersion > _handledExplicitSignInVersion;
    if (explicitLogin) _handledExplicitSignInVersion = explicitSignInVersion;
    unawaited(_prepareIdentity(explicitLogin: explicitLogin));
  }

  Future<void> requestPermissionFromExplanation() async {
    final userId = _userId;
    if (!_authenticated || userId == null || _activeLocationId == null) return;
    emit(
      state.copyWith(
        isBusy: true,
        shouldShowPermissionExplanation: false,
        clearErrorMessage: true,
      ),
    );
    await _saveChoice(userId, PushNotificationChoice.enabled);
    try {
      await _activateIdentity(userId);
      var snapshot = state.permissionGranted
          ? await _service.optIn()
          : await _service.requestPermission(
              fallbackToSettings: !state.canRequestPermission,
            );
      _applySnapshot(snapshot);
      if (snapshot.permissionGranted && !snapshot.optedIn) {
        snapshot = await _service.optIn();
        _applySnapshot(snapshot);
      }
      await _synchronizeRegistration();
    } catch (error) {
      _emitError(error);
    } finally {
      if (!isClosed) emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> dismissPermissionExplanation() async {
    final userId = _userId;
    if (userId != null) {
      await _saveChoice(userId, PushNotificationChoice.declined);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          choice: PushNotificationChoice.declined,
          shouldShowPermissionExplanation: false,
        ),
      );
    }
  }

  Future<void> enableFromSettings() => requestPermissionFromExplanation();

  Future<void> disableBeforeSignOut() async {
    _authenticated = false;
    _activeLocationId = null;
    _lastRegisteredKey = null;
    final subscriptionId = state.subscriptionId;
    try {
      await _activeRegistration?.timeout(const Duration(seconds: 8));
      if (subscriptionId != null && subscriptionId.isNotEmpty) {
        await _service
            .disableSubscription(subscriptionId)
            .timeout(const Duration(seconds: 8));
      }
    } catch (error) {
      _emitError(error);
    } finally {
      await _deactivateIdentity();
    }
  }

  Future<void> handleUnexpectedSignOut() async {
    _authenticated = false;
    _userId = null;
    _activeLocationId = null;
    _lastRegisteredKey = null;
    await _deactivateIdentity();
  }

  void consumeIntent(PushNotificationIntent intent) {
    emit(
      state.copyWith(
        pendingIntents: state.pendingIntents
            .where((item) => item != intent)
            .toList(growable: false),
      ),
    );
  }

  Future<void> refresh() async {
    if (!state.isSupported) return;
    if (_authenticated && _userId != null && _activeLocationId != null) {
      await _prepareIdentity(explicitLogin: false, force: true);
      return;
    }
    try {
      _applySnapshot(await _service.refreshSnapshot());
    } catch (error) {
      _emitError(error);
    }
  }

  Future<void> _prepareIdentity({
    required bool explicitLogin,
    bool force = false,
  }) {
    if (_identityPreparation != null && !force) return _identityPreparation!;
    final future = _runIdentityPreparation(explicitLogin: explicitLogin);
    _identityPreparation = future;
    return future.whenComplete(() {
      if (identical(_identityPreparation, future)) _identityPreparation = null;
    });
  }

  Future<void> _runIdentityPreparation({required bool explicitLogin}) async {
    final userId = _userId;
    if (!_authenticated || userId == null || _activeLocationId == null) return;
    if (explicitLogin) {
      await _deactivateIdentity();
      if (!isClosed) {
        emit(
          state.copyWith(
            choice: PushNotificationChoice.unknown,
            shouldShowPermissionExplanation: true,
            clearErrorMessage: true,
          ),
        );
      }
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final storedChoice = _parseChoice(
      preferences.getString('$_choiceKeyPrefix$userId'),
    );
    if (storedChoice == PushNotificationChoice.enabled) {
      await _activateAndSynchronize(userId);
      return;
    }
    if (storedChoice == PushNotificationChoice.declined) {
      if (!isClosed) {
        emit(
          state.copyWith(
            choice: storedChoice,
            shouldShowPermissionExplanation: false,
          ),
        );
      }
      return;
    }

    final subscriptionId = state.subscriptionId;
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      try {
        final registration = await _service.getRegistrationStatus(
          subscriptionId,
        );
        if (registration.enabled) {
          await _saveChoice(userId, PushNotificationChoice.enabled);
          await _activateAndSynchronize(userId);
          return;
        }
      } catch (error) {
        _emitError(error);
        return;
      }
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          choice: PushNotificationChoice.unknown,
          shouldShowPermissionExplanation: true,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _activateAndSynchronize(String userId) async {
    try {
      await _activateIdentity(userId);
      if (state.permissionGranted && !state.optedIn) {
        _applySnapshot(await _service.optIn());
      }
      await _synchronizeRegistration();
    } catch (error) {
      _emitError(error);
    }
  }

  Future<void> _activateIdentity(String userId) async {
    _applySnapshot(await _service.activate(userId));
    if (!isClosed) {
      emit(
        state.copyWith(
          identityActive: true,
          choice: PushNotificationChoice.enabled,
          shouldShowPermissionExplanation: false,
        ),
      );
    }
  }

  Future<void> _deactivateIdentity() async {
    if (!state.isSupported) return;
    try {
      _applySnapshot(await _service.deactivate());
    } catch (error) {
      _emitError(error);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          identityActive: false,
          clearRegisteredLocationId: true,
          shouldShowPermissionExplanation: false,
        ),
      );
    }
  }

  Future<void> _saveChoice(String userId, PushNotificationChoice choice) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_choiceKeyPrefix$userId', choice.name);
    if (!isClosed) emit(state.copyWith(choice: choice));
  }

  PushNotificationChoice _parseChoice(String? value) {
    return PushNotificationChoice.values.firstWhere(
      (choice) => choice.name == value,
      orElse: () => PushNotificationChoice.unknown,
    );
  }

  void _applySnapshot(PushSubscriptionSnapshot snapshot) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PushNotificationsStatus.ready,
        permissionGranted: snapshot.permissionGranted,
        canRequestPermission: snapshot.canRequestPermission,
        optedIn: snapshot.optedIn,
        subscriptionId: snapshot.subscriptionId,
        token: snapshot.token,
        clearSubscriptionId: snapshot.subscriptionId == null,
        clearToken: snapshot.token == null,
        clearRegisteredLocationId:
            !state.identityActive ||
            !snapshot.permissionGranted ||
            !snapshot.optedIn ||
            snapshot.subscriptionId == null,
        clearErrorMessage: true,
      ),
    );
    if (state.identityActive) unawaited(_synchronizeRegistration());
  }

  void _emitReadiness() {
    if (isClosed || !state.isSupported) return;
    emit(state.copyWith(shouldShowPermissionExplanation: false));
  }

  Future<void> _synchronizeRegistration() async {
    if (_syncing ||
        !_authenticated ||
        !state.identityActive ||
        _activeLocationId == null ||
        !state.permissionGranted ||
        !state.optedIn) {
      return;
    }
    final subscriptionId = state.subscriptionId;
    if (subscriptionId == null || subscriptionId.isEmpty) return;
    final locationId = _activeLocationId!;
    final registrationKey = '$subscriptionId:$locationId';
    if (_lastRegisteredKey == registrationKey) return;

    _syncing = true;
    final registration = _service.registerSubscription(
      subscriptionId: subscriptionId,
      businessLocationId: locationId,
    );
    _activeRegistration = registration;
    try {
      await registration;
      if (!_authenticated || !state.identityActive) {
        await _service.disableSubscription(subscriptionId);
        return;
      }
      if (_activeLocationId != locationId) return;
      _lastRegisteredKey = registrationKey;
      if (!isClosed) {
        emit(
          state.copyWith(
            registeredLocationId: locationId,
            clearRegisteredLocationId: false,
            clearErrorMessage: true,
          ),
        );
      }
    } catch (error) {
      _emitError(error);
    } finally {
      final shouldResynchronize =
          _authenticated &&
          state.identityActive &&
          (_activeLocationId != locationId ||
              state.subscriptionId != subscriptionId);
      if (identical(_activeRegistration, registration)) {
        _activeRegistration = null;
      }
      _syncing = false;
      if (shouldResynchronize) unawaited(_synchronizeRegistration());
    }
  }

  void _queueIntent(PushNotificationIntent intent) {
    if (state.pendingIntents.contains(intent)) return;
    emit(state.copyWith(pendingIntents: [...state.pendingIntents, intent]));
  }

  void _emitError(Object error) {
    if (!isClosed) {
      emit(
        state.copyWith(errorMessage: '$error'.replaceFirst('Bad state: ', '')),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscriptionChanges?.cancel();
    await _notificationIntents?.cancel();
    await _service.close();
    return super.close();
  }
}
