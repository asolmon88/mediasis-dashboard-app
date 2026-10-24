import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mediasis_dashboard_app/config/supabase/supabase_config.dart';
import 'package:mediasis_dashboard_app/infrastructure/models.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class WindowsUpdateService {
  WindowsUpdateService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<WindowsUpdateCheckResult> checkForRequiredUpdate() async {
    if (!Platform.isWindows) {
      return const WindowsUpdateCheckResult(
        currentVersion: '',
        manifest: null,
        requiresUpdate: false,
      );
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version.trim();
    if (currentVersion.isEmpty) {
      return const WindowsUpdateCheckResult(
        currentVersion: '',
        manifest: null,
        requiresUpdate: false,
      );
    }

    final response = await _client.get(
      Uri.parse(SupabaseConfig.windowsUpdateManifestUrl),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Manifest respondio con ${response.statusCode}.');
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw const FormatException(
        'El manifest no tiene un objeto JSON valido.',
      );
    }

    final manifest = WindowsUpdateManifest.fromMap(
      body.cast<String, dynamic>(),
    );
    final requiresUpdate = _isVersionLowerThan(
      currentVersion,
      manifest.minimumSupportedVersion,
    );

    return WindowsUpdateCheckResult(
      currentVersion: currentVersion,
      manifest: manifest,
      requiresUpdate: requiresUpdate,
    );
  }

  Future<void> downloadAndInstallRequiredUpdate({
    required WindowsUpdateManifest manifest,
    required void Function(double progress) onProgress,
  }) async {
    if (!Platform.isWindows) return;

    final installerUri = Uri.tryParse(manifest.installerUrl);
    if (installerUri == null || !installerUri.hasScheme) {
      throw const FormatException(
        'El installer_url del manifest no es valido.',
      );
    }
    if (manifest.sha256.trim().isEmpty) {
      throw const FormatException('El manifest no incluye sha256.');
    }

    final request = http.Request('GET', installerUri);
    final streamed = await _client.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw HttpException(
        'No se pudo descargar el instalador (${streamed.statusCode}).',
      );
    }

    final downloadDir = await Directory.systemTemp.createTemp(
      'mediasis-orders-update',
    );
    final installerFile = File(
      '${downloadDir.path}\\mediasis-orders-setup.exe',
    );
    final sink = installerFile.openWrite();
    final totalBytes = streamed.contentLength ?? 0;
    var receivedBytes = 0;

    try {
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
    } finally {
      await sink.close();
    }

    if (totalBytes <= 0) {
      onProgress(1);
    }

    final fileBytes = await installerFile.readAsBytes();
    final digest = sha256.convert(fileBytes).toString();
    if (digest.toLowerCase() != manifest.sha256.trim().toLowerCase()) {
      throw const FileSystemException(
        'La verificacion del instalador fallo. El hash no coincide.',
      );
    }

    await Process.start(
      installerFile.path,
      const [],
      mode: ProcessStartMode.detached,
      workingDirectory: downloadDir.path,
    );
    exit(0);
  }

  bool _isVersionLowerThan(String current, String minimumSupported) {
    final currentParts = _normalizeVersion(current);
    final minimumParts = _normalizeVersion(minimumSupported);

    for (var index = 0; index < 3; index++) {
      final currentValue = currentParts[index];
      final minimumValue = minimumParts[index];
      if (currentValue < minimumValue) return true;
      if (currentValue > minimumValue) return false;
    }

    return false;
  }

  List<int> _normalizeVersion(String value) {
    final clean = value.split('+').first;
    final parts = clean.split('.');
    return List<int>.generate(
      3,
      (index) => index < parts.length ? int.tryParse(parts[index]) ?? 0 : 0,
      growable: false,
    );
  }
}
