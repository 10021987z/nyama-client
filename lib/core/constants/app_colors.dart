import 'package:flutter/material.dart';

/// Design tokens — Culinary Signature
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Nyama Orange — dominante, 60% des surfaces colorées
  static const Color primary = Color(0xFFF57C20);

  /// Variante foncée — pour gradients CTA
  static const Color primaryDark = Color(0xFF994700);

  /// Charcoal — titres, icônes nav
  static const Color charcoal = Color(0xFF3D3D3D);

  /// Forest Green — TOUS les CTA principaux (Commander, Valider, Payer)
  static const Color forestGreen = Color(0xFF1B4332);

  /// Gold — étoiles, gains, badges premium
  static const Color gold = Color(0xFFD4A017);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  /// Crème — fond de page GLOBAL (PAS blanc pur)
  static const Color creme = Color(0xFFF5F5F0);

  /// Surface basse — fonds de sections, inputs inactifs
  static const Color surfaceLow = Color(0xFFF4F4EF);

  /// Blanc — cards uniquement
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // ── États ─────────────────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFE8413C);

  // ── Bordures ──────────────────────────────────────────────────────────────
  /// Bordure très subtile — opacité max 15%
  static const Color outlineVariant = Color(0xFFDEC1B1);

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = charcoal;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color onSurface = charcoal;

  // ── UI utilitaires ────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE5E5E5);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x0A3D3D3D); // ~4% charcoal
  static const Color overlay = Color(0x80000000);

  // ── Compatibilité descendante (anciens tokens) ────────────────────────────
  static const Color secondary = charcoal;
  static const Color ctaGreen = forestGreen;
  static const Color background = creme;
  static const Color surface = creme;
  static const Color surfaceContainerLow = surfaceLow;
  static const Color surfaceContainerLowest = surfaceWhite;
  static const Color error = errorRed;
  static const Color success = forestGreen;
  static const Color warning = primary;
  static const Color newOrder = primary;
  static const Color accent = errorRed;
  static const Color divider = surfaceLow;
  static const Color primaryVibrant = primary;
  static const Color primaryLight = Color(0xFFFFF0DC);
  static const Color secondaryVibrant = gold;
  static const Color secondaryLight = Color(0xFFFFF8E0);
  static const Color tertiary = forestGreen;
  static const Color tertiaryVibrant = Color(0xFF5EEA72);
  static const Color terracotta = primaryDark;

  // ── Gradient bouton primaire ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
