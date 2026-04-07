import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyama_client/features/cart/providers/cart_provider.dart';
import 'package:nyama_client/features/cart/screens/cart_screen.dart';

CartItem _item({int qty = 1, int price = 2500}) => CartItem(
      menuItemId: 'm1',
      name: 'Ndolé Royal',
      priceXaf: price,
      quantity: qty,
      cookId: 'c1',
      cookName: 'Mama Ngono',
    );

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('Empty cart shows empty state', (tester) async {
    await tester.pumpWidget(_wrap(const CartScreen()));
    expect(find.text('Votre panier est vide'), findsOneWidget);
  });

  testWidgets('Cart shows items + Commander CTA', (tester) async {
    await tester.pumpWidget(_wrap(
      Consumer(builder: (context, ref, _) {
        // Seed cart on first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(cartProvider.notifier).addItem(_item());
        });
        return const CartScreen();
      }),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Mon Panier'), findsOneWidget);
    expect(find.text('Ndolé Royal'), findsOneWidget);
    expect(find.textContaining('Commander'), findsOneWidget);
    expect(find.text('STANDARD'), findsOneWidget);
    expect(find.text('EXPRESS'), findsOneWidget);
  });

  testWidgets('Express speed adds 500 FCFA to total', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).addItem(_item(price: 2000));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pump();

    // Standard total = 2000
    expect(find.textContaining('2'), findsWidgets);

    // Tap EXPRESS
    await tester.tap(find.text('EXPRESS'));
    await tester.pump();

    // After express, total should include +500 fee
    expect(find.textContaining('500'), findsWidgets);
  });

  testWidgets('Quantity pill +/- updates cart', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartProvider.notifier).addItem(_item());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CartScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
