import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() {
      setState(() => _focused = _phoneFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = Validators.normalizePhone(_phoneController.text.trim());
    await ref.read(authStateProvider.notifier).requestOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.otpSent && next.phone != null) {
        context.go('/onboarding/otp', extra: next.phone);
      }
      if (next.status == AuthStatus.authenticated) {
        // Google / Email success → route vers quartier ou home
        SecureStorage.getQuartier().then((q) {
          if (!context.mounted) return;
          if (q != null && q.isNotEmpty) {
            context.go('/home');
          } else {
            context.go('/onboarding/quartier');
          }
        });
      }
    });

    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final hasError = authState.status == AuthStatus.error;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header NYAMA ─────────────────────────────────────
                Center(
                  child: Text(
                    'NYAMA',
                    style: TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Illustration cercle ──────────────────────────────
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smartphone,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Titres ───────────────────────────────────────────
                Center(
                  child: Text(
                    'Bienvenue !',
                    style: TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Entre ton numéro de téléphone pour accéder aux saveurs du Cameroun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Champ téléphone ──────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasError
                          ? AppColors.errorRed
                          : (_focused
                              ? AppColors.primary
                              : AppColors.outlineVariant
                                  .withValues(alpha: 0.5)),
                      width: _focused || hasError ? 2 : 1,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      const Text('🇨🇲', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      const Text(
                        '+237',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.outlineVariant
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d\s]')),
                            LengthLimitingTextInputFormatter(11),
                          ],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.charcoal,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14),
                            hintText: '6XX XXX XXX',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          validator: Validators.validateCameroonPhone,
                          onFieldSubmitted: (_) => _submit(),
                          onChanged: (_) {
                            if (hasError) {
                              ref
                                  .read(authStateProvider.notifier)
                                  .clearError();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  'Un code de vérification sera envoyé par SMS',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                if (hasError && authState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: authState.errorMessage!),
                ],

                const SizedBox(height: 32),

                // ── CTA ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Recevoir le code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Séparateur ───────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color:
                            AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou continuer avec',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color:
                            AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Boutons Google + Email ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        label: 'Google',
                        icon: _GoogleG(),
                        onTap: isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(authStateProvider.notifier)
                                    .signInWithGoogle();
                                if (!context.mounted) return;
                                final st =
                                    ref.read(authStateProvider);
                                if (st.status == AuthStatus.error &&
                                    st.errorMessage != null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(st.errorMessage!),
                                      backgroundColor:
                                          AppColors.errorRed,
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        label: 'Email',
                        icon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        onTap: isLoading
                            ? null
                            : () =>
                                context.push('/onboarding/email'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: AppTheme.bodyFamily,
                      ),
                      children: [
                        const TextSpan(
                            text: 'En continuant, tu acceptes nos '),
                        TextSpan(
                          text: 'Conditions d\'utilisation',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(child: icon),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFFEA4335)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.errorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
