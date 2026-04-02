import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NyamaErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? emoji;

  const NyamaErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji ?? '😕',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return NyamaErrorWidget(
      emoji: '📵',
      message: 'Vérifiez votre connexion internet et réessayez.',
      onRetry: onRetry,
    );
  }
}
