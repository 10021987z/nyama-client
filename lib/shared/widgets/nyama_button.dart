import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// CTA principal NYAMA — Forest Green, 56dp, radius 12, shadow signature.
class NyamaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const NyamaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.25),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ]
            : const [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
