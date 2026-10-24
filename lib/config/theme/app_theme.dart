import 'package:flutter/material.dart';

const _mediasisPrimaryBlue = Color(0xFF08ADD7);
const _mediasisAccentGreen = Color(0xFF93C01F);
const _mediasisInk = Color(0xFF111111);
const _mediasisCanvas = Color(0xFFFBFBFC);
const _mediasisSurface = Color(0xFFF5F6F8);
const _mediasisOutline = Color(0xFFE4E7EC);
const _mediasisOutlineSoft = Color(0xFFEEF1F5);
const _mediasisSurfaceTint = Color(0xFFF0F2F5);

const _fontFamily = 'Poppins';
final TextTheme _poppinsTextTheme = Typography.material2021().black.apply(
  fontFamily: _fontFamily,
  bodyColor: _mediasisInk,
  displayColor: _mediasisInk,
);

final ThemeData materialThemeData = ThemeData(
  scaffoldBackgroundColor: _mediasisCanvas,
  colorScheme:
      const ColorScheme(
        brightness: Brightness.light,
        primary: _mediasisPrimaryBlue,
        onPrimary: Colors.white,
        secondary: _mediasisAccentGreen,
        onSecondary: Colors.white,
        error: Color(0xFFDC2626),
        onError: Colors.white,
        surface: _mediasisSurface,
        onSurface: _mediasisInk,
      ).copyWith(
        surfaceContainerHighest: _mediasisSurfaceTint,
        surfaceContainerLowest: Colors.white,
        outline: _mediasisOutline,
        outlineVariant: _mediasisOutlineSoft,
        onSurfaceVariant: const Color(0xFF6B7280),
      ),
  fontFamily: _fontFamily,
  textTheme: _poppinsTextTheme,
  primaryTextTheme: _poppinsTextTheme,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: _mediasisPrimaryBlue,
    selectionColor: Color(0x3308ADD7),
    selectionHandleColor: _mediasisPrimaryBlue,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _mediasisCanvas,
    labelStyle: const TextStyle(color: _mediasisInk),
    hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _mediasisOutline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _mediasisOutline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _mediasisPrimaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _mediasisPrimaryBlue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFF9BD9E8),
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: _poppinsTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : _mediasisInk,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _mediasisPrimaryBlue
            : Colors.white,
      ),
      side: WidgetStatePropertyAll(const BorderSide(color: _mediasisOutline)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _mediasisInk,
    contentTextStyle: _poppinsTextTheme.bodyMedium?.copyWith(
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
  ),
);
