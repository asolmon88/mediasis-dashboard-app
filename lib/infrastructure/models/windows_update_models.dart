class WindowsUpdateManifest {
  const WindowsUpdateManifest({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.installerUrl,
    required this.sha256,
    required this.notes,
    required this.publishedAt,
  });

  final String latestVersion;
  final String minimumSupportedVersion;
  final String installerUrl;
  final String sha256;
  final String notes;
  final String publishedAt;

  factory WindowsUpdateManifest.fromMap(Map<String, dynamic> map) {
    return WindowsUpdateManifest(
      latestVersion: map['latest_version'] as String? ?? '',
      minimumSupportedVersion:
          map['minimum_supported_version'] as String? ?? '',
      installerUrl: map['installer_url'] as String? ?? '',
      sha256: map['sha256'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      publishedAt: map['published_at'] as String? ?? '',
    );
  }
}

class WindowsUpdateCheckResult {
  const WindowsUpdateCheckResult({
    required this.currentVersion,
    required this.manifest,
    required this.requiresUpdate,
  });

  final String currentVersion;
  final WindowsUpdateManifest? manifest;
  final bool requiresUpdate;
}
