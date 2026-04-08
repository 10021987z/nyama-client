import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Global offline indicator updated by the API interceptor AND by
/// connectivity_plus stream events.
/// true = offline/unreachable, false = connected.
final offlineNotifier = ValueNotifier<bool>(false);

StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

/// Starts watching the OS connectivity and reflects changes into
/// [offlineNotifier]. Idempotent — safe to call multiple times.
Future<void> startConnectivityWatcher() async {
  if (_connectivitySub != null) return;
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  offlineNotifier.value = _isOffline(initial);
  _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
    offlineNotifier.value = _isOffline(results);
  });
}

bool _isOffline(List<ConnectivityResult> results) {
  if (results.isEmpty) return true;
  return results.every((r) => r == ConnectivityResult.none);
}
