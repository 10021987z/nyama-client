import '../../cart/providers/cart_provider.dart';

/// Snapshot du panier transmis du Cart au Payment via go_router extra.
class CheckoutData {
  final List<CartItem> items;
  final String cookId;
  final String cookName;
  final int subtotalXaf;
  final int deliveryFeeXaf;
  final String deliverySpeed; // 'standard' | 'express'
  final int totalXaf;

  const CheckoutData({
    required this.items,
    required this.cookId,
    required this.cookName,
    required this.subtotalXaf,
    required this.deliveryFeeXaf,
    required this.deliverySpeed,
    required this.totalXaf,
  });
}
