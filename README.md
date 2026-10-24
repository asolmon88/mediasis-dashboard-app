# Mediasis Dashboard App

Flutter app for Mediasis operations.

## Publish To Google Play

The Android project is now wired to support a proper release keystore through
`android/key.properties`.

Before the first Play Store upload, update these items:

1. The Android app id is `com.mediasis.dashboardapp`.
   Keep this consistent for all future Play Store uploads.
2. Create an upload keystore:

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

3. Copy `android/key.properties.example` to `android/key.properties` and fill in
   the real values.
4. Increase the app version in `pubspec.yaml`.
   Play requires every upload to have a higher build number than the last one.
5. Build the Android App Bundle:

```bash
flutter build appbundle --release
```

6. Upload `build/app/outputs/bundle/release/app-release.aab` in Google Play
   Console.

## Pre-Launch Checklist

- Confirm the app name, icon, screenshots, and Play Store listing copy.
- Verify your Supabase production URL/key values are the ones you want shipped.
- Test login, logout, order loading, deep links, and external URL launches in a
  release build.
- Create a privacy policy URL if Play asks for one based on data collection.
- Decide whether you want Play App Signing enabled. For most apps, the answer
  should be yes.

## Notes

- If `android/key.properties` is missing, local release builds still fall back to
  the debug key. That is fine for device testing, but not for Play Store
  submission.
- The current version is `0.0.33+34`. The `+34` is the Android `versionCode`.
