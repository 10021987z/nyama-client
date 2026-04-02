import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../data/models/order_models.dart';
import '../data/orders_repository.dart';
import '../providers/orders_provider.dart';
import 'orders_list_screen.dart' show OrderStatusBadge;

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Commande #${orderId.substring(0, 8).toUpperCase()}')),
      body: asyncOrder.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Statut + date ──────────────────────────────────────────────
        _Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${order.shortId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(order.formattedDate,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Timeline ───────────────────────────────────────────────────
        _Card(
          child: _OrderTimeline(status: order.status),
        ),
        const SizedBox(height: 12),

        // ── Articles ───────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(label: 'Articles'),
              const SizedBox(height: 8),
              ...order.items.map((item) => _ItemRow(item: item)),
              const Divider(height: 20),
              _AmountRow(
                  label: '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                  amount: order.subtotalXaf),
              const SizedBox(height: 4),
              const _FreeDeliveryRow(),
              const Divider(height: 16),
              _AmountRow(
                  label: 'Total',
                  amount: order.totalXaf,
                  bold: true,
                  primaryColor: true),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Cuisinière ─────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(label: 'Cuisinière'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surface,
                    child: Text('👩‍🍳', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(order.cookName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  if (order.cookPhone != null)
                    IconButton(
                      icon: const Icon(Icons.phone,
                          color: AppColors.success, size: 22),
                      tooltip: 'Appeler la cuisinière',
                      onPressed: () =>
                          _launchPhone(context, order.cookPhone!),
                    ),
                ],
              ),
              if (order.noteForCook != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(order.noteForCook!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Livraison ──────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(label: 'Livraison'),
              const SizedBox(height: 8),
              if (order.delivery.address != null)
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: order.delivery.address!),
              if (order.delivery.repere != null)
                _InfoRow(
                    icon: Icons.place_outlined,
                    text: order.delivery.repere!),
              if (order.delivery.riderName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surface,
                      child: Text('🛵', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(order.delivery.riderName!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    if (order.delivery.riderPhone != null)
                      IconButton(
                        icon: const Icon(Icons.phone,
                            color: AppColors.success, size: 20),
                        tooltip: 'Appeler le livreur',
                        onPressed: () =>
                            _launchPhone(context, order.delivery.riderPhone!),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Paiement ───────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardTitle(label: 'Paiement'),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.payment,
                  text: order.payment.methodLabel),
              _InfoRow(
                  icon: order.payment.status == 'paid'
                      ? Icons.check_circle_outline
                      : Icons.hourglass_empty,
                  text: order.payment.status == 'paid' ? 'Payé' : 'En attente',
                  color: order.payment.status == 'paid'
                      ? AppColors.success
                      : AppColors.textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Boutons d'action ───────────────────────────────────────────
        if (order.status == OrderStatus.delivering) ...[
          OutlinedButton.icon(
            onPressed: () {
              // Phase 5: map tracking
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Suivi carte disponible en Phase 5')),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Suivre la livraison'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (order.status == OrderStatus.delivered &&
            order.review == null) ...[
          _RatingButton(order: order),
          const SizedBox(height: 12),
        ],

        if (order.status == OrderStatus.delivered &&
            order.review != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('Avis envoyé',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  void _launchPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'appeler $phone')),
        );
      }
    }
  }
}

// ─── Rating button ────────────────────────────────────────────────────────────

class _RatingButton extends ConsumerStatefulWidget {
  final OrderModel order;

  const _RatingButton({required this.order});

  @override
  ConsumerState<_RatingButton> createState() => _RatingButtonState();
}

class _RatingButtonState extends ConsumerState<_RatingButton> {
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Avis envoyé',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showRatingSheet(context),
      icon: const Icon(Icons.star_outline),
      label: const Text('Laisser un avis'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showRatingSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RatingSheet(
        order: widget.order,
        onSubmitted: () {
          ref.invalidate(orderDetailProvider(widget.order.id));
          setState(() => _submitted = true);
        },
      ),
    );
  }
}

// ─── Rating bottom sheet ──────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onSubmitted;

  const _RatingSheet({required this.order, required this.onSubmitted});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  double _cookRating = 4;
  double _riderRating = 4;
  final _cookCommentCtrl = TextEditingController();
  final _riderCommentCtrl = TextEditingController();
  bool _rateRider = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cookCommentCtrl.dispose();
    _riderCommentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Votre avis',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 20),

            // ── Cuisinière ───────────────────────────────────────────
            Text(
              '👩‍🍳 ${widget.order.cookName}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Center(
              child: RatingBar.builder(
                initialRating: _cookRating,
                minRating: 1,
                itemCount: 5,
                itemSize: 36,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: AppColors.secondary),
                onRatingUpdate: (r) => setState(() => _cookRating = r),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cookCommentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Commentaire (optionnel)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Icon(Icons.edit_note),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Livreur (optionnel) ──────────────────────────────────
            Row(
              children: [
                Checkbox(
                  value: _rateRider,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _rateRider = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Évaluer le livreur',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            if (_rateRider) ...[
              const SizedBox(height: 4),
              const Text('🛵 Livreur',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Center(
                child: RatingBar.builder(
                  initialRating: _riderRating,
                  minRating: 1,
                  itemCount: 5,
                  itemSize: 36,
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppColors.secondary),
                  onRatingUpdate: (r) =>
                      setState(() => _riderRating = r),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _riderCommentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Commentaire livreur (optionnel)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(Icons.edit_note),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Envoyer mon avis',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await OrdersRepository().createReview(
        orderId: widget.order.id,
        cookRating: _cookRating,
        riderRating: _rateRider ? _riderRating : null,
        cookComment: _cookCommentCtrl.text.trim().isEmpty
            ? null
            : _cookCommentCtrl.text.trim(),
        riderComment: _rideRiderComment,
      );
      widget.onSubmitted();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? get _rideRiderComment {
    if (!_rateRider) return null;
    final t = _riderCommentCtrl.text.trim();
    return t.isEmpty ? null : t;
  }
}

// ─── Widgets communs ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String label;
  const _CardTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary));
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItemModel item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                item.imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, url, error) => const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                        child: Text('🍽️',
                            style: TextStyle(fontSize: 20)))),
              ),
            )
          else
            const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${item.quantity}× ${item.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
          Text(item.subtotal.toFcfa(),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;
  final bool primaryColor;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.primaryColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 15 : 13)),
        Text(amount.toFcfa(),
            style: TextStyle(
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 13,
                color: primaryColor
                    ? AppColors.primary
                    : AppColors.textPrimary)),
      ],
    );
  }
}

class _FreeDeliveryRow extends StatelessWidget {
  const _FreeDeliveryRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Livraison',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text('Gratuite',
            style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: color ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: color ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline ────────────────────────────────────────────────────────────────

class _OrderTimeline extends StatelessWidget {
  final OrderStatus status;

  const _OrderTimeline({required this.status});

  static const _steps = [
    (OrderStatus.pending, Icons.receipt_long_outlined, 'Commande reçue'),
    (OrderStatus.confirmed, Icons.check_circle_outline, 'Confirmée'),
    (OrderStatus.preparing, Icons.soup_kitchen_outlined, 'En préparation'),
    (OrderStatus.ready, Icons.done_all, 'Prête'),
    (OrderStatus.delivering, Icons.delivery_dining_outlined, 'En livraison'),
    (OrderStatus.delivered, Icons.home_outlined, 'Livrée'),
  ];

  int get _currentIndex {
    if (status == OrderStatus.cancelled) return -1;
    return _steps.indexWhere((s) => s.$1 == status);
  }

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Commande annulée',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      );
    }

    final current = _currentIndex;

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i <= current;
        final isCurrent = i == current;
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon column
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : AppColors.surface,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Icon(
                    step.$2,
                    size: 16,
                    color: isDone ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: i < current
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 28),
              child: Text(
                step.$3,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isDone
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
