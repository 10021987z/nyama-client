import 'package:local_auth/local_auth.dart';

/// Service d'authentification biométrique (empreinte / FaceID / PIN fallback).
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();
  factory BiometricService() => instance;

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason = 'Utilise ton empreinte pour accéder à NYAMA',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
