import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_progress_timeline.dart';

/// Écran 1.7 — Suivi commande temps réel.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  OrderStatus? _liveStatus;
  Timer? _pollTimer;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final DateTime _eta = DateTime.now().add(const Duration(minutes: 12));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.emit('order:join', {'orderId': widget.orderId});

    // tracking:update → met à jour la position du livreur
    socket.on('tracking:update', (data) {
      if (!mounted || data is! Map) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final pos = LatLng(lat, lng);
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'rider');
        _markers.add(Marker(
          markerId: const MarkerId('rider'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Kevin'),
        ));
        _updatePolyline(pos);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    });

    // order:status → met à jour l'étape active
    socket.on('order:status', (data) {
      if (!mounted || data is! Map) return;
      final status = OrderStatus.fromString(data['status'] as String?);
      setState(() => _liveStatus = status);
      ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  void _updatePolyline(LatLng rider) {
    final order = ref.read(orderDetailProvider(widget.orderId)).value;
    if (order?.delivery.lat == null || order?.delivery.lng == null) return;
    final dest = LatLng(order!.delivery.lat!, order.delivery.lng!);
    _polylines
      ..clear()
      ..add(Polyline(
        polylineId: const PolylineId('route'),
        points: [rider, dest],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
  }

  @override
  void dispose() {
    final socket = ref.read(socketServiceProvider);
    socket.off('tracking:update');
    socket.off('order:status');
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrder = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.charcoal),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Suivi de commande',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ),
      body: asyncOrder.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(
                  fontFamily: 'NunitoSans', color: AppColors.textSecondary)),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    final hasDest = order.delivery.lat != null && order.delivery.lng != null;
    final destLatLng =
        hasDest ? LatLng(order.delivery.lat!, order.delivery.lng!)
                : const LatLng(4.0503, 9.7679);

    // Position du restaurant (mock — à remplacer par les vraies données)
    const restaurantLatLng = LatLng(4.0445, 9.6966);

    // Point milieu pour le livreur (simulation)
    final riderLatLng = LatLng(
      (restaurantLatLng.latitude + destLatLng.latitude) / 2,
      (restaurantLatLng.longitude + destLatLng.longitude) / 2,
    );

    // Marqueur restaurant (orange)
    _markers.removeWhere((m) => m.markerId.value == 'restaurant');
    _markers.add(Marker(
      markerId: const MarkerId('restaurant'),
      position: restaurantLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: order.items.isNotEmpty ? order.items.first.name : 'Restaurant',
      ),
    ));

    // Marqueur client (vert)
    _markers.removeWhere((m) => m.markerId.value == 'destination');
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Chez vous'),
    ));

    // Marqueur livreur (bleu) — au milieu du trajet par défaut
    if (_markers.every((m) => m.markerId.value != 'rider')) {
      _markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: riderLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Kevin — En route'),
      ));
    }

    // Polyline restaurant → livreur → client
    final riderPos = _markers
        .firstWhere((m) => m.markerId.value == 'rider')
        .position;
    _polylines
      ..clear()
      ..add(Polyline(
        polylineId: const PolylineId('route'),
        points: [restaurantLatLng, riderPos, destLatLng],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));

    // Calcul du centre pour la caméra
    final centerLat = (restaurantLatLng.latitude + destLatLng.latitude) / 2;
    final centerLng = (restaurantLatLng.longitude + destLatLng.longitude) / 2;

    final currentStatus = _liveStatus ?? order.status;
    final etaMin = _eta.difference(DateTime.now()).inMinutes.clamp(0, 999);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Carte (40%) avec ETA en overlay ──────────────────────────
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.40,
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(centerLat, centerLng),
                    zoom: 13,
                  ),
                  markers: Set.from(_markers),
                  polylines: Set.from(_polylines),
                  onMapCreated: (c) {
                    _mapController = c;
                    // Ajuste la vue pour inclure tous les points
                    Future.delayed(const Duration(milliseconds: 300), () {
                      final bounds = LatLngBounds(
                        southwest: LatLng(
                          [restaurantLatLng.latitude, destLatLng.latitude, riderPos.latitude]
                              .reduce((a, b) => a < b ? a : b),
                          [restaurantLatLng.longitude, destLatLng.longitude, riderPos.longitude]
                              .reduce((a, b) => a < b ? a : b),
                        ),
                        northeast: LatLng(
                          [restaurantLatLng.latitude, destLatLng.latitude, riderPos.latitude]
                              .reduce((a, b) => a > b ? a : b),
                          [restaurantLatLng.longitude, destLatLng.longitude, riderPos.longitude]
                              .reduce((a, b) => a > b ? a : b),
                        ),
                      );
                      c.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 60),
                      );
                    });
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
              // ETA overlay card
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESTIMATION',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arrivée dans ~$etaMin min',
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Info livreur ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _RiderCard(
            phone: order.delivery.riderPhone,
            onCall: () => _callRider(order.delivery.riderPhone),
          ),
        ),

        const SizedBox(height: 24),

        // ── Header statut (dynamique) + ETA ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headlineFor(currentStatus),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              if (currentStatus != OrderStatus.delivered &&
                  currentStatus != OrderStatus.cancelled)
                Text(
                  'Livraison estimée : ${_hm(_eta)}',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Timeline 7 étapes ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: OrderProgressTimeline(
            status: currentStatus,
            stepTimestamps: _buildStepTimestamps(order, currentStatus),
          ),
        ),

        const SizedBox(height: 16),

        // ── Détail commande footer ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _OrderFooter(order: order),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  String _hm(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());

  String _headlineFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'Commande envoyée au restaurant';
      case OrderStatus.confirmed:
        return 'Commande acceptée';
      case OrderStatus.preparing:
        return 'Votre commande est en préparation';
      case OrderStatus.ready:
      case OrderStatus.assigned:
        return 'Votre commande est prête';
      case OrderStatus.pickedUp:
        return 'Votre livreur a récupéré la commande';
      case OrderStatus.delivering:
        return 'Votre commande arrive bientôt';
      case OrderStatus.delivered:
        return 'Commande livrée';
      case OrderStatus.cancelled:
        return 'Commande annulée';
    }
  }

  /// Horodatages étalés entre `createdAt` et `updatedAt` pour les étapes
  /// franchies. Remplacer par les timestamps backend réels dès qu'ils sont
  /// disponibles (ex: `order.timeline.preparingAt`).
  List<DateTime?> _buildStepTimestamps(OrderModel order, OrderStatus status) {
    final timestamps = List<DateTime?>.filled(7, null);
    final progress = _progressFor(status);
    if (progress <= 0) return timestamps;

    timestamps[0] = order.createdAt;
    if (progress >= 2) {
      final start = order.createdAt;
      final end = order.updatedAt.isAfter(start) ? order.updatedAt : DateTime.now();
      final span = end.difference(start);
      for (int i = 1; i < progress; i++) {
        timestamps[i] = start.add(span * (i / (progress - 1)));
      }
    }
    if (status == OrderStatus.delivered && order.delivery.deliveredAt != null) {
      timestamps[6] = order.delivery.deliveredAt;
    }
    return timestamps;
  }

  int _progressFor(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.delivering:
        return 6;
      case OrderStatus.pickedUp:
        return 5;
      case OrderStatus.ready:
      case OrderStatus.assigned:
        return 4;
      case OrderStatus.preparing:
        return 3;
      case OrderStatus.confirmed:
        return 2;
      case OrderStatus.pending:
        return 1;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Future<void> _callRider(String? phone) async {
    final number = phone ?? '+237699000000';
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Rider card ───────────────────────────────────────────────────────────

class _RiderCard extends StatelessWidget {
  final String? phone;
  final VoidCallback onCall;

  const _RiderCard({required this.phone, required this.onCall});

  Future<void> _sms() async {
    final number = phone ?? '+237699000000';
    final uri = Uri.parse('sms:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Stack(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  'K',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kevin',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Moto • Honda CB 125',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _RoundBtn(icon: Icons.phone_rounded, onTap: onCall),
          const SizedBox(width: 8),
          _RoundBtn(icon: Icons.chat_bubble_outline_rounded, onTap: _sms),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.forestGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Order footer ─────────────────────────────────────────────────────────

class _OrderFooter extends StatelessWidget {
  final OrderModel order;
  const _OrderFooter({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortRef = order.shortId.length >= 4
        ? order.shortId.substring(0, 4)
        : order.shortId;
    final firstItem = order.items.isNotEmpty ? order.items.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMANDE #NY-$shortRef',
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                  letterSpacing: 1,
                ),
              ),
              Text(
                order.totalXaf.toFcfa(),
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (firstItem != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.primaryLight,
                    child: firstItem.imageUrl != null
                        ? Image.network(firstItem.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.primary))
                        : const Icon(Icons.restaurant_menu_rounded,
                            color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${firstItem.quantity}× ${firstItem.name}'
                    '${order.items.length > 1 ? "  +${order.items.length - 1}" : ""}',
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
