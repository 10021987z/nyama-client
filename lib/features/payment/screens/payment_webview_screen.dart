import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';

enum PaymentResult { success, failed, cancelled }

class PaymentWebViewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String? paymentId;

  const PaymentWebViewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    this.paymentId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  static const _callbackScheme = 'nyama';
  static const _callbackHost = 'payment';
  static const _pollInterval = Duration(seconds: 3);
  static const _pollTimeout = Duration(seconds: 60);

  late final WebViewController _controller;
  Timer? _pollTimer;
  DateTime? _pollStart;
  bool _finished = false;
  bool _loading = true;
  bool _isSandbox = false;
  bool _forcingTest = false;

  bool _detectSandbox(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('test.');
  }

  Future<void> _forceTestComplete() async {
    final paymentId = widget.paymentId;
    if (paymentId == null || _forcingTest || _finished) return;
    setState(() => _forcingTest = true);
    try {
      await PaymentService.testComplete(paymentId);
      _finish(PaymentResult.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _forcingTest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(
            'Forçage test échoué: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _isSandbox = _detectSandbox(widget.authorizationUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.creme)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _loading = true;
                _isSandbox = _isSandbox || _detectSandbox(url);
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _loading = false;
                _isSandbox = _isSandbox || _detectSandbox(url);
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme == _callbackScheme &&
                uri.host == _callbackHost) {
              _handleCallback(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));

    _startPolling();
  }

  void _startPolling() {
    _pollStart = DateTime.now();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_finished || !mounted) return;
      final elapsed = DateTime.now().difference(_pollStart!);
      if (elapsed > _pollTimeout) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final result = await PaymentService.verifyPayment(widget.reference);
        final status = (result['status'] as String?)?.toLowerCase() ?? '';
        if (status == 'complete' || status == 'paid' || status == 'success') {
          _finish(PaymentResult.success);
        } else if (status == 'failed' || status == 'canceled' ||
            status == 'cancelled') {
          _finish(PaymentResult.failed);
        }
      } catch (_) {
        // Ignore transient errors; polling continues.
      }
    });
  }

  void _handleCallback(Uri uri) {
    final status = uri.queryParameters['status']?.toLowerCase() ?? '';
    switch (status) {
      case 'success':
      case 'complete':
      case 'paid':
        _finish(PaymentResult.success);
        break;
      case 'cancel':
      case 'cancelled':
      case 'canceled':
        _finish(PaymentResult.cancelled);
        break;
      default:
        _finish(PaymentResult.failed);
    }
  }

  void _finish(PaymentResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    _pollTimer?.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _finish(PaymentResult.cancelled);
      },
      child: Scaffold(
        backgroundColor: AppColors.creme,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 18, color: AppColors.forestGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Paiement sécurisé NotchPay',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _finish(PaymentResult.cancelled),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.errorRed),
                      label: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceLow,
                  ),
                ),
              if (_isSandbox && widget.paymentId != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: ElevatedButton.icon(
                    onPressed: _forcingTest ? null : _forceTestComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _forcingTest
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 20),
                    label: const Text(
                      'Forcer paiement (test)',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
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
