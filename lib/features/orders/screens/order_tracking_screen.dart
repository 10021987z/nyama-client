import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/socket_provider.dart';
import '../data/models/order_models.dart';
import '../providers/orders_provider.dart';
import 'orders_list_screen.dart' show OrderStatusBadge;

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _riderPosition;
  OrderStatus? _liveStatus;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);

    // Join order room
    socket.emit('order:join', {'orderId': widget.orderId});

    // Live rider position
    socket.on('tracking:update', (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final pos = LatLng(lat, lng);
      setState(() {
        _riderPosition = pos;
        _markers.removeWhere(
            (m) => m.markerId.value == 'rider');
        _markers.add(Marker(
          markerId: const MarkerId('rider'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: '🏍️ Livreur'),
        ));
        _updatePolyline(pos);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    });

    // Order status update
    socket.on('order:status', (data) {
      if (!mounted) return;
      if (data is! Map) return;
      final statusStr = data['status'] as String?;
      final status = OrderStatus.fromString(statusStr);
      setState(() => _liveStatus = status);

      // Invalidate order detail so it refreshes
      ref.invalidate(orderDetailProvider(widget.orderId));

      if (status == OrderStatus.delivered) {
        _showDeliveredDialog();
      }
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
        color: const Color(0xFF1B4332),
        width: 4,
      ));
  }

  void _showDeliveredDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Commande livrée !'),
        content: const Text('Votre repas a bien été livré. Bon appétit !'),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncOrder = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      body: asyncOrder.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (order) => _buildMap(order),
      ),
    );
  }

  Widget _buildMap(OrderModel order) {
    final hasDestination =
        order.delivery.lat != null && order.delivery.lng != null;
    final destLatLng = hasDestination
        ? LatLng(order.delivery.lat!, order.delivery.lng!)
        : const LatLng(4.0503, 9.7679); // Douala fallback

    // Build destination marker once
    if (_markers.every((m) => m.markerId.value != 'destination')) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '📍 Livraison',
          snippet: order.delivery.address,
        ),
      ));
    }

    final currentStatus = _liveStatus ?? order.status;

    return Stack(
      children: [
        // ── Google Maps ──────────────────────────────────────────────
        GoogleMap(
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

        // ── Back button ──────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),

        // ── Info bandeau bas ─────────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.15,
          maxChildSize: 0.45,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, -3))
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statut + livreur
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.surface,
                                child: Text('🛵',
                                    style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.delivery.riderName ??
                                          'Livreur en route',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    OrderStatusBadge(status: currentStatus),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Pas encore de position
                          if (_riderPosition == null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'En attente de la position du livreur...',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Adresse livraison
                          if (order.delivery.address != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order.delivery.address!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Bouton appeler livreur
                          if (order.delivery.riderPhone != null)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _callRider(order.delivery.riderPhone!),
                              icon: const Text('📞',
                                  style: TextStyle(fontSize: 16)),
                              label: const Text('Appeler le livreur'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 46),
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
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

  Future<void> _callRider(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
