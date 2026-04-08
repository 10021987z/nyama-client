import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/data/orders_repository.dart';
import '../data/checkout_data.dart';
import '../data/payments_repository.dart';

/// Écran 1.6 — Paiement.
///
/// Reçoit un [CheckoutData] via go_router extra. Crée la commande puis
/// déclenche le paiement (simulé Phase 4) et navigue vers le tracking.
class PaymentScreen extends ConsumerStatefulWidget {
  final CheckoutData? checkout;

  const PaymentScreen({super.key, this.checkout});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'mtn_momo'; // 'mtn_momo' | 'orange_money' | 'falla_momo'
  late final TextEditingController _phoneController;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    final userPhone = ref.read(authStateProvider).user?.phone;
    _phoneController = TextEditingController(
      text: (userPhone != null && userPhone.isNotEmpty)
          ? userPhone
          : '+237 6XX XXX XXX',
    );
  }

  // Adresse — pré-remplie. Brief : "Bonapriso, Douala / Appartement 4B"
  String _address = 'Bonapriso, Douala';
  String _addressDetail = 'Appartement 4B';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = widget.checkout;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Paiement',
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
      body: checkout == null
          ? const _MissingCheckout()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // ── Adresse ──────────────────────────────────────
                      _SectionLabel('Adresse de livraison'),
                      const SizedBox(height: 8),
                      _AddressCard(
                        address: _address,
                        detail: _addressDetail,
                        onEdit: _showAddressDialog,
                      ),
                      const SizedBox(height: 24),

                      // ── Méthode de paiement ──────────────────────────
                      _SectionLabel('Méthode de paiement'),
                      const SizedBox(height: 8),
                      _PaymentMethodCard(
                        title: 'MTN Mobile Money',
                        subtitle: 'Paiement instantané',
                        iconColor: const Color(0xFFFFCC00),
                        selected: _method == 'mtn_momo',
                        onTap: () => setState(() => _method = 'mtn_momo'),
                      ),
                      const SizedBox(height: 10),
                      _PaymentMethodCard(
                        title: 'Orange Money',
                        subtitle: 'Paiement instantané',
                        iconColor: AppColors.primary,
                        selected: _method == 'orange_money',
                        onTap: () => setState(() => _method = 'orange_money'),
                      ),
                      const SizedBox(height: 10),
                      _PaymentMethodCard(
                        title: 'Falla Mobile Money',
                        subtitle: 'Paiement instantané',
                        iconColor: AppColors.forestGreen,
                        selected: _method == 'falla_momo',
                        onTap: () => setState(() => _method = 'falla_momo'),
                      ),
                      const SizedBox(height: 24),

                      // ── Numéro téléphone ─────────────────────────────
                      const Text(
                        'Numéro de téléphone',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.outlineVariant, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '+237 6XX XXX XXX',
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Un code de confirmation vous sera envoyé par SMS',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Récapitulatif ────────────────────────────────
                      _Summary(
                        subtotal: checkout.subtotalXaf,
                        deliveryFee: checkout.deliveryFeeXaf,
                        total: checkout.totalXaf,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _PayCta(
                  total: checkout.totalXaf,
                  loading: _processing,
                  onTap: () => _onPay(checkout),
                ),
              ],
            ),
    );
  }

  void _showAddressDialog() {
    final addrCtrl = TextEditingController(text: _address);
    final detailCtrl = TextEditingController(text: _addressDetail);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l\'adresse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            TextField(
              controller: detailCtrl,
              decoration: const InputDecoration(labelText: 'Détails'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _address = addrCtrl.text.trim();
                _addressDetail = detailCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _onPay(CheckoutData checkout) async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro')),
      );
      return;
    }

    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      // 1. Créer la commande côté backend
      final order = await OrdersRepository().createOrder(
        CreateOrderRequest(
          cookId: checkout.cookId,
          items: checkout.items
              .map((i) =>
                  {'menuItemId': i.menuItemId, 'quantity': i.quantity})
              .toList(),
          deliveryAddress: '$_address — $_addressDetail',
          paymentMethod: _method,
          paymentPhone: _phoneController.text.trim(),
        ),
      );

      // 2. Déclencher le paiement (simulé Phase 4)
      final result = await PaymentsRepository().initiatePayment(
        orderId: order.id,
        amount: checkout.totalXaf,
        currency: 'XAF',
        phone: _phoneController.text.trim(),
        method: _method,
      );

      if (!mounted) return;

      if (!result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Paiement échoué')),
        );
        setState(() => _processing = false);
        return;
      }

      // 3. Vider panier + naviguer vers tracking
      ref.read(cartProvider.notifier).clearCart();
      router.go('/tracking/${order.id}');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
      setState(() => _processing = false);
    }
  }
}

// ─── Section Label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.charcoal,
      ),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final String address;
  final String detail;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.address,
    required this.detail,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 32),
            ),
            child: const Text(
              'Modifier',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment method card ──────────────────────────────────────────────────

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
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
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
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

class _PayCta extends StatelessWidget {
  final int total;
  final bool loading;
  final VoidCallback onTap;

  const _PayCta({
    required this.total,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: AppColors.creme,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            disabledBackgroundColor:
                AppColors.forestGreen.withValues(alpha: 0.6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Payer ${total.toFcfa()}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MissingCheckout extends StatelessWidget {
  const _MissingCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'Aucune commande à payer',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).go('/cart'),
            child: const Text('Retour au panier'),
          ),
        ],
      ),
    );
  }
}
