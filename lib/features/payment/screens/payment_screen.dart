import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/data/orders_repository.dart';
import '../data/checkout_data.dart';
import 'payment_webview_screen.dart';

/// Écran 1.6 — Paiement NotchPay (MTN / Orange) + Cash à la livraison.
class PaymentScreen extends ConsumerStatefulWidget {
  final CheckoutData? checkout;
  const PaymentScreen({super.key, this.checkout});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = 'mtn_momo';
  late final TextEditingController _phoneCtrl;
  bool _processing = false;
  String _address = '';

  @override
  void initState() {
    super.initState();
    final userPhone = ref.read(authStateProvider).user?.phone;
    _phoneCtrl = TextEditingController(
      text: (userPhone != null && userPhone.isNotEmpty) ? userPhone : '',
    );
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final city = await SecureStorage.getCity();
    final quartier = await SecureStorage.getQuartier();
    if (!mounted) return;
    setState(() {
      _address = [quartier, city]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      if (_address.isEmpty) _address = 'Bonapriso, Douala';
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isCash => _method == 'cash';
  bool get _isMomo => _method == 'mtn_momo' || _method == 'orange_money';

  @override
  Widget build(BuildContext context) {
    final checkout = widget.checkout;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t('payment', ref),
          style: const TextStyle(
            fontFamily: AppTheme.headlineFamily,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.charcoal,
          ),
        ),
      ),
      body: checkout == null
          ? _buildMissing()
          : Stack(
              children: [
                _buildBody(checkout),
                if (_processing) _buildLoadingOverlay(),
              ],
            ),
    );
  }

  Widget _buildBody(CheckoutData checkout) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _buildAddressCard(),
              const SizedBox(height: 20),
              _divider(),
              const SizedBox(height: 20),
              Text(
                t('your_cart', ref),
                style: const TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              ...checkout.items.map(_buildCartItem),
              const SizedBox(height: 16),
              _buildSummary(checkout),
              const SizedBox(height: 20),
              _divider(),
              const SizedBox(height: 20),
              Text(
                t('payment_method', ref),
                style: const TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              _paymentOption(
                value: 'mtn_momo',
                title: 'MTN Mobile Money',
                logoAsset: 'assets/images/mock/mtn-mobile-money-logo.jpg',
                badge: 'Populaire',
              ),
              const SizedBox(height: 10),
              _paymentOption(
                value: 'orange_money',
                title: 'Orange Money',
                logoAsset: 'assets/images/mock/orange-money-logo.png',
              ),
              const SizedBox(height: 10),
              _paymentOption(
                value: 'cash',
                title: 'Cash à la livraison',
                icon: Icons.payments_rounded,
              ),
              if (_isMomo) ...[
                const SizedBox(height: 20),
                Text(
                  'Numéro MoMo',
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.outlineVariant, width: 1),
                  ),
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '+237 6XX XXX XXX',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t('sms_confirmation', ref),
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: AppColors.creme,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : () => _onPay(checkout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  disabledBackgroundColor:
                      AppColors.forestGreen.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _processing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _isCash
                                ? 'Confirmer ${checkout.totalXaf.toFcfa()}'
                                : '${t('pay', ref)} ${checkout.totalXaf.toFcfa()}',
                            style: const TextStyle(
                              fontFamily: AppTheme.headlineFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return const Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('delivery_address', ref),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _address,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/onboarding/quartier'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 32),
            ),
            child: Text(
              t('modify', ref),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.primaryLight,
              child: item.imageUrl != null
                  ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.restaurant_menu_rounded,
                          color: AppColors.primary))
                  : const Icon(Icons.restaurant_menu_rounded,
                      color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.quantity}×  ${item.name}',
              style: const TextStyle(
                fontFamily: AppTheme.bodyFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            (item.priceXaf * item.quantity).toFcfa(),
            style: const TextStyle(
              fontFamily: AppTheme.monoFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(CheckoutData checkout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row(t('subtotal', ref), checkout.subtotalXaf.toFcfa()),
          const SizedBox(height: 8),
          _row(
            t('delivery_fee', ref),
            checkout.deliveryFeeXaf == 0
                ? t('free_delivery', ref)
                : checkout.deliveryFeeXaf.toFcfa(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.outlineVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('total', ref),
                style: const TextStyle(
                  fontFamily: AppTheme.headlineFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                checkout.totalXaf.toFcfa(),
                style: const TextStyle(
                  fontFamily: AppTheme.monoFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ],
      );

  Widget _paymentOption({
    required String value,
    required String title,
    String? logoAsset,
    IconData? icon,
    String? badge,
  }) {
    final selected = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (logoAsset != null)
              ClipOval(
                child: Image.asset(
                  logoAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => _iconFallback(),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.account_balance_wallet_rounded,
                  color: AppColors.forestGreen,
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppColors.primary : AppColors.outlineVariant,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surfaceLow,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      );

  Widget _divider() => const Divider(
        height: 1,
        color: AppColors.surfaceLow,
        thickness: 1,
      );

  Future<void> _onPay(CheckoutData checkout) async {
    if (_isMomo && _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('enter_number', ref))),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (_isMomo) {
      final biometricEnabled = await SecureStorage.getBiometricEnabled();
      if (biometricEnabled) {
        final available =
            await BiometricService.instance.isBiometricAvailable();
        if (available) {
          final ok = await BiometricService.instance.authenticate(
            reason: '${t('payment', ref)} ${checkout.totalXaf.toFcfa()}',
          );
          if (!ok) {
            messenger.showSnackBar(
              SnackBar(content: Text(t('payment_cancelled', ref))),
            );
            return;
          }
        }
      }
    }

    setState(() => _processing = true);

    try {
      final orderId = await _createOrderOrFallback(checkout);

      if (_isCash) {
        if (!mounted) return;
        ref.read(cartProvider.notifier).clearCart();
        setState(() => _processing = false);
        router.go('/orders/$orderId/track');
        return;
      }

      final notchPayMethod = PaymentService.normalizeMethod(_method);
      final init = await PaymentService.initiatePayment(
        orderId: orderId,
        amount: checkout.totalXaf,
        phone: _phoneCtrl.text.trim(),
        method: notchPayMethod,
      );

      final reference = init['reference'] as String?;
      final raw = init['raw'];
      final authorizationUrl =
          raw is Map ? raw['authorization_url'] as String? : null;

      if (reference == null ||
          authorizationUrl == null ||
          authorizationUrl.isEmpty) {
        throw const FormatException(
          'Réponse NotchPay invalide (référence ou URL manquante)',
        );
      }

      if (!mounted) return;
      setState(() => _processing = false);

      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PaymentWebViewScreen(
            authorizationUrl: authorizationUrl,
            reference: reference,
          ),
        ),
      );

      if (!mounted) return;

      switch (result) {
        case PaymentResult.success:
          ref.read(cartProvider.notifier).clearCart();
          router.go('/orders/$orderId/track');
          break;
        case PaymentResult.failed:
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.errorRed,
              content: Text(
                'Paiement échoué',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
          break;
        case PaymentResult.cancelled:
        case null:
          messenger.showSnackBar(
            const SnackBar(content: Text('Paiement annulé')),
          );
          break;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _processing = false);
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(
            'Échec du paiement. Vérifiez votre solde et réessayez.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<String> _createOrderOrFallback(CheckoutData checkout) async {
    try {
      final order = await OrdersRepository().createOrder(
        CreateOrderRequest(
          cookId: checkout.cookId,
          items: checkout.items
              .map((i) => {
                    'menuItemId': i.menuItemId,
                    'quantity': i.quantity,
                  })
              .toList(),
          deliveryAddress: _address,
          paymentMethod: _method,
          paymentPhone: _isMomo ? _phoneCtrl.text.trim() : null,
        ),
      );
      return order.id;
    } on NotFoundException {
      return 'order-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Widget _buildMissing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            t('cart_empty', ref),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(t('explore_dishes', ref)),
          ),
        ],
      ),
    );
  }
}
