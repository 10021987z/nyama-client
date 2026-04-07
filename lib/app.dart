import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/auth/screens/quartier_selection_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/restaurant/screens/restaurant_detail_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/orders/screens/order_tracking_screen.dart';
import 'features/payment/data/checkout_data.dart';
import 'features/payment/screens/payment_screen.dart';
import 'features/rating/screens/rating_screen.dart';
import 'features/rider_signup/screens/rider_signup_screen.dart';

class App extends StatelessWidget {
  App({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Onboarding ────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/onboarding/phone',
        builder: (c, s) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/onboarding/otp',
        builder: (c, s) {
          final phone = s.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/onboarding/quartier',
        builder: (c, s) => const QuartierSelectionScreen(),
      ),
      // ── Aliases (compat ancien code) ──────────────────────────────────
      GoRoute(path: '/phone', builder: (c, s) => const PhoneInputScreen()),
      GoRoute(
        path: '/otp',
        builder: (c, s) {
          final phone = s.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),

      // ── Tabs principaux (HomeScreen gère son propre bottom nav) ───────
      GoRoute(
        path: '/home',
        builder: (c, s) => const HomeScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/search',
        builder: (c, s) => const HomeScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/cart',
        builder: (c, s) => const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/orders',
        builder: (c, s) => const HomeScreen(initialTab: 3),
      ),
      GoRoute(
        path: '/profile',
        builder: (c, s) => const HomeScreen(initialTab: 4),
      ),

      // ── Détails ───────────────────────────────────────────────────────
      GoRoute(
        path: '/restaurant/:id',
        builder: (c, s) =>
            RestaurantDetailScreen(restaurantId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (c, s) =>
            OrderDetailScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/track',
        builder: (c, s) =>
            OrderTrackingScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (c, s) =>
            OrderTrackingScreen(orderId: s.pathParameters['orderId']!),
      ),

      // ── Paiement & notation ───────────────────────────────────────────
      GoRoute(
        path: '/payment',
        builder: (c, s) {
          final data = s.extra is CheckoutData ? s.extra as CheckoutData : null;
          return PaymentScreen(checkout: data);
        },
      ),
      GoRoute(
        path: '/rating/:orderId',
        builder: (c, s) =>
            RatingScreen(orderId: s.pathParameters['orderId']!),
      ),

      // ── Divers ────────────────────────────────────────────────────────
      GoRoute(
        path: '/become-rider',
        builder: (c, s) => const RiderSignupScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Page introuvable'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NYAMA',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'CM'),
      supportedLocales: const [
        Locale('fr', 'CM'),
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
    );
  }
}
