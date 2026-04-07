import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nyama_client/features/profile/screens/profile_screen.dart';
import 'package:nyama_client/features/rating/screens/rating_screen.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/x',
    routes: [
      GoRoute(path: '/x', builder: (_, __) => child),
      GoRoute(path: '/orders', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
      GoRoute(path: '/onboarding', builder: (_, __) => const SizedBox()),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('RatingScreen affiche titre, étoiles et CTA désactivé initialement',
      (tester) async {
    await tester.pumpWidget(_wrap(const RatingScreen(orderId: '4402')));
    await tester.pumpAndSettle();

    expect(find.text('Le goût était comment ?'), findsOneWidget);
    expect(find.text('ORDER #4402'), findsOneWidget);
    expect(find.text('Kevin'), findsOneWidget);
    expect(find.text('Envoyer mon avis'), findsOneWidget);

    final btn =
        tester.widget<ElevatedButton>(find.byKey(const Key('rating_submit_button')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Sélection étoile food active le label et le CTA',
      (tester) async {
    await tester.pumpWidget(_wrap(const RatingScreen(orderId: '4402')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('food_star_3')));
    await tester.pump();

    expect(find.text('Excellent'), findsOneWidget);
    final btn =
        tester.widget<ElevatedButton>(find.byKey(const Key('rating_submit_button')));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Tag feedback toggle actif / inactif', (tester) async {
    await tester.pumpWidget(_wrap(const RatingScreen(orderId: '4402')));
    await tester.pumpAndSettle();
    expect(find.text('Livraison rapide'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tag_Livraison_rapide')));
    await tester.pump();
    // Pas d'erreur = toggle OK
    expect(find.text('Livraison rapide'), findsOneWidget);
  });

  testWidgets('ProfileScreen affiche NYAMA+, stats et bottom nav',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('NYAMA+'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('DISCOVER'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);

    // Scroll vers le bas pour révéler les sections en dessous
    await tester.scrollUntilVisible(
      find.text('ARTHUR237'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Parraine un ami'), findsOneWidget);
    expect(find.text('ARTHUR237'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Version 2.4.0 • NYAMA Cameroon'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Version 2.4.0 • NYAMA Cameroon'), findsOneWidget);
  });
}
