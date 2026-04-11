import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/data/home_repository.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';

// ─── Trending item model ────────────────────────────────────────────────────
class _TrendingDish {
  final String name;
  final String orders;
  final IconData icon;
  const _TrendingDish(this.name, this.orders, this.icon);
}

const _trendingDishes = [
  _TrendingDish('Ndole complet', '312 commandes ce mois', Icons.local_fire_department_rounded),
  _TrendingDish('Poulet DG', '187 commandes', Icons.local_fire_department_rounded),
  _TrendingDish('Poisson braise', '156 commandes', Icons.local_fire_department_rounded),
  _TrendingDish('Eru & Waterfufu', '134 commandes', Icons.local_fire_department_rounded),
  _TrendingDish('Achu & Yellow Soup', '98 commandes', Icons.local_fire_department_rounded),
];

// ─── Category model ─────────────────────────────────────────────────────────
class _CategoryItem {
  final String label;
  final String image;
  final String searchTerm;
  const _CategoryItem(this.label, this.image, this.searchTerm);
}

const _categories = [
  _CategoryItem('Plats traditionnels', 'assets/images/mock/ndole.jpg', 'traditionnel'),
  _CategoryItem('Grillades', 'assets/images/mock/grillades-jardin-d-olympe.jpg', 'Grillades'),
  _CategoryItem('Poissons', 'assets/images/mock/poisson.jpg', 'Poisson'),
  _CategoryItem('Boissons', 'assets/images/mock/Boissons.jpg', 'Boisson'),
  _CategoryItem('Desserts', 'assets/images/mock/dessert.jpg', 'Desserts'),
  _CategoryItem('Fast-food', 'assets/images/mock/fast-food.jpg', 'Rapide'),
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<MenuItem> _menuResults = [];
  List<Cook> _cookResults = [];
  String? _error;
  List<String> _recentSearches = [];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _focus.addListener(() {
      if (_focus.hasFocus && _query.isEmpty) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
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
    _scrollController.dispose();
    _pulseController.dispose();
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
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.collapsed(offset: query.length);
    }
    setState(() {
      _query = query;
      _isLoading = true;
      _error = null;
    });

    final repo = HomeRepository();
    await SecureStorage.addSearchHistory(query);
    final updated = await SecureStorage.getSearchHistory();
    if (mounted) setState(() => _recentSearches = updated);

    try {
      final results = await Future.wait([
        repo.getMenuItems(search: query, limit: 15),
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

  Future<void> _removeHistoryItem(String item) async {
    await SecureStorage.removeSearchItem(item);
    final updated = await SecureStorage.getSearchHistory();
    if (mounted) setState(() => _recentSearches = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
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

  // ─── Search Bar ─────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.creme,
        boxShadow: _query.isNotEmpty
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.charcoal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  color: AppColors.charcoal,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'Plat, cuisiniere, specialite...',
                  hintStyle: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  prefixIcon: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: _focus.hasFocus ? AppColors.primary : AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _onChanged('');
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Discovery Content ──────────────────────────────────────────────────
  Widget _buildDiscoveryContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Recent Searches ──────────────────────────────────────
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recherches recentes',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await SecureStorage.clearSearchHistory();
                    setState(() => _recentSearches = []);
                  },
                  child: const Text(
                    'Effacer',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceLow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          search,
                          style: const TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeHistoryItem(search),
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],

          // ── Trending ──────────────────────────────────────────────
          const Text(
            'Tendances du moment',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: List.generate(_trendingDishes.length, (i) {
                final dish = _trendingDishes[i];
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        _controller.text = dish.name;
                        _onChanged(dish.name);
                      },
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? const Radius.circular(16) : Radius.zero,
                        bottom: i == _trendingDishes.length - 1 ? const Radius.circular(16) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dish.name,
                                    style: const TextStyle(
                                      fontFamily: 'NunitoSans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dish.orders,
                                    style: const TextStyle(
                                      fontFamily: 'NunitoSans',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.trending_up_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
                          ],
                        ),
                      ),
                    ),
                    if (i < _trendingDishes.length - 1)
                      Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.surfaceLow),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 28),

          // ── Categories Grid ──────────────────────────────────────
          const Text(
            'Categories',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: (MediaQuery.of(context).size.width / 2 - 22) / 120,
            children: _categories.map((cat) {
              return GestureDetector(
                onTap: () {
                  _controller.text = cat.searchTerm;
                  _onChanged(cat.searchTerm);
                },
                child: SizedBox(
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          cat.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceLow),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Text(
                            cat.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Explorer les Regions ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explorer les Regions',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/search/map'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Carte',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RegionCard(label: 'Douala', image: 'assets/images/mock/douala.jpg', onTap: () => _search('Douala'))),
              const SizedBox(width: 10),
              Expanded(child: _RegionCard(label: 'Yaounde', image: 'assets/images/mock/Yaoundé.jpeg', onTap: () => _search('Yaounde'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _RegionCard(label: 'Bafoussam', image: 'assets/images/mock/eru-specialite-camerounaise.jpg', onTap: () => _search('Bafoussam'))),
              const SizedBox(width: 10),
              Expanded(child: _RegionCard(label: 'Limbe', image: 'assets/images/mock/limbe-2-2.jpg', onTap: () => _search('Limbe'))),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Search Results ─────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(5, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _ResultShimmer(),
        )),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.errorRed),
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur de connexion',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _search(_query),
                child: const Text('Reessayer', style: TextStyle(fontFamily: 'NunitoSans', fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final hasResults = _menuResults.isNotEmpty || _cookResults.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.search_off_rounded, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun resultat pour "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.charcoal),
              ),
              const SizedBox(height: 8),
              const Text(
                'Essayez un autre mot-cle ou\nnaviguez dans les categories',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        // ── Cook results (horizontal scroll) ─────────────────────
        if (_cookResults.isNotEmpty) ...[
          const _SectionHeader(title: 'Cuisinieres', icon: Icons.person_rounded),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cookResults.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _CookChip(cook: _cookResults[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Menu results ─────────────────────────────────────────
        if (_menuResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const _SectionHeader(title: 'Plats', icon: Icons.restaurant_menu_rounded),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_menuResults.length} resultat${_menuResults.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_menuResults.length, (i) => _MenuResultCard(item: _menuResults[i])),
        ],
      ],
    );
  }
}

// ─── Region Card ────────────────────────────────────────────────────────────
class _RegionCard extends StatelessWidget {
  final String label;
  final String image;
  final VoidCallback? onTap;

  const _RegionCard({required this.label, required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceLow),
              ),
              Container(color: Colors.black.withValues(alpha: 0.4)),
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
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

// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cook Chip (horizontal result) ──────────────────────────────────────────
class _CookChip extends StatelessWidget {
  final Cook cook;

  const _CookChip({required this.cook});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/restaurant/${cook.id}'),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                cook.displayName.isNotEmpty ? cook.displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                cook.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                const SizedBox(width: 2),
                Text(
                  cook.avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Result Card ───────────────────────────────────────────────────────
class _MenuResultCard extends StatelessWidget {
  final MenuItem item;

  const _MenuResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dish/${item.id}', extra: item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.surfaceLow),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceLow,
                          child: const Icon(Icons.restaurant_rounded, color: AppColors.textTertiary, size: 24),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceLow,
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.textTertiary, size: 24),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isDailySpecial)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SPECIAL',
                            style: TextStyle(fontFamily: 'NunitoSans', fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.charcoal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.cook != null)
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.cook!.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                        if (item.cook!.avgRating > 0) ...[
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text(
                            item.cook!.avgRating.toStringAsFixed(1),
                            style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        item.priceXaf.toFcfa(),
                        style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                      ),
                      const Spacer(),
                      if (item.prepTimeMin != null)
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textTertiary),
                            const SizedBox(width: 3),
                            Text(
                              '${item.prepTimeMin} min',
                              style: const TextStyle(fontFamily: 'NunitoSans', fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
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

// ─── Result Shimmer ─────────────────────────────────────────────────────────
class _ResultShimmer extends StatelessWidget {
  const _ResultShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 72, height: 72, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 12, borderRadius: 6),
                SizedBox(height: 8),
                ShimmerBox(width: 80, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
