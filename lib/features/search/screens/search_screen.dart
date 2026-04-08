import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/data/home_repository.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<MenuItem> _menuResults = [];
  List<Cook> _cookResults = [];
  String? _error;
  String _activeFilter = 'Note';

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await SecureStorage.getSearchHistory();
    if (!mounted) return;
    setState(() => _recentSearches = history);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
    if (value.trim().isEmpty) {
      setState(() {
        _menuResults = [];
        _cookResults = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = HomeRepository();
    await SecureStorage.addSearchHistory(query);
    final updated = await SecureStorage.getSearchHistory();
    if (mounted) setState(() => _recentSearches = updated);
    try {
      final results = await Future.wait([
        repo.getMenuItems(search: query, limit: 10),
        repo.getCooks(search: query, limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _menuResults = (results[0] as PaginatedResult<MenuItem>).data;
        _cookResults = (results[1] as PaginatedResult<Cook>).data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        onChanged: _onChanged,
                        style: TextStyle(fontFamily: 'NunitoSans',
                            fontSize: 15, color: AppColors.onSurface),
                        cursorColor: AppColors.primaryVibrant,
                        decoration: InputDecoration(
                          hintText: 'Plat, cuisinière, spécialité...',
                          hintStyle: TextStyle(fontFamily: 'NunitoSans',
                              fontSize: 15, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textTertiary, size: 22),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: AppColors.textTertiary, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryVibrant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: _query.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDiscoveryContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search Results ────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: MenuItemShimmer(),
          ),
        ),
      );
    }

    if (_error != null) {
      return NyamaErrorWidget(
        message: _error!,
        onRetry: () => _search(_query),
      );
    }

    final hasResults = _menuResults.isNotEmpty || _cookResults.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$_query"',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_menuResults.isNotEmpty) ...[
          _SectionTitle(title: 'Plats', count: _menuResults.length),
          ..._menuResults.map((item) => _MenuResultTile(item: item)),
          const SizedBox(height: 8),
        ],
        if (_cookResults.isNotEmpty) ...[
          _SectionTitle(title: 'Cuisinières', count: _cookResults.length),
          ..._cookResults.map((cook) => _CookResultTile(cook: cook)),
        ],
      ],
    );
  }

  // ─── Discovery Content (empty query) ───────────────────────────────────

  Widget _buildDiscoveryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Recherches Récentes ──────────────────────────────────
          Text(
            'Recherches Récentes',
            style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _controller.text = search;
                  _onChanged(search);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    search,
                    style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Explorer les Régions ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explorer les Régions',
                style: TextStyle(fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'Voir la Carte',
                style: TextStyle(fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryVibrant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RegionCard(
                  label: 'Littoral',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RegionCard(
                  label: 'Centre',
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Catégories ───────────────────────────────────────────
          Text(
            'Catégories',
            style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _CategoryCard(
                label: 'Grillades',
                subtitle: 'Fumé & Savoureux',
                color: Color(0xFF8B4513),
              ),
              _CategoryCard(
                label: 'Ragouts Traditionnels',
                subtitle: '',
                color: Color(0xFF2E7D32),
              ),
              _CategoryCard(
                label: 'Restauration Rapide',
                subtitle: '',
                color: Color(0xFFE65100),
              ),
              _CategoryCard(
                label: 'Desserts',
                subtitle: 'Sucré & Fruité',
                color: Color(0xFF6A1B9A),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Meilleurs Choix à Proximité ──────────────────────────
          Text(
            'Meilleurs Choix à Proximité',
            style: TextStyle(fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: ['Prix', 'Temps', 'Note'].map((filter) {
              final isActive = _activeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeFilter = filter),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: isActive
                          ? Border.all(
                              color: AppColors.primaryVibrant, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.primaryVibrant
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Nearby restaurant cards (placeholder data)
          const _NearbyRestaurantCard(
            name: 'Chez Mama Ngono',
            description: 'Cuisine traditionnelle du Littoral',
            rating: 4.8,
            deliveryTime: '25-35 min',
            priceRange: '2 500 - 8 000 CFA',
            hasFreeDelivery: true,
            bgColor: Color(0xFF5D4037),
          ),
          const SizedBox(height: 16),
          const _NearbyRestaurantCard(
            name: 'Le Foyer Bamiléké',
            description: 'Spécialités de l\'Ouest Cameroun',
            rating: 4.6,
            deliveryTime: '30-45 min',
            priceRange: '3 000 - 10 000 CFA',
            hasFreeDelivery: false,
            bgColor: Color(0xFF33691E),
          ),
          const SizedBox(height: 16),
          const _NearbyRestaurantCard(
            name: 'Grillades du Port',
            description: 'Poissons grillés & braisés',
            rating: 4.9,
            deliveryTime: '20-30 min',
            priceRange: '1 500 - 6 000 CFA',
            hasFreeDelivery: true,
            bgColor: Color(0xFFBF360C),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Region Card ─────────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  final String label;
  final Color color;

  const _RegionCard({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Card ───────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;

  const _CategoryCard({
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'NunitoSans',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nearby Restaurant Card ──────────────────────────────────────────────

class _NearbyRestaurantCard extends StatelessWidget {
  final String name;
  final String description;
  final double rating;
  final String deliveryTime;
  final String priceRange;
  final bool hasFreeDelivery;
  final Color bgColor;

  const _NearbyRestaurantCard({
    required this.name,
    required this.description,
    required this.rating,
    required this.deliveryTime,
    required this.priceRange,
    required this.hasFreeDelivery,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      bgColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.restaurant_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
              // Rating badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVibrant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Free delivery badge
              if (hasFreeDelivery)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryVibrant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LIVRAISON GRATUITE',
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryVibrant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'NunitoSans',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      deliveryTime,
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.payments_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      priceRange,
                      style: TextStyle(fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

// ─── Section Title ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu Result Tile ────────────────────────────────────────────────────

class _MenuResultTile extends StatelessWidget {
  final MenuItem item;

  const _MenuResultTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          height: 56,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, _) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Icon(Icons.restaurant,
                        color: AppColors.textTertiary),
                  ),
                )
              : Container(
                  color: AppColors.surfaceContainerLow,
                  child: const Icon(Icons.restaurant,
                      color: AppColors.textTertiary),
                ),
        ),
      ),
      title: Text(item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'NunitoSans',fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        item.cook?.displayName ?? '',
        style:
            TextStyle(fontFamily: 'NunitoSans',color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        item.priceXaf.toFcfa(),
        style: const TextStyle(
            fontFamily: 'SpaceMono',
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 13),
      ),
      onTap: item.cook != null
          ? () => context.go('/restaurant/${item.cook!.id}')
          : null,
    );
  }
}

// ─── Cook Result Tile ────────────────────────────────────────────────────

class _CookResultTile extends StatelessWidget {
  final Cook cook;

  const _CookResultTile({required this.cook});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          cook.displayName.isNotEmpty ? cook.displayName[0].toUpperCase() : '?',
          style: TextStyle(fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(cook.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'NunitoSans',fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        cook.specialty.take(2).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(fontFamily: 'NunitoSans',color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 14, color: AppColors.secondaryVibrant),
          const SizedBox(width: 3),
          Text(
            cook.avgRating.toStringAsFixed(1),
            style:
                TextStyle(fontFamily: 'NunitoSans',fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
      onTap: () => context.go('/restaurant/${cook.id}'),
    );
  }
}
