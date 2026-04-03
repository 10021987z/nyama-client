import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../core/network/socket_provider.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';

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
  LatLng? _riderPosition;
  OrderStatus? _liveStatus;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late AnimationController _pulseController;
  bool _summaryExpanded = false;

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

    socket.on('tracking:update', (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final pos = LatLng(lat, lng);
      setState(() {
        _riderPosition = pos;
        _markers.removeWhere((m) => m.markerId.value == 'rider');
        _markers.add(Marker(
          markerId: const MarkerId('rider'),
          position: pos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Livreur'),
        ));
        _updatePolyline(pos);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    });

    socket.on('order:status', (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final statusStr = data['status'] as String?;
      final status = OrderStatus.fromString(statusStr);
      setState(() => _liveStatus = status);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (status == OrderStatus.delivered) _showDeliveredDialog();
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
        color: AppColors.primaryVibrant,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ));
  }

  void _showDeliveredDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Commande livrée !',
          style: GoogleFonts.newsreader(
              fontSize: 22, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Votre repas a bien été livré. Bon appétit !',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/orders/${widget.orderId}');
            },
            child: const Text('Voir la commande'),
          ),
        ],
      ),
    );
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
      backgroundColor: AppColors.surface,
      body: asyncOrder.when(
        loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.primaryVibrant)),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
        data: (order) => _buildContent(order),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    final hasDestination =
        order.delivery.lat != null && order.delivery.lng != null;
    final destLatLng = hasDestination
        ? LatLng(order.delivery.lat!, order.delivery.lng!)
        : const LatLng(4.0503, 9.7679);

    if (_markers.every((m) => m.markerId.value != 'destination')) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destLatLng,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Livraison',
          snippet: order.delivery.address,
        ),
      ));
    }

    final currentStatus = _liveStatus ?? order.status;

    return Stack(
      children: [
        // ── Header ─────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.onSurface),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Livraison à',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Douala, Cameroon',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryVibrant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.onSurface, size: 22),
                ),
              ],
            ),
          ),
        ),

        // ── Map ────────────────────────────────────────────────────
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          bottom: 0,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: destLatLng,
              zoom: 14,
            ),
            markers: Set.from(_markers),
            polylines: Set.from(_polylines),
            onMapCreated: (c) => _mapController = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        // ── Bottom Sheet ───────────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.25,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── ETA ───────────────────────────────────
                          Text(
                            'ARRIVÉE DANS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '12 min',
                            style: GoogleFonts.newsreader(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Statut',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryVibrant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentStatus == OrderStatus.delivering
                                      ? 'En chemin'
                                      : currentStatus.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Timeline ──────────────────────────────
                          _TimelineStep(
                            label: 'Commande Reçue',
                            subtitle:
                                'En attente de confirmation du restaurant',
                            status: _stepStatus(currentStatus, 0),
                            isFirst: true,
                            pulseController: _pulseController,
                          ),
                          _TimelineStep(
                            label: 'En Préparation',
                            subtitle:
                                'Le Chef ${order.cookName} prépare votre commande',
                            status: _stepStatus(currentStatus, 1),
                            pulseController: _pulseController,
                          ),
                          _TimelineStep(
                            label: 'En Chemin',
                            subtitle: _riderPosition != null
                                ? 'Votre coursier est en route'
                                : 'Votre coursier est à 1.2km',
                            status: _stepStatus(currentStatus, 2),
                            pulseController: _pulseController,
                          ),
                          _TimelineStep(
                            label: 'Livré',
                            subtitle: 'Bon appétit !',
                            status: _stepStatus(currentStatus, 3),
                            isLast: true,
                            pulseController: _pulseController,
                          ),

                          const SizedBox(height: 20),

                          // ── Rider Card ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    (order.delivery.riderName ?? 'M')[0]
                                        .toUpperCase(),
                                    style: GoogleFonts.newsreader(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.delivery.riderName ??
                                            'Moussa Traoré',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Coursier Rapide & Fiable',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryVibrant
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 13,
                                                color:
                                                    AppColors.primaryVibrant),
                                            const SizedBox(width: 3),
                                            Text(
                                              '4.9',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    AppColors.primaryVibrant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (order.delivery.riderPhone != null)
                                  GestureDetector(
                                    onTap: () => _callRider(
                                        order.delivery.riderPhone!),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryVibrant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.phone_rounded,
                                          color: Colors.white, size: 22),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Order Summary (expandable) ────────────
                          GestureDetector(
                            onTap: () => setState(
                                () => _summaryExpanded = !_summaryExpanded),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Résumé de la commande #${order.shortId}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _summaryExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  if (_summaryExpanded) ...[
                                    const SizedBox(height: 12),
                                    ...order.items.map((item) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${item.quantity}x',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors
                                                      .primaryVibrant,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  item.name,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13),
                                                ),
                                              ),
                                              Text(
                                                item.subtotal.toFcfa(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          order.totalXaf.toFcfa(),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryVibrant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Returns 'done', 'active', or 'future' for the timeline step.
  String _stepStatus(OrderStatus status, int stepIndex) {
    // Map status to a progress level
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
    if (stepIndex < progress) return 'done';
    if (stepIndex == progress) return 'active';
    return 'future';
  }

  Future<void> _callRider(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ─── Timeline Step ───────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  final String label;
  final String subtitle;
  final String status; // 'done' | 'active' | 'future'
  final bool isFirst;
  final bool isLast;
  final AnimationController pulseController;

  const _TimelineStep({
    required this.label,
    required this.subtitle,
    required this.status,
    this.isFirst = false,
    this.isLast = false,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'done';
    final isActive = status == 'active';

    final dotColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primaryVibrant
            : AppColors.surfaceContainerLow;

    final lineColor = isDone
        ? AppColors.success
        : AppColors.surfaceContainerLow;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(width: 2, height: 8, color: lineColor),
                // Dot
                isActive
                    ? AnimatedBuilder(
                        animation: pulseController,
                        builder: (_, child) {
                          return Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor.withValues(
                                  alpha:
                                      0.3 + 0.4 * pulseController.value),
                              border: Border.all(
                                  color: dotColor, width: 2),
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
                          );
                        },
                      )
                    : Container(
                        width: 18,
                        height: 18,
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
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 30),
                      color: isDone
                          ? AppColors.success
                          : AppColors.surfaceContainerLow,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDone || isActive
                          ? AppColors.onSurface
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
