part of 'windows_update_cubit.dart';

enum WindowsUpdateStatus { initial, checking, ready, required, downloading }

class WindowsUpdateState extends Equatable {
  const WindowsUpdateState({
    this.status = WindowsUpdateStatus.initial,
    this.currentVersion = '',
    this.latestVersion = '',
    this.minimumSupportedVersion = '',
    this.progress = 0,
    this.errorMessage = '',
    this.manifest,
  });

  final WindowsUpdateStatus status;
  final String currentVersion;
  final String latestVersion;
  final String minimumSupportedVersion;
  final double progress;
  final String errorMessage;
  final WindowsUpdateManifest? manifest;

  WindowsUpdateState copyWith({
    WindowsUpdateStatus? status,
    String? currentVersion,
    String? latestVersion,
    String? minimumSupportedVersion,
    double? progress,
    String? errorMessage,
    WindowsUpdateManifest? manifest,
    bool clearErrorMessage = false,
  }) {
    return WindowsUpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      minimumSupportedVersion:
          minimumSupportedVersion ?? this.minimumSupportedVersion,
      progress: progress ?? this.progress,
      errorMessage: clearErrorMessage ? '' : errorMessage ?? this.errorMessage,
      manifest: manifest ?? this.manifest,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentVersion,
    latestVersion,
    minimumSupportedVersion,
    progress,
    errorMessage,
    manifest,
  ];
}
