import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../shared/widgets/cart_bounce_controller.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/data/models/menu_item.dart';
import '../../home/providers/home_provider.dart';

class DishDetailScreen extends ConsumerStatefulWidget {
  final String dishId;
  const DishDetailScreen({super.key, required this.dishId});

  @override
  ConsumerState<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends ConsumerState<DishDetailScreen> {
  int _quantity = 1;
  int _portionIdx = 0; // 0 Solo, 1 Duo, 2 Familial
  final Set<int> _sides = {};
  double _spice = 2;
  bool _isFav = false;

  static const _portions = ['Solo', 'Duo', 'Familial'];
  static const _portionMultipliers = [1.0, 1.8, 3.0];
  static const _sideOptions = ['Miondo', 'Plantain', 'Riz'];

  static const _mockReviews = [
    _Review('Awa M.', 5.0, 'Excellent ! Le meilleur ndolé de Douala.'),
    _Review('Jean P.', 4.5, 'Très bon, bien épicé. Livraison rapide.'),
    _Review('Sarah K.', 4.0, 'Bonne portion, je recommande.'),
  ];

  int _computePrice(int basePrice) {
    return (basePrice * _portionMultipliers[_portionIdx] * _quantity).round();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(filteredMenuItemsProvider);
    final allItems = menuAsync.maybeWhen(
      data: (r) => r.data,
      orElse: () => <MenuItem>[],
    );

    // Find the dish or use a mock
    MenuItem? dish;
    for (final item in allItems) {
      if (item.id == widget.dishId) {
        dish = item;
        break;
      }
    }

    // Mock fallback
    final name = dish?.name ?? 'Ndolé Viande';
    final description = dish?.description ??
        'Plat traditionnel camerounais à base de feuilles de ndolé, '
            "crevettes séchées et viande de bœuf. Servi avec du plantain mûr.";
    final basePrice = dish?.priceXaf ?? 2500;
    final cookName = dish?.cook?.displayName ?? 'Maman Catherine';
    final cookId = dish?.cook?.id ?? '';
    final prepTime = dish?.prepTimeMin ?? 25;
    final category = dish?.category ?? 'Plats Traditionnels';
    final imageUrl = dish?.imageUrl;
    final totalPrice = _computePrice(basePrice);

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Hero image
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.42,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x40000000),
                              Colors.transparent,
                              Color(0x80000000),
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: _CircleBtn(
                          icon: Icons.arrow_back,
                          onTap: () => context.pop(),
                        ),
                      ),
                      // Fav button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: _CircleBtn(
                          icon: _isFav
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFav ? AppColors.errorRed : AppColors.charcoal,
                          onTap: () => setState(() => _isFav = !_isFav),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content card
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Restaurant
                        GestureDetector(
                          onTap: cookId.isNotEmpty
                              ? () => context.push('/restaurant/$cookId')
                              : null,
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                cookName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (cookId.isNotEmpty)
                                const Icon(Icons.chevron_right,
                                    size: 16,
                                    color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Rating + prep time row
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.gold, size: 18),
                            const SizedBox(width: 4),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontFamily: AppTheme.monoFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const Text(
                              ' (124 avis)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.schedule,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '$prepTime min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price
                        Text(
                          FcfaFormatter.format(basePrice),
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFamily,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Customize section
                        Text(
                          t('customize', ref),
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Portion
                        Text(
                          t('portion', ref),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(_portions.length, (i) {
                            final active = _portionIdx == i;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _portionIdx = i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.surfaceLow,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _portions[i],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : AppColors.charcoal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Side dish
                        Text(
                          t('side_dish', ref),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children:
                              List.generate(_sideOptions.length, (i) {
                            final active = _sides.contains(i);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (active) {
                                  _sides.remove(i);
                                } else {
                                  _sides.add(i);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.forestGreen
                                      : AppColors.surfaceLow,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _sideOptions[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? Colors.white
                                        : AppColors.charcoal,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Spice slider
                        Text(
                          '${t('spice_level', ref)} — ${_spiceLabel(_spice)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Slider(
                          value: _spice,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.surfaceLow,
                          label: _spiceLabel(_spice),
                          onChanged: (v) =>
                              setState(() => _spice = v),
                        ),

                        const SizedBox(height: 28),

                        // Reviews
                        Text(
                          t('recent_reviews', ref),
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._mockReviews.map(_buildReview),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Footer: quantity + add to cart
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity counter
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () =>
                                  setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          color: AppColors.charcoal,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontFamily: AppTheme.monoFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _quantity++),
                          icon: const Icon(Icons.add, size: 18),
                          color: AppColors.charcoal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          for (int i = 0; i < _quantity; i++) {
                            ref.read(cartProvider.notifier).addItem(
                                  CartItem(
                                    menuItemId: widget.dishId,
                                    name: name,
                                    priceXaf: (basePrice *
                                            _portionMultipliers[
                                                _portionIdx])
                                        .round(),
                                    quantity: 1,
                                    cookId: cookId.isNotEmpty
                                        ? cookId
                                        : 'restaurant-1',
                                    cookName: cookName,
                                    imageUrl: imageUrl,
                                  ),
                                );
                          }
                          triggerCartBounce();
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                    '$name ${t('added_to_cart', ref)}'),
                                backgroundColor:
                                    AppColors.forestGreen,
                                behavior:
                                    SnackBarBehavior.floating,
                              ),
                            );
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          '${t('add_to_cart', ref)}  |  ${FcfaFormatter.format(totalPrice)}',
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Image.asset(
          'assets/images/mock/ndole.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.restaurant_menu,
                size: 64, color: Colors.white54),
          ),
        ),
      );

  String _spiceLabel(double v) => switch (v.round()) {
        0 => 'Aucun',
        1 => 'Doux',
        2 => 'Moyen',
        3 => 'Piquant',
        4 => 'Fort',
        5 => 'Inferno 🔥',
        _ => '',
      };

  Widget _buildReview(_Review r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    r.name[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  r.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.charcoal,
                  ),
                ),
                const Spacer(),
                RatingBarIndicator(
                  rating: r.rating,
                  itemSize: 14,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star, color: AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({
    required this.icon,
    this.color = AppColors.charcoal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _Review {
  final String name;
  final double rating;
  final String comment;
  const _Review(this.name, this.rating, this.comment);
}
