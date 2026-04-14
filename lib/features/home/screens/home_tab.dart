
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/translations.dart';
import '../../../core/services/auth_gate.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/cart_bounce_controller.dart';
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
const _kAllCategory = 'Tout';
const _mockCategories = <String>[
  _kAllCategory,
  'Plats traditionnels',
  'Grillades',
  'Beignets',
  'Poissons',
  'Boissons',
];

// Mots-clés associés à chaque catégorie pour filtrer les plats
const _categoryKeywords = <String, List<String>>{
  'Plats traditionnels': ['ndolé', 'ndole', 'eru', 'koki'],
  'Grillades': ['braisé', 'braise', 'poulet', 'grillade'],
  'Beignets': ['beignet', 'accra'],
  'Poissons': ['poisson', 'braisé', 'braise'],
  'Boissons': ['jus', 'folere', 'foléré', 'boisson'],
};

bool _dishMatchesCategory(String dishName, String category) {
  if (category == _kAllCategory) return true;
  final keywords = _categoryKeywords[category] ?? const <String>[];
  final n = dishName.toLowerCase();
  return keywords.any((k) => n.contains(k));
}

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

/// Quartiers connus — coordonnées approximatives pour la détection.
class _KnownQuartier {
  final String city;
  final String name;
  final double lat;
  final double lng;
  const _KnownQuartier(this.city, this.name, this.lat, this.lng);
}

const _knownQuartiers = <_KnownQuartier>[
  _KnownQuartier('Douala', 'Akwa', 4.0445, 9.6966),
  _KnownQuartier('Douala', 'Bonapriso', 4.0200, 9.6900),
  _KnownQuartier('Douala', 'Deido', 4.0550, 9.6850),
  _KnownQuartier('Douala', 'Bonanjo', 4.0300, 9.7050),
  _KnownQuartier('Yaoundé', 'Bastos', 3.8800, 11.5100),
];

class _LocationInfo {
  final String? city;
  final String? quartier;
  const _LocationInfo(this.city, this.quartier);
  bool get isResolved => quartier != null && quartier!.isNotEmpty;
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  String _activeCategory = _kAllCategory;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  final ValueNotifier<_LocationInfo> _location =
      ValueNotifier(const _LocationInfo(null, null));

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocateIfNeeded());
  }

  Future<void> _autoLocateIfNeeded() async {
    try {
      final city = await SecureStorage.getCity();
      final quartier = await SecureStorage.getQuartier();
      if (quartier != null && quartier.isNotEmpty) {
        _location.value = _LocationInfo(city, quartier);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      final resolved = _resolveLocation(pos.latitude, pos.longitude);
      await SecureStorage.saveQuartier(resolved.city!, resolved.quartier!);
      if (mounted) _location.value = resolved;
    } catch (_) {
      // Silencieux : on garde "Localisation..." par défaut
    }
  }

  _LocationInfo _resolveLocation(double lat, double lng) {
    String city;
    if (lat >= 4.0 && lat <= 4.15) {
      city = 'Douala';
    } else if (lat >= 3.8 && lat <= 3.95) {
      city = 'Yaoundé';
    } else {
      city = 'Douala';
    }
    _KnownQuartier? best;
    double bestDist = double.infinity;
    for (final q in _knownQuartiers) {
      final dLat = q.lat - lat;
      final dLng = q.lng - lng;
      final d = math.sqrt(dLat * dLat + dLng * dLng);
      if (d < bestDist) {
        bestDist = d;
        best = q;
      }
    }
    return _LocationInfo(city, best?.name ?? 'Akwa');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cooksAsync = ref.watch(cooksProvider);
    final menuAsync = ref.watch(filteredMenuItemsProvider);

    final cooks = cooksAsync.maybeWhen(
      data: (r) => r.data,
      orElse: () => const <Cook>[],
    );
    final menuAll = menuAsync.maybeWhen(
      data: (r) => r.data,
      orElse: () => const <MenuItem>[],
    );
    final menu = _activeCategory == _kAllCategory
        ? menuAll
        : menuAll
            .where((m) => _dishMatchesCategory(m.name, _activeCategory))
            .toList();

    return Scaffold(
      backgroundColor: _kCreme,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Material(
          color: _kCreme,
          elevation: 0,
          child: _Header(location: _location),
        ),
      ),
      body: RefreshIndicator(
        color: _kOrange,
        onRefresh: () async {
          ref.invalidate(cooksProvider);
          ref.invalidate(filteredMenuItemsProvider);
          ref.invalidate(dailySpecialsProvider);
        },
        child: FadeTransition(
          opacity: _fade,
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              const SizedBox(height: 8),
              const _SearchBar(),
              const SizedBox(height: 20),
              const _DailyBanner(),
              const SizedBox(height: 28),
              _SectionHeader(title: t('categories', ref), action: t('see_all', ref)),
              const SizedBox(height: 12),
              _CategoryChips(
                active: _activeCategory,
                onTap: (c) => setState(() => _activeCategory = c),
              ),
              const SizedBox(height: 28),
              _SectionHeader(title: t('restaurants_nearby', ref)),
              const SizedBox(height: 12),
              _RestaurantsRow(cooks: cooks),
              const SizedBox(height: 28),
              _SectionHeader(
                  title: t('popular_dishes', ref)),
              const SizedBox(height: 16),
              _PopularGrid(items: menu, activeCategory: _activeCategory),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final ValueNotifier<_LocationInfo> location;
  const _Header({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(authStateProvider).isAuthenticated;
    final userName = ref.watch(authStateProvider).user?.name;
    return Container(
      color: _kCreme,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_kHPad, 12, _kHPad, 12),
          child: Row(
            children: [
              if (isAuth)
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
                )
              else
                TextButton(
                  onPressed: () => AuthGate.ensureAuthenticated(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _kOrange,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    t('login', ref),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kOrange,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isAuth
                          ? 'Bonjour ${(userName ?? '').isNotEmpty ? userName! : 'toi'} 👋'
                          : 'Bienvenue 👋',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<_LocationInfo>(
                      valueListenable: location,
                      builder: (context, info, _) {
                        final hasLoc = info.isResolved;
                        final label = hasLoc
                            ? (info.city != null && info.city!.isNotEmpty
                                ? '${info.city}, ${info.quartier}'
                                : info.quartier!)
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
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t('no_notifications', ref)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
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
class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  t('search_placeholder', ref),
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
class _DailyBanner extends ConsumerWidget {
  const _DailyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kHPad),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/search'),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 12, color: _kWhite),
                    const SizedBox(width: 4),
                    Text(
                      t('du_jour', ref),
                      style: const TextStyle(
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
              id: 'restaurant-${i + 1}',
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
          final prepMin = c.prepTimeAvgMin ?? 25;
          return _RestaurantCard(
            id: c.id,
            name: c.displayName,
            area: c.quarter != null
                ? '${c.quarter!.name}, ${c.quarter!.city}'
                : (c.landmark ?? 'Douala'),
            rating: c.avgRating,
            eta: '$prepMin-${prepMin + 10} min',
            gradient: m.gradient,
            imageAsset: m.image,
            specialty: c.specialty.isNotEmpty ? c.specialty.first : null,
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final String id;
  final String name;
  final String area;
  final double rating;
  final String eta;
  final List<Color> gradient;
  final String imageAsset;
  final String? specialty;
  const _RestaurantCard({
    required this.id,
    required this.name,
    required this.area,
    required this.rating,
    required this.eta,
    required this.gradient,
    required this.imageAsset,
    this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kWhite,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: 256,
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _kCardShadow,
        ),
        child: InkWell(
          onTap: () => context.push('/restaurant/$id'),
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
                if (specialty != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    specialty!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
        ),
      ),
    );
  }
}

// ─── Popular grid ──────────────────────────────────────────────────────────
class _PopularGrid extends ConsumerWidget {
  final List<MenuItem> items;
  final String activeCategory;
  const _PopularGrid({required this.items, required this.activeCategory});

  void _showAddedSnack(BuildContext context, WidgetRef ref, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: _kWhite, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('$name ${t('added_to_cart', ref)}')),
            ],
          ),
          backgroundColor: _kForest,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMock = items.isEmpty;
    final mockFiltered = _mockDishes
        .where((d) => _dishMatchesCategory(d.name, activeCategory))
        .toList();
    final count = useMock ? mockFiltered.length : items.length;

    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kHPad, vertical: 24),
        child: Center(
          child: Text(
            t('no_category', ref),
            style: TextStyle(color: _kMuted.withValues(alpha: 0.8)),
          ),
        ),
      );
    }

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
            final m = mockFiltered[i];
            const cookId = 'restaurant-1';
            return _DishCard(
              name: m.name,
              priceXaf: m.price,
              gradient: m.gradient,
              imageAsset: m.image,
              onTap: () => context.push('/dish/mock-${m.name}'),
              onAdd: () {
                ref.read(cartProvider.notifier).addItem(
                      CartItem(
                        menuItemId: 'mock-${m.name}',
                        name: m.name,
                        priceXaf: m.price,
                        quantity: 1,
                        cookId: cookId,
                        cookName: 'Maman Catherine',
                      ),
                    );
                _showAddedSnack(context, ref, m.name);
              },
            );
          }
          final it = items[i];
          final cookId = it.cook?.id ?? '';
          return _DishCard(
            name: it.name,
            priceXaf: it.priceXaf,
            gradient: _dishGradients[i % _dishGradients.length],
            imageAsset: _mockDishes[i % _mockDishes.length].image,
            onTap: () => context.push('/dish/${it.id}'),
            onAdd: () {
              ref.read(cartProvider.notifier).addItem(
                    CartItem(
                      menuItemId: it.id,
                      name: it.name,
                      priceXaf: it.priceXaf,
                      quantity: 1,
                      cookId: cookId,
                      cookName: it.cook?.displayName ?? '',
                      imageUrl: it.imageUrl,
                    ),
                  );
              _showAddedSnack(context, ref, it.name);
            },
          );
        },
      ),
    );
  }
}

class _DishCard extends StatefulWidget {
  final String name;
  final int priceXaf;
  final List<Color> gradient;
  final String imageAsset;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  const _DishCard({
    required this.name,
    required this.priceXaf,
    required this.gradient,
    required this.imageAsset,
    required this.onAdd,
    this.onTap,
  });

  @override
  State<_DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<_DishCard> {
  final GlobalKey _addBtnKey = GlobalKey();

  Future<void> _flyToCart() async {
    final ctx = _addBtnKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context);
    if (box == null) return;
    final start = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height / 2),
    );
    final screen = MediaQuery.of(context).size;
    final safe = MediaQuery.of(context).padding.bottom;
    final end = Offset(screen.width / 2, screen.height - safe - 60);

    final entry = OverlayEntry(
      builder: (_) => _FlyToCartOverlay(
        start: start,
        end: end,
        imageAsset: widget.imageAsset,
        gradient: widget.gradient,
      ),
    );
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    entry.remove();
    triggerCartBounce();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final priceXaf = widget.priceXaf;
    final gradient = widget.gradient;
    final imageAsset = widget.imageAsset;
    final onTap = widget.onTap;
    return Material(
      color: _kWhite,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _kCardShadow,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
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
                  child: _AddButton(
                    key: _addBtnKey,
                    onAdd: () {
                      _flyToCart();
                      widget.onAdd();
                    },
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
          ),
        ),
      ),
    );
  }
}

// ─── Add button (scale on press) ───────────────────────────────────────────
class _AddButton extends StatefulWidget {
  final VoidCallback onAdd;
  const _AddButton({super.key, required this.onAdd});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.9);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onAdd,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
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
    );
  }
}

// ─── Fly-to-cart overlay ───────────────────────────────────────────────────
class _FlyToCartOverlay extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String imageAsset;
  final List<Color> gradient;
  const _FlyToCartOverlay({
    required this.start,
    required this.end,
    required this.imageAsset,
    required this.gradient,
  });

  @override
  State<_FlyToCartOverlay> createState() => _FlyToCartOverlayState();
}

class _FlyToCartOverlayState extends State<_FlyToCartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_ctrl.value);
          final x = widget.start.dx + (widget.end.dx - widget.start.dx) * t;
          // Parabole : monte d'abord (soustraction d'une bosse) puis descend
          final straightY =
              widget.start.dy + (widget.end.dy - widget.start.dy) * t;
          final peak = 120.0;
          final bump = math.sin(t * math.pi) * peak;
          final y = straightY - bump;
          final scale = 1.0 - 0.3 * t;
          final opacity = 1.0 - (t * 0.2);
          return Positioned(
            left: x - 20,
            top: y - 20,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
