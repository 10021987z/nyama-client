import 'dart:async';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
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

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  OrderStatus? _liveStatus;
  DeliveryStage _stage = DeliveryStage.none;
  String? _banner;
  Timer? _pollTimer;
  // Flag de garde pour la navigation vers /rating/:id — évite les multiples
  // pushes si `order:status` et `delivery:status` arrivent tous les deux avec
  // un état DELIVERED (le Timer 2s ne doit se planifier qu'UNE fois).
  bool _navScheduled = false;

  // Live rider tracking
  LatLng? _riderPos;
  LatLng? _riderTargetPos;
  LatLng? _riderPrevPos;
  AnimationController? _riderAnim;
  DeliveryModel? _liveRider;
  String? _riderId;
  bool _didHttpLocationFallback = false;
  final MapController _mapController = MapController();

  // ETA calculation — mis à jour dès qu'on a la position du rider.
  DateTime _eta = DateTime.now().add(const Duration(minutes: 20));

  // Vitesse moyenne Douala/Yaoundé = 25 km/h
  static const double _avgSpeedKmh = 25.0;

  @override
  void initState() {
    super.initState();
    _riderAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_onRiderTween);
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
    // Backend (events.gateway.ts) expose 'order:subscribe' pour rejoindre la
    // room `order-<id>`. L'ancien nom `order:join` n'est pas routé côté NestJS
    // → on envoie les deux pour être robuste aux déploiements mixtes.
    socket.emit('order:subscribe', {'orderId': widget.orderId});
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

    // Depuis LOT 1, le backend pousse `deliveryStatus` (ex: ARRIVED_CLIENT) et
    // un objet `rider` (id, name, phone, photo, vehicleType, plateNumber) dans
    // le payload `order:status`. On hydrate le DeliveryStage et la card rider.
    final deliveryStatusRaw = data['deliveryStatus'] as String?;
    final newStage = deliveryStatusRaw != null
        ? DeliveryStage.fromString(deliveryStatusRaw)
        : null;
    _hydrateRiderFromPayload(data);

    // Le backend émet `order:status = PICKED_UP` pour PICKED_UP ET pour
    // ARRIVED_CLIENT. Pour que le point "En route" s'allume (au lieu de rester
    // à "Récupérée"), on promeut en `delivering` dès qu'on sait (via
    // deliveryStatus ou stage) que le livreur est au moins en route.
    OrderStatus effective = status;
    if (newStage == DeliveryStage.pickedUp ||
        newStage == DeliveryStage.arrivedClient ||
        _stage == DeliveryStage.pickedUp ||
        _stage == DeliveryStage.arrivedClient) {
      if (_progressFor(OrderStatus.delivering) > _progressFor(effective)) {
        effective = OrderStatus.delivering;
      }
    }

    setState(() {
      // N'autorise pas la timeline à régresser si un event tardif arrive.
      final current = _liveStatus;
      if (current == null ||
          _progressFor(effective) >= _progressFor(current) ||
          effective == OrderStatus.cancelled) {
        _liveStatus = effective;
      }
      if (newStage != null && newStage != DeliveryStage.none) {
        _stage = newStage;
        _banner = _bannerFor(newStage);
      }
    });
    ref.invalidate(orderDetailProvider(widget.orderId));

    // Vibration + ouverture écran notation quand la livraison est terminée.
    if (status == OrderStatus.delivered) {
      _triggerDeliveredFeedback();
      _navigateToRating();
    }
    if (newStage == DeliveryStage.arrivedClient) {
      _triggerArrivalFeedback();
    }

    // Arrête le polling dès qu'on atteint un état terminal.
    if (status == OrderStatus.delivered ||
        status == OrderStatus.cancelled) {
      _pollTimer?.cancel();
    }
  }

  void _onOrderAssigned(dynamic data) {
    if (!mounted || data is! Map) return;
    _hydrateRiderFromPayload(data);
    setState(() {
      if (_stage == DeliveryStage.none) _stage = DeliveryStage.assigned;
    });
    ref.invalidate(orderDetailProvider(widget.orderId));
    // Dès l'assignation du livreur, on essaie une fois le HTTP fallback
    // `GET /rider/:id/location` pour afficher un premier point sur la carte
    // avant même le premier `rider:location` du socket.
    _tryHttpRiderLocation();
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

    _hydrateRiderFromPayload(data);

    // Mapping delivery.status → OrderStatus pour faire avancer la timeline 7
    // étapes même quand le backend n'envoie pas d'event `order:status` séparé.
    //   PICKED_UP / ARRIVED_CLIENT → `delivering` (point "En route" allumé,
    //                                  point "Récupérée" déjà franchi).
    //   DELIVERED                  → `delivered` (tous les points allumés).
    OrderStatus? promoted;
    switch (stage) {
      case DeliveryStage.pickedUp:
      case DeliveryStage.arrivedClient:
        promoted = OrderStatus.delivering;
        break;
      case DeliveryStage.delivered:
        promoted = OrderStatus.delivered;
        break;
      case DeliveryStage.assigned:
        // "Prête" reste l'état côté client. L'écran allume juste la card rider.
        break;
      case DeliveryStage.arrivedRestaurant:
      case DeliveryStage.none:
        break;
    }

    setState(() {
      _stage = stage;
      _banner = _bannerFor(stage);
      if (promoted != null) {
        // Ne jamais régresser la timeline — on garde le plus avancé des deux.
        final current = _liveStatus;
        if (current == null ||
            _progressFor(promoted) > _progressFor(current)) {
          _liveStatus = promoted;
        }
      }
    });

    if (stage == DeliveryStage.arrivedClient) {
      _triggerArrivalFeedback();
    }
    if (stage == DeliveryStage.delivered) {
      _triggerDeliveredFeedback();
      _navigateToRating();
      _pollTimer?.cancel();
    }

    ref.invalidate(orderDetailProvider(widget.orderId));
  }

  /// Hydrate `_liveRider` depuis un payload backend. Accepte aussi bien les
  /// champs plats (`riderName`, `riderPhone`, …) que le nesting produit par le
  /// LOT 1 : `rider: { id, name, phone, photo, vehicleType, plateNumber }`.
  void _hydrateRiderFromPayload(Map data) {
    final Map? riderObj = data['rider'] is Map
        ? data['rider'] as Map
        : (data['driver'] is Map ? data['driver'] as Map : null);

    dynamic lookup(Map? src, String k) => src?[k];
    String? read(String a, [String? b, String? c]) {
      final v = data[a] ??
          (b == null ? null : data[b]) ??
          (c == null ? null : data[c]) ??
          lookup(riderObj, a) ??
          (b == null ? null : lookup(riderObj, b)) ??
          (c == null ? null : lookup(riderObj, c));
      return v?.toString();
    }

    // Capture l'id du rider dès qu'on le voit passer — utile pour le
    // fallback HTTP `GET /rider/:id/location` si le socket ne pousse jamais
    // de `rider:location` (tentative unique, voir _tryHttpRiderLocation).
    final riderIdFromPayload = read('riderId', 'id') ?? read('driverId');
    if (riderIdFromPayload != null && riderIdFromPayload.isNotEmpty) {
      _riderId = riderIdFromPayload;
    }

    final name = read('riderName', 'name');
    final phone = read('riderPhone', 'phone', 'phoneNumber');
    final photo = read('riderPhotoUrl', 'photoUrl', 'photo') ??
        read('riderAvatarUrl', 'avatarUrl');
    final vehicleType = read('riderVehicleType', 'vehicleType');
    final vehicleModel = read('riderVehicleModel', 'vehicleModel');
    final plate = read('riderPlate', 'licensePlate', 'plate') ??
        read('plateNumber');
    final ratingRaw = data['riderRating'] ?? data['rating'] ??
        riderObj?['rating'];
    final rating = ratingRaw is num ? ratingRaw.toDouble() : null;

    // Si rien n'est présent, on ne modifie pas l'état rider existant.
    if (name == null &&
        phone == null &&
        photo == null &&
        vehicleType == null &&
        vehicleModel == null &&
        plate == null &&
        rating == null) {
      return;
    }

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
    setState(() => _liveRider = hydrated);
  }

  void _onRiderLocation(dynamic data) {
    if (!mounted || data is! Map) return;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    _updateRiderPos(LatLng(lat, lng));
  }

  /// Met à jour la position rider avec une interpolation (tween) depuis la
  /// dernière position connue. Évite les sauts brusques quand le backend émet
  /// `rider:location` toutes les 5s (lerp 900ms entre 2 points GPS).
  void _updateRiderPos(LatLng pos) {
    final order = ref.read(orderDetailProvider(widget.orderId)).value;
    // Démarre l'animation depuis la position courante → nouvelle cible.
    _riderPrevPos = _riderPos ?? pos;
    _riderTargetPos = pos;
    _riderAnim
      ?..stop()
      ..value = 0
      ..forward();

    setState(() {
      if (order?.delivery.lat != null && order?.delivery.lng != null) {
        final dist = _haversineKm(
          pos,
          LatLng(order!.delivery.lat!, order.delivery.lng!),
        );
        final minutes = (dist / _avgSpeedKmh * 60).round().clamp(1, 180);
        _eta = DateTime.now().add(Duration(minutes: minutes));
      }
    });

    // Recentre la carte sur la cible finale (la tween n'affecte que le marker).
    if (_showLiveMap && mounted) {
      try {
        _mapController.move(pos, _mapController.camera.zoom);
      } catch (_) {
        // MapController pas encore attaché — ignore.
      }
    }
  }

  /// Callback ticker : interpole linéairement de `_riderPrevPos` → `_riderTargetPos`
  /// et met à jour `_riderPos` pour le rebuild du marker.
  void _onRiderTween() {
    final ctrl = _riderAnim;
    final from = _riderPrevPos;
    final to = _riderTargetPos;
    if (ctrl == null || from == null || to == null) return;
    final t = Curves.easeInOut.transform(ctrl.value);
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    if (!mounted) return;
    setState(() => _riderPos = LatLng(lat, lng));
  }

  void _triggerArrivalFeedback() {
    HapticFeedback.mediumImpact();
    // Deuxième impulsion après 120ms pour une vraie alerte tactile.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
    });
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

  void _triggerDeliveredFeedback() {
    HapticFeedback.lightImpact();
  }

  /// Redirige vers l'écran de notation une fois la commande DELIVERED.
  /// Gardé idempotent par `_navScheduled` pour éviter les pushes multiples
  /// si `order:status` et `delivery:status` arrivent tous les deux avec
  /// un état DELIVERED.
  ///
  /// Délai 2s : laisse l'utilisateur voir le dernier point "Livrée" allumé
  /// dans la timeline avant la transition vers /rating/:orderId.
  void _navigateToRating() {
    if (_navScheduled) return;
    _navScheduled = true;
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      // `go_router` est utilisé dans /Users/opiumdigital/nyama_client/lib/app.dart
      // — route `/rating/:orderId` déjà déclarée.
      context.go('/rating/${widget.orderId}');
    });
  }

  /// Tentative unique d'appel HTTP `GET /rider/:id/location` en fallback
  /// quand le socket n'envoie pas encore de `rider:location`. Accepte les
  /// payloads { lat, lng } ou { location: { lat, lng } }. Si l'endpoint
  /// n'existe pas (404) ou échoue, on ignore silencieusement et on garde
  /// la dernière position connue dans le state (`_riderPos`).
  Future<void> _tryHttpRiderLocation() async {
    if (_didHttpLocationFallback) return;
    if (_riderPos != null) return;
    final id = _riderId;
    if (id == null || id.isEmpty) return;
    _didHttpLocationFallback = true;
    try {
      final resp = await ApiClient.instance.get<dynamic>('/rider/$id/location');
      final data = resp.data;
      if (data is Map) {
        final Map loc = data['location'] is Map
            ? data['location'] as Map
            : data;
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat != null && lng != null && mounted) {
          _updateRiderPos(LatLng(lat, lng));
        }
      }
    } catch (_) {
      // 404 / endpoint absent — fallback silencieux sur la dernière position
      // connue (peut rester `null` tant qu'aucun `rider:location` n'arrive).
    }
  }

  /// Miroir exact de la progression utilisée par `OrderProgressTimeline` —
  /// utilisé pour empêcher la timeline de régresser quand un event `order:status`
  /// plus ancien arrive après un `delivery:status` plus avancé.
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

  String? _bannerFor(DeliveryStage s) {
    switch (s) {
      case DeliveryStage.arrivedRestaurant:
        return 'Le livreur est arrivé au restaurant';
      case DeliveryStage.pickedUp:
        return 'Le livreur a récupéré votre commande, il arrive !';
      case DeliveryStage.arrivedClient:
        return 'Votre livreur est arrivé à destination !';
      case DeliveryStage.assigned:
      case DeliveryStage.delivered:
      case DeliveryStage.none:
        return null;
    }
  }

  /// Affiche la carte live dès qu'un livreur est assigné.
  /// Spec Client : `delivery.status ∈ {ASSIGNED, PICKED_UP, EN_ROUTE}` → carte
  /// visible. On couvre aussi les états plus avancés (ARRIVED_CLIENT) et les
  /// états dérivés d'`order:status` (assigned/pickedUp/delivering/delivered)
  /// au cas où le backend ne pousserait que `order:status`.
  bool get _showLiveMap =>
      _stage == DeliveryStage.assigned ||
      _stage == DeliveryStage.arrivedRestaurant ||
      _stage == DeliveryStage.pickedUp ||
      _stage == DeliveryStage.arrivedClient ||
      _stage == DeliveryStage.delivered ||
      (_liveStatus == OrderStatus.assigned ||
          _liveStatus == OrderStatus.pickedUp ||
          _liveStatus == OrderStatus.delivering ||
          _liveStatus == OrderStatus.delivered);

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
    _riderAnim?.removeListener(_onRiderTween);
    _riderAnim?.dispose();
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
        // ── Carte live rider (haut) — 50% écran, visible dès PICKED_UP ───
        // Inclut une bannière ETA (Kevin arrive dans X min · Y km) au-dessus
        // de la carte OSM pour matcher le pattern Deliveroo.
        if (_showLiveMap) _buildLiveMap(order, rider),

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
              // ETA visible ici uniquement quand la carte live n'est PAS
              // affichée — sinon l'ETA banner au-dessus de la carte le porte
              // déjà ("Kevin arrive dans X min · Y km").
              if (!_showLiveMap &&
                  currentStatus != OrderStatus.delivered &&
                  currentStatus != OrderStatus.cancelled)
                Text(
                  'Livraison estimée : ${_hm(_eta)}',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              else if (_showLiveMap &&
                  currentStatus != OrderStatus.delivered &&
                  currentStatus != OrderStatus.cancelled)
                Text(
                  'Arrivée prévue à ${_hm(_eta)} (≈ $etaMin min)',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 13,
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

  /// Carte live façon Deliveroo, visible dès `PICKED_UP`.
  ///   - Hauteur = 50% de la hauteur écran.
  ///   - Marker rider = photo en cercle (fallback initiales) avec halo pulse.
  ///   - Marker dest  = pin maison vert.
  ///   - Polyline orange entre les deux (ligne droite, pas de routing service).
  ///   - ETA banner au-dessus : "Kevin arrive dans X min · Y km".
  ///   - Tap sur marker rider → modal nom/note/Appeler Kevin.
  Widget _buildLiveMap(OrderModel order, DeliveryModel riderInfo) {
    final destLat = order.delivery.lat ?? 4.0511;
    final destLng = order.delivery.lng ?? 9.7679;
    final dest = LatLng(destLat, destLng);

    // Position rider : dernière connue (interpolée), sinon point d'approche.
    final rider = _riderPos ?? LatLng(destLat + 0.006, destLng + 0.006);

    final mid = LatLng(
      (rider.latitude + dest.latitude) / 2,
      (rider.longitude + dest.longitude) / 2,
    );

    // Hauteur carte : ~280px (spec Client). On laisse une petite marge sur les
    // très grands écrans pour que la carte reste ergonomique sans dominer la
    // vue (la timeline + card rider doivent rester visibles sans scroll excessif).
    final mediaH = MediaQuery.of(context).size.height;
    final mapH = mediaH < 700 ? 260.0 : 280.0;

    final etaMin = _eta.difference(DateTime.now()).inMinutes.clamp(0, 999);
    final distKm = _haversineKm(rider, dest);
    final riderName = (riderInfo.riderName ?? '').isNotEmpty
        ? riderInfo.riderName!
        : 'Le livreur';

    return Column(
      children: [
        // ── ETA banner ("Kevin arrive dans 8 min · 2.3 km") ────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_bike_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$riderName arrive dans $etaMin min · ${distKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Carte OSM ───────────────────────────────────────────────────
        SizedBox(
          height: mapH,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
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
                      width: 64,
                      height: 64,
                      child: GestureDetector(
                        onTap: () => _showRiderTapModal(riderInfo),
                        child: _RiderPhotoPin(
                          name: riderName,
                          photoUrl: riderInfo.riderPhotoUrl,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom-sheet déclenché au tap du marker rider.
  /// Affiche photo + nom + note moyenne + bouton "Appeler {nom}" (tel:…).
  void _showRiderTapModal(DeliveryModel rider) {
    HapticFeedback.selectionClick();
    final name = (rider.riderName ?? '').isNotEmpty
        ? rider.riderName!
        : 'Le livreur';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';
    final rating = rider.riderRating;
    final phone = rider.riderPhone;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: (rider.riderPhotoUrl ?? '').isNotEmpty
                      ? NetworkImage(rider.riderPhotoUrl!)
                      : null,
                  child: (rider.riderPhotoUrl ?? '').isEmpty
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      rating != null ? rating.toStringAsFixed(1) : '5.0',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'note moyenne',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _callRider(phone);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.phone_rounded, size: 20),
                    label: Text(
                      'Appeler $name',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

// ─── Rider photo pin (carte) ────────────────────────────────────────────────

/// Marker carte avec photo du livreur (ou initiales fallback) en cercle, halo
/// pulse orange autour. Apparait dès que le rider a son `riderPhotoUrl`.
class _RiderPhotoPin extends StatefulWidget {
  final String name;
  final String? photoUrl;

  const _RiderPhotoPin({required this.name, this.photoUrl});

  @override
  State<_RiderPhotoPin> createState() => _RiderPhotoPinState();
}

class _RiderPhotoPinState extends State<_RiderPhotoPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'L';
    final hasPhoto = (widget.photoUrl ?? '').isNotEmpty;

    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
        color: AppColors.surfaceWhite,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: widget.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Container(
                color: AppColors.primaryLight,
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
      ),
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44 + v * 20,
              height: 44 + v * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.25 * (1 - v)),
              ),
            ),
            avatar,
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
