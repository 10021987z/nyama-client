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
  String _paymentMethod = 'cash';
  String? _paymentPhone;
  bool _isOrdering = false;
  double? _lat;
  double? _lng;

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
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, notifier),
              child: const Text('Vider',
                  style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Nom de la cuisinière ───────────────────────────
                      if (notifier.cookName != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Text('👩‍🍳',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                notifier.cookName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Articles ───────────────────────────────────────
                      ...List.generate(cart.length, (i) {
                        final item = cart[i];
                        return Column(
                          children: [
                            _CartItemTile(
                              item: item,
                              onAdd: () => notifier.addItem(item),
                              onRemove: () =>
                                  notifier.removeItem(item.menuItemId),
                            ),
                            if (i < cart.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }),

                      const SizedBox(height: 24),
                      const _SectionLabel(label: 'Livraison'),
                      const SizedBox(height: 12),

                      // ── Adresse ────────────────────────────────────────
                      _AddressField(
                        controller: _addressController,
                        onGps: _fetchGps,
                      ),
                      const SizedBox(height: 12),

                      // ── Repère ─────────────────────────────────────────
                      TextField(
                        controller: _repereController,
                        decoration: const InputDecoration(
                          labelText: 'Repère (optionnel)',
                          hintText: 'Ex : Face pharmacie centrale',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const _SectionLabel(label: 'Paiement'),
                      const SizedBox(height: 8),

                      // ── Méthode de paiement ────────────────────────────
                      _PaymentSelector(
                        selected: _paymentMethod,
                        phone: _paymentPhone,
                        onMethodChanged: (m) =>
                            setState(() => _paymentMethod = m),
                        onPhoneChanged: (p) =>
                            setState(() => _paymentPhone = p),
                      ),

                      const SizedBox(height: 24),
                      const _SectionLabel(label: 'Note pour la cuisinière'),
                      const SizedBox(height: 8),

                      // ── Note cuisinière ────────────────────────────────
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Ex : Pas trop épicé, sans oignons...',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Icon(Icons.edit_note),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // ── Récapitulatif ──────────────────────────────────────
                _CartSummary(
                  itemCount: notifier.itemCount,
                  total: notifier.totalXaf,
                  isOrdering: _isOrdering,
                  onOrder: () => _placeOrder(context, notifier),
                ),
              ],
            ),
    );
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
                content: Text('Accès à la localisation refusé définitivement')),
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
        const SnackBar(content: Text('Veuillez saisir une adresse de livraison')),
      );
      return;
    }

    if ((_paymentMethod == 'orange_money' || _paymentMethod == 'mtn_momo') &&
        (_paymentPhone == null || _paymentPhone!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro de paiement')),
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

  void _confirmClear(BuildContext context, CartNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: const Text('Tous vos articles seront supprimés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              notifier.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onGps;

  const _AddressField({required this.controller, required this.onGps});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Adresse de livraison *',
        hintText: 'Ex : Akwa, rue de la joie',
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location, color: AppColors.primary),
          tooltip: 'Utiliser ma position',
          onPressed: onGps,
        ),
      ),
    );
  }
}

class _PaymentSelector extends StatefulWidget {
  final String selected;
  final String? phone;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String?> onPhoneChanged;

  const _PaymentSelector({
    required this.selected,
    required this.phone,
    required this.onMethodChanged,
    required this.onPhoneChanged,
  });

  @override
  State<_PaymentSelector> createState() => _PaymentSelectorState();
}

class _PaymentSelectorState extends State<_PaymentSelector> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methods = [
      ('orange_money', '🟠 Orange Money'),
      ('mtn_momo', '🟡 MTN MoMo'),
      ('cash', '💵 Espèces'),
    ];

    return RadioGroup<String>(
      groupValue: widget.selected,
      onChanged: (v) {
        if (v != null) {
          widget.onMethodChanged(v);
          if (v == 'cash') widget.onPhoneChanged(null);
        }
      },
      child: Column(
      children: [
        ...methods.map((m) {
          final value = m.$1;
          final label = m.$2;
          return RadioListTile<String>(
            value: value,
            dense: true,
            activeColor: AppColors.primary,
            title: Text(label, style: const TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          );
        }),
        if (widget.selected == 'orange_money' ||
            widget.selected == 'mtn_momo') ...[
          const SizedBox(height: 4),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (v) {
              final normalized = Validators.normalizePhone(v);
              widget.onPhoneChanged(normalized);
              // Auto-switch if prefix detected
              if (Validators.isOrangeMoney(v) && widget.selected != 'orange_money') {
                widget.onMethodChanged('orange_money');
              } else if (Validators.isMtnMomo(v) && widget.selected != 'mtn_momo') {
                widget.onMethodChanged('mtn_momo');
              }
            },
            decoration: InputDecoration(
              labelText:
                  'Numéro ${widget.selected == 'orange_money' ? 'Orange' : 'MTN'} *',
              hintText: '6XXXXXXXX',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ],
    ));
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛒', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez des plats depuis l\'accueil',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url, error) => Container(
                        color: AppColors.surface,
                        child: const Center(
                            child: Text('🍽️',
                                style: TextStyle(fontSize: 24))),
                      ),
                    )
                  : Container(
                      color: AppColors.surface,
                      child: const Center(
                          child: Text('🍽️',
                              style: TextStyle(fontSize: 24))),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(item.priceXaf.toFcfa(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: [
              _SmallCounterBtn(icon: Icons.remove, onTap: onRemove),
              SizedBox(
                width: 32,
                child: Text('${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              _SmallCounterBtn(icon: Icons.add, onTap: onAdd),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              (item.priceXaf * item.quantity).toFcfa(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallCounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int itemCount;
  final int total;
  final bool isOrdering;
  final VoidCallback onOrder;

  const _CartSummary({
    required this.itemCount,
    required this.total,
    required this.isOrdering,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount article${itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              Text(total.toFcfa(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Livraison',
                  style: TextStyle(color: AppColors.textSecondary)),
              Text('Gratuite',
                  style: TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              Text(total.toFcfa(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: isOrdering ? null : onOrder,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: isOrdering
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('Commander · ${total.toFcfa()}',
                    style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
