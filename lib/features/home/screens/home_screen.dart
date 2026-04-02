import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/connectivity_notifier.dart';
import '../../../core/network/socket_provider.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../cart/screens/cart_screen.dart';
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
            backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Bannière hors-ligne ───────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: offlineNotifier,
            builder: (context, isOffline, _) {
              if (!isOffline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: AppColors.error,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: const SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '📡 Hors connexion',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

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

