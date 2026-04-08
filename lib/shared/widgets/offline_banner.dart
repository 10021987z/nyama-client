import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/connectivity_notifier.dart';

/// Bannière globale hors-ligne — s'affiche dès que [offlineNotifier] passe à
/// `true`. Le watcher connectivity_plus est lancé dans [main] via
/// `startConnectivityWatcher()` et l'interceptor Dio met aussi à jour le
/// notifier en cas d'erreur réseau.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offlineNotifier,
      builder: (context, isOffline, _) {
        if (!isOffline) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            color: Colors.orange.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Mode hors-ligne — Les données peuvent ne pas être à jour',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
