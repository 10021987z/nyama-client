import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

/// Écran de bienvenue affiché après une inscription réussie.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  Timer? _autoNav;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _autoNav = Timer(const Duration(seconds: 3), _goNext);
  }

  @override
  void dispose() {
    _autoNav?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final q = await SecureStorage.getQuartier();
    if (!mounted) return;
    if (q != null && q.isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/onboarding/quartier');
    }
  }

  String _connectedLabel(AppUser? user) {
    final v = user?.phone ?? '';
    if (v.isEmpty) return 'Connecté avec ton compte Google';
    if (v.contains('@')) return 'Connecté avec $v';
    if (v.startsWith('+237') && v.length >= 13) {
      final local = v.substring(4);
      return 'Connecté avec +237 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return 'Connecté avec $v';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/logo_nyama.jpg', width: 120, height: 120),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenue sur NYAMA !',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ton compte a été créé avec succès',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _connectedLabel(user),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _autoNav?.cancel();
                    _goNext();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "C'est parti ! →",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
