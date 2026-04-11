import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';

/// Écran de confirmation après un paiement NotchPay réussi.
///
/// Affiche une animation check + le montant + la référence, puis
/// redirige automatiquement vers `/tracking/:orderId` après 3 secondes.
class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  final int amountXaf;
  final String reference;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.amountXaf,
    required this.reference,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  Timer? _autoNavTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    _autoNavTimer = Timer(const Duration(seconds: 3), _goToTracking);
  }

  @override
  void dispose() {
    _autoNavTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goToTracking() {
    if (!mounted) return;
    context.go('/tracking/${widget.orderId}');
  }

  @override
  Widget build(BuildContext context) {
    final shortRef = widget.reference.length > 12
        ? widget.reference.substring(widget.reference.length - 12)
        : widget.reference;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Paiement réussi !',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.amountXaf.toFcfa(),
                style: const TextStyle(
                  fontFamily: AppTheme.monoFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre commande est en préparation',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Référence : NYAMA-$shortRef',
                style: const TextStyle(
                  fontFamily: AppTheme.monoFamily,
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Suivre ma commande',
                    style: TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
