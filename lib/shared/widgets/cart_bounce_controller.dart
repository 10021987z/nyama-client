import 'package:flutter/foundation.dart';

/// Incrémenté à chaque fois qu'un article est ajouté au panier via le
/// "fly to cart" : le badge du bottom nav observe ce compteur et joue
/// une animation de bounce scale (1.0 → 1.3 → 1.0).
final ValueNotifier<int> cartBounceTick = ValueNotifier<int>(0);

void triggerCartBounce() {
  cartBounceTick.value = cartBounceTick.value + 1;
}
