import 'package:flutter/material.dart';

abstract final class GabColors {
  static const primary = Color(0xFF006A35);
  static const secondary = Color(0xFF206B3D);
  static const background = Color(0xFFEDFDF4);
  static const softGreen = Color(0xFFE7F7EE);
  static const ink = Color(0xFF111E19);
  static const muted = Color(0xFF3F4940);
  static const danger = Color(0xFFBA1A1A);
  static const outlineVariant = Color(0xFFBEC9BD);
}

ThemeData buildPatientTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GabColors.primary,
    brightness: Brightness.light,
    surface: Colors.white,
    error: GabColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GabColors.background,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: GabColors.background,
      foregroundColor: GabColors.ink,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: GabColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: GabColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: GabColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: GabColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: GabColors.danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: GabColors.softGreen,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          height: 1,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? GabColors.primary : GabColors.muted,
        );
      }),
    ),
  );
}
