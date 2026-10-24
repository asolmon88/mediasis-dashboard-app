class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const dashboardApiBaseUrl = String.fromEnvironment(
    'DASHBOARD_API_BASE_URL',
  );
  static const windowsUpdateManifestUrl = String.fromEnvironment(
    'WINDOWS_UPDATE_MANIFEST_URL',
    defaultValue:
        'https://raw.githubusercontent.com/asolmon88/mediasis-dashboard-app-releases/main/latest/update-manifest.json',
  );

  static void validate() {
    if (url.isEmpty || publishableKey.isEmpty) {
      throw StateError(
        'Supabase environment is missing. '
        'Provide SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define.',
      );
    }
  }
}
