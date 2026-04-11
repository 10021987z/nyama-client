import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';
import '../../home/providers/home_provider.dart';
import 'product_bottom_sheet.dart';

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
        loading: () => const _ShimmerLoading(),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Restaurant')),
          body: NyamaErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(cookDetailProvider(restaurantId)),
          ),
        ),
        data: (cook) => _RestaurantBody(
          cook: cook,
          cart: cart,
          cartNotifier: cartNotifier,
        ),
      ),
    );
  }
}

// ─── Main body ───────────────────────────────────────────────────────────────

class _RestaurantBody extends StatefulWidget {
  final Cook cook;
  final List<CartItem> cart;
  final CartNotifier cartNotifier;

  const _RestaurantBody({
    required this.cook,
    required this.cart,
    required this.cartNotifier,
  });

  @override
  State<_RestaurantBody> createState() => _RestaurantBodyState();
}

class _RestaurantBodyState extends State<_RestaurantBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, List<MenuItem>> _grouped;
  late final List<String> _categories;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _grouped = _groupMenu();
    _categories = _grouped.keys.toList();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<MenuItem>> _groupMenu() {
    final map = <String, List<MenuItem>>{};
    final specials =
        widget.cook.menuItems.where((i) => i.isDailySpecial).toList();
    if (specials.isNotEmpty) map['Les Plus Populaires'] = specials;
    for (final item in widget.cook.menuItems) {
      final cat = item.category ?? 'Plats Principaux';
      (map[cat] ??= []).add(item);
    }
    if (map.isEmpty) map['Plats Principaux'] = [];
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.cart.fold(0, (s, i) => s + i.quantity);
    final cartTotal =
        widget.cart.fold(0, (s, i) => s + i.priceXaf * i.quantity);

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── Hero header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.charcoal,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.charcoal, size: 20),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _isFav = !_isFav),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFav ? Icons.favorite : Icons.favorite_border,
                          color:
                              _isFav ? AppColors.errorRed : AppColors.charcoal,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroImage(cook: widget.cook),
                ),
              ),

              // ── Info bar ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _InfoBar(cook: widget.cook),
              ),

              // ── Tabs ─────────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: AppColors.forestGreen,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.forestGreen,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: AppTheme.bodyFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Menu'),
                      Tab(text: 'Avis'),
                      Tab(text: 'Infos'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Menu tab
                _MenuTab(
                  categories: _categories,
                  grouped: _grouped,
                  cook: widget.cook,
                  cart: widget.cart,
                  cartNotifier: widget.cartNotifier,
                  bottomPadding: cartCount > 0 ? 80 : 24,
                ),
                // Reviews tab
                _ReviewsTab(
                  cook: widget.cook,
                  bottomPadding: cartCount > 0 ? 80 : 24,
                ),
                // Info tab
                _InfosTab(
                  cook: widget.cook,
                  bottomPadding: cartCount > 0 ? 80 : 24,
                ),
              ],
            ),
          ),

          // ── Floating cart bar ────────────────────────────────────────
          if (cartCount > 0)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 16,
              right: 16,
              child: _FloatingCartBar(count: cartCount, total: cartTotal),
            ),
        ],
      ),
    );
  }
}

// ─── Hero image ──────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final Cook cook;
  const _HeroImage({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE06A10), Color(0xFFF57C20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.restaurant, size: 64, color: Colors.white38),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Open/Closed badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cook.isOpenNow
                      ? AppColors.forestGreen
                      : AppColors.errorRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cook.isOpenNow ? 'OUVERT' : 'FERME',
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Restaurant name
              Text(
                cook.displayName,
                style: const TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (cook.specialty.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  cook.specialty.take(3).join(' · '),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info bar ────────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final Cook cook;
  const _InfoBar({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            icon: Icons.star,
            iconColor: AppColors.gold,
            label: cook.avgRating.toStringAsFixed(1),
            subtitle: '${cook.totalOrders} avis',
          ),
          _divider(),
          const _InfoChip(
            icon: Icons.schedule,
            iconColor: AppColors.forestGreen,
            label: '25 min',
            subtitle: 'Livraison',
          ),
          _divider(),
          const _InfoChip(
            icon: Icons.delivery_dining,
            iconColor: AppColors.primary,
            label: '500 FCFA',
            subtitle: 'Frais',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.surfaceLow,
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: AppTheme.bodyFamily,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Sticky tab delegate ────────────────────────────────────────────────────

class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _StickyTabDelegate old) => false;
}

// ─── Menu Tab ───────────────────────────────────────────────────────────────

class _MenuTab extends StatelessWidget {
  final List<String> categories;
  final Map<String, List<MenuItem>> grouped;
  final Cook cook;
  final List<CartItem> cart;
  final CartNotifier cartNotifier;
  final double bottomPadding;

  const _MenuTab({
    required this.categories,
    required this.grouped,
    required this.cook,
    required this.cart,
    required this.cartNotifier,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <_MenuEntry>[];
    for (final cat in categories) {
      allItems.add(_MenuEntry.header(cat, (grouped[cat] ?? []).length));
      for (final item in grouped[cat] ?? <MenuItem>[]) {
        allItems.add(_MenuEntry.item(item));
      }
    }

    if (allItems.isEmpty) {
      return const Center(
        child: NyamaErrorWidget(
          emoji: '🍽',
          message: 'Aucun plat disponible pour le moment',
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final entry = allItems[index];
        if (entry.isHeader) {
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : 24,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.headerTitle!,
                  style: const TextStyle(
                    fontFamily: AppTheme.headlineFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.headerCount} plat${entry.headerCount! > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final item = entry.menuItem!;
        final qty = cart
            .where((c) => c.menuItemId == item.id)
            .fold(0, (s, c) => s + c.quantity);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MenuItemCard(
            item: item,
            quantity: qty,
            onTap: () => showProductSheet(context, item, cook, cartNotifier),
            onAdd: () => _handleAdd(context, item),
          ),
        );
      },
    );
  }

  void _handleAdd(BuildContext context, MenuItem item) {
    try {
      cartNotifier.addItem(CartItem(
        menuItemId: item.id,
        name: item.name,
        priceXaf: item.priceXaf,
        quantity: 1,
        cookId: item.cook?.id ?? cook.id,
        cookName: item.cook?.displayName ?? cook.displayName,
        imageUrl: item.imageUrl,
      ));
    } on CartConflictException catch (e) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Panier different',
              style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontWeight: FontWeight.w700)),
          content: Text(e.message,
              style: const TextStyle(fontFamily: AppTheme.bodyFamily)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                cartNotifier.clearCart();
                Navigator.pop(ctx);
              },
              child: const Text('Vider et commander ici'),
            ),
          ],
        ),
      );
    }
  }
}

class _MenuEntry {
  final bool isHeader;
  final String? headerTitle;
  final int? headerCount;
  final MenuItem? menuItem;

  const _MenuEntry._({
    required this.isHeader,
    this.headerTitle,
    this.headerCount,
    this.menuItem,
  });

  factory _MenuEntry.header(String title, int count) =>
      _MenuEntry._(isHeader: true, headerTitle: title, headerCount: count);
  factory _MenuEntry.item(MenuItem item) =>
      _MenuEntry._(isHeader: false, menuItem: item);
}

// ─── Menu item card ─────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surfaceLow),
                        errorWidget: (context, url, error) =>
                            _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.priceXaf.toFcfa(),
                        style: const TextStyle(
                          fontFamily: AppTheme.monoFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!item.canOrder)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Epuise',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFamily,
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forestGreen
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: quantity > 0
                                ? Center(
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.monoFamily,
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.restaurant, color: AppColors.primary, size: 28),
        ),
      );
}

// ─── Reviews tab ────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final Cook cook;
  final double bottomPadding;
  const _ReviewsTab({required this.cook, required this.bottomPadding});

  static const _mockReviews = [
    _MockReview('Samuel M.', 5, 'Le Ndole etait sucre ! On sent la fraicheur des arachides.', 'Ndole Royal'),
    _MockReview('Alice E.', 4, 'Poulet DG bien assaisonne. Livraison un peu lente mais ca valait le coup.', 'Poulet DG'),
    _MockReview('Paul K.', 5, 'Le meilleur Achu de Douala. Le piment jaune est juste incroyable.', 'Achu'),
    _MockReview('Marie T.', 4, 'Eru bien prepare, waterfufu moelleux. Je reviendrai.', 'Eru & Waterfufu'),
    _MockReview('Jean L.', 5, 'Service rapide et plat delicieux. Bravo !', 'Poisson Braise'),
  ];

  @override
  Widget build(BuildContext context) {
    const totalReviews = 312;
    final distribution = [188, 89, 24, 8, 3]; // 5 to 1 stars

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
      children: [
        // Average + distribution
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.charcoal.withValues(alpha: 0.06),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              // Big average
              Column(
                children: [
                  const Text(
                    '4.6',
                    style: TextStyle(
                      fontFamily: AppTheme.monoFamily,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < 4 ? Icons.star : Icons.star_half,
                        size: 16,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '$totalReviews avis',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFamily,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Distribution bars
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final stars = 5 - i;
                    final count = distribution[i];
                    final pct = count / totalReviews;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            child: Text(
                              '$stars',
                              style: const TextStyle(
                                fontFamily: AppTheme.monoFamily,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star,
                              size: 12, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceLow,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.gold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontFamily: AppTheme.monoFamily,
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Review list
        ..._mockReviews.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: r),
            )),
      ],
    );
  }
}

class _MockReview {
  final String name;
  final int stars;
  final String comment;
  final String dish;
  const _MockReview(this.name, this.stars, this.comment, this.dish);
}

class _ReviewCard extends StatelessWidget {
  final _MockReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  review.name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.name,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.stars ? Icons.star : Icons.star_border,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              review.dish,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Infos tab ──────────────────────────────────────────────────────────────

class _InfosTab extends StatelessWidget {
  final Cook cook;
  final double bottomPadding;
  const _InfosTab({required this.cook, required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    final address = [cook.landmark, cook.quarter?.name]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    final todayHours = cook.todayHours;
    final hoursStr = todayHours != null && !todayHours.closed
        ? '${todayHours.open} - ${todayHours.close}'
        : '08h00 - 20h00';

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
      children: [
        // Address
        _InfoCard(
          icon: Icons.location_on_outlined,
          label: 'Adresse',
          value: address.isEmpty ? 'Douala, Cameroun' : address,
        ),
        const SizedBox(height: 12),
        // Hours
        _InfoCard(
          icon: Icons.schedule,
          label: 'Horaires',
          value: hoursStr,
        ),
        const SizedBox(height: 12),
        // Phone
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse('tel:+237699000000');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: const _InfoCard(
            icon: Icons.phone_outlined,
            label: 'Telephone',
            value: '+237 6 99 00 00 00',
            isLink: true,
          ),
        ),
        const SizedBox(height: 20),
        // Specialties
        if (cook.specialty.isNotEmpty) ...[
          const Text(
            'Specialites',
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cook.specialty.map((s) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isLink ? AppColors.primary : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call,
                  color: AppColors.forestGreen, size: 18),
            ),
        ],
      ),
    );
  }
}

// ─── Floating cart bar ──────────────────────────────────────────────────────

class _FloatingCartBar extends StatelessWidget {
  final int count;
  final int total;
  const _FloatingCartBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/cart'),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.forestGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFamily,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Voir le panier',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                total.toFcfa(),
                style: const TextStyle(
                  fontFamily: AppTheme.monoFamily,
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer loading ────────────────────────────────────────────────────────

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: Column(
        children: [
          // Hero placeholder
          Container(
            height: 280,
            color: AppColors.surfaceLow,
          ),
          // Info bar placeholder
          Container(
            height: 60,
            color: Colors.white,
          ),
          // Items placeholder
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
