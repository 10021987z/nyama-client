import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/restaurant/screens/restaurant_detail_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/orders/screens/order_tracking_screen.dart';
import 'features/rider_signup/screens/rider_signup_screen.dart';

class App extends StatelessWidget {
  App({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const HomeScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const HomeScreen(initialTab: 3),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) => RestaurantDetailScreen(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orders/:id/track',
        builder: (context, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/become-rider',
        builder: (context, state) => const RiderSignupScreen(),
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
              child: const Text('Retour à l\'accueil'),
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
