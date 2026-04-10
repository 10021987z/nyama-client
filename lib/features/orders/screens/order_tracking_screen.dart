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

/// Écran 1.7 — Suivi commande temps réel.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  OrderStatus? _liveStatus;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late AnimationController _pulseController;

  // Horodatages timeline (en attendant un payload backend riche)
  final DateTime _receivedAt = DateTime.now().subtract(const Duration(minutes: 17));
  final DateTime _preparingAt = DateTime.now().subtract(const Duration(minutes: 5));
  final DateTime _eta = DateTime.now().add(const Duration(minutes: 12));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
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
    _mapController?.dispose();
    _pulseController.dispose();
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

        // ── Timeline ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statut de la livraison',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),
              _TimelineStep(
                label: 'Commande reçue',
                time: _hm(_receivedAt),
                description: 'Nous avons bien reçu votre commande',
                status: _stepStatus(currentStatus, 0),
                isFirst: true,
                pulseController: _pulseController,
              ),
              _TimelineStep(
                label: 'En préparation',
                time: _hm(_preparingAt),
                description:
                    'Le chef prépare votre ${order.items.isNotEmpty ? order.items.first.name : "commande"}',
                status: _stepStatus(currentStatus, 1),
                pulseController: _pulseController,
              ),
              _TimelineStep(
                label: 'En route',
                time: '',
                description: 'Kevin a récupéré votre commande',
                status: _stepStatus(currentStatus, 2),
                pulseController: _pulseController,
              ),
              _TimelineStep(
                label: 'Livrée',
                time: '',
                description: 'Prévu vers ${_hm(_eta)}',
                status: _stepStatus(currentStatus, 3),
                isLast: true,
                pulseController: _pulseController,
              ),
            ],
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

  String _stepStatus(OrderStatus status, int idx) {
    int progress;
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        progress = 0;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        progress = 1;
      case OrderStatus.delivering:
        progress = 2;
      case OrderStatus.delivered:
        progress = 3;
      case OrderStatus.cancelled:
        progress = -1;
    }
    if (idx < progress) return 'done';
    if (idx == progress) return 'active';
    return 'future';
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

// ─── Timeline step ────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final String time;
  final String description;
  final String status; // 'done' | 'active' | 'future'
  final bool isFirst;
  final bool isLast;
  final AnimationController pulseController;

  const _TimelineStep({
    required this.label,
    required this.time,
    required this.description,
    required this.status,
    this.isFirst = false,
    this.isLast = false,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'done';
    final isActive = status == 'active';

    final Color dotColor = isDone
        ? AppColors.forestGreen
        : isActive
            ? AppColors.primary
            : AppColors.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 6,
                      color: isDone || isActive
                          ? AppColors.forestGreen
                          : AppColors.outlineVariant),
                isActive
                    ? AnimatedBuilder(
                        animation: pulseController,
                        builder: (_, __) => Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor.withValues(
                                alpha: 0.25 + 0.35 * pulseController.value),
                            border: Border.all(color: dotColor, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? dotColor : Colors.transparent,
                          border: Border.all(color: dotColor, width: 2),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 28),
                      color: isDone
                          ? AppColors.forestGreen
                          : AppColors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDone || isActive
                              ? AppColors.charcoal
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '— $time',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
