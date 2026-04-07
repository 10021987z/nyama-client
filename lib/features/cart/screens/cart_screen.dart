import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../payment/data/checkout_data.dart';
import '../providers/cart_provider.dart';

/// Écran 1.5 — Panier pur.
///
/// Brief Phase 4 : articles + vitesse livraison + récap + CTA "Commander".
/// L'adresse, le paiement et la note sont gérés dans /payment.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String _deliverySpeed = 'standard'; // 'standard' | 'express'

  static const int _expressFeeXaf = 500;

  int _deliveryFee() => _deliverySpeed == 'express' ? _expressFeeXaf : 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final subtotal = notifier.totalXaf;
    final fee = _deliveryFee();
    final total = subtotal + fee;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Mon Panier',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                'U',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // ── Articles ──────────────────────────────────────
                      ...cart.map((item) => _CartItemCard(
                            item: item,
                            onAdd: () => notifier.addItem(item),
                            onRemove: () => notifier.removeItem(item.menuItemId),
                          )),

                      const SizedBox(height: 24),

                      // ── Vitesse livraison ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SpeedOption(
                              title: 'STANDARD',
                              subtitle: '30 min',
                              isActive: _deliverySpeed == 'standard',
                              onTap: () =>
                                  setState(() => _deliverySpeed = 'standard'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SpeedOption(
                              title: 'EXPRESS',
                              subtitle: '15 min (+500)',
                              icon: Icons.bolt_rounded,
                              isActive: _deliverySpeed == 'express',
                              onTap: () =>
                                  setState(() => _deliverySpeed = 'express'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Récapitulatif ────────────────────────────────
                      _Summary(
                        subtotal: subtotal,
                        deliveryFee: fee,
                        total: total,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _OrderCta(
                  total: total,
                  onTap: () => _goToPayment(notifier, subtotal, fee, total),
                ),
              ],
            ),
    );
  }

  void _goToPayment(
      CartNotifier notifier, int subtotal, int fee, int total) {
    if (notifier.cookId == null) return;
    final data = CheckoutData(
      items: List.of(ref.read(cartProvider)),
      cookId: notifier.cookId!,
      cookName: notifier.cookName ?? '',
      subtotalXaf: subtotal,
      deliveryFeeXaf: fee,
      deliverySpeed: _deliverySpeed,
      totalXaf: total,
    );
    context.push('/payment', extra: data);
  }
}

// ─── Item Card ────────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image plat 100px radius 12
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Nom + prix + counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (item.priceXaf * item.quantity).toFcfa(),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                _QuantityPill(
                  quantity: item.quantity,
                  onAdd: onAdd,
                  onRemove: onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.restaurant_menu_rounded,
            color: AppColors.primary, size: 40),
      );
}

// ─── Quantity Pill (- N +) ────────────────────────────────────────────────

class _QuantityPill extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityPill({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillBtn(icon: Icons.remove, onTap: onRemove),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _PillBtn(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PillBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// ─── Speed option ─────────────────────────────────────────────────────────

class _SpeedOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SpeedOption({
    required this.title,
    required this.subtitle,
    this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outlineVariant,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, color: AppColors.primary, size: 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isActive ? AppColors.primary : AppColors.charcoal,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary ──────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  final int subtotal;
  final int deliveryFee;
  final int total;

  const _Summary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Sous-total', subtotal.toFcfa()),
          const SizedBox(height: 8),
          _row('Frais de livraison',
              deliveryFee == 0 ? 'Gratuit' : deliveryFee.toFcfa()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                total.toFcfa(),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ],
      );
}

// ─── CTA ──────────────────────────────────────────────────────────────────

class _OrderCta extends StatelessWidget {
  final int total;
  final VoidCallback onTap;

  const _OrderCta({required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.creme,
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Commander  |  ${total.toFcfa()}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Votre panier est vide',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ajoutez des plats depuis l'accueil",
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
