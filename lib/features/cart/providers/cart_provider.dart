import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Exception ────────────────────────────────────────────────────────────

class CartConflictException implements Exception {
  final String message;
  final String existingCookName;
  const CartConflictException(this.message, {required this.existingCookName});
}

// ─── Modèle CartItem ──────────────────────────────────────────────────────

class CartItem {
  final String menuItemId;
  final String name;
  final int priceXaf;
  final int quantity;
  final String cookId;
  final String cookName;
  final String? imageUrl;

  const CartItem({
    required this.menuItemId,
    required this.name,
    required this.priceXaf,
    required this.quantity,
    required this.cookId,
    required this.cookName,
    this.imageUrl,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        menuItemId: menuItemId,
        name: name,
        priceXaf: priceXaf,
        quantity: quantity ?? this.quantity,
        cookId: cookId,
        cookName: cookName,
        imageUrl: imageUrl,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isEmpty => state.isEmpty;

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);

  int get totalXaf =>
      state.fold(0, (sum, item) => sum + item.priceXaf * item.quantity);

  String? get cookId => state.isEmpty ? null : state.first.cookId;
  String? get cookName => state.isEmpty ? null : state.first.cookName;

  int quantityOf(String menuItemId) {
    final match = state.where((i) => i.menuItemId == menuItemId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  // ── Mutations ───────────────────────────────────────────────────────────

  /// Ajoute ou incrémente un article.
  /// Lance [CartConflictException] si le plat vient d'une autre cuisinière.
  void addItem(CartItem item) {
    if (state.isNotEmpty && state.first.cookId != item.cookId) {
      throw CartConflictException(
        'Vous avez déjà des plats de ${state.first.cookName}. '
        'Videz le panier pour commander chez ${item.cookName}.',
        existingCookName: state.first.cookName,
      );
    }

    final index = state.indexWhere((i) => i.menuItemId == item.menuItemId);
    if (index >= 0) {
      // Incrémente
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(quantity: state[index].quantity + 1),
        ...state.sublist(index + 1),
      ];
    } else {
      state = [...state, item.copyWith(quantity: 1)];
    }
  }

  /// Décrémente ou supprime si quantity tombe à 0.
  void removeItem(String menuItemId) {
    final index = state.indexWhere((i) => i.menuItemId == menuItemId);
    if (index < 0) return;

    final current = state[index];
    if (current.quantity <= 1) {
      state = [...state.sublist(0, index), ...state.sublist(index + 1)];
    } else {
      state = [
        ...state.sublist(0, index),
        current.copyWith(quantity: current.quantity - 1),
        ...state.sublist(index + 1),
      ];
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    state = state
        .map((i) =>
            i.menuItemId == menuItemId ? i.copyWith(quantity: quantity) : i)
        .toList();
  }

  void clearCart() => state = [];
}

// ─── Provider ─────────────────────────────────────────────────────────────

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
