import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Snapshot of the current socket state, diffusé via [SocketService.debug].
@immutable
class SocketDebugInfo {
  final String state; // idle | connecting | connected | error
  final String url;
  final String tokenPreview;
  final String? sid;
  final String? lastEvent;
  final String? lastError;
  final int errorCount;
  final int connectCallCount;

  const SocketDebugInfo({
    this.state = 'idle',
    this.url = '',
    this.tokenPreview = '',
    this.sid,
    this.lastEvent,
    this.lastError,
    this.errorCount = 0,
    this.connectCallCount = 0,
  });

  SocketDebugInfo copyWith({
    String? state,
    String? url,
    String? tokenPreview,
    String? sid,
    String? lastEvent,
    String? lastError,
    int? errorCount,
    int? connectCallCount,
    bool clearSid = false,
    bool clearError = false,
  }) {
    return SocketDebugInfo(
      state: state ?? this.state,
      url: url ?? this.url,
      tokenPreview: tokenPreview ?? this.tokenPreview,
      sid: clearSid ? null : (sid ?? this.sid),
      lastEvent: lastEvent ?? this.lastEvent,
      lastError: clearError ? null : (lastError ?? this.lastError),
      errorCount: errorCount ?? this.errorCount,
      connectCallCount: connectCallCount ?? this.connectCallCount,
    );
  }
}

/// Singleton Socket.IO client for the NYAMA client app.
///
/// Use [SocketService.instance] to access the unique instance.
/// Call [connect] once the user is authenticated (token available).
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  /// Public debug stream — subscribe via [ValueListenableBuilder] to show
  /// the current socket state directly in the UI.
  static final ValueNotifier<SocketDebugInfo> debug =
      ValueNotifier<SocketDebugInfo>(const SocketDebugInfo());

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;

  void _update(SocketDebugInfo Function(SocketDebugInfo) mutate) {
    debug.value = mutate(debug.value);
  }

  /// Connects to the websocket with the given [token].
  /// [userId] is optional; if omitted it is read from SecureStorage.
  /// [role] defaults to `CLIENT`.
  Future<void> connect(
    String token, {
    String? userId,
    String role = 'CLIENT',
  }) async {
    _update((d) => d.copyWith(
          connectCallCount: d.connectCallCount + 1,
          url: ApiConstants.wsUrl,
        ));

    if (token.isEmpty) {
      // ignore: avoid_print
      print('[SocketService] 🔌 connect() skipped — empty token');
      _update((d) => d.copyWith(
            state: 'error',
            lastError: 'empty token',
            errorCount: d.errorCount + 1,
          ));
      return;
    }
    if (_socket != null && _socket!.connected) {
      // ignore: avoid_print
      print('[SocketService] 🔌 already connected, sid=${_socket?.id}');
      _update((d) => d.copyWith(state: 'connected', sid: _socket?.id));
      return;
    }

    final preview = token.length >= 20 ? token.substring(0, 20) : token;
    final resolvedUserId = userId ?? await SecureStorage.getUserId();

    _update((d) => d.copyWith(
          state: 'connecting',
          url: ApiConstants.wsUrl,
          tokenPreview: preview,
          clearSid: true,
          clearError: true,
        ));

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
      _update((d) => d.copyWith(
            state: 'connected',
            sid: _socket?.id,
            clearError: true,
          ));
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
      _update((d) => d.copyWith(lastEvent: event));
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('[SocketService] 🔌 Disconnected');
      _update((d) => d.copyWith(state: 'connecting', clearSid: true));
    });

    _socket!.onConnectError((err) {
      // ignore: avoid_print
      print('[SocketService] ❌ Connect error: $err');
      _update((d) => d.copyWith(
            state: 'error',
            lastError: err?.toString() ?? 'unknown',
            errorCount: d.errorCount + 1,
          ));
    });

    _socket!.onError((data) {
      // ignore: avoid_print
      print('[SocketService] ❌ Socket error: $data');
      _update((d) => d.copyWith(
            state: 'error',
            lastError: data?.toString() ?? 'unknown',
            errorCount: d.errorCount + 1,
          ));
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
    _update((d) => d.copyWith(state: 'idle', clearSid: true));
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
