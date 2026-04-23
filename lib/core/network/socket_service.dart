import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Singleton Socket.IO client for the NYAMA client app.
///
/// Use [SocketService.instance] to access the unique instance.
/// Call [connect] once the user is authenticated (token available).
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// Connects to the websocket with the given [token].
  /// [userId] is optional; if omitted it is read from SecureStorage.
  /// [role] defaults to `CLIENT`.
  Future<void> connect(
    String token, {
    String? userId,
    String role = 'CLIENT',
  }) async {
    if (token.isEmpty) {
      // ignore: avoid_print
      print('[SocketService] 🔌 connect() skipped — empty token');
      return;
    }
    if (_socket != null && _socket!.connected) {
      // ignore: avoid_print
      print('[SocketService] 🔌 already connected, sid=${_socket?.id}');
      return;
    }

    final preview = token.length >= 20 ? token.substring(0, 20) : token;
    final resolvedUserId = userId ?? await SecureStorage.getUserId();

    // ignore: avoid_print
    print(
      '[SocketService] 🔌 connect() called token=$preview... userId=$resolvedUserId role=$role',
    );
    // ignore: avoid_print
    print('[SocketService] 🔌 Socket URL = ${ApiConstants.wsUrl}');

    _socket?.dispose();
    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print('[SocketService] ✅ Connected, sid=${_socket?.id}');
      _socket?.emit('join', {
        'userId': resolvedUserId,
        'role': role,
      });
      // ignore: avoid_print
      print('[SocketService] 🔌 join emitted userId=$resolvedUserId role=$role');
    });

    _socket!.onAny((event, data) {
      // ignore: avoid_print
      print('[SocketService] 🔌 Event: $event, data: $data');
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('[SocketService] 🔌 Disconnected');
    });

    _socket!.onConnectError((err) {
      // ignore: avoid_print
      print('[SocketService] ❌ Connect error: $err');
    });

    _socket!.onError((data) {
      // ignore: avoid_print
      print('[SocketService] ❌ Socket error: $data');
    });

    _socket!.connect();
  }

  void disconnect() {
    if (_socket == null) return;
    // ignore: avoid_print
    print('[SocketService] 🔌 disconnect() called');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}
