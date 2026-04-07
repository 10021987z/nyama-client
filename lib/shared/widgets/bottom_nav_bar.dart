import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../features/cart/providers/cart_provider.dart';

/// Bottom nav NYAMA — fond blanc, item actif = pill orange (icône blanche)
/// + label orange 10px sous la pill. Pas de bordure supérieure visible.
class NyamaBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NyamaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider
        .select((items) => items.fold(0, (sum, i) => sum + i.quantity)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.restaurant_menu,
                label: 'DECOUVRIR',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'EXPLORER',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.receipt_long,
                label: 'COMMANDES',
                isActive: currentIndex == 2,
                badgeCount: cartCount,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'PROFIL',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive ? Colors.white : AppColors.textTertiary,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.surfaceWhite, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    isActive ? AppColors.primary : AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
