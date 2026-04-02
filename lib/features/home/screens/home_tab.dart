import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/restaurant_card.dart';
import '../data/models/cook.dart';
import '../data/models/menu_item.dart';
import '../providers/home_provider.dart';
import '../../cart/providers/cart_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailySpecialsProvider);
    final cooksAsync = ref.watch(cooksProvider);
    // Watch pour déclencher le rechargement, les catégories en dépendent
    ref.watch(filteredMenuItemsProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dailySpecialsProvider);
          ref.invalidate(cooksProvider);
          ref.invalidate(filteredMenuItemsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverAppBar(
              pinned: false,
              floating: true,
              snap: true,
              backgroundColor: AppColors.primary,
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Localisation
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.secondary, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'Douala',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Que voulez-vous manger ?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Barre de recherche (tap → /search)
                        GestureDetector(
                          onTap: () => context.go('/search'),
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(width: 12),
                                Icon(Icons.search,
                                    color: AppColors.textSecondary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Rechercher un plat, une cuisinière...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Contenu scrollable ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Plats du jour ──────────────────────────────────────
                  _SectionHeader(
                    title: '🔥 Plats du jour',
                    onSeeAll: () => context.go('/search'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: dailyAsync.when(
                      loading: () => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) =>
                            const HorizontalMenuItemShimmer(),
                      ),
                      error: (e, _) => Center(
                        child: Text(e.toString(),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      data: (result) {
                        if (result.data.isEmpty) {
                          return const Center(
                            child: Text('Aucun plat du jour',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          );
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: result.data.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) =>
                              _DailySpecialCard(item: result.data[i]),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Catégories ─────────────────────────────────────────
                  const _SectionHeader(title: 'Catégories'),
                  const SizedBox(height: 12),
                  _CategoriesRow(
                    categories: categories,
                    selected: selectedCategory,
                    onSelect: (cat) => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = cat,
                  ),

                  const SizedBox(height: 24),

                  // ── Cuisinières ────────────────────────────────────────
                  _SectionHeader(
                    title: '👩‍🍳 Cuisinières',
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 12),
                  cooksAsync.when(
                    loading: () => Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: RestaurantCardShimmer(),
                        ),
                      ),
                    ),
                    error: (e, _) => NyamaErrorWidget(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(cooksProvider),
                    ),
                    data: (result) {
                      if (result.data.isEmpty) {
                        return const NyamaErrorWidget(
                          emoji: '👩‍🍳',
                          message: 'Aucune cuisinière disponible pour le moment',
                        );
                      }
                      return Column(
                        children: result.data
                            .map((cook) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _CookCard(
                                    cook: cook,
                                    onTap: () =>
                                        context.go('/restaurant/${cook.id}'),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text('Voir tout',
                style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _DailySpecialCard extends ConsumerWidget {
  final MenuItem item;

  const _DailySpecialCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
        cartProvider.select((items) => items
            .where((i) => i.menuItemId == item.id)
            .fold(0, (s, i) => s + i.quantity)));
    final notifier = ref.read(cartProvider.notifier);

    return GestureDetector(
      onTap: item.cook != null
          ? () => context.go('/restaurant/${item.cook!.id}')
          : null,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Hero(
                  tag: 'menu-${item.id}',
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, url, error) => Container(
                            color: AppColors.surface,
                            child: const Center(
                                child: Text('🍲',
                                    style: TextStyle(fontSize: 36))),
                          ),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                              child: Text('🍲',
                                  style: TextStyle(fontSize: 36))),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.priceXaf.toFcfa(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                        if (item.canOrder)
                          qty == 0
                              ? GestureDetector(
                                  onTap: () {
                                    if (item.cook == null) return;
                                    notifier.addItem(CartItem(
                                      menuItemId: item.id,
                                      name: item.name,
                                      priceXaf: item.priceXaf,
                                      quantity: 1,
                                      cookId: item.cook!.id,
                                      cookName: item.cook!.displayName,
                                      imageUrl: item.imageUrl,
                                    ));
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.add,
                                        size: 16, color: Colors.white),
                                  ),
                                )
                              : Text('×$qty',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  // Emoji associés aux catégories communes
  static const _emojiMap = {
    'viandes': '🍖',
    'poissons': '🐟',
    'légumes': '🥬',
    'grillades': '🍗',
    'soupes': '🥘',
    'boissons': '🥤',
    'riz': '🍚',
    'plantain': '🍌',
    'desserts': '🍰',
    'snacks': '🥙',
  };

  const _CategoriesRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  String _emoji(String cat) =>
      _emojiMap[cat.toLowerCase()] ?? '🍽️';

  @override
  Widget build(BuildContext context) {
    // "Tous" + catégories du backend
    final items = ['Tous', ...categories];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = items[i];
          final isAll = label == 'Tous';
          final isActive = isAll ? selected == null : selected == label;

          return GestureDetector(
            onTap: () => onSelect(isAll ? null : label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Text(
                isAll ? '🍽️  Tous' : '${_emoji(label)}  $label',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CookCard extends StatelessWidget {
  final Cook cook;
  final VoidCallback onTap;

  const _CookCard({required this.cook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RestaurantCard(
      id: cook.id,
      name: cook.displayName,
      imageUrl: null,
      rating: cook.avgRating,
      reviewCount: cook.totalOrders,
      deliveryTimeMin: 30,
      deliveryFee: 0,
      isOpen: cook.isOpenNow,
      subtitle: cook.landmark ??
          cook.quarter?.name ??
          cook.specialty.take(2).join(' · '),
      onTap: onTap,
    );
  }
}
