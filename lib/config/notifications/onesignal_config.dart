import 'package:flutter/foundation.dart';

class OneSignalConfig {
  static const _productionAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const _developmentAppId = String.fromEnvironment(
    'ONESIGNAL_DEVELOPMENT_APP_ID',
  );

  static String get appId =>
      kReleaseMode ? _productionAppId.trim() : _developmentAppId.trim();
}
