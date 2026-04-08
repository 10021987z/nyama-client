import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/models/cook.dart';
import '../data/models/menu_item.dart';
import '../providers/home_provider.dart';

// ─── Design tokens (Culinary Signature v2) ─────────────────────────────────
const _kCreme = Color(0xFFF5F5F0);
const _kWhite = Color(0xFFFFFFFF);
const _kInk = Color(0xFF1A1C19);
const _kCharcoal = Color(0xFF3D3D3D);
const _kMuted = Color(0xFF5F5E5E);
const _kOrange = Color(0xFFF57C20);
const _kOrangeDeep = Color(0xFF994700);
const _kForest = Color(0xFF1B4332);
const _kRed = Color(0xFFE8413C);
const _kSoftBg = Color(0xFFEEEEE9);

const _kCardShadow = [
  BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 4),
    blurRadius: 12,
  ),
];

const _kHPad = 24.0;

// ─── Mock data ─────────────────────────────────────────────────────────────
const _mockCategories = <String>[
  'Plats traditionnels',
  'Grillades',
  'Beignets',
  'Poissons',
  'Boissons',
];

class _MockRestaurant {
  final String name;
  final String area;
  final double rating;
  final String eta;
  final List<Color> gradient;
  final String image;
  const _MockRestaurant(
      this.name, this.area, this.rating, this.eta, this.gradient, this.image);
}

const _mockRestaurants = <_MockRestaurant>[
  _MockRestaurant(
    'Maman Catherine',
    'Akwa, Douala',
    4.8,
    '25-35 min',
    [Color(0xFFF57C20), Color(0xFFD4A017)],
    'assets/images/mock/plats_camerounais.jpg',
  ),
  _MockRestaurant(
    'Le Grilladin d\'Akwa',
    'Bali, Douala',
    4.5,
    '30-40 min',
    [Color(0xFF1B4332), Color(0xFF2A9D8F)],
    'assets/images/mock/grillades_mix.jpg',
  ),
];

class _MockDish {
  final String name;
  final int price;
  final List<Color> gradient;
  final String image;
  const _MockDish(this.name, this.price, this.gradient, this.image);
}

const _mockDishes = <_MockDish>[
  _MockDish('Ndolé Viande', 2500, [Color(0xFF8B4513), Color(0xFFD2691E)],
      'assets/images/mock/ndole.jpg'),
  _MockDish('Poisson Braisé', 4000, [Color(0xFF2F4F4F), Color(0xFF5F9EA0)],
      'assets/images/mock/poisson_braise.jpg'),
  _MockDish('Beignets Haricot', 1000, [Color(0xFFDAA520), Color(0xFFF4A460)],
      'assets/images/mock/beignets.jpg'),
  _MockDish('Salade Mixte', 1500, [Color(0xFF2E8B57), Color(0xFF66CDAA)],
      'assets/images/mock/salade.jpg'),
];

// ─── Image with gradient fallback ──────────────────────────────────────────
class _AssetWithFallback extends StatelessWidget {
  final String assetPath;
  final List<Color> gradient;
  const _AssetWithFallback({required this.assetPath, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

const _dishGradients = <List<Color>>[
  [Color(0xFF8B4513), Color(0xFFD2691E)],
  [Color(0xFF2F4F4F), Color(0xFF5F9EA0)],
  [Color(0xFFDAA520), Color(0xFFF4A460)],
  [Color(0xFF2E8B57), Color(0xFF66CDAA)],
];

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

    final topPad = MediaQuery.of(context).padding.top;

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
              padding: EdgeInsets.only(top: topPad + 76, bottom: 32),
              children: [
                const SizedBox(height: 8),
                const _SearchBar(),
                const SizedBox(height: 20),
                const _DailyBanner(),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Catégories', action: 'Tout voir'),
                const SizedBox(height: 12),
                _CategoryChips(
                  active: _activeCategory,
                  onTap: (c) => setState(() => _activeCategory = c),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Restaurants près de toi'),
                const SizedBox(height: 12),
                _RestaurantsRow(cooks: cooks),
                const SizedBox(height: 28),
                const _SectionHeader(
                    title: 'Plats populaires',
                    action: 'Le goût de chez nous'),
                const SizedBox(height: 16),
                _PopularGrid(items: menu),
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
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: _kCreme.withValues(alpha: 0.7),
          padding: EdgeInsets.fromLTRB(_kHPad, top + 12, _kHPad, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/mock/logo_nyama.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _kWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bonjour Arthur 👋',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<List<String?>>(
                      future: Future.wait([
                        SecureStorage.getCity(),
                        SecureStorage.getQuartier(),
                      ]),
                      builder: (context, snap) {
                        final data = snap.data;
                        final city = data?[0];
                        final quartier = data?[1];
                        final hasLoc =
                            quartier != null && quartier.isNotEmpty;
                        final label = hasLoc
                            ? (city != null && city.isNotEmpty
                                ? '$city, $quartier'
                                : quartier)
                            : 'Localisation...';
                        return Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: _kOrange, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        );
                      },
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
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _kOrange,
                        shape: BoxShape.circle,
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
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/search'),
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
              const Icon(Icons.search, color: _kMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cherche un plat, un restaurant...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _kMuted.withValues(alpha: 0.5),
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

// ─── Daily banner ──────────────────────────────────────────────────────────
class _DailyBanner extends StatelessWidget {
  const _DailyBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Container(
        height: 192,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_kOrange, _kOrangeDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AssetWithFallback(
              assetPath: 'assets/images/mock/grillades_mix.jpg',
              gradient: [_kOrange, _kOrangeDeep],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 12, color: _kWhite),
                    SizedBox(width: 4),
                    Text(
                      'DU JOUR',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: _kWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
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
                    "L'équilibre parfait entre épices et douceur",
                    style: TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const Spacer(),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(
                fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: _kHPad),
        itemCount: _mockCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = _mockCategories[i];
          final isActive = c == active;
          return GestureDetector(
            onTap: () => onTap(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? _kOrange : _kWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : _kCardShadow,
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _kWhite : _kInk,
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
    final count = useMock ? _mockRestaurants.length : cooks.length;

    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kHPad),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          if (useMock) {
            final m = _mockRestaurants[i];
            return _RestaurantCard(
              name: m.name,
              area: m.area,
              rating: m.rating,
              eta: m.eta,
              gradient: m.gradient,
              imageAsset: m.image,
            );
          }
          final c = cooks[i];
          final m = _mockRestaurants[i % _mockRestaurants.length];
          return _RestaurantCard(
            name: c.displayName,
            area: c.quarter != null
                ? '${c.quarter!.name}, ${c.quarter!.city}'
                : (c.landmark ?? 'Douala'),
            rating: c.avgRating,
            eta: '25-35 min',
            gradient: m.gradient,
            imageAsset: m.image,
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
  final List<Color> gradient;
  final String imageAsset;
  const _RestaurantCard({
    required this.name,
    required this.area,
    required this.rating,
    required this.eta,
    required this.gradient,
    required this.imageAsset,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 144,
                  width: double.infinity,
                  child: _AssetWithFallback(
                    assetPath: imageAsset,
                    gradient: gradient,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kWhite.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                        ),
                      ),
                    ],
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
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kSoftBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: _kMuted),
                          const SizedBox(width: 3),
                          Text(
                            eta,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kMuted,
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
    final count = useMock ? _mockDishes.length : items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
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
            final m = _mockDishes[i];
            return _DishCard(
              name: m.name,
              priceXaf: m.price,
              gradient: m.gradient,
              imageAsset: m.image,
              onAdd: () => ref.read(cartProvider.notifier).addItem(
                    CartItem(
                      menuItemId: 'mock-$i',
                      name: m.name,
                      priceXaf: m.price,
                      quantity: 1,
                      cookId: 'mock-cook',
                      cookName: 'Maman Catherine',
                    ),
                  ),
            );
          }
          final it = items[i];
          return _DishCard(
            name: it.name,
            priceXaf: it.priceXaf,
            gradient: _dishGradients[i % _dishGradients.length],
            imageAsset: _mockDishes[i % _mockDishes.length].image,
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
  final List<Color> gradient;
  final String imageAsset;
  final VoidCallback onAdd;
  const _DishCard({
    required this.name,
    required this.priceXaf,
    required this.gradient,
    required this.imageAsset,
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
                  child: _AssetWithFallback(
                    assetPath: imageAsset,
                    gradient: gradient,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kForest,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: _kWhite, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
          ),
          const SizedBox(height: 2),
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
