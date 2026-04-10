import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_theme.dart';

const String _kGoogleApiKey = 'AIzaSyBk2tpT6aYYYSSKxo7onOD7Xv_Sq4bnuz8';

/// Centre par défaut : Douala, Akwa
const LatLng _kDefaultCenter = LatLng(4.0445, 9.6966);

class _Quartier {
  final String name;
  final String city;
  final LatLng position;
  const _Quartier(this.name, this.city, this.position);
}

const _kPopularQuartiers = <_Quartier>[
  _Quartier('Akwa', 'Douala 1er', LatLng(4.0486, 9.7679)),
  _Quartier('Bonapriso', 'Douala 1er', LatLng(4.0383, 9.6927)),
  _Quartier('Deido', 'Douala 1er', LatLng(4.0681, 9.7036)),
  _Quartier('Bonanjo', 'Douala 1er', LatLng(4.0500, 9.6900)),
  _Quartier('Bastos', 'Yaoundé', LatLng(3.8900, 11.5130)),
  _Quartier('Bali', 'Douala 1er', LatLng(4.0430, 9.6980)),
  _Quartier('Ndokotti', 'Douala 3e', LatLng(4.0578, 9.7300)),
  _Quartier('New Bell', 'Douala 2e', LatLng(4.0350, 9.7200)),
];

class QuartierSelectionScreen extends StatefulWidget {
  const QuartierSelectionScreen({super.key});

  @override
  State<QuartierSelectionScreen> createState() =>
      _QuartierSelectionScreenState();
}

class _QuartierSelectionScreenState extends State<QuartierSelectionScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String _address = '';
  String _city = '';
  String _quartier = '';
  bool _isDragging = false;
  bool _locating = false;

  List<_PlacePrediction> _predictions = [];
  Timer? _debounce;

  late final AnimationController _pinBounceCtrl;
  late final Animation<double> _pinScale;

  @override
  void initState() {
    super.initState();
    _pinBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pinBounceCtrl, curve: Curves.easeInOut),
    );
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _pinBounceCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Google Places Autocomplete ──────────────────────────────────────────

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchCtrl.text.trim();
    if (query.length < 3) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPredictions(query);
    });
  }

  Future<void> _fetchPredictions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&key=$_kGoogleApiKey'
      '&components=country:cm'
      '&language=fr',
    );
    try {
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final preds = (json['predictions'] as List?)
              ?.map((p) => _PlacePrediction(
                    description: p['description'] as String? ?? '',
                    placeId: p['place_id'] as String? ?? '',
                  ))
              .toList() ??
          [];
      if (mounted) setState(() => _predictions = preds);
    } catch (_) {}
  }

  Future<void> _selectPrediction(_PlacePrediction pred) async {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _predictions = []);

    // Get place details for lat/lng
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${pred.placeId}'
      '&fields=geometry'
      '&key=$_kGoogleApiKey',
    );
    try {
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final loc = json['result']?['geometry']?['location'];
      if (loc == null) return;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
      );
    } catch (_) {}
  }

  // ── Geocoding inversé ──────────────────────────────────────────────────

  Future<void> _reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${pos.latitude},${pos.longitude}'
      '&key=$_kGoogleApiKey'
      '&language=fr',
    );
    try {
      final resp = await http.get(url);
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = json['results'] as List?;
      if (results == null || results.isEmpty) return;

      String addr = results[0]['formatted_address'] as String? ?? '';
      String city = '';
      String quartier = '';

      // Parse address components
      final components =
          results[0]['address_components'] as List? ?? [];
      for (final comp in components) {
        final types = (comp['types'] as List?)?.cast<String>() ?? [];
        final name = comp['long_name'] as String? ?? '';
        if (types.contains('sublocality') ||
            types.contains('sublocality_level_1') ||
            types.contains('neighborhood')) {
          quartier = name;
        }
        if (types.contains('locality')) {
          city = name;
        }
      }

      if (mounted) {
        setState(() {
          _address = addr;
          _city = city;
          _quartier = quartier.isNotEmpty ? quartier : city;
        });
      }
    } catch (_) {}
  }

  // ── GPS position ───────────────────────────────────────────────────────

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Active le GPS dans les paramètres');
        await Geolocator.openLocationSettings();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Permission de localisation refusée');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Active la localisation dans les paramètres');
        await Geolocator.openAppSettings();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          16,
        ),
      );
    } catch (e) {
      _showSnack('Erreur GPS : $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ── Confirmer adresse ──────────────────────────────────────────────────

  Future<void> _confirmAddress() async {
    final city = _city.isNotEmpty ? _city : 'Douala';
    final quartier = _quartier.isNotEmpty ? _quartier : 'Akwa';
    await SecureStorage.saveQuartier(city, quartier);
    if (!mounted) return;
    context.go('/home');
  }

  // ── Quartiers populaires bottomsheet ───────────────────────────────────

  void _showPopularQuartiers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quartiers populaires',
              style: TextStyle(
                fontFamily: AppTheme.headlineFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_kPopularQuartiers.length, (i) {
              final q = _kPopularQuartiers[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  q.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.charcoal,
                  ),
                ),
                subtitle: Text(
                  q.city,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
                onTap: () {
                  Navigator.pop(ctx);
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(q.position, 16),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Google Map plein écran ──
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _kDefaultCenter,
                zoom: 15,
              ),
              onMapCreated: (c) {
                _mapController = c;
                // Initial reverse geocode
                _reverseGeocode(_kDefaultCenter);
              },
              onCameraMove: (_) {
                if (!_isDragging) {
                  setState(() => _isDragging = true);
                  _pinBounceCtrl.forward();
                }
              },
              onCameraIdle: () async {
                if (_isDragging) {
                  setState(() => _isDragging = false);
                  _pinBounceCtrl.reverse();
                }
                // Récupère le centre actuel de la carte
                final bounds =
                    await _mapController?.getVisibleRegion();
                if (bounds == null) return;
                final center = LatLng(
                  (bounds.northeast.latitude +
                          bounds.southwest.latitude) /
                      2,
                  (bounds.northeast.longitude +
                          bounds.southwest.longitude) /
                      2,
                );
                _reverseGeocode(center);
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),

          // ── Pin central fixe ──
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: AnimatedBuilder(
                animation: _pinScale,
                builder: (_, _) => Transform.scale(
                  scale: _pinScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.charcoal
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Barre de recherche en haut ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search bar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/onboarding/otp'),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.charcoal, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.charcoal,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText:
                                'Rechercher une adresse...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _predictions = []);
                          },
                          child: const Icon(Icons.close,
                              color: AppColors.textSecondary,
                              size: 20),
                        ),
                    ],
                  ),
                ),

                // Suggestions Places
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints:
                        const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _predictions.length,
                      separatorBuilder: (_, _) => const Divider(
                          height: 1, color: AppColors.surfaceLow),
                      itemBuilder: (_, i) {
                        final pred = _predictions[i];
                        return InkWell(
                          onTap: () =>
                              _selectPrediction(pred),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.location_on_outlined,
                                    color:
                                        AppColors.textSecondary,
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    pred.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.charcoal,
                                    ),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Bouton "Ma position" flottant ──
          Positioned(
            right: 16,
            bottom: 200,
            child: GestureDetector(
              onTap: _useMyLocation,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.my_location,
                        color: AppColors.primary, size: 24),
              ),
            ),
          ),

          // ── Bouton "Quartiers populaires" ──
          Positioned(
            left: 16,
            bottom: 200,
            child: GestureDetector(
              onTap: _showPopularQuartiers,
              child: Container(
                height: 40,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Quartiers populaires',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Card adresse en bas ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(
                      fontFamily: AppTheme.headlineFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address.isNotEmpty
                              ? _address
                              : 'Déplace la carte pour choisir ta position',
                          style: TextStyle(
                            fontSize: 14,
                            color: _address.isNotEmpty
                                ? AppColors.charcoal
                                : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _address.isNotEmpty ? _confirmAddress : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        disabledBackgroundColor:
                            AppColors.forestGreen.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmer cette adresse',
                        style: TextStyle(
                          fontFamily: AppTheme.headlineFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacePrediction {
  final String description;
  final String placeId;
  const _PlacePrediction({
    required this.description,
    required this.placeId,
  });
}
