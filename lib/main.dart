import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/network/connectivity_notifier.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase core init (Auth + Messaging). No-op si google-services.json absent.
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('❌ Firebase init error: $e');
  }

  // Firebase Cloud Messaging — no-op silencieux si google-services.json absent
  await PushNotificationService.instance.init();

  // Watcher de connectivité (bannière offline temps réel)
  await startConnectivityWatcher();

  // Force portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      child: App(),
    ),
  );
}
