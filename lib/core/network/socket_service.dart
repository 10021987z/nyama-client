import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (_socket != null && _socket!.connected) return;

    // ignore: avoid_print
    print('[Client] 🔌 Connecting to ${ApiConstants.wsUrl}');
    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': accessToken})
          .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) async {
      // ignore: avoid_print
      print('[Client] Socket connected, socketId=${_socket?.id}');
      final userId = await SecureStorage.getUserId();
      _socket?.emit('join', {
        'userId': userId,
        'role': 'CLIENT',
      });
      // ignore: avoid_print
      print('[Client] join emitted for userId=$userId role=CLIENT');
    });

    _socket!.onAny((event, data) {
      // ignore: avoid_print
      print('[Client] Event: $event, data: $data');
    });

    _socket!.onDisconnect((_) {
      // ignore: avoid_print
      print('[Client] Socket disconnected');
    });

    _socket!.onConnectError((err) {
      // ignore: avoid_print
      print('[Client] Connect error: $err');
    });

    _socket!.onError((data) {
      // ignore: avoid_print
      print('[Client] Socket error: $data');
    });

    _socket!.connect();
  }

  void disconnect() {
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
