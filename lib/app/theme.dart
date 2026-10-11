import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const canvas = Color(0xFFA98BF5);
  static const surface = Color(0xFF4A2FA8);
  static const surfaceDeep = Color(0xFF35208A);
  static const surfaceDarkest = Color(0xFF2A1870);
  static const lime = Color(0xFFD4F54A);
  static const limeDeep = Color(0xFFB8DB2E);
  static const coral = Color(0xFFFF4D6D);
  static const coralLight = Color(0xFFFFC2CD);
  static const pink = Color(0xFFF472B6);
  static const amber = Color(0xFFFFD166);
  static const ink = Color(0xFF1E1147);
  static const muted = Color(0xFFC9BCF5);
  static const outline = Color(0xFF8F76E8);
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
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.ink,
      secondary: AppColors.pink,
      surface: AppColors.surface,
      onSurface: Colors.white,
      error: AppColors.coral,
    ),
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: Colors.white, displayColor: Colors.white);
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
      fillColor: AppColors.surfaceDeep,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        borderSide: const BorderSide(color: AppColors.lime, width: 2),
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
      activeTrackColor: AppColors.lime,
      inactiveTrackColor: AppColors.surfaceDeep,
      thumbColor: AppColors.lime,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.ink),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.lime
            : AppColors.surfaceDeep,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDarkest,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
  );
}
