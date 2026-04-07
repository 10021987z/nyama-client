import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// État — Échec paiement MoMo/OM
class PaymentError extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onChangeMethod;
  final VoidCallback? onPayCash;

  const PaymentError({
    super.key,
    this.onRetry,
    this.onChangeMethod,
    this.onPayCash,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(
                  Icons.phone_android,
                  size: 88,
                  color: AppColors.charcoal,
                ),
                Positioned(
                  top: 30,
                  right: 40,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ),
                const Positioned(
                  bottom: 16,
                  left: 22,
                  child: Icon(Icons.paid_outlined, size: 22, color: AppColors.gold),
                ),
                const Positioned(
                  top: 20,
                  left: 30,
                  child: Icon(Icons.paid_outlined, size: 18, color: AppColors.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PAIEMENT ÉCHOUÉ',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.errorRed,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aie, le paiement a kalé...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'La transaction MoMo/OM n’a pas abouti. Vérifie ton solde ou réessaie.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pourquoi ça n’a pas marché ?',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 12),
                _CauseItem(icon: Icons.account_balance_wallet_outlined, label: 'Solde insuffisant'),
                SizedBox(height: 10),
                _CauseItem(icon: Icons.lock_outline, label: 'PIN non confirmé'),
                SizedBox(height: 10),
                _CauseItem(icon: Icons.signal_wifi_off_outlined, label: 'Réseau indisponible'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _GradientCta(label: 'Réessayer le paiement', onPressed: onRetry),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onChangeMethod,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.forestGreen,
              side: const BorderSide(color: AppColors.forestGreen, width: 1.5),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Changer de moyen de paiement'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onPayCash,
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Payer en cash à la livraison'),
          ),
          const SizedBox(height: 16),
          const Text(
            'PAY_ERROR: MOMO_TIMEOUT_237',
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

class _CauseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CauseItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 14,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
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
