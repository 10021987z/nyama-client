import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final phone = user?.phone ?? '—';
    final initials = _initials(user?.name, phone);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        children: [
          // ── En-tête ────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.name != null)
                        Text(
                          user!.name!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      Text(
                        _formatPhone(phone),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Mon compte ─────────────────────────────────────────────
          _SectionTitle(label: 'Mon compte'),
          _InfoTile(
            emoji: '📍',
            label: 'Quartier',
            value: 'Douala',
          ),
          _InfoTile(
            emoji: '📱',
            label: 'Téléphone',
            value: _formatPhone(phone),
          ),

          const SizedBox(height: 8),

          // ── Préférences ────────────────────────────────────────────
          _SectionTitle(label: 'Préférences'),
          _InfoTile(
            emoji: '🌐',
            label: 'Langue',
            value: 'Français',
          ),

          const SizedBox(height: 8),

          // ── Historique ─────────────────────────────────────────────
          _SectionTitle(label: 'Historique'),
          _ActionTile(
            emoji: '📦',
            label: 'Mes commandes',
            onTap: () => context.go('/orders'),
          ),

          const SizedBox(height: 8),

          // ── À propos ───────────────────────────────────────────────
          _SectionTitle(label: 'À propos'),
          _InfoTile(
            emoji: 'ℹ️',
            label: 'Version',
            value: '1.0.0',
          ),
          _ActionTile(
            emoji: '📜',
            label: 'Conditions d\'utilisation',
            onTap: () => _showPlaceholder(context, 'Conditions d\'utilisation'),
          ),
          _ActionTile(
            emoji: '🔒',
            label: 'Politique de confidentialité',
            onTap: () =>
                _showPlaceholder(context, 'Politique de confidentialité'),
          ),

          const SizedBox(height: 24),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // ── Déconnexion ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _initials(String? name, String phone) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return phone.isNotEmpty ? phone[phone.length - 1] : '?';
  }

  String _formatPhone(String phone) {
    if (phone.startsWith('+237') && phone.length == 13) {
      final local = phone.substring(4);
      return '+237 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return phone;
  }

  void _showPlaceholder(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
            'Ce document sera disponible dans une prochaine version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous devrez vous reconnecter avec votre numéro de téléphone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/onboarding');
    }
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _InfoTile({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary)),
      trailing: Text(value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
