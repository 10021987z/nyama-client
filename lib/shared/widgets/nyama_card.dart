import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Card NYAMA — fond blanc, radius 16, shadow très subtile, NO border.
class NyamaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const NyamaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
