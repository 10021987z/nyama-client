import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/translations.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/services/auth_gate.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../auth/providers/auth_provider.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  DateTime? _pausedAt;
  bool _locked = false;
  bool _checkingBiometric = false;

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocket();
      initLanguage(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  Future<void> _maybeLockOnResume() async {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;
    final away = DateTime.now().difference(pausedAt);
    if (away.inSeconds < 30) return;

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    final enabled = await SecureStorage.getBiometricEnabled();
    if (!enabled) return;
    final available = await BiometricService.instance.isBiometricAvailable();
    if (!available) return;

    if (!mounted) return;
    setState(() => _locked = true);
    _promptBiometric();
  }

  Future<void> _promptBiometric() async {
    if (_checkingBiometric) return;
    _checkingBiometric = true;
    try {
      final ok = await BiometricService.instance.authenticate(
        reason: 'Déverrouille NYAMA avec ton empreinte',
      );
      if (!mounted) return;
      if (ok) setState(() => _locked = false);
    } finally {
      _checkingBiometric = false;
    }
  }

  Future<void> _onTabTap(int i) async {
    // Les onglets Commandes (3) et Profil (4) exigent une auth.
    if (i == 3 || i == 4) {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        final ok = await AuthGate.ensureAuthenticated(context);
        if (!ok || !mounted) return;
      }
    }
    if (!mounted) return;
    setState(() => _currentIndex = i);
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
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          if (_locked) _BiometricLockOverlay(onRetry: _promptBiometric),
        ],
      ),
      bottomNavigationBar: NyamaBottomNavBar(
        currentIndex: _currentIndex,
        isAuthenticated: ref.watch(authStateProvider).isAuthenticated,
        onTap: _onTabTap,
      ),
    );
  }
}

// ─── Lock overlay ──────────────────────────────────────────────────────────

class _BiometricLockOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  const _BiometricLockOverlay({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline, color: Colors.white, size: 72),
              const SizedBox(height: 24),
              const Text(
                'NYAMA verrouillé',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Utilise ton empreinte pour continuer",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
