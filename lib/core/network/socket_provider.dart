import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../storage/secure_storage.dart';
import 'socket_service.dart';

/// Exposes the [SocketService] singleton to widgets via Riverpod.
///
/// Also acts as a safety-net listener on [authStateProvider] to
/// (dis)connect on auth transitions — the primary connect call lives
/// inside [AuthNotifier] after a successful login.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService.instance;

  ref.listen<AuthState>(authStateProvider, (previous, next) async {
    if (next.isAuthenticated) {
      final token = await SecureStorage.getAccessToken();
      if (token != null && token.isNotEmpty && !service.isConnected) {
        await service.connect(token, role: 'CLIENT');
      }
    } else if (previous?.isAuthenticated == true) {
      service.disconnect();
    }
  }, fireImmediately: true);

  return service;
});
