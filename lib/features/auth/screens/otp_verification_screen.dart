import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
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
  static const int _otpLength = 6;
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;
  bool _autoSubmitted = false;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(_otpLength, (_) => TextEditingController());
    _nodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes.first.requestFocus();
    });
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
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String value) {
    if (value.length > 1) {
      // Paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int k = 0; k < _otpLength; k++) {
        _ctrls[k].text = k < digits.length ? digits[k] : '';
      }
      final next =
          digits.length >= _otpLength ? _otpLength - 1 : digits.length;
      _nodes[next].requestFocus();
    } else if (value.isNotEmpty && i < _otpLength - 1) {
      _nodes[i + 1].requestFocus();
    } else if (value.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});

    final hasError =
        ref.read(authStateProvider).status == AuthStatus.error;
    if (hasError) ref.read(authStateProvider.notifier).clearError();

    if (_code.length == _otpLength && !_autoSubmitted) {
      _autoSubmitted = true;
      _verify();
    }
  }

  Future<void> _verify() async {
    if (_code.length != _otpLength) return;
    await ref
        .read(authStateProvider.notifier)
        .verifyOtp(widget.phone, _code);
    _autoSubmitted = false;
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    for (final c in _ctrls) {
      c.clear();
    }
    setState(() {});
    _nodes.first.requestFocus();
    await ref.read(authStateProvider.notifier).resendOtp();
    if (mounted &&
        ref.read(authStateProvider).status == AuthStatus.otpSent) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code renvoyé par SMS'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String get _displayPhone {
    final p = widget.phone;
    if (p.startsWith('+237') && p.length >= 13) {
      final local = p.substring(4);
      return '+237 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return p;
  }

  String _fmtTimer(int s) {
    final m = (s ~/ 60).toString();
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/onboarding/quartier');
      }
    });

    final authState = ref.watch(authStateProvider);
    final isVerifying = authState.status == AuthStatus.verifying;
    final hasError = authState.status == AuthStatus.error;
    final canSubmit = _code.length == _otpLength && !isVerifying;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar ───────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(authStateProvider.notifier).clearError();
                      context.go('/onboarding/phone');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.charcoal, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'NYAMA',
                        style: TextStyle(
                          fontFamily: AppTheme.headlineFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          color: AppColors.charcoal,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                'Vérification',
                style: TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saisissez le code envoyé au $_displayPhone',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── 6 OTP fields ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (i) {
                  final focused = _nodes[i].hasFocus;
                  return Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError
                            ? AppColors.errorRed
                            : (focused
                                ? AppColors.primary
                                : Colors.transparent),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _ctrls[i],
                      focusNode: _nodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (v) => _onChanged(i, v),
                    ),
                  );
                }),
              ),

              if (hasError && authState.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: authState.errorMessage!),
              ],

              const SizedBox(height: 24),

              // ── Timer ───────────────────────────────────────────
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resend,
                        child: const Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            const TextSpan(text: 'Renvoyer dans '),
                            TextSpan(
                              text: _fmtTimer(_countdown),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // ── CTA ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canSubmit ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    disabledBackgroundColor:
                        AppColors.forestGreen.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Valider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Card image ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bakery_dining,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bientôt à toi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Beignets, ndolè, poulet DG…',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: AppTheme.bodyFamily,
                    ),
                    children: const [
                      TextSpan(text: 'Vous n\'avez pas reçu de code ? '),
                      TextSpan(
                        text: 'Contactez le support',
                        style: TextStyle(
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
