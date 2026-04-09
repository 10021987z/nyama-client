import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

/// Bottom sheet de connexion — style Uber Eats / Deliveroo.
/// Affiché par [AuthGate] quand une action requiert un compte.
/// Pop avec `true` si l'utilisateur s'est connecté, `false` sinon.
class LoginBottomSheet extends ConsumerStatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  ConsumerState<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends ConsumerState<LoginBottomSheet> {
  bool _googleLoading = false;

  Future<void> _onGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await ref.read(authStateProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      final status = ref.read(authStateProvider).status;
      if (status == AuthStatus.authenticated) {
        Navigator.of(context).pop(true);
      } else {
        final msg = ref.read(authStateProvider).errorMessage ??
            'Connexion Google échouée';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _onPhone() async {
    final ok = await context.push<bool>('/onboarding/phone');
    if (!mounted) return;
    if (ok == true) Navigator.of(context).pop(true);
  }

  Future<void> _onEmail() async {
    final ok = await context.push<bool>('/onboarding/email');
    if (!mounted) return;
    if (ok == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h * 0.70,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Close button row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, size: 24),
                    splashRadius: 20,
                  ),
                ],
              ),
              // ── Logo ──
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo_nyama.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connecte-toi pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pour commander tes plats préférés',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // ── Google ──
              _LoginButton(
                height: 52,
                background: Colors.white,
                borderColor: const Color(0xFFE5E5E5),
                textColor: AppColors.charcoal,
                icon: _googleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const _GoogleLogo(),
                label: 'Continuer avec Google',
                onTap: _googleLoading ? null : _onGoogle,
              ),
              const SizedBox(height: 12),

              // ── Phone ──
              _LoginButton(
                height: 52,
                background: AppColors.forestGreen,
                borderColor: AppColors.forestGreen,
                textColor: Colors.white,
                icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                label: 'Continuer avec un numéro',
                onTap: _onPhone,
              ),
              const SizedBox(height: 12),

              // ── Email ──
              _LoginButton(
                height: 52,
                background: Colors.white,
                borderColor: const Color(0xFFE5E5E5),
                textColor: AppColors.charcoal,
                icon: const Icon(Icons.email_outlined,
                    color: AppColors.charcoal, size: 20),
                label: 'Continuer avec Email',
                onTap: _onEmail,
              ),

              const Spacer(),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'En continuant, tu acceptes nos '),
                    TextSpan(
                      text: "Conditions d'utilisation",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final double height;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _LoginButton({
    required this.height,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: Center(child: icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) {
    // Simple "G" coloré — placeholder visuel léger sans asset externe.
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4285F4), width: 2),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
