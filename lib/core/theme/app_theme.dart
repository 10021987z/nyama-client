import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String headlineFamily = 'Montserrat'; // alt to Plus Jakarta Sans
  static const String bodyFamily = 'NunitoSans'; // alt to Be Vietnam Pro
  static const String monoFamily = 'SpaceMono';

  // Subtle border for outline variant @ 15% opacity
  static final Color _outline15 =
      AppColors.outlineVariant.withValues(alpha: 0.15);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: bodyFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.charcoal,
        tertiary: AppColors.forestGreen,
        surface: AppColors.creme,
        error: AppColors.errorRed,
        outlineVariant: AppColors.outlineVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.charcoal,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: AppColors.creme,

      // ── AppBar : transparent / crème ──────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: headlineFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.charcoal,
        ),
        iconTheme: IconThemeData(color: AppColors.charcoal),
      ),

      // ── Cards : blanc, radius 16, shadow subtile, NO border ───────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shadowColor: AppColors.cardShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── ElevatedButton CTA : Forest Green, 56dp, radius 12 ────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textTertiary,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.forestGreen.withValues(alpha: 0.25),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── OutlinedButton : contour orange ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input : fond blanc, radius 12, bordure outline 15%, focus orange 2px
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _outline15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _outline15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        labelStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        errorStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 12,
          color: AppColors.errorRed,
        ),
      ),

      // ── Chip ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLow,
        selectedColor: AppColors.primaryLight,
        labelStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 13,
          color: AppColors.charcoal,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Bottom Nav : blanc, sans bordure supérieure ────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontFamily: bodyFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: bodyFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),

      // No-line rule : pas de divider visible (sauf opt-in dans listes profil)
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // ── TextTheme ─────────────────────────────────────────────────────
      // headlines = headlineFamily 700-800 ; body = bodyFamily 400-600 ;
      // labelLarge = SpaceMono 700 (prix), couleur orange.
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: headlineFamily, fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.charcoal),
        displayMedium: TextStyle(fontFamily: headlineFamily, fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.charcoal),
        displaySmall: TextStyle(fontFamily: headlineFamily, fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        headlineLarge: TextStyle(fontFamily: headlineFamily, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        headlineMedium: TextStyle(fontFamily: headlineFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        headlineSmall: TextStyle(fontFamily: headlineFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        titleLarge: TextStyle(fontFamily: headlineFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.charcoal),
        titleMedium: TextStyle(fontFamily: bodyFamily, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.charcoal),
        titleSmall: TextStyle(fontFamily: bodyFamily, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        bodyLarge: TextStyle(fontFamily: bodyFamily, fontSize: 16, color: AppColors.charcoal),
        bodyMedium: TextStyle(fontFamily: bodyFamily, fontSize: 14, color: AppColors.charcoal),
        bodySmall: TextStyle(fontFamily: bodyFamily, fontSize: 12, color: AppColors.textSecondary),
        // Prix FCFA / chiffres — Space Mono 700 orange
        labelLarge: TextStyle(fontFamily: monoFamily, fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
        labelMedium: TextStyle(fontFamily: bodyFamily, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: bodyFamily, fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary),
      ),
    );
  }
}
