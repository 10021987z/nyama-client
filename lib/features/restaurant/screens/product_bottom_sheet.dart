import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/data/models/cook.dart';
import '../../home/data/models/menu_item.dart';

/// Opens a Deliveroo-style draggable product sheet.
void showProductSheet(
  BuildContext context,
  MenuItem item,
  Cook cook,
  CartNotifier cartNotifier,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProductSheet(
      item: item,
      cook: cook,
      cartNotifier: cartNotifier,
    ),
  );
}

class _ProductSheet extends StatefulWidget {
  final MenuItem item;
  final Cook cook;
  final CartNotifier cartNotifier;

  const _ProductSheet({
    required this.item,
    required this.cook,
    required this.cartNotifier,
  });

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalPrice => widget.item.priceXaf * _quantity;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(bottom: bottom + 100),
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppColors.surfaceLow),
                                errorWidget: (context, url, error) =>
                                    _placeholder(),
                              )
                            : _placeholder(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontFamily: AppTheme.headlineFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Description
                          if (item.description != null)
                            Text(
                              item.description!,
                              style: const TextStyle(
                                fontFamily: AppTheme.bodyFamily,
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Price
                          Text(
                            item.priceXaf.toFcfa(),
                            style: const TextStyle(
                              fontFamily: AppTheme.monoFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Info row: timer + cook
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 14,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.prepTimeMin ?? 25} min',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person,
                                        size: 14,
                                        color: AppColors.forestGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Par ${widget.cook.displayName}',
                                      style: const TextStyle(
                                        fontFamily: AppTheme.bodyFamily,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Quantity selector
                          Row(
                            children: [
                              const Text(
                                'Quantite',
                                style: TextStyle(
                                  fontFamily: AppTheme.headlineFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const Spacer(),
                              _QuantityButton(
                                icon: Icons.remove,
                                enabled: _quantity > 1,
                                onTap: () =>
                                    setState(() => _quantity--),
                              ),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$_quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.monoFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add,
                                enabled: true,
                                onTap: () =>
                                    setState(() => _quantity++),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Special instructions
                          const Text(
                            'Instructions speciales',
                            style: TextStyle(
                              fontFamily: AppTheme.headlineFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Ex: sans oignon, bien cuit, extra piment...',
                              hintStyle: const TextStyle(
                                fontFamily: AppTheme.bodyFamily,
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Add to cart button
              Container(
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: item.canOrder ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ajouter au panier  —  ${_totalPrice.toFcfa()}',
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
        );
      },
    );
  }

  void _addToCart() {
    final item = widget.item;
    try {
      for (var i = 0; i < _quantity; i++) {
        widget.cartNotifier.addItem(CartItem(
          menuItemId: item.id,
          name: item.name,
          priceXaf: item.priceXaf,
          quantity: 1,
          cookId: item.cook?.id ?? widget.cook.id,
          cookName: item.cook?.displayName ?? widget.cook.displayName,
          imageUrl: item.imageUrl,
        ));
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${item.name} ajoute au panier'),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on CartConflictException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _placeholder() => Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.restaurant, color: AppColors.primary, size: 48),
        ),
      );
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.forestGreen.withValues(alpha: 0.1)
              : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.forestGreen : AppColors.textTertiary,
        ),
      ),
    );
  }
}
