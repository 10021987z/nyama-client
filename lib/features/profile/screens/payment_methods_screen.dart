import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

enum PaymentProvider {
  mtnMomo,
  orangeMoney,
  falla;

  String get label {
    switch (this) {
      case PaymentProvider.mtnMomo:
        return 'MTN MoMo';
      case PaymentProvider.orangeMoney:
        return 'Orange Money';
      case PaymentProvider.falla:
        return 'Falla';
    }
  }

  String get code {
    switch (this) {
      case PaymentProvider.mtnMomo:
        return 'mtn_momo';
      case PaymentProvider.orangeMoney:
        return 'orange_money';
      case PaymentProvider.falla:
        return 'falla';
    }
  }

  Color get color {
    switch (this) {
      case PaymentProvider.mtnMomo:
        return const Color(0xFFFFC107);
      case PaymentProvider.orangeMoney:
        return const Color(0xFFF57C20);
      case PaymentProvider.falla:
        return const Color(0xFF1B4332);
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentProvider.mtnMomo:
        return Icons.phone_android;
      case PaymentProvider.orangeMoney:
        return Icons.account_balance_wallet;
      case PaymentProvider.falla:
        return Icons.payments;
    }
  }

  String get logoAsset {
    switch (this) {
      case PaymentProvider.mtnMomo:
        return 'assets/images/mock/mtn-mobile-money-logo.jpg';
      case PaymentProvider.orangeMoney:
        return 'assets/images/mock/orange-money-logo.png';
      case PaymentProvider.falla:
        return 'assets/images/mock/Fala-Money-logo-.png';
    }
  }

  static PaymentProvider? fromCode(String code) {
    switch (code) {
      case 'mtn_momo':
        return PaymentProvider.mtnMomo;
      case 'orange_money':
        return PaymentProvider.orangeMoney;
      case 'falla':
        return PaymentProvider.falla;
      default:
        return null;
    }
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<_PaymentEntry> _methods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await SecureStorage.getPaymentMethods();
    final parsed = raw
        .map((s) {
          final parts = s.split('|');
          if (parts.length < 2) return null;
          final provider = PaymentProvider.fromCode(parts[0]);
          if (provider == null) return null;
          return _PaymentEntry(
            provider: provider,
            phone: parts[1],
            isDefault: parts.length >= 3 && parts[2] == '1',
          );
        })
        .whereType<_PaymentEntry>()
        .toList();
    if (!mounted) return;
    setState(() {
      _methods = parsed;
      _loading = false;
    });
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final last4 = digits.substring(digits.length - 4);
    return '•••• $last4';
  }

  Future<void> _showAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddPaymentSheet(),
    );
    if (added == true) _load();
  }

  Future<void> _setDefault(int index) async {
    await SecureStorage.setDefaultPaymentMethod(index);
    _load();
  }

  Future<void> _remove(int index) async {
    await SecureStorage.removePaymentMethod(index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Moyens de paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : context.go('/profile'),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_methods.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun moyen de paiement',
                          style: TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ajoutez un numero pour payer plus rapidement',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFamily,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._methods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MethodCard(
                        provider: method.provider,
                        maskedPhone: _maskPhone(method.phone),
                        isDefault: method.isDefault,
                        onSetDefault: () => _setDefault(index),
                        onRemove: () => _remove(index),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                // Add button
                GestureDetector(
                  onTap: _showAddSheet,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Ajouter un numero',
                          style: TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PaymentEntry {
  final PaymentProvider provider;
  final String phone;
  final bool isDefault;
  const _PaymentEntry({
    required this.provider,
    required this.phone,
    required this.isDefault,
  });
}

class _MethodCard extends StatelessWidget {
  final PaymentProvider provider;
  final String maskedPhone;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _MethodCard({
    required this.provider,
    required this.maskedPhone,
    required this.isDefault,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  provider.logoAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: provider.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(provider.icon, color: provider.color, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          provider.label,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Par defaut',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maskedPhone,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFamily,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'default') {
                    onSetDefault();
                  } else if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('Definir par defaut'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet();

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  PaymentProvider _provider = PaymentProvider.mtnMomo;
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numero invalide'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    await SecureStorage.addPaymentMethod('${_provider.code}|$phone|0');
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Ajouter un moyen de paiement',
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Operateur',
            style: TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: PaymentProvider.values.map((p) {
              final active = _provider == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _provider = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? p.color : AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            p.logoAsset,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(p.icon,
                                size: 16,
                                color: active ? Colors.white : p.color),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? Colors.white
                                : AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Numero de telephone',
            style: TextStyle(
              fontFamily: AppTheme.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
            ],
            decoration: InputDecoration(
              hintText: '+237 6 99 00 00 00',
              filled: true,
              fillColor: AppColors.surfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
