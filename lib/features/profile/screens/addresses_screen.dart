import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  String? _currentCity;
  String? _currentQuartier;
  List<_SavedAddress> _saved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final city = await SecureStorage.getCity();
    final quartier = await SecureStorage.getQuartier();
    final raw = await SecureStorage.getSavedAddresses();
    final parsed = raw
        .map((s) {
          final parts = s.split('|');
          if (parts.length < 2) return null;
          return _SavedAddress(
            label: parts[0],
            address: parts[1],
            isDefault: parts.length >= 3 && parts[2] == '1',
          );
        })
        .whereType<_SavedAddress>()
        .toList();
    if (!mounted) return;
    setState(() {
      _currentCity = city;
      _currentQuartier = quartier;
      _saved = parsed;
      _loading = false;
    });
  }

  Future<void> _setDefault(int index) async {
    await SecureStorage.setDefaultSavedAddress(index);
    _load();
  }

  Future<void> _remove(int index) async {
    await SecureStorage.removeSavedAddress(index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = (_currentQuartier != null && _currentQuartier!.isNotEmpty)
        ? '${_currentQuartier!}${_currentCity != null && _currentCity!.isNotEmpty ? ', ${_currentCity!}' : ''}'
        : 'Aucune adresse definie';

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Mes adresses'),
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
                // Adresse actuelle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Adresse actuelle',
                                  style: TextStyle(
                                    fontFamily: AppTheme.headlineFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Actuelle',
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentLabel,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_saved.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Adresses sauvegardees',
                      style: TextStyle(
                        fontFamily: AppTheme.headlineFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  ..._saved.asMap().entries.map((entry) {
                    final index = entry.key;
                    final address = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressCard(
                        address: address,
                        onSetDefault: () => _setDefault(index),
                        onRemove: () => _remove(index),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 8),
                // Add button
                GestureDetector(
                  onTap: () => context.push('/onboarding/quartier'),
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
                          'Ajouter une adresse',
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

class _SavedAddress {
  final String label;
  final String address;
  final bool isDefault;
  const _SavedAddress({
    required this.label,
    required this.address,
    required this.isDefault,
  });
}

class _AddressCard extends StatelessWidget {
  final _SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _AddressCard({
    required this.address,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.forestGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: const TextStyle(
                            fontFamily: AppTheme.headlineFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (address.isDefault)
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
                      address.address,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFamily,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.surfaceLow),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!address.isDefault)
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSetDefault,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Par defaut',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.forestGreen,
                    ),
                  ),
                ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
