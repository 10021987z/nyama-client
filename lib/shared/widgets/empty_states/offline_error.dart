import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// État — Erreur réseau / offline
class OfflineError extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onCheckStatus;

  const OfflineError({
    super.key,
    this.onRetry,
    this.onCheckStatus,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.pedal_bike,
                  size: 96,
                  color: AppColors.forestGreen,
                ),
                Positioned(
                  top: 24,
                  right: 36,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'On a un petit souci...',
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
                TextSpan(text: 'Le réseau est instable comme le piment de '),
                TextSpan(
                  text: 'Deido',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: '. On essaie de reconnecter.'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onRetry,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: const Text(
                    'Réessayer',
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
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onCheckStatus,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forestGreen,
              side: const BorderSide(color: AppColors.forestGreen, width: 1.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Vérifier le statut'),
          ),
          const SizedBox(height: 16),
          const Text(
            'ERROR CODE: 503_NYAMA_TERROIR',
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
