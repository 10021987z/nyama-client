import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpVerificationScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  String _currentOtp = '';
  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 0;
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length < 6) return;
    await ref
        .read(authStateProvider.notifier)
        .verifyOtp(widget.phone, code);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    _otpController.clear();
    setState(() => _currentOtp = '');
    await ref.read(authStateProvider.notifier).resendOtp();
    if (mounted && ref.read(authStateProvider).status == AuthStatus.otpSent) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code renvoyé par SMS'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Masque les 4 chiffres du milieu : +237699123456 → +237 699 ****56
  String get _displayPhone {
    final p = widget.phone;
    if (p.startsWith('+237') && p.length >= 13) {
      final local = p.substring(4); // 9 chiffres
      return '+237 ${local.substring(0, 3)} ****${local.substring(7)}';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    // Navigation réactive vers /home après vérification réussie
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    final authState = ref.watch(authStateProvider);
    final isVerifying = authState.status == AuthStatus.verifying;
    final isResending = authState.status == AuthStatus.loading;
    final hasError = authState.status == AuthStatus.error;
    final canSubmit = _currentOtp.length == 6 && !isVerifying;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: BackButton(
          onPressed: () {
            ref.read(authStateProvider.notifier).clearError();
            context.go('/phone');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'Entrez le code\nreçu par SMS',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      height: 1.2,
                    ),
              ),

              const SizedBox(height: 12),

              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                  children: [
                    const TextSpan(text: 'Code envoyé au '),
                    TextSpan(
                      text: _displayPhone,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── 6 cases OTP ──────────────────────────────────────────
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                autoDismissKeyboard: true,
                animationType: AnimationType.scale,
                animationDuration: const Duration(milliseconds: 180),
                enableActiveFill: true,
                cursorColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 58,
                  fieldWidth: 46,
                  activeFillColor: Colors.white,
                  inactiveFillColor: AppColors.surface,
                  selectedFillColor: Colors.white,
                  activeColor: hasError ? AppColors.error : AppColors.primary,
                  inactiveColor: hasError ? AppColors.error.withValues(alpha: 0.4) : AppColors.divider,
                  selectedColor: AppColors.primary,
                  errorBorderColor: AppColors.error,
                ),
                onChanged: (val) {
                  setState(() => _currentOtp = val);
                  // Efface l'erreur dès que l'utilisateur modifie le code
                  if (hasError) {
                    ref.read(authStateProvider.notifier).clearError();
                  }
                },
                // Auto-submit à 6 chiffres
                onCompleted: (code) => _verify(code),
                errorAnimationController: null,
                beforeTextPaste: null,
              ),

              // ── Erreur ───────────────────────────────────────────────
              if (hasError && authState.errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorBanner(message: authState.errorMessage!),
              ],

              const SizedBox(height: 28),

              // ── Timer / Renvoyer ──────────────────────────────────────
              Center(
                child: _canResend
                    ? TextButton.icon(
                        onPressed: isResending ? null : _resend,
                        icon: isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Renvoyer le code'),
                      )
                    : Text(
                        'Renvoyer dans $_countdown s',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
              ),

              const Spacer(),

              // ── Bouton Confirmer ──────────────────────────────────────
              ElevatedButton(
                onPressed: canSubmit ? () => _verify(_currentOtp) : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: isVerifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirmer',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
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
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
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
