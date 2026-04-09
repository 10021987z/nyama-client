import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase 1 — apparition (0 → 400ms => 0.0 → 0.16)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Phase 2 — smile bounce (400 → 800ms => 0.16 → 0.32)
  late final Animation<double> _bounceY;
  late final Animation<double> _bouncePulse;

  // Phase 3 — texte (800 → 1200ms => 0.32 → 0.48)
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleTranslateY;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleTranslateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Phase 1 — 0.0 → 0.16
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.16, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.16, curve: Curves.easeOut),
      ),
    );

    // Phase 2 — 0.16 → 0.32
    _bounceY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -15.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -15.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.32),
      ),
    );
    _bouncePulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.32),
      ),
    );

    // Phase 3 — 0.32 → 0.48 (titre) + 0.40 → 0.56 (sous-titre décalé 200ms)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.48, curve: Curves.easeOut),
      ),
    );
    _titleTranslateY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.48, curve: Curves.easeOut),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.56, curve: Curves.easeOut),
      ),
    );
    _subtitleTranslateY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.56, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Phase 4 — navigation à la fin du controller (≈2500ms total)
    Future.delayed(const Duration(milliseconds: 2500), _decideRoute);
  }

  Future<void> _decideRoute() async {
    if (!mounted) return;
    // Modèle Uber Eats : accès libre à l'app.
    // Au premier lancement (pas de quartier choisi), on propose l'onboarding
    // localisation ; sinon on va direct sur /home — sans jamais exiger de login.
    final quartier = await SecureStorage.getQuartier();
    if (!mounted) return;
    if (quartier == null || quartier.isEmpty) {
      context.go('/onboarding/quartier');
      return;
    }

    // Biométrie : uniquement si l'utilisateur EST déjà connecté ET l'a activée.
    final token = await SecureStorage.getAccessToken();
    final biometricEnabled = await SecureStorage.getBiometricEnabled();
    if (token != null && token.isNotEmpty && biometricEnabled) {
      final available = await BiometricService.instance.isBiometricAvailable();
      if (available) {
        final ok = await BiometricService.instance.authenticate();
        if (!mounted) return;
        if (!ok) {
          // Échec bio : on laisse quand même entrer en mode non-connecté
          // (l'app est libre d'accès).
        }
      }
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // ── Carte logo animée ─────────────────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Opacity(
                    opacity: _logoOpacity.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _bounceY.value),
                      child: Transform.scale(
                        scale: _logoScale.value * _bouncePulse.value,
                        child: Transform.rotate(
                          angle: 3 * math.pi / 180,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _LogoCard(),
              ),
              const SizedBox(height: 32),
              // ── Titre ─────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Opacity(
                    opacity: _titleOpacity.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _titleTranslateY.value),
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'NYAMA',
                  style: TextStyle(
                    fontFamily: AppTheme.headlineFamily,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.5,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Sous-titre ────────────────────────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Opacity(
                    opacity: _subtitleOpacity.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, _subtitleTranslateY.value),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'VOS PLATS PRÉFÉRÉS LIVRÉS CHEZ VOUS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3.6, // ≈ 0.3em
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // ── 3 dots ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on,
                      size: 14, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Text(
                    'DOUALA • YAOUNDÉ • KRIBI',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.only(top: 10, left: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                'assets/images/logo_nyama.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Chip décoratif en haut à droite
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
