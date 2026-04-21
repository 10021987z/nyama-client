import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';

enum _HistoryFilter { all, active, delivered, cancelled }

extension on _HistoryFilter {
  String get label {
    switch (this) {
      case _HistoryFilter.all:
        return 'Toutes';
      case _HistoryFilter.active:
        return 'En cours';
      case _HistoryFilter.delivered:
        return 'Livrées';
      case _HistoryFilter.cancelled:
        return 'Annulées';
    }
  }
}

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  List<OrderModel> _applyFilter(List<OrderModel> all) {
    switch (_filter) {
      case _HistoryFilter.all:
        return [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _HistoryFilter.active:
        return all.where((o) => o.status.isActive).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _HistoryFilter.delivered:
        return all.where((o) => o.status == OrderStatus.delivered).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _HistoryFilter.cancelled:
        return all.where((o) => o.status == OrderStatus.cancelled).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrders = ref.watch(ordersListProvider(null));

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Mes commandes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: asyncOrders.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => _buildError(e),
              data: (orders) {
                final list = _applyFilter(orders);
                if (list.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(ordersListProvider(null)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _OrderCard(order: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _HistoryFilter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              selected: selected,
              label: Text(f.label),
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontFamily: AppTheme.bodyFamily,
                color: selected ? Colors.white : AppColors.charcoal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off,
                  color: AppColors.errorRed, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Erreur de chargement',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(ordersListProvider(null)),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final (icon, title, subtitle) = switch (_filter) {
      _HistoryFilter.all => (
          Icons.receipt_long,
          'Aucune commande',
          'Vos commandes apparaitront ici'
        ),
      _HistoryFilter.active => (
          Icons.delivery_dining,
          'Aucune commande en cours',
          'Explorez les plats disponibles'
        ),
      _HistoryFilter.delivered => (
          Icons.check_circle_outline,
          'Aucune commande livree',
          'Vos livraisons apparaitront ici'
        ),
      _HistoryFilter.cancelled => (
          Icons.cancel_outlined,
          'Aucune commande annulee',
          'Rien a afficher'
        ),
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 14,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.restaurant_menu, size: 18),
            label: const Text('Explorer les plats'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = order.status.isActive;
    final isDelivered = order.status == OrderStatus.delivered;
    final hasReview = order.review != null;

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.cookName,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          )),
                      const SizedBox(height: 2),
                      Text(order.formattedDate,
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFamily,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            if (order.items.isNotEmpty)
              Text(
                order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(order.totalXaf.toFcfa(),
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
                const Spacer(),
                if (isDelivered)
                  _RatingChip(
                      review: order.review,
                      onRate: hasReview
                          ? null
                          : () => context.push('/rating/${order.id}')),
                const SizedBox(width: 8),
                if (isActive)
                  _ActionButton(
                    label: 'Suivre',
                    icon: Icons.map_outlined,
                    color: AppColors.forestGreen,
                    onTap: () => context.push('/orders/${order.id}/track'),
                  )
                else if (isDelivered)
                  _ActionButton(
                    label: 'Commander a nouveau',
                    icon: Icons.replay,
                    color: AppColors.primary,
                    onTap: () {
                      final cartNotifier = ref.read(cartProvider.notifier);
                      cartNotifier.clearCart();
                      for (final item in order.items) {
                        cartNotifier.addItem(CartItem(
                          menuItemId: item.menuItemId,
                          name: item.name,
                          priceXaf: item.priceXaf,
                          quantity: item.quantity,
                          cookId: order.cookId,
                          cookName: order.cookName,
                          imageUrl: item.imageUrl,
                        ));
                      }
                      context.go('/cart');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final ReviewModel? review;
  final VoidCallback? onRate;

  const _RatingChip({required this.review, required this.onRate});

  @override
  Widget build(BuildContext context) {
    if (review != null) {
      final stars = review!.cookRating.round().clamp(0, 5);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          return Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: AppColors.gold,
          );
        }),
      );
    }
    return GestureDetector(
      onTap: onRate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded, size: 14, color: AppColors.gold),
            SizedBox(width: 4),
            Text('Noter',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                )),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  Color get _bg {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.forestGreen.withValues(alpha: 0.1);
      case OrderStatus.cancelled:
        return AppColors.errorRed.withValues(alpha: 0.1);
      case OrderStatus.delivering:
        return const Color(0xFF2196F3).withValues(alpha: 0.1);
      case OrderStatus.preparing:
        return AppColors.gold.withValues(alpha: 0.1);
      default:
        return AppColors.primary.withValues(alpha: 0.1);
    }
  }

  Color get _fg {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.forestGreen;
      case OrderStatus.cancelled:
        return AppColors.errorRed;
      case OrderStatus.delivering:
        return const Color(0xFF2196F3);
      case OrderStatus.preparing:
        return AppColors.gold;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTheme.bodyFamily,
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}
