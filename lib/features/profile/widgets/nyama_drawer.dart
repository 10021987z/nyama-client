import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class NyamaDrawer extends ConsumerWidget {
  const NyamaDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final name = (user?.name?.isNotEmpty ?? false)
        ? user!.name!
        : 'Utilisateur NYAMA';

    return Drawer(
      backgroundColor: AppColors.creme,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.forestGreen, Color(0xFF2D6B4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontFamily: AppTheme.headlineFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'NYAMA+',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.receipt_long,
                    label: 'Mes commandes',
                    onTap: () => _navigate(context, '/orders/history'),
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_outlined,
                    label: 'Mes adresses',
                    onTap: () => _navigate(context, '/profile/addresses'),
                  ),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Paiement',
                    onTap: () => _navigate(context, '/profile/payments'),
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Promos',
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium,
                    label: 'NYAMA+',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ACTIF',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  _DrawerItem(
                    icon: Icons.card_giftcard,
                    label: 'Parrainage',
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  const _DrawerDivider(),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: 'Support',
                    onTap: () => _navigate(context, '/profile/support'),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Parametres',
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    label: 'A propos',
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  const _DrawerDivider(),
                  _DrawerItem(
                    icon: Icons.logout,
                    label: 'Deconnexion',
                    color: AppColors.errorRed,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
            // Footer
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 2.4.0',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop(); // Close drawer
    context.push(route);
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deconnexion',
            style: TextStyle(fontFamily: AppTheme.headlineFamily)),
        content: const Text('Voulez-vous vraiment vous deconnecter ?',
            style: TextStyle(fontFamily: AppTheme.bodyFamily)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SecureStorage.clearAll();
      if (!context.mounted) return;
      context.go('/onboarding');
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.charcoal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: c),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      height: 1,
      color: AppColors.surfaceLow,
    );
  }
}
