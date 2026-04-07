import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// État — Panier vide
class EmptyCart extends StatelessWidget {
  final VoidCallback? onExplore;
  final VoidCallback? onAddSuggestion;

  const EmptyCart({
    super.key,
    this.onExplore,
    this.onAddSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Illustration : cloche alimentaire vide avec étoiles
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.room_service_outlined,
                    size: 90,
                    color: AppColors.primary,
                  ),
                ),
                const Positioned(
                  top: 10,
                  left: 40,
                  child: Icon(Icons.star, size: 16, color: AppColors.gold),
                ),
                const Positioned(
                  top: 30,
                  right: 30,
                  child: Icon(Icons.star, size: 12, color: AppColors.gold),
                ),
                const Positioned(
                  bottom: 20,
                  right: 50,
                  child: Icon(Icons.star, size: 14, color: AppColors.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ton estomac gronde pour rien...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text:
                      'Les meilleurs plats camerounais t’attendent. Fais-toi plaisir, c’est ',
                ),
                TextSpan(
                  text: 'Maman Catherine',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' qui cuisine.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _GradientCta(
            label: 'Explorer les plats',
            onPressed: onExplore,
          ),
          const SizedBox(height: 24),
          _ChefSuggestionCard(onAdd: onAddSuggestion),
          const SizedBox(height: 16),
          const Text(
            'HINT: EMPTY_BELLY_237',
            textAlign: TextAlign.center,
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

class _ChefSuggestionCard extends StatelessWidget {
  final VoidCallback? onAdd;
  const _ChefSuggestionCard({this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ndolé Royal & Plantains',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "CHEF’S CHOICE",
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFamily,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '3 500 FCFA',
                  style: TextStyle(
                    fontFamily: AppTheme.monoFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _GradientCta({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
