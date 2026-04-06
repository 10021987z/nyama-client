import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../core/utils/validators.dart' show Validators;
import '../providers/cart_provider.dart';
import '../../orders/data/orders_repository.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _addressController = TextEditingController();
  final _repereController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'mtn_momo';
  String? _paymentPhone;
  bool _isOrdering = false;
  double? _lat;
  double? _lng;
  String _deliverySpeed = 'standard';

  @override
  void dispose() {
    _addressController.dispose();
    _repereController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'NYAMA',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                'U',
                style: TextStyle(fontFamily: 'Montserrat',
                  fontSize: 16,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Title ─────────────────────────────────────────
                        Text(
                          'Paiement',
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consultez votre sélection pour Savor Cameroon.',
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Delivery Destination ─────────────────────────
                        _SectionLabel(label: 'Destination de livraison'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: AppColors.primaryVibrant, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _addressController,
                                      style: TextStyle(fontFamily: 'NunitoSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Akwa, rue de la joie',
                                        hintStyle: TextStyle(fontFamily: 'NunitoSans',
                                          fontSize: 14,
                                          color: AppColors.textTertiary,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        fillColor: Colors.transparent,
                                        filled: false,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _fetchGps,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.primaryVibrant,
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'MODIFIER',
                                    style: TextStyle(fontFamily: 'NunitoSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryVibrant,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Order Summary ────────────────────────────────
                        _SectionLabel(label: 'Résumé de la commande'),
                        const SizedBox(height: 10),
                        ...List.generate(cart.length, (i) {
                          final item = cart[i];
                          return _VibrantCartItem(
                            item: item,
                            onAdd: () => notifier.addItem(item),
                            onRemove: () =>
                                notifier.removeItem(item.menuItemId),
                          );
                        }),

                        const SizedBox(height: 24),

                        // ── Delivery Speed ───────────────────────────────
                        _SectionLabel(label: 'Vitesse de Livraison'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _DeliverySpeedChip(
                                label: 'Standard (35-45 min)',
                                isActive: _deliverySpeed == 'standard',
                                onTap: () => setState(
                                    () => _deliverySpeed = 'standard'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DeliverySpeedChip(
                                label: 'Prioritaire (15-25 min)',
                                isActive: _deliverySpeed == 'priority',
                                onTap: () => setState(
                                    () => _deliverySpeed = 'priority'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Payment Method ───────────────────────────────
                        _SectionLabel(label: 'Mode de Paiement'),
                        const SizedBox(height: 10),
                        _VibrantPaymentSelector(
                          selected: _paymentMethod,
                          phone: _paymentPhone,
                          onMethodChanged: (m) =>
                              setState(() => _paymentMethod = m),
                          onPhoneChanged: (p) =>
                              setState(() => _paymentPhone = p),
                        ),

                        const SizedBox(height: 24),

                        // ── Note for cook ────────────────────────────────
                        _SectionLabel(label: 'Note pour la cuisinière'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: _noteController,
                            maxLines: 2,
                            style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14),
                            decoration: InputDecoration(
                              hintText:
                                  'Ex : Pas trop épicé, sans oignons...',
                              hintStyle: TextStyle(fontFamily: 'NunitoSans',
                                  fontSize: 14,
                                  color: AppColors.textTertiary),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: false,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Summary ──────────────────────────────────────
                        _VibrantSummary(
                          subtotal: notifier.totalXaf,
                          deliveryFee: _deliverySpeed == 'priority'
                              ? 1200
                              : 0,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Bottom CTA ─────────────────────────────────────────
                _BottomCta(
                  total: _calculateTotal(notifier.totalXaf),
                  isOrdering: _isOrdering,
                  onOrder: () => _placeOrder(context, notifier),
                ),
              ],
            ),
    );
  }

  int _calculateTotal(int subtotal) {
    final deliveryFee = _deliverySpeed == 'priority' ? 1200 : 0;
    final serviceFee = (subtotal * 0.015).round();
    return subtotal + deliveryFee + serviceFee;
  }

  Future<void> _fetchGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Accès à la localisation refusé définitivement')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addressController.text =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur GPS : $e')),
        );
      }
    }
  }

  Future<void> _placeOrder(
      BuildContext context, CartNotifier notifier) async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir une adresse de livraison')),
      );
      return;
    }

    if ((_paymentMethod == 'orange_money' || _paymentMethod == 'mtn_momo') &&
        (_paymentPhone == null || _paymentPhone!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir votre numéro de paiement')),
      );
      return;
    }

    setState(() => _isOrdering = true);

    final cart = ref.read(cartProvider);
    final request = CreateOrderRequest(
      cookId: notifier.cookId!,
      items: cart
          .map((i) => {'menuItemId': i.menuItemId, 'quantity': i.quantity})
          .toList(),
      deliveryAddress: _addressController.text.trim(),
      repere: _repereController.text.trim().isEmpty
          ? null
          : _repereController.text.trim(),
      noteForCook: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      paymentPhone: _paymentPhone,
      lat: _lat,
      lng: _lng,
    );

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final order = await OrdersRepository().createOrder(request);
      notifier.clearCart();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Commande passée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      router.go('/orders/${order.id}');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }
}

// ─── Section Label ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontFamily: 'Montserrat',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        color: AppColors.onSurface,
      ),
    );
  }
}

// ─── Vibrant Cart Item ───────────────────────────────────────────────────

class _VibrantCartItem extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VibrantCartItem({
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
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Round image
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.cookName,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ÉPICES SIGNATURE',
                    style: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Price + qty
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (item.priceXaf * item.quantity).toFcfa(),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CounterBtn(
                      icon: Icons.remove, onTap: onRemove),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Qté : ${item.quantity}',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _CounterBtn(icon: Icons.add, onTap: onAdd),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Icon(Icons.restaurant, color: AppColors.primaryVibrant),
    );
  }
}

// ─── Counter Button ──────────────────────────────────────────────────────

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryVibrant.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppColors.primaryVibrant),
      ),
    );
  }
}

// ─── Delivery Speed Chip ─────────────────────────────────────────────────

class _DeliverySpeedChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DeliverySpeedChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppColors.textTertiary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontFamily: 'NunitoSans',
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? AppColors.onSurface
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Payment Selector ────────────────────────────────────────────────────

class _VibrantPaymentSelector extends StatefulWidget {
  final String selected;
  final String? phone;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String?> onPhoneChanged;

  const _VibrantPaymentSelector({
    required this.selected,
    required this.phone,
    required this.onMethodChanged,
    required this.onPhoneChanged,
  });

  @override
  State<_VibrantPaymentSelector> createState() =>
      _VibrantPaymentSelectorState();
}

class _VibrantPaymentSelectorState extends State<_VibrantPaymentSelector> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _PaymentOption(
            icon: Icons.phone_android,
            iconColor: const Color(0xFFFFCC00),
            label: 'MTN Mobile Money',
            value: 'mtn_momo',
            selected: widget.selected,
            onTap: () => widget.onMethodChanged('mtn_momo'),
          ),
          const Divider(height: 1, indent: 56),
          _PaymentOption(
            icon: Icons.phone_android,
            iconColor: AppColors.primaryVibrant,
            label: 'Orange Money',
            value: 'orange_money',
            selected: widget.selected,
            onTap: () => widget.onMethodChanged('orange_money'),
          ),
          const Divider(height: 1, indent: 56),
          _PaymentOption(
            icon: Icons.payments_outlined,
            iconColor: AppColors.textSecondary,
            label: 'Paiement à la livraison',
            value: 'cash',
            selected: widget.selected,
            onTap: () {
              widget.onMethodChanged('cash');
              widget.onPhoneChanged(null);
            },
          ),
          if (widget.selected == 'orange_money' ||
              widget.selected == 'mtn_momo') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14),
                onChanged: (v) {
                  final normalized = Validators.normalizePhone(v);
                  widget.onPhoneChanged(normalized);
                  if (Validators.isOrangeMoney(v) &&
                      widget.selected != 'orange_money') {
                    widget.onMethodChanged('orange_money');
                  } else if (Validators.isMtnMomo(v) &&
                      widget.selected != 'mtn_momo') {
                    widget.onMethodChanged('mtn_momo');
                  }
                },
                decoration: InputDecoration(
                  labelText:
                      'Numéro ${widget.selected == 'orange_money' ? 'Orange' : 'MTN'} (+237)',
                  hintText: '6XXXXXXXX',
                  labelStyle: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 13, color: AppColors.textSecondary),
                  hintStyle: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 14, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primaryVibrant, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryVibrant
                      : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryVibrant,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vibrant Summary ─────────────────────────────────────────────────────

class _VibrantSummary extends StatelessWidget {
  final int subtotal;
  final int deliveryFee;

  const _VibrantSummary({
    required this.subtotal,
    required this.deliveryFee,
  });

  @override
  Widget build(BuildContext context) {
    final serviceFee = (subtotal * 0.015).round();
    final total = subtotal + deliveryFee + serviceFee;
    final isFreeDelivery = deliveryFee == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Sous-total',
            value: subtotal.toFcfa(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isFreeDelivery
                  ? Text(
                      'Frais de livraison',
                      style: TextStyle(fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.terracotta,
                        decoration: TextDecoration.lineThrough,
                      ),
                    )
                  : Text(
                      'Frais de livraison',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
              Text(
                isFreeDelivery ? 'Gratuit' : deliveryFee.toFcfa(),
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isFreeDelivery ? AppColors.success : AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Taxe de service (1.5%)',
            value: serviceFee.toFcfa(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total.toFcfa(),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                  Text(
                    'TVA incluse',
                    style: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'NunitoSans',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'NunitoSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Bottom CTA ──────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final int total;
  final bool isOrdering;
  final VoidCallback onOrder;

  const _BottomCta({
    required this.total,
    required this.isOrdering,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: isOrdering ? null : onOrder,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: isOrdering ? null : AppColors.primaryGradient,
            color: isOrdering ? AppColors.textTertiary : null,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: isOrdering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Commander • ${total.toFcfa()}',
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty Cart ──────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des plats depuis l\'accueil',
            style: TextStyle(fontFamily: 'NunitoSans',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
