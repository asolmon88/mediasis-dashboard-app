import 'dart:io';

import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:mediasis_dashboard_app/infrastructure/services.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'windows_update_state.dart';

class WindowsUpdateCubit extends Cubit<WindowsUpdateState> {
  WindowsUpdateCubit({WindowsUpdateService? updateService})
    : _updateService = updateService ?? WindowsUpdateService(),
      super(const WindowsUpdateState());

  final WindowsUpdateService _updateService;

  Future<void> initialize() async {
    if (!Platform.isWindows) {
      emit(const WindowsUpdateState(status: WindowsUpdateStatus.ready));
      return;
    }

    emit(
      state.copyWith(
        status: WindowsUpdateStatus.checking,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await _updateService.checkForRequiredUpdate();
      if (!result.requiresUpdate || result.manifest == null) {
        emit(
          state.copyWith(
            status: WindowsUpdateStatus.ready,
            currentVersion: result.currentVersion,
            latestVersion: result.manifest?.latestVersion ?? '',
            minimumSupportedVersion:
                result.manifest?.minimumSupportedVersion ?? '',
            manifest: result.manifest,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: WindowsUpdateStatus.required,
          currentVersion: result.currentVersion,
          latestVersion: result.manifest!.latestVersion,
          minimumSupportedVersion: result.manifest!.minimumSupportedVersion,
          manifest: result.manifest,
          progress: 0,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WindowsUpdateStatus.ready,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> startUpdate() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    emit(
      state.copyWith(
        status: WindowsUpdateStatus.downloading,
        progress: 0,
        clearErrorMessage: true,
      ),
    );

    try {
      await _updateService.downloadAndInstallRequiredUpdate(
        manifest: manifest,
        onProgress: (progress) {
          emit(state.copyWith(progress: progress));
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: WindowsUpdateStatus.required,
          progress: 0,
          errorMessage:
              'No se pudo descargar o abrir la actualizacion. Intenta de nuevo. Detalle: $error',
        ),
      );
    }
  }
}
