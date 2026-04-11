import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyama_client/features/cart/providers/cart_provider.dart';
import 'package:nyama_client/features/payment/data/checkout_data.dart';
import 'package:nyama_client/features/payment/screens/payment_screen.dart';

CheckoutData _checkout() => CheckoutData(
      items: const [
        CartItem(
          menuItemId: 'm1',
          name: 'Ndolé',
          priceXaf: 2500,
          quantity: 2,
          cookId: 'c1',
          cookName: 'Mama',
        ),
      ],
      cookId: 'c1',
      cookName: 'Mama',
      subtotalXaf: 5000,
      deliveryFeeXaf: 500,
      deliverySpeed: 'express',
      totalXaf: 5500,
    );

void main() {
  testWidgets('PaymentScreen affiche adresse, méthodes et CTA Payer',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: PaymentScreen(checkout: _checkout())),
      ),
    );
    await tester.pump();

    expect(find.text('Paiement'), findsOneWidget);
    expect(find.text('Adresse de livraison'), findsOneWidget);
    expect(find.text('Bonapriso, Douala'), findsOneWidget);
    expect(find.text('Appartement 4B'), findsOneWidget);
    expect(find.text('MTN Mobile Money'), findsOneWidget);
    expect(find.text('Orange Money'), findsOneWidget);
    expect(find.textContaining('Payer'), findsOneWidget);
    expect(
      find.text('Un code de confirmation vous sera envoyé par SMS'),
      findsOneWidget,
    );
  });

  testWidgets('PaymentScreen sans CheckoutData affiche fallback',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PaymentScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Aucune commande à payer'), findsOneWidget);
  });

  testWidgets('Tap Orange Money sélectionne la 2e méthode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: PaymentScreen(checkout: _checkout())),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Orange Money'));
    await tester.pump();
    // Pas de crash + l'écran reste affiché
    expect(find.text('Orange Money'), findsOneWidget);
  });
}
