import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_gate.dart';
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
          appBar: AppBar(title: const Text('Restaurant')),
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

class _CookDetailView extends StatefulWidget {
  final Cook cook;
  final List<CartItem> cart;
  final CartNotifier cartNotifier;

  const _CookDetailView({
    required this.cook,
    required this.cart,
    required this.cartNotifier,
  });

  @override
  State<_CookDetailView> createState() => _CookDetailViewState();
}

class _CookDetailViewState extends State<_CookDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Map<String, List<MenuItem>> _grouped;
  late final List<String> _categories;
  late final List<String> _allTabs;

  @override
  void initState() {
    super.initState();
    _grouped = _groupedMenu();
    _categories = _grouped.keys.toList();
    _allTabs = [..._categories, 'Avis', 'Infos'];
    _tabController = TabController(length: _allTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<MenuItem>> _groupedMenu() {
    final map = <String, List<MenuItem>>{};
    // Put "Les Plus Populaires" first if any daily specials
    final specials =
        widget.cook.menuItems.where((i) => i.isDailySpecial).toList();
    if (specials.isNotEmpty) {
      map['Les Plus Populaires'] = specials;
    }
    for (final item in widget.cook.menuItems) {
      final cat = item.category ?? 'Plats Principaux';
      (map[cat] ??= []).add(item);
    }
    if (map.isEmpty) {
      map['Plats Principaux'] = [];
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount =
        widget.cart.fold(0, (s, i) => s + i.quantity);
    final cartTotal =
        widget.cart.fold(0, (s, i) => s + i.priceXaf * i.quantity);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── Hero header ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).canPop()
                          ? Navigator.of(context).pop()
                          : null,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black38,
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroHeader(cook: widget.cook),
                ),
              ),

              // ── Tabs ───────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primaryVibrant,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryVibrant,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                    unselectedLabelStyle: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    tabs: _allTabs.map((c) => Tab(text: c)).toList(),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                ..._categories.map((cat) {
                  final items = _grouped[cat] ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: NyamaErrorWidget(
                        emoji: '🍽️',
                        message: 'Aucun plat disponible pour le moment',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, cartCount > 0 ? 100 : 24),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _SectionHeader(
                          title: cat,
                          subtitle:
                              '${items.length} plat${items.length > 1 ? 's' : ''} disponible${items.length > 1 ? 's' : ''}',
                        );
                      }
                      final item = items[index - 1];
                      final qty = widget.cart
                          .where((i) => i.menuItemId == item.id)
                          .fold(0, (s, i) => s + i.quantity);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VibrantMenuCard(
                          item: item,
                          quantity: qty,
                          onAdd: () => _handleAdd(context, item),
                          onRemove: () =>
                              widget.cartNotifier.removeItem(item.id),
                        ),
                      );
                    },
                  );
                }),
                _ReviewsTab(bottomPadding: cartCount > 0 ? 100 : 24),
                _InfoTab(
                  cook: widget.cook,
                  bottomPadding: cartCount > 0 ? 100 : 24,
                ),
              ],
            ),
          ),

          // ── Sticky cart bar ─────────────────────────────────────────
          if (cartCount > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _StickyCartBar(
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
      widget.cartNotifier.addItem(CartItem(
        menuItemId: item.id,
        name: item.name,
        priceXaf: item.priceXaf,
        quantity: 1,
        cookId: item.cook?.id ?? '',
        cookName: item.cook?.displayName ?? widget.cook.displayName,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Panier différent',
            style: TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700)),
        content: Text(e.message, style: TextStyle(fontFamily: 'NunitoSans',fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              widget.cartNotifier.clearCart();
              Navigator.pop(dialogContext);
            },
            child: const Text('Vider et commander ici'),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final Cook cook;

  const _HeroHeader({required this.cook});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image / placeholder
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE06A10), Color(0xFFF57C20)],
            ),
          ),
          child: const Center(
            child: Text('🍽️', style: TextStyle(fontSize: 64)),
          ),
        ),

        // Gradient overlay sombre en bas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.35, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Content overlay
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges row
              Row(
                children: [
                  // Rating badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryVibrant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          cook.avgRating.toStringAsFixed(1),
                          style: TextStyle(fontFamily: 'NunitoSans',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delivery badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryVibrant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '25-35 min',
                          style: TextStyle(fontFamily: 'NunitoSans',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Open/Closed
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cook.isOpenNow ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cook.isOpenNow ? 'Ouvert' : 'Fermé',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Restaurant name
              Text(
                cook.displayName,
                style: TextStyle(fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Specialties subtitle
              if (cook.specialty.isNotEmpty)
                Text(
                  cook.specialty.take(3).join(' · '),
                  style: TextStyle(fontFamily: 'NunitoSans',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 6),

              // Orders + landmark
              Row(
                children: [
                  Text(
                    '${cook.totalOrders} commandes',
                    style: TextStyle(fontFamily: 'NunitoSans',
                        color: Colors.white60, fontSize: 12),
                  ),
                  if (cook.landmark != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on,
                        color: Colors.white60, size: 13),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        cook.landmark!,
                        style: TextStyle(fontFamily: 'NunitoSans',
                            color: Colors.white60, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab bar delegate ────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─── Section header ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontFamily: 'NunitoSans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Card vibrant (asymétrique avec image cutout) ────────────────────

class _VibrantMenuCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VibrantMenuCard({
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
      child: SizedBox(
        height: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card body
            Container(
              height: 150,
              padding: const EdgeInsets.fromLTRB(20, 16, 110, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name + description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),

                  // Price + add button
                  Row(
                    children: [
                      Text(
                        item.priceXaf.toFcfa(),
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      const Spacer(),
                      if (!canOrder)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Épuisé',
                              style: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              )),
                        )
                      else if (quantity == 0)
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryVibrant,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryVibrant
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 24),
                          ),
                        )
                      else
                        Row(
                          children: [
                            _CounterBtn(icon: Icons.remove, onTap: onRemove),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'NunitoSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
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
            ),

            // Circular cutout image — overflows right
            Positioned(
              right: -10,
              top: 15,
              child: Hero(
                tag: 'menu-${item.id}',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(-2, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, _) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 36)),
      ),
    );
  }
}

// ─── Counter button ──────────────────────────────────────────────────────

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryVibrant.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryVibrant),
      ),
    );
  }
}

// ─── Sticky Cart Bar ─────────────────────────────────────────────────────

class _StickyCartBar extends StatelessWidget {
  final int count;
  final int total;

  const _StickyCartBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go('/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Label + count badge
                Text(
                  'VOTRE COMMANDE',
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryVibrant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Total
                Text(
                  total.toFcfa(),
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),

                const SizedBox(width: 12),

                // CTA button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Voir le Panier',
                    style: TextStyle(fontFamily: 'NunitoSans',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading view ────────────────────────────────────────────────────────

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

// ─── Reviews Tab (mock data fallback) ────────────────────────────────────

class _MockReview {
  final String name;
  final int stars;
  final String comment;
  final String dish;
  const _MockReview(this.name, this.stars, this.comment, this.dish);
}

class _ReviewsTab extends StatelessWidget {
  final double bottomPadding;
  const _ReviewsTab({required this.bottomPadding});

  static const List<_MockReview> _mockReviews = [
    _MockReview(
      'Samuel M.',
      5,
      'Le Ndolé était sucré ! On sent la fraîcheur des arachides.',
      'Ndolé Royal',
    ),
    _MockReview(
      'Alice E.',
      4,
      'Poulet DG bien assaisonné. Livraison un peu lente mais ça valait le coup.',
      'Poulet DG',
    ),
    _MockReview(
      'Paul K.',
      5,
      'Le meilleur Achu de Douala. Le piment jaune est juste incroyable.',
      'Achu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: _mockReviews.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        if (idx == 0) {
          return _AddReviewButton();
        }
        final i = idx - 1;
        final r = _mockReviews[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
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
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      r.name[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (idx) => Icon(
                        idx < r.stars ? Icons.star : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFF5B301),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                r.comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  r.dish,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Info Tab ────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final Cook cook;
  final double bottomPadding;
  const _InfoTab({required this.cook, required this.bottomPadding});

  Future<void> _call() async {
    final uri = Uri.parse('tel:+237699000000');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final address = [
      cook.landmark,
      cook.quarter?.name,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      children: [
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Adresse',
          value: address.isEmpty ? 'Douala, Cameroun' : address,
        ),
        const SizedBox(height: 12),
        const _InfoRow(
          icon: Icons.schedule,
          label: 'Horaires',
          value: '08h00 - 20h00',
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _call,
          borderRadius: BorderRadius.circular(16),
          child: const _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: '+237 6 99 00 00 00',
            isLink: true,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  const _InfoRow({
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
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isLink
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isLink)
            const Icon(Icons.call, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}

// ─── Add review button (auth-gated) ───────────────────────────────────────

class _AddReviewButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final ok = await AuthGate.ensureAuthenticated(context);
          if (!ok || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laisse ton avis après ta prochaine commande 🌟'),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Écrire un avis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
