import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Thème clair ───────────────────────────────────────────────────────────

  static ThemeData get light {
    const montserrat = 'Montserrat';
    const nunitoSans = 'NunitoSans';

    return ThemeData(
      useMaterial3: true,
      fontFamily: nunitoSans,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.ctaGreen,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.onSurface,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: montserrat,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton : CTA Green ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textTertiary,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: nunitoSans,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── OutlinedButton : Orange border ────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: nunitoSans,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: nunitoSans,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: nunitoSans,
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        labelStyle: const TextStyle(
          fontFamily: nunitoSans,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        errorStyle: const TextStyle(
          fontFamily: nunitoSans,
          fontSize: 12,
          color: AppColors.error,
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          fontFamily: nunitoSans,
          fontSize: 13,
          color: AppColors.onSurface,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: nunitoSans,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: nunitoSans,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(
          fontFamily: nunitoSans,
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ── TextTheme ─────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: montserrat, fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.onSurface),
        displayMedium: TextStyle(fontFamily: montserrat, fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.onSurface),
        displaySmall: TextStyle(fontFamily: montserrat, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineLarge: TextStyle(fontFamily: montserrat, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineMedium: TextStyle(fontFamily: montserrat, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        headlineSmall: TextStyle(fontFamily: montserrat, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleLarge: TextStyle(fontFamily: montserrat, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface),
        titleMedium: TextStyle(fontFamily: nunitoSans, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleSmall: TextStyle(fontFamily: nunitoSans, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        bodyLarge: TextStyle(fontFamily: nunitoSans, fontSize: 16, color: AppColors.onSurface),
        bodyMedium: TextStyle(fontFamily: nunitoSans, fontSize: 14, color: AppColors.onSurface),
        bodySmall: TextStyle(fontFamily: nunitoSans, fontSize: 12, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontFamily: nunitoSans, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        labelMedium: TextStyle(fontFamily: nunitoSans, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: nunitoSans, fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
      ),
    );
  }
}
