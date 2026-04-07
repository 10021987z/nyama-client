import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// État — Aucun résultat de recherche
class NoResults extends StatelessWidget {
  final String query;
  final ValueChanged<String>? onTagTap;
  final VoidCallback? onSeeAll;

  static const List<String> suggestions = [
    'Ndolé',
    'Poulet DG',
    'Eru & Fufu',
    'Poisson braisé',
    'Beignets haricot',
  ];

  const NoResults({
    super.key,
    this.query = 'sushi japonais',
    this.onTagTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Illustration : grande loupe
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 96,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hmm, on connaît pas ça...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pas de résultat pour "$query". Ici c’est le Cameroun, essaie plutôt :',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTagTap?.call(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSeeAll,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: const Text(
                      'Voir tous les plats →',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SEARCH: NO_MATCH_CM',
            style: TextStyle(
              fontFamily: AppTheme.monoFamily,
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
