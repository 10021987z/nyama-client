import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';
import '../../home/providers/home_provider.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookAsync = ref.watch(cookDetailProvider(restaurantId));
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      body: cookAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Cuisinière')),
          body: NyamaErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(cookDetailProvider(restaurantId)),
          ),
        ),
        data: (cook) => _CookDetailView(
          cook: cook,
          cart: cart,
          cartNotifier: cartNotifier,
        ),
      ),
    );
  }
}

// ─── Vue principale ───────────────────────────────────────────────────────

class _CookDetailView extends StatelessWidget {
  final Cook cook;
  final List<CartItem> cart;
  final CartNotifier cartNotifier;

  const _CookDetailView({
    required this.cook,
    required this.cart,
    required this.cartNotifier,
  });

  /// Regroupe les plats par catégorie
  Map<String, List<MenuItem>> _groupedMenu() {
    final map = <String, List<MenuItem>>{};
    for (final item in cook.menuItems) {
      final cat = item.category ?? 'Autres';
      (map[cat] ??= []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedMenu();
    final cartCount = cart.fold(0, (s, i) => s + i.quantity);
    final cartTotal = cart.fold(0, (s, i) => s + i.priceXaf * i.quantity);

    // Construit la liste de sections à afficher
    final sections = <Widget>[];
    sections.add(_HoursSection(cook: cook));
    sections.add(const SizedBox(height: 16));

    for (final entry in grouped.entries) {
      sections.add(_CategoryHeader(title: entry.key));
      for (final item in entry.value) {
        sections.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MenuItemRow(
            item: item,
            quantity: cart
                .where((i) => i.menuItemId == item.id)
                .fold(0, (s, i) => s + i.quantity),
            onAdd: () => _handleAdd(context, item),
            onRemove: () => cartNotifier.removeItem(item.id),
          ),
        ));
      }
      sections.add(const SizedBox(height: 12));
    }

    if (cook.menuItems.isEmpty) {
      sections.add(const NyamaErrorWidget(
        emoji: '🍽️',
        message: 'Aucun plat disponible pour le moment',
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header gradient ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () =>
                        Navigator.of(context).canPop() ? Navigator.of(context).pop() : null,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _CookHeader(cook: cook),
                ),
              ),

              // ── Menu ─────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, cartCount > 0 ? 96 : 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(sections),
                ),
              ),
            ],
          ),

          // ── FAB panier ───────────────────────────────────────────────
          if (cartCount > 0)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _CartFab(
                count: cartCount,
                total: cartTotal,
              ),
            ),
        ],
      ),
    );
  }

  void _handleAdd(BuildContext context, MenuItem item) {
    try {
      cartNotifier.addItem(CartItem(
        menuItemId: item.id,
        name: item.name,
        priceXaf: item.priceXaf,
        quantity: 1,
        cookId: item.cook?.id ?? '',
        cookName: item.cook?.displayName ?? cook.displayName,
        imageUrl: item.imageUrl,
      ));
    } on CartConflictException catch (e) {
      _showConflictDialog(context, e);
    }
  }

  void _showConflictDialog(BuildContext context, CartConflictException e) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Panier différent'),
        content: Text(e.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              cartNotifier.clearCart();
              Navigator.pop(dialogContext);
            },
            child: const Text('Vider et commander ici'),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────

class _CookHeader extends StatelessWidget {
  final Cook cook;

  const _CookHeader({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom + statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    cook.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cook.isOpenNow
                        ? AppColors.success
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cook.isOpenNow ? 'Ouvert' : 'Fermé',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Spécialités chips
            if (cook.specialty.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: cook.specialty
                    .take(4)
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white54),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12)),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 10),

            // Rating + orders + landmark
            Row(
              children: [
                RatingBarIndicator(
                  rating: cook.avgRating,
                  itemSize: 14,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cook.avgRating.toStringAsFixed(1)} · ${cook.totalOrders} commandes',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            if (cook.landmark != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cook.landmark!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HoursSection extends StatelessWidget {
  final Cook cook;

  const _HoursSection({required this.cook});

  static const _daysFr = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };
  static const _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  static const _todayKeys = [
    'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
  ];

  @override
  Widget build(BuildContext context) {
    if (cook.openingHours.isEmpty) return const SizedBox.shrink();

    final todayKey = _todayKeys[DateTime.now().weekday % 7];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Horaires',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          ..._dayOrder
              .where((d) => cook.openingHours.containsKey(d))
              .map((d) {
            final hours = cook.openingHours[d]!;
            final isToday = d == todayKey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      _daysFr[d] ?? d,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    hours.closed
                        ? 'Fermé'
                        : '${hours.open} – ${hours.close}',
                    style: TextStyle(
                      fontSize: 13,
                      color: hours.closed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canOrder = item.canOrder;

    return Opacity(
      opacity: canOrder ? 1.0 : 0.55,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Texte
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (item.description != null) ...[
                            const SizedBox(height: 3),
                            Text(item.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          if (item.prepTimeMin != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.schedule,
                                  size: 11,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text('${item.prepTimeMin} min',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ]),
                          ],
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.priceXaf.toFcfa(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                          if (!canOrder)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Épuisé',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                            )
                          else if (quantity == 0)
                            GestureDetector(
                              onTap: onAdd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('+ Ajouter',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            )
                          else
                            Row(children: [
                              _CounterBtn(icon: Icons.remove, onTap: onRemove),
                              SizedBox(
                                width: 28,
                                child: Text('$quantity',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              _CounterBtn(icon: Icons.add, onTap: onAdd),
                            ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Image
              Hero(
                tag: 'menu-${item.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12)),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, url, error) => Container(
                              color: AppColors.surface,
                              child: const Center(
                                  child: Text('🍽️',
                                      style: TextStyle(fontSize: 32))),
                            ),
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Center(
                                child: Text('🍽️',
                                    style: TextStyle(fontSize: 32))),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _CartFab extends StatelessWidget {
  final int count;
  final int total;

  const _CartFab({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count article${count > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            const Text('Voir le panier',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const Spacer(),
            Text(
              total.toFcfa(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primary),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: MenuItemShimmer(),
          ),
        ),
      ),
    );
  }
}
