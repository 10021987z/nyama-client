import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../storage/secure_storage.dart';

/// Service de gestion des notifications push via Firebase Cloud Messaging.
///
/// Tant que `google-services.json` n'est pas fourni, `Firebase.initializeApp`
/// lèvera une exception : on la capture silencieusement pour ne PAS bloquer
/// l'app. Les méthodes deviennent alors des no-op.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Messenger global — affecté par l'App pour pouvoir afficher des
  /// SnackBars quand une notification arrive en foreground.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isFirebaseAvailable = false;
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _isFirebaseAvailable = true;
    } catch (e) {
      debugPrint('[Push] Firebase not configured — $e');
      _isFirebaseAvailable = false;
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
          '[Push] Permission status: ${settings.authorizationStatus}');

      _fcmToken = await messaging.getToken();
      debugPrint('[Push] FCM token: $_fcmToken');
      if (_fcmToken != null) {
        await SecureStorage.saveFcmToken(_fcmToken!);
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _onMessageOpenedApp(initial);
      }
    } catch (e) {
      debugPrint('[Push] init error: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Nouvelle notification';
    debugPrint('[Push] foreground: $title');
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(title),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[Push] opened from notification: ${message.data}');
  }
}
