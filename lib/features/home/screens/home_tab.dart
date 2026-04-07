import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/fcfa_formatter.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/models/cook.dart';
import '../data/models/menu_item.dart';
import '../providers/home_provider.dart';

// ─── Design tokens (Culinary Signature) ────────────────────────────────────
const _kCreme = Color(0xFFF5F5F0);
const _kWhite = Color(0xFFFFFFFF);
const _kOrange = Color(0xFFF57C20);
const _kCharcoal = Color(0xFF3D3D3D);
const _kForest = Color(0xFF1B4332);
const _kRed = Color(0xFFE8413C);
const _kSecondary = Color(0xFF6B7280);

const _kCardShadow = [
  BoxShadow(
    color: Color(0x08000000),
    offset: Offset(0, 4),
    blurRadius: 12,
  ),
];

// ─── Mock data (fallback si l'API ne répond pas) ───────────────────────────
const _mockMenu = <_MockDish>[
  _MockDish('Ndolé Viande', 2500,
      'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=300&h=300&fit=crop'),
  _MockDish('Poisson Braisé', 4000,
      'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=300&h=300&fit=crop'),
  _MockDish('Beignets Haricot', 1000,
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300&h=300&fit=crop'),
  _MockDish('Salade Mixte', 1500,
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&h=300&fit=crop'),
];

const _mockCooks = <_MockCook>[
  _MockCook('Chez Mama Ngono', 'Akwa, Douala', 4.8, '25-35 min',
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&h=300&fit=crop'),
  _MockCook('La Table de Bonas', 'Bonapriso, Douala', 4.7, '30-40 min',
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&h=300&fit=crop'),
];

const _mockCategories = [
  'Plats traditionnels',
  'Grillades',
  'Beignets',
  'Poissons',
  'Boissons',
];

class _MockDish {
  final String name;
  final int price;
  final String img;
  const _MockDish(this.name, this.price, this.img);
}

class _MockCook {
  final String name;
  final String area;
  final double rating;
  final String eta;
  final String img;
  const _MockCook(this.name, this.area, this.rating, this.eta, this.img);
}

// ─── Screen ────────────────────────────────────────────────────────────────
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String _activeCategory = _mockCategories.first;

  @override
  Widget build(BuildContext context) {
    final cooksAsync = ref.watch(cooksProvider);
    final menuAsync = ref.watch(filteredMenuItemsProvider);

    final cooks = cooksAsync.maybeWhen(
      data: (r) => r.data,
      orElse: () => const <Cook>[],
    );
    final menu = menuAsync.maybeWhen(
      data: (r) => r.data,
      orElse: () => const <MenuItem>[],
    );

    return Scaffold(
      backgroundColor: _kCreme,
      body: RefreshIndicator(
        color: _kOrange,
        onRefresh: () async {
          ref.invalidate(cooksProvider);
          ref.invalidate(filteredMenuItemsProvider);
          ref.invalidate(dailySpecialsProvider);
        },
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(top: 88, bottom: 24),
              children: [
                const SizedBox(height: 8),
                _SearchBar(),
                const SizedBox(height: 20),
                _DailyBanner(),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Catégories', action: 'Tout voir'),
                const SizedBox(height: 12),
                _CategoryChips(
                  active: _activeCategory,
                  onTap: (c) => setState(() => _activeCategory = c),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Restaurants près de toi'),
                const SizedBox(height: 12),
                _RestaurantsRow(cooks: cooks),
                const SizedBox(height: 24),
                _SectionHeader(
                    title: 'Plats populaires', action: 'Le goût de chez nous'),
                const SizedBox(height: 12),
                _PopularGrid(items: menu),
                const SizedBox(height: 16),
              ],
            ),
            const _Header(),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: _kCreme.withValues(alpha: 0.7),
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&h=200&fit=crop'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bonjour Arthur 👋',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kCharcoal,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: _kOrange, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'Douala, Akwa',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 12,
                            color: _kSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _kCardShadow,
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        color: _kCharcoal, size: 22),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _kRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kWhite, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _kCardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: _kSecondary.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cherche un plat, un restaurant...',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                  color: _kSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily banner ──────────────────────────────────────────────────────────
class _DailyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 192,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=600&h=400&fit=crop',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: _kCharcoal),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 12, color: _kWhite),
                      SizedBox(width: 4),
                      Text(
                        'DU JOUR',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: _kWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le Poulet DG Royal',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kWhite,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Une explosion de saveurs camerounaises',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: Color(0xCCFFFFFF),
                      ),
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

// ─── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kCharcoal,
            ),
          ),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kOrange,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Categories ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final String active;
  final ValueChanged<String> onTap;
  const _CategoryChips({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mockCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _mockCategories[i];
          final isActive = c == active;
          return GestureDetector(
            onTap: () => onTap(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? _kOrange : _kWhite,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : _kCardShadow,
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _kWhite : _kCharcoal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Restaurants row ───────────────────────────────────────────────────────
class _RestaurantsRow extends StatelessWidget {
  final List<Cook> cooks;
  const _RestaurantsRow({required this.cooks});

  @override
  Widget build(BuildContext context) {
    final useMock = cooks.isEmpty;
    final count = useMock ? _mockCooks.length : cooks.length;

    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (useMock) {
            final m = _mockCooks[i];
            return _RestaurantCard(
              name: m.name,
              area: m.area,
              rating: m.rating,
              eta: m.eta,
              img: m.img,
            );
          }
          final c = cooks[i];
          return _RestaurantCard(
            name: c.displayName,
            area: c.quarter != null
                ? '${c.quarter!.name}, ${c.quarter!.city}'
                : (c.landmark ?? 'Douala'),
            rating: c.avgRating,
            eta: '25-35 min',
            img: _mockCooks[i % _mockCooks.length].img,
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final String name;
  final String area;
  final double rating;
  final String eta;
  final String img;
  const _RestaurantCard({
    required this.name,
    required this.area,
    required this.rating,
    required this.eta,
    required this.img,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  img,
                  height: 144,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 144,
                    color: _kCreme,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Color(0xFFD4A017), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kCharcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          color: _kSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kCreme,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time,
                              size: 11, color: _kSecondary),
                          const SizedBox(width: 3),
                          Text(
                            eta,
                            style: const TextStyle(
                              fontFamily: 'NunitoSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Popular grid ──────────────────────────────────────────────────────────
class _PopularGrid extends ConsumerWidget {
  final List<MenuItem> items;
  const _PopularGrid({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMock = items.isEmpty;
    final count = useMock ? _mockMenu.length : items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, i) {
          if (useMock) {
            final m = _mockMenu[i];
            return _DishCard(
              name: m.name,
              priceXaf: m.price,
              img: m.img,
              onAdd: () => ref.read(cartProvider.notifier).addItem(
                    CartItem(
                      menuItemId: 'mock-$i',
                      name: m.name,
                      priceXaf: m.price,
                      quantity: 1,
                      cookId: 'mock-cook',
                      cookName: 'Chez Mama Ngono',
                      imageUrl: m.img,
                    ),
                  ),
            );
          }
          final it = items[i];
          return _DishCard(
            name: it.name,
            priceXaf: it.priceXaf,
            img: it.imageUrl ?? _mockMenu[i % _mockMenu.length].img,
            onAdd: () => ref.read(cartProvider.notifier).addItem(
                  CartItem(
                    menuItemId: it.id,
                    name: it.name,
                    priceXaf: it.priceXaf,
                    quantity: 1,
                    cookId: it.cook?.id ?? '',
                    cookName: it.cook?.displayName ?? '',
                    imageUrl: it.imageUrl,
                  ),
                ),
          );
        },
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final String name;
  final int priceXaf;
  final String img;
  final VoidCallback onAdd;
  const _DishCard({
    required this.name,
    required this.priceXaf,
    required this.img,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: _kCreme),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: _kForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: _kWhite, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kCharcoal,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              FcfaFormatter.format(priceXaf),
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
