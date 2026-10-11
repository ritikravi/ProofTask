import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const canvas = Color(0xFFF5F5F7); // Light gray background like mockup
  static const surface = Color(0xFF7C3AED); // Purple for buttons/cards
  static const surfaceDeep = Color(0xFF6D28D9);
  static const surfaceDarkest = Color(0xFF5B21B6);
  static const lime = Color(0xFFD4F54A);
  static const limeDeep = Color(0xFFB8DB2E);
  static const coral = Color(0xFFFF4D6D);
  static const coralLight = Color(0xFFFFC2CD);
  static const pink = Color(0xFFF472B6);
  static const amber = Color(0xFFFFD166);
  static const ink = Color(0xFF1E1147);
  static const muted = Color(0xFF9CA3AF); // Gray text
  static const outline = Color(0xFFE5E7EB); // Light gray borders
  static const success = Color(0xFF10B981);
  static const statusInProgress = Color(0xFF3B82F6);
  static const statusPending = Color(0xFFFBBF24);
}

abstract class AppRadius {
  static const pill = 999.0;
  static const card = 28.0;
  static const cardSm = 20.0;
  static const tile = 16.0;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.surface,
      onPrimary: Colors.white,
      secondary: AppColors.pink,
      surface: Colors.white,
      onSurface: AppColors.ink,
      error: AppColors.coral,
      background: AppColors.canvas,
    ),
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      titleTextStyle: text.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.surface, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.coral, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.coral, width: 2),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.surface,
      inactiveTrackColor: AppColors.outline,
      thumbColor: AppColors.surface,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.surface
            : AppColors.outline,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
  );
}
