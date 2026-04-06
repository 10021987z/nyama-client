import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Palette officielle NYAMA ──────────────────────────────────────────────

  /// Orange NYAMA — couleur principale (60 %)
  static const Color primary = Color(0xFFF57C20);

  /// Charcoal — texte, barres (25 %)
  static const Color secondary = Color(0xFF3D3D3D);

  /// Forest Green — boutons CTA
  static const Color ctaGreen = Color(0xFF1B4332);

  /// Gold — prix, étoiles, revenus
  static const Color gold = Color(0xFFD4A017);

  /// Rouge accent (5 %) — alertes, erreurs
  static const Color accent = Color(0xFFE8413C);

  /// Crème — fond de page
  static const Color background = Color(0xFFF5F5F0);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF5F5F0);
  static const Color surfaceContainerLow = Color(0xFFEFEFEF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3D3D3D);
  static const Color onSurface = Color(0xFF3D3D3D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── États ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE8413C);
  static const Color success = Color(0xFF1B4332);
  static const Color warning = Color(0xFFF57C20);
  static const Color newOrder = Color(0xFFF57C20);

  // ── UI utilitaires ────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE5E5E5);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x0F000000);
  static const Color overlay = Color(0x80000000);
  static const Color divider = Color(0xFFEFEFEF);

  // ── Compatibilité ─────────────────────────────────────────────────────────
  static const Color primaryVibrant = primary;
  static const Color primaryLight = Color(0xFFFFF0DC);
  static const Color secondaryVibrant = gold;
  static const Color secondaryLight = Color(0xFFFFF8E0);
  static const Color tertiary = ctaGreen;
  static const Color tertiaryVibrant = Color(0xFF5EEA72);
  static const Color terracotta = Color(0xFFA03C00);
  static const Color primaryDark = Color(0xFF5C3400);

  // ── Gradient bouton primaire ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE06A10), Color(0xFFF57C20)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
