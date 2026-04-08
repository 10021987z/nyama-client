import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/socket_provider.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../cart/screens/cart_screen.dart';
import '../../orders/screens/orders_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';
import 'home_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  static const _screens = [
    HomeTab(),
    SearchScreen(),
    CartScreen(),
    OrdersListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);

    socket.on('order:status', (data) {
      if (!mounted) return;
      final status = data is Map ? data['status'] as String? : null;
      final msg = _statusMessage(status);
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.primaryVibrant,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  String? _statusMessage(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Votre commande a été confirmée par la cuisinière ✅';
      case 'preparing':
        return 'Votre repas est en cours de préparation 🍳';
      case 'ready':
        return 'Votre commande est prête, un livreur arrive 🏍️';
      case 'delivering':
        return 'Votre commande est en route ! 🚀';
      case 'delivered':
        return 'Votre commande a été livrée ! Bon appétit 🎉';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Bannière hors-ligne ───────────────────────────────────────
          const OfflineBanner(),

          // ── Contenu principal ─────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NyamaBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

