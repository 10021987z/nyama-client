import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    // Attend minimum 2s pour l'effet splash + que checkAuth() se termine
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final status = ref.read(authStateProvider).status;
      _navigate(status);
    });
  }

  void _navigate(AuthStatus status) {
    if (!mounted) return;
    if (status == AuthStatus.initial) {
      // checkAuth pas encore terminé : écoute le prochain changement
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final next = ref.read(authStateProvider).status;
        _navigate(next == AuthStatus.initial ? AuthStatus.unauthenticated : next);
      });
    } else {
      // Authentifié ou non → affiche la page d'accueil (endpoints publics)
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écoute les changements d'état pour naviguer si checkAuth finit tôt
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (prev?.status == AuthStatus.initial &&
          next.status != AuthStatus.initial) {
        _navigate(next.status);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo SVG NYAMA
              SvgPicture.asset(
                'assets/nyama-logo.svg',
                width: 180,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'La cuisine camerounaise,\nlivrée chez vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 64),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
