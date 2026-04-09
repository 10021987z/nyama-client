import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

class _Quartier {
  final String name;
  final String city;
  const _Quartier(this.name, this.city);
}

const _kAllQuartiers = <_Quartier>[
  _Quartier('Akwa', 'Douala 1er'),
  _Quartier('Bonapriso', 'Douala 1er'),
  _Quartier('Deido', 'Douala 1er'),
  _Quartier('Bonanjo', 'Douala 1er'),
  _Quartier('Bastos', 'Yaoundé'),
  _Quartier('Bali', 'Douala 1er'),
  _Quartier('Ndokotti', 'Douala 3e'),
  _Quartier('New Bell', 'Douala 2e'),
];

const _kPopular = <_Quartier>[
  _Quartier('Akwa', 'Douala 1er'),
  _Quartier('Bonapriso', 'Douala 1er'),
  _Quartier('Deido', 'Douala 1er'),
  _Quartier('Bastos', 'Yaoundé'),
  _Quartier('Bonanjo', 'Douala 1er'),
  _Quartier('Ndokotti', 'Douala 3e'),
];

class QuartierSelectionScreen extends StatefulWidget {
  const QuartierSelectionScreen({super.key});

  @override
  State<QuartierSelectionScreen> createState() =>
      _QuartierSelectionScreenState();
}

class _QuartierSelectionScreenState extends State<QuartierSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _locating = false;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text);
      }
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(_Quartier q) async {
    await SecureStorage.saveQuartier(q.city, q.name);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      // 1) Service GPS activé ?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Active le GPS dans les paramètres');
        await Geolocator.openLocationSettings();
        return;
      }

      // 2) Permissions
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showError('Permission de localisation refusée');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showError('Active la localisation dans les paramètres');
        await Geolocator.openAppSettings();
        return;
      }

      // 3) Position (timeout 15s)
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final q = _reverseGeocode(pos.latitude, pos.longitude);
      await SecureStorage.saveQuartier(q.city, q.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Position trouvée : ${q.city}, ${q.name}'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home');
    } catch (e) {
      _showError('Erreur GPS: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // Géocodage inversé simplifié — retourne le quartier le plus proche
  // de quelques points connus de Douala/Yaoundé.
  _Quartier _reverseGeocode(double lat, double lng) {
    const anchors = <(_Quartier, double, double)>[
      (_Quartier('Akwa', 'Douala 1er'), 4.0486, 9.7679),
      (_Quartier('Bonapriso', 'Douala 1er'), 4.0383, 9.6927),
      (_Quartier('Deido', 'Douala 1er'), 4.0681, 9.7036),
      (_Quartier('Bonanjo', 'Douala 1er'), 4.0500, 9.6900),
      (_Quartier('Ndokotti', 'Douala 3e'), 4.0578, 9.7300),
      (_Quartier('Bastos', 'Yaoundé'), 3.8900, 11.5130),
    ];
    _Quartier best = anchors.first.$1;
    double bestD = double.infinity;
    for (final a in anchors) {
      final dLat = a.$2 - lat;
      final dLng = a.$3 - lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = a.$1;
      }
    }
    return best;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  List<_Quartier> get _suggestions {
    if (_query.trim().isEmpty) return const [];
    final q = _query.toLowerCase();
    return _kAllQuartiers
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.city.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSuggestions(suggestions),
                    ],
                    const SizedBox(height: 16),
                    _buildGpsButton(),
                    const SizedBox(height: 24),
                    _buildSeparator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Quartiers populaires',
                      style: TextStyle(
                        fontFamily: AppTheme.headlineFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._kPopular.map(_buildQuartierTile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/onboarding/otp'),
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
          ),
          const Text(
            'Adresse de livraison',
            style: TextStyle(
              fontFamily: AppTheme.headlineFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.charcoal,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Rechercher une adresse, un quartier...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () => _searchCtrl.clear(),
              child: const Icon(Icons.close,
                  color: AppColors.textSecondary, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<_Quartier> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pick(items[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.charcoal,
                          ),
                          children: [
                            TextSpan(
                              text: items[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: '  ${items[i].city}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textTertiary, size: 20),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.surfaceLow),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: _locating
                  ? const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    )
                  : ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                        CurvedAnimation(
                          parent: _pulseCtrl,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Icon(Icons.my_location,
                          color: AppColors.primary, size: 24),
                    ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utiliser ma position actuelle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Via GPS',
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
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: const [
        Expanded(child: Divider(color: AppColors.surfaceLow, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou choisir un quartier',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.surfaceLow, thickness: 1)),
      ],
    );
  }

  Widget _buildQuartierTile(_Quartier q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(q),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        q.city,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
