import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/data/models/cook.dart';
import '../../home/providers/home_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  // Douala centre par défaut
  static const _defaultCenter = LatLng(4.0445, 9.6966);

  Set<Marker> _buildMarkers(List<Cook> cooks) {
    final markers = <Marker>{};
    for (final cook in cooks) {
      if (cook.locationLat != null && cook.locationLng != null) {
        markers.add(Marker(
          markerId: MarkerId(cook.id),
          position: LatLng(cook.locationLat!, cook.locationLng!),
          infoWindow: InfoWindow(
            title: cook.displayName,
            snippet: cook.specialty.take(2).join(' · '),
            onTap: () => context.push('/restaurant/${cook.id}'),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final cooksAsync = ref.watch(cooksProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Restaurants sur la Carte',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: cooksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cooksProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (result) {
          final cooks = result.data;
          final markers = _buildMarkers(cooks);

          // Si on a des markers, calculer le centre moyen
          LatLng center = _defaultCenter;
          if (markers.isNotEmpty) {
            double latSum = 0, lngSum = 0;
            for (final m in markers) {
              latSum += m.position.latitude;
              lngSum += m.position.longitude;
            }
            center = LatLng(
              latSum / markers.length,
              lngSum / markers.length,
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: 13,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (c) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(c);
                  }
                },
              ),
              // Badge nombre de restaurants
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cooks.length} restaurant${cooks.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const Text(
                              'Touche un marqueur pour voir le menu',
                              style: TextStyle(
                                fontFamily: 'NunitoSans',
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
              ),
            ],
          );
        },
      ),
    );
  }
}
