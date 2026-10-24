// Recovered from: https://medium.com/@dishankjindal/how-the-flutter-handling-different-mobile-screen-sizes-0c10c24f6aec

import 'package:flutter/widgets.dart';

/// Returns true only for compact phone-sized windows.
///
/// This intentionally uses logical width instead of device/platform checks:
/// an iPad in portrait is commonly 744–768 logical pixels wide and must use
/// the tablet layout, not the phone card layout.
bool isCompactWindow(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

/// Returns true when there is enough horizontal room for dense desktop boards
/// and tables. Tablet layouts stay card-based so controls never get squeezed.
bool isWideWindow(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 1100;

final _sizedCache = <num, Map<num, double>>{};

extension ScreenDimension on num {
  double ws(BuildContext context) {
    final deviceWidth = MediaQuery.sizeOf(context).width;

    if (_sizedCache.containsKey(deviceWidth) &&
        _sizedCache[deviceWidth]!.containsKey(this)) {
      return _sizedCache[deviceWidth]![this] as double;
    }

    if (!_sizedCache.containsKey(deviceWidth)) {
      _sizedCache.addAll({deviceWidth: {}});
    }

    final value = deviceWidth * (this / 100);
    _sizedCache[deviceWidth]!.addAll({this: value});

    return value;
  }

  double pixelScale(BuildContext context) => (this / 4).ws(context);

  double removeSpacingOnKeyboardVisible(BuildContext context) {
    if (MediaQuery.maybeViewInsetsOf(context)!.bottom > 0) {
      return this * 0;
    }
    return this * 1;
  }

  double addSpacingOnKeyboardVisible(BuildContext context) =>
      this + MediaQuery.maybeViewInsetsOf(context)!.bottom;

  double hs(BuildContext context) =>
      MediaQuery.sizeOf(context).height * (this / 100);
}
