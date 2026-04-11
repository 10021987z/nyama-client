import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              labelColor: AppColors.charcoal,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'Passees'),
              ],
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OrderList(
                  asyncOrders: ref.watch(activeOrdersProvider),
                  onRefresh: () => ref.invalidate(activeOrdersProvider),
                  isActive: true,
                  emptyIcon: Icons.delivery_dining,
                  emptyTitle: 'Aucune commande en cours',
                  emptySubtitle: 'Explorez les plats disponibles',
                ),
                _OrderList(
                  asyncOrders: ref.watch(pastOrdersProvider),
                  onRefresh: () => ref.invalidate(pastOrdersProvider),
                  isActive: false,
                  emptyIcon: Icons.receipt_long,
                  emptyTitle: 'Aucune commande passee',
                  emptySubtitle: 'Vos commandes terminees apparaitront ici',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final AsyncValue<List<OrderModel>> asyncOrders;
  final VoidCallback onRefresh;
  final bool isActive;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _OrderList({
    required this.asyncOrders,
    required this.onRefresh,
    required this.isActive,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncOrders.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
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
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onRefresh,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('Reessayer'),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
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
                  child: Icon(emptyIcon, color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  emptyTitle,
                  style: const TextStyle(
                    fontFamily: AppTheme.headlineFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptySubtitle,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('Explorer les plats'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _OrderCard(
              order: orders[i],
              isActive: isActive,
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isActive;

  const _OrderCard({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Header: cook name + status badge
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
                      Text(
                        order.cookName,
                        style: const TextStyle(
                          fontFamily: AppTheme.headlineFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.formattedDate,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            // Items preview
            if (order.items.isNotEmpty)
              Text(
                order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFamily,
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            // Footer: total + action
            Row(
              children: [
                Text(
                  order.totalXaf.toFcfa(),
                  style: const TextStyle(
                    fontFamily: AppTheme.monoFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  _ActionButton(
                    label: 'Suivre',
                    icon: Icons.map_outlined,
                    color: AppColors.forestGreen,
                    onTap: () => context.push('/orders/${order.id}/track'),
                  )
                else
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
