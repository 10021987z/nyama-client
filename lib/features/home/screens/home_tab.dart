import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/loading_shimmer.dart';
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
    ref.watch(filteredMenuItemsProvider);
    final categories = ref.watch(availableCategoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cartCount = ref.watch(
        cartProvider.select((items) => items.fold(0, (s, i) => s + i.quantity)));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primaryVibrant,
        onRefresh: () async {
          ref.invalidate(dailySpecialsProvider);
          ref.invalidate(cooksProvider);
          ref.invalidate(filteredMenuItemsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Custom AppBar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      // Gauche : burger + localisation
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_rounded,
                                  color: AppColors.onSurface, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IDEAL AVEC DU BOBOLO',
                                  style: TextStyle(fontFamily: 'NunitoSans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: AppColors.primaryVibrant,
                                        size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Bonapriso, Douala',
                                      style: TextStyle(fontFamily: 'NunitoSans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.keyboard_arrow_down,
                                        color: AppColors.textSecondary,
                                        size: 16),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Centre : titre
                      Text(
                        'NYAMA',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),

                      // Droite : panier + avatar
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Badge panier
                            GestureDetector(
                              onTap: () => context.go('/cart'),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.onSurface,
                                        size: 20),
                                  ),
                                  if (cartCount > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryVibrant,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          cartCount > 99
                                              ? '99+'
                                              : '$cartCount',
                                          style: TextStyle(fontFamily: 'NunitoSans',
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person_outline,
                                  color: AppColors.primary, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Barre de recherche ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryVibrant.withValues(alpha: 0.12),
                          AppColors.secondaryVibrant.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(Icons.search,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Une envie de Ndole ou de...',
                            style: TextStyle(fontFamily: 'NunitoSans',
                              color: AppColors.textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(Icons.tune_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Banniere promotionnelle ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE06A10), Color(0xFFF57C20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Motif décoratif
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.restaurant,
                          size: 140,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryVibrant,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'NOUVEAU',
                                style: TextStyle(fontFamily: 'NunitoSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Saveurs du Cameroun\nlivrées chez vous',
                              style: TextStyle(fontFamily: 'Montserrat',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '-20% sur votre 1ere commande',
                              style: TextStyle(fontFamily: 'NunitoSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── La Carte des Saveurs ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: _SectionHeader(
                  title: 'La Carte des Saveurs',
                  onSeeAll: () => context.go('/search'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _SavorCategoriesRow(
                  categories: categories,
                  selected: selectedCategory,
                  onSelect: (cat) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                ),
              ),
            ),

            // ── Le Meilleur de Douala ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: _SectionHeader(
                  title: 'Le Meilleur de Douala',
                  onSeeAll: () {},
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: cooksAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: _RestaurantCardShimmer(),
                    ),
                    childCount: 3,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(cooksProvider),
                  ),
                ),
                data: (result) {
                  if (result.data.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        emoji: '👩\u200d🍳',
                        message: 'Aucune cuisiniere disponible',
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _SavorRestaurantCard(
                          cook: result.data[i],
                          onTap: () => context
                              .go('/restaurant/${result.data[i].id}'),
                        ),
                      ),
                      childCount: result.data.length,
                    ),
                  );
                },
              ),
            ),

            // ── Populaire en ce Moment ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SectionHeader(
                  title: 'Populaire en ce Moment',
                  onSeeAll: () => context.go('/search'),
                  trailing: const Icon(Icons.arrow_forward,
                      color: AppColors.primaryVibrant, size: 20),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: dailyAsync.when(
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _PopularItemShimmer(),
                    ),
                    childCount: 4,
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Text(e.toString(),
                      style: TextStyle(fontFamily: 'NunitoSans',
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
                data: (result) {
                  if (result.data.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PopularDishRow(item: result.data[i]),
                      ),
                      childCount: result.data.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═══════════════════════════════════════════════════════════════════════════════

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.onSeeAll, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: AppColors.onSurface,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: trailing ??
                Text(
                  'Tout Voir',
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryVibrant,
                  ),
                ),
          ),
      ],
    );
  }
}

// ── Categories (cercles style Savor) ────────────────────────────────────────

class _SavorCategoriesRow extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  static const _categoryData = <String, (String, Color)>{
    'Tous': ('🍽️', AppColors.primaryVibrant),
    'Ndole': ('🥘', Color(0xFF006B23)),
    'Poulet DG': ('🍗', Color(0xFFA03C00)),
    'Grilled Fish': ('🐟', Color(0xFF705900)),
    'Koki': ('🫘', Color(0xFF884D00)),
    'viandes': ('🍖', Color(0xFFA03C00)),
    'poissons': ('🐟', Color(0xFF705900)),
    'legumes': ('🥬', Color(0xFF006B23)),
    'grillades': ('🍗', Color(0xFFA03C00)),
    'soupes': ('🥘', Color(0xFF884D00)),
    'boissons': ('🥤', Color(0xFF705900)),
    'riz': ('🍚', Color(0xFF884D00)),
    'plantain': ('🍌', Color(0xFF705900)),
    'desserts': ('🍰', Color(0xFFA03C00)),
    'snacks': ('🥙', Color(0xFF884D00)),
  };

  const _SavorCategoriesRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  (String, Color) _getData(String cat) {
    final key = cat.toLowerCase();
    for (final entry in _categoryData.entries) {
      if (entry.key.toLowerCase() == key) return entry.value;
    }
    return ('🍽️', AppColors.primaryVibrant);
  }

  @override
  Widget build(BuildContext context) {
    final items = ['Tous', ...categories];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, i) {
          final label = items[i];
          final isAll = label == 'Tous';
          final isActive = isAll ? selected == null : selected == label;
          final (emoji, tint) = _getData(label);

          return GestureDetector(
            onTap: () => onSelect(isAll ? null : label),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(
                            color: AppColors.primaryVibrant, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive
                        ? AppColors.primaryVibrant
                        : AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Restaurant Card (style Savor : large, premium) ──────────────────────────

class _SavorRestaurantCard extends StatelessWidget {
  final Cook cook;
  final VoidCallback onTap;

  const _SavorRestaurantCard({required this.cook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cook.isOpenNow ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image zone (60% ~170px)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Center(
                      child:
                          Text('👩\u200d🍳', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                ),
                // Badge LIVRAISON RAPIDE
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryVibrant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'LIVRAISON RAPIDE',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Badge ICONIC
                if (cook.avgRating >= 4.5)
                  Positioned(
                    left: 140,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'ICONIC',
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Badge note dorée
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryVibrant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          cook.avgRating.toStringAsFixed(1),
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Overlay fermé
                if (!cook.isOpenNow)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      color: AppColors.overlay,
                      child: Center(
                        child: Text(
                          'FERME',
                          style: TextStyle(fontFamily: 'NunitoSans',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Infos sous l'image
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cook.displayName,
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cook.specialty.take(3).join(' · '),
                          style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'IDEAL AVEC DU BOBOLO',
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '25-35 min',
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryVibrant,
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
}

// ── Popular Dish Row ────────────────────────────────────────────────────────

class _PopularDishRow extends ConsumerWidget {
  final MenuItem item;

  const _PopularDishRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final isBestSeller = (item.isDailySpecial);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image ronde
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stack) => Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                            child: Text('🍲',
                                style: TextStyle(fontSize: 24))),
                      ),
                    )
                  : Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                          child: Text('🍲',
                              style: TextStyle(fontSize: 24))),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom + description + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontFamily: 'Montserrat',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (isBestSeller)
                      _Badge(
                          label: 'MEILLEURE VENTE',
                          color: AppColors.primaryVibrant),
                    if (item.category != null && !isBestSeller)
                      _Badge(
                          label: 'CHOIX DU CHEF',
                          color: AppColors.tertiary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Prix + bouton ajouter
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.priceXaf.toFcfa(),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              if (item.canOrder)
                GestureDetector(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '+ Ajouter',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Badge widget ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'NunitoSans',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Error Card ──────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('😕', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'NunitoSans',
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Reessayer',
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;

  const _EmptyState({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            message,
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

// ── Shimmers ────────────────────────────────────────────────────────────────

class _RestaurantCardShimmer extends StatelessWidget {
  const _RestaurantCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: double.infinity, height: 170, borderRadius: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 180, height: 18, borderRadius: 8),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularItemShimmer extends StatelessWidget {
  const _PopularItemShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          ShimmerBox(width: 60, height: 60, borderRadius: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBox(width: 100, height: 12, borderRadius: 6),
              ],
            ),
          ),
          ShimmerBox(width: 70, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}
