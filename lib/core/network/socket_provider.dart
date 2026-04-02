import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../storage/secure_storage.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();

  // Connect/disconnect based on auth state
  ref.listen<AuthState>(authStateProvider, (previous, next) async {
    if (next.isAuthenticated) {
      final token = await SecureStorage.getAccessToken();
      if (token != null) {
        service.connect(token);
      }
    } else {
      service.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(() => service.disconnect());

  return service;
});
