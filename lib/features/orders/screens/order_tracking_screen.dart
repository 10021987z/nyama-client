import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_progress_timeline.dart';

/// État de livraison dérivé des events socket `delivery:status`.
///
/// Backend émet `ASSIGNED` | `ARRIVED_RESTAURANT` | `PICKED_UP` |
/// `ARRIVED_CLIENT` | `DELIVERED`.
enum DeliveryStage {
  none,
  assigned,
  arrivedRestaurant,
  pickedUp,
  arrivedClient,
  delivered;

  static DeliveryStage fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'ASSIGNED':
        return DeliveryStage.assigned;
      case 'ARRIVED_RESTAURANT':
      case 'ARRIVED_RESTO':
        return DeliveryStage.arrivedRestaurant;
      case 'PICKED_UP':
      case 'PICKEDUP':
        return DeliveryStage.pickedUp;
      case 'ARRIVED_CLIENT':
      case 'ARRIVED':
        return DeliveryStage.arrivedClient;
      case 'DELIVERED':
        return DeliveryStage.delivered;
      default:
        return DeliveryStage.none;
    }
  }
}

/// Écran 1.7 — Suivi commande temps réel avec carte OSM live rider.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  OrderStatus? _liveStatus;
  DeliveryStage _stage = DeliveryStage.none;
  String? _banner;
  Timer? _pollTimer;

  // Live rider tracking
  LatLng? _riderPos;
  DeliveryModel? _liveRider;
  final MapController _mapController = MapController();

  // ETA calculation — mis à jour dès qu'on a la position du rider.
  DateTime _eta = DateTime.now().add(const Duration(minutes: 20));

  // Vitesse moyenne Douala/Yaoundé = 25 km/h
  static const double _avgSpeedKmh = 25.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
    // Polling fallback 5s : rafraîchit la commande tant qu'elle n'est pas
    // DELIVERED ou CANCELLED. Sert de safety net si le socket ne pousse pas
    // les events `order:status` / `delivery:status` en temps réel.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final status = _liveStatus ??
          ref.read(orderDetailProvider(widget.orderId)).value?.status;
      if (status == OrderStatus.delivered ||
          status == OrderStatus.cancelled) {
        _pollTimer?.cancel();
        return;
      }
      ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  // ─── Socket setup ────────────────────────────────────────────────────────

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.emit('order:join', {'orderId': widget.orderId});

    socket.on('order:status', _onOrderStatus);
    socket.on('order:assigned', _onOrderAssigned);
    socket.on('delivery:status', _onDeliveryStatus);
    socket.on('rider:location', _onRiderLocation);
    // Back-compat avec la version précédente (tracking:update = rider:location)
    socket.on('tracking:update', _onRiderLocation);
  }

  void _onOrderStatus(dynamic data) {
    if (!mounted || data is! Map) return;
    final status = OrderStatus.fromString(data['status'] as String?);
    setState(() => _liveStatus = status);
    ref.invalidate(orderDetailProvider(widget.orderId));
    // Arrête le polling dès qu'on atteint un état terminal.
    if (status == OrderStatus.delivered ||
        status == OrderStatus.cancelled) {
      _pollTimer?.cancel();
    }
  }

  void _onOrderAssigned(dynamic data) {
    if (!mounted || data is! Map) return;

    final name = data['riderName'] as String? ?? data['name'] as String?;
    final phone = data['riderPhone'] as String? ?? data['phone'] as String?;
    final photo = data['riderPhotoUrl'] as String? ??
        data['photoUrl'] as String? ??
        data['avatarUrl'] as String?;
    final vehicleType = data['riderVehicleType'] as String? ??
        data['vehicleType'] as String?;
    final vehicleModel = data['riderVehicleModel'] as String? ??
        data['vehicleModel'] as String?;
    final plate = data['riderPlate'] as String? ??
        data['licensePlate'] as String? ??
        data['plate'] as String?;
    final rating = (data['riderRating'] as num?)?.toDouble() ??
        (data['rating'] as num?)?.toDouble();

    final order = ref.read(orderDetailProvider(widget.orderId)).value;
    final base = _liveRider ?? order?.delivery ?? const DeliveryModel();
    final hydrated = base.copyWith(
      riderName: name,
      riderPhone: phone,
      riderPhotoUrl: photo,
      riderVehicleType: vehicleType,
      riderVehicleModel: vehicleModel,
      riderPlate: plate,
      riderRating: rating,
    );

    setState(() {
      _liveRider = hydrated;
      if (_stage == DeliveryStage.none) _stage = DeliveryStage.assigned;
    });
    ref.invalidate(orderDetailProvider(widget.orderId));
  }

  void _onDeliveryStatus(dynamic data) {
    if (!mounted || data is! Map) return;
    final stage = DeliveryStage.fromString(data['status'] as String?);

    // Certains backends intègrent la position rider dans delivery:status.
    final lat = (data['lat'] as num?)?.toDouble() ??
        (data['riderLat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble() ??
        (data['riderLng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      _updateRiderPos(LatLng(lat, lng));
    }

    // Hydrate rider info depuis le payload — premier event ASSIGNED
    // contient généralement nom/photo/véhicule/plaque.
    final name = data['riderName'] as String? ?? data['name'] as String?;
    final phone = data['riderPhone'] as String? ?? data['phone'] as String?;
    final photo = data['riderPhotoUrl'] as String? ??
        data['photoUrl'] as String? ??
        data['avatarUrl'] as String?;
    final vehicleType = data['riderVehicleType'] as String? ??
        data['vehicleType'] as String?;
    final vehicleModel = data['riderVehicleModel'] as String? ??
        data['vehicleModel'] as String?;
    final plate = data['riderPlate'] as String? ??
        data['licensePlate'] as String? ??
        data['plate'] as String?;
    final rating = (data['riderRating'] as num?)?.toDouble() ??
        (data['rating'] as num?)?.toDouble();

    final order = ref.read(orderDetailProvider(widget.orderId)).value;
    final base = _liveRider ?? order?.delivery ?? const DeliveryModel();
    final hydrated = base.copyWith(
      riderName: name,
      riderPhone: phone,
      riderPhotoUrl: photo,
      riderVehicleType: vehicleType,
      riderVehicleModel: vehicleModel,
      riderPlate: plate,
      riderRating: rating,
    );

    setState(() {
      _stage = stage;
      _liveRider = hydrated;
      _banner = _bannerFor(stage);
    });

    if (stage == DeliveryStage.arrivedClient) {
      _triggerArrivalFeedback();
    }

    ref.invalidate(orderDetailProvider(widget.orderId));
  }

  void _onRiderLocation(dynamic data) {
    if (!mounted || data is! Map) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    _updateRiderPos(LatLng(lat, lng));
  }

  void _updateRiderPos(LatLng pos) {
    final order = ref.read(orderDetailProvider(widget.orderId)).value;
    setState(() {
      _riderPos = pos;
      if (order?.delivery.lat != null && order?.delivery.lng != null) {
        final dist = _haversineKm(
          pos,
          LatLng(order!.delivery.lat!, order.delivery.lng!),
        );
        final minutes = (dist / _avgSpeedKmh * 60).round().clamp(1, 180);
        _eta = DateTime.now().add(Duration(minutes: minutes));
      }
    });

    // Recentre la carte si on est en mode carte live (PICKED_UP+)
    if (_showLiveMap && mounted) {
      try {
        _mapController.move(pos, _mapController.camera.zoom);
      } catch (_) {
        // MapController pas encore attaché — ignore.
      }
    }
  }

  void _triggerArrivalFeedback() {
    HapticFeedback.heavyImpact();
    // Fallback "notification locale" : SnackBar persistant — `flutter_local_notifications`
    // n'est pas encore installé. Firebase FCM gère déjà le push cloud côté prod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Votre livreur est arrivé !',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  String? _bannerFor(DeliveryStage s) {
    switch (s) {
      case DeliveryStage.arrivedRestaurant:
        return 'Le livreur est arrivé au restaurant';
      case DeliveryStage.pickedUp:
        return 'Le livreur a récupéré votre commande, il arrive !';
      case DeliveryStage.arrivedClient:
        return 'Votre livreur est arrivé !';
      case DeliveryStage.assigned:
      case DeliveryStage.delivered:
      case DeliveryStage.none:
        return null;
    }
  }

  bool get _showLiveMap =>
      _stage == DeliveryStage.pickedUp ||
      _stage == DeliveryStage.arrivedClient ||
      (_liveStatus == OrderStatus.pickedUp ||
          _liveStatus == OrderStatus.delivering);

  // ─── Dispose ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    final socket = ref.read(socketServiceProvider);
    socket.off('order:status');
    socket.off('order:assigned');
    socket.off('delivery:status');
    socket.off('rider:location');
    socket.off('tracking:update');
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

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
    final currentStatus = _liveStatus ?? order.status;
    final etaMin = _eta.difference(DateTime.now()).inMinutes.clamp(0, 999);
    final rider = _liveRider ?? order.delivery;

    final hasRider = (rider.riderName ?? '').isNotEmpty ||
        (rider.riderPhone ?? '').isNotEmpty ||
        _stage.index >= DeliveryStage.assigned.index;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Carte live rider (haut) — ~220dp, visible dès PICKED_UP ───
        if (_showLiveMap) _buildLiveMap(order),

        // ── Bannière statut delivery ─────────────────────────────────
        if (_banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _Banner(
              message: _banner!,
              stage: _stage,
            ),
          ),

        const SizedBox(height: 16),

        // ── Card rider (dès ASSIGNED) ────────────────────────────────
        if (hasRider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RiderCard(
              rider: rider,
              onCall: () => _callRider(rider.riderPhone),
            ),
          ),

        const SizedBox(height: 24),

        // ── Header statut dynamique + ETA ────────────────────────────
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
                  _showLiveMap
                      ? 'Arrivée dans ~$etaMin min • ${_hm(_eta)}'
                      : 'Livraison estimée : ${_hm(_eta)}',
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

        // ── Timeline 7 étapes ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: OrderProgressTimeline(
            status: currentStatus,
            stepTimestamps: _buildStepTimestamps(order, currentStatus),
          ),
        ),

        const SizedBox(height: 16),

        // ── Détail commande footer ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _OrderFooter(order: order),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Live map ────────────────────────────────────────────────────────────

  Widget _buildLiveMap(OrderModel order) {
    final destLat = order.delivery.lat ?? 4.0511;
    final destLng = order.delivery.lng ?? 9.7679;
    final dest = LatLng(destLat, destLng);

    // Position rider : dernière connue, sinon point d'approche estimé.
    final rider = _riderPos ??
        LatLng(destLat + 0.006, destLng + 0.006);

    final mid = LatLng(
      (rider.latitude + dest.latitude) / 2,
      (rider.longitude + dest.longitude) / 2,
    );

    return SizedBox(
      height: 220,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: mid,
          initialZoom: 14,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.nyama.client',
            maxZoom: 19,
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [rider, dest],
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: dest,
                width: 44,
                height: 44,
                child: const _MapPin(
                  color: AppColors.forestGreen,
                  icon: Icons.home_rounded,
                ),
              ),
              Marker(
                point: rider,
                width: 48,
                height: 48,
                child: const _MapPin(
                  color: AppColors.primary,
                  icon: Icons.delivery_dining_rounded,
                  pulse: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Haversine distance ─────────────────────────────────────────────────

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(b.latitude - a.latitude);
    final dLng = toRad(b.longitude - a.longitude);
    final la1 = toRad(a.latitude);
    final la2 = toRad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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

// ─── Banner ─────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final String message;
  final DeliveryStage stage;

  const _Banner({required this.message, required this.stage});

  IconData get _icon {
    switch (stage) {
      case DeliveryStage.arrivedRestaurant:
        return Icons.restaurant_rounded;
      case DeliveryStage.pickedUp:
        return Icons.delivery_dining_rounded;
      case DeliveryStage.arrivedClient:
        return Icons.location_on_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get _bg {
    switch (stage) {
      case DeliveryStage.arrivedClient:
        return AppColors.primary;
      case DeliveryStage.pickedUp:
        return AppColors.forestGreen;
      default:
        return AppColors.primaryLight;
    }
  }

  Color get _fg {
    switch (stage) {
      case DeliveryStage.arrivedClient:
      case DeliveryStage.pickedUp:
        return Colors.white;
      default:
        return AppColors.charcoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map pin ────────────────────────────────────────────────────────────────

class _MapPin extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool pulse;

  const _MapPin({
    required this.color,
    required this.icon,
    this.pulse = false,
  });

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: 18),
    );

    if (!widget.pulse) return Center(child: dot);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36 + v * 16,
              height: 36 + v * 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.25 * (1 - v)),
              ),
            ),
            dot,
          ],
        );
      },
    );
  }
}

// ─── Rider card ─────────────────────────────────────────────────────────────

class _RiderCard extends StatelessWidget {
  final DeliveryModel rider;
  final VoidCallback onCall;

  const _RiderCard({required this.rider, required this.onCall});

  Future<void> _sms() async {
    final number = rider.riderPhone ?? '+237699000000';
    final uri = Uri.parse('sms:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final name = rider.riderName ?? 'Livreur';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    final vehicle = [
      if ((rider.riderVehicleType ?? '').isNotEmpty) rider.riderVehicleType,
      if ((rider.riderVehicleModel ?? '').isNotEmpty) rider.riderVehicleModel,
    ].whereType<String>().join(' • ');
    final plate = rider.riderPlate;
    final rating = rider.riderRating;

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
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: (rider.riderPhotoUrl ?? '').isNotEmpty
                    ? NetworkImage(rider.riderPhotoUrl!)
                    : null,
                child: (rider.riderPhotoUrl ?? '').isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFF5A623)),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (vehicle.isNotEmpty)
                  Text(
                    vehicle,
                    style: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if ((plate ?? '').isNotEmpty)
                  Text(
                    'Plaque : $plate',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 11,
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

// ─── TODO BACKEND ───────────────────────────────────────────────────────────
// Pour que la carte live fonctionne à 100%, le backend doit émettre :
//   - `rider:location` { orderId, riderId, lat, lng } toutes les 5s
//     après l'event `delivery:status` PICKED_UP.
//   - `delivery:status` avec payload { orderId, status, riderName, riderPhone,
//     riderPhotoUrl, riderVehicleType, riderVehicleModel, riderPlate,
//     riderRating, lat?, lng? }.
// Ces fields optionnels sont tous absorbés par _onDeliveryStatus / _onRiderLocation.
