import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers/auth_provider.dart';

/// Écran 1.9 — Profil NYAMA+.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _premiumGradEnd = Color(0xFF2D6B4F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final name = (user?.name?.isNotEmpty ?? false)
        ? user!.name!
        : 'Utilisateur NYAMA';

    return ColoredBox(
      color: AppColors.creme,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildHero(name),
                  const SizedBox(height: 20),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildNyamaPlusBanner(),
                  const SizedBox(height: 16),
                  _buildReferralBlock(),
                  const SizedBox(height: 20),
                  _buildMenuItems(context),
                  const SizedBox(height: 12),
                  _buildLogout(context, ref),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Version 2.4.0 • NYAMA Cameroon',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const Expanded(
            child: Center(
              child: Text(
                'NYAMA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            backgroundImage: AssetImage('assets/images/mock/logo_nyama.jpg'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String name) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                backgroundColor: AppColors.primary,
                backgroundImage:
                    AssetImage('assets/images/mock/logo_nyama.jpg'),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        FutureBuilder<List<String?>>(
          future: Future.wait([
            SecureStorage.getCity(),
            SecureStorage.getQuartier(),
          ]),
          builder: (context, snap) {
            final city = snap.data?[0];
            final quartier = snap.data?[1];
            final label = (city != null && quartier != null)
                ? '$city, $quartier'
                : (quartier ?? city ?? 'Douala');
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStats() {
    Widget col(String label, String value, {bool gold = false, IconData? ic}) {
      return Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ic != null) ...[
                  Icon(ic, size: 16, color: AppColors.gold),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: gold ? AppColors.gold : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          col('Commandes', '24'),
          col('Favoris', '5'),
          col('Points Nyama', '1,250', gold: true, ic: Icons.star_rounded),
        ],
      ),
    );
  }

  Widget _buildNyamaPlusBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.forestGreen, _premiumGradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium, color: AppColors.gold, size: 22),
              SizedBox(width: 8),
              Text(
                'NYAMA+',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'Livraison gratuite illimitée pour '),
                TextSpan(
                  text: '2 500',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' FCFA/mois'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité bientôt disponible !'),
                    ),
                  );
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Essayer 7 jours gratuit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Parraine un ami',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(text: 'Gagne '),
                          TextSpan(
                            text: '500',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' FCFA chacun'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Share.share(
                    'Rejoins NYAMA et gagne 500 FCFA ! Code : ARTHUR237. Télécharge l\'app : https://nyama.cm',
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Partager',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'ARTHUR237',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final items = <_MenuEntry>[
      _MenuEntry(Icons.notifications_none, 'Notifications',
          onTap: () => _showNotificationsSheet(context)),
      _MenuEntry(Icons.location_on_outlined, 'Mes adresses',
          onTap: () => context.push('/onboarding/quartier')),
      _MenuEntry(Icons.receipt_long, 'Historique commandes',
          onTap: () => context.go('/orders')),
      _MenuEntry(Icons.payments_outlined, 'Moyens de paiement (MoMo/OM)',
          onTap: () => _showPaymentMethodsSheet(context)),
      _MenuEntry(Icons.language, 'Langue (Français/Pidgin)',
          onTap: () => _showLanguageDialog(context)),
      _MenuEntry(Icons.help_outline, 'Support & Aide',
          onTap: _openWhatsAppSupport),
    ];
    return Column(
      children: [
        for (final it in items) ...[
          _MenuCard(entry: it),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _confirmLogout(context, ref),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout,
                  size: 18, color: AppColors.errorRed),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Se déconnecter',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.errorRed,
                ),
              ),
            ),
          ],
        ),
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
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      await SecureStorage.clearAll();
      if (context.mounted) context.go('/onboarding/phone');
    }
  }

  // ─── Helpers : feuilles modales / dialogues ─────────────────────────────

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse(
        'https://wa.me/237699000000?text=Bonjour%20NYAMA');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 56,
                color: AppColors.textTertiary.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text(
              'Aucune notification',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tu seras prévenu dès qu\'il se passe quelque chose.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Moyens de paiement',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 16),
                _PaymentMethodTile(
                  label: 'MTN Mobile Money',
                  color: Color(0xFFFFCC00),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                SizedBox(height: 10),
                _PaymentMethodTile(
                  label: 'Orange Money',
                  color: Color(0xFFF57C20),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                SizedBox(height: 10),
                _PaymentMethodTile(
                  label: 'Falla Mobile Money',
                  color: Color(0xFF1B4332),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle,
                  color: AppColors.primary),
              title: const Text('Français'),
              onTap: () => Navigator.pop(ctx),
            ),
            const ListTile(
              enabled: false,
              leading: Icon(Icons.lock_outline,
                  size: 18, color: AppColors.textTertiary),
              title: Text('Pidgin'),
              subtitle: Text('Bientôt disponible'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

// ─── Payment method tile (sheet) ────────────────────────────────────────────
class _PaymentMethodTile extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _PaymentMethodTile({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  _MenuEntry(this.icon, this.label, {this.onTap});
}

class _MenuCard extends StatelessWidget {
  final _MenuEntry entry;
  const _MenuCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: entry.onTap ?? () {},
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon,
                    size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
