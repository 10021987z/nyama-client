import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyama_client/shared/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('Bottom nav has 5 items', (WidgetTester tester) async {
    var tapped = -1;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: NyamaBottomNavBar(
              currentIndex: 0,
              onTap: (i) => tapped = i,
            ),
          ),
        ),
      ),
    );

    expect(find.text('ACCUEIL'), findsOneWidget);
    expect(find.text('RECHERCHE'), findsOneWidget);
    expect(find.text('PANIER'), findsOneWidget);
    expect(find.text('COMMANDES'), findsOneWidget);
    expect(find.text('PROFIL'), findsOneWidget);

    await tester.tap(find.text('PANIER'));
    expect(tapped, 2);
  });
}
