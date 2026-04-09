import 'package:flutter/material.dart';

import '../storage/secure_storage.dart';
import '../../features/auth/widgets/login_bottom_sheet.dart';

/// Gate d'authentification — Uber Eats style.
/// L'accès à l'app est libre ; on ne demande l'identification
/// que lorsqu'elle est strictement nécessaire (checkout, profil,
/// commandes, avis...).
class AuthGate {
  AuthGate._();

  /// Renvoie `true` si l'utilisateur est (déjà ou devient) authentifié.
  /// Si non, affiche le bottom sheet de connexion et attend son résultat.
  static Future<bool> ensureAuthenticated(BuildContext context) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) return true;

    if (!context.mounted) return false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const LoginBottomSheet(),
    );
    return result == true;
  }
}
