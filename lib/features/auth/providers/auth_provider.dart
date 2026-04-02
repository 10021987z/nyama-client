import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

// ─── Enum d'état ──────────────────────────────────────────────────────────

enum AuthStatus {
  initial,        // Pas encore vérifié
  loading,        // Envoi OTP en cours
  otpSent,        // OTP envoyé, en attente du code
  verifying,      // Vérification OTP en cours
  authenticated,  // Session active
  unauthenticated,// Pas de session
  error,          // Erreur
}

// ─── Modèle d'état ────────────────────────────────────────────────────────

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? phone;         // Numéro en cours de vérification
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.phone,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.verifying;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? phone,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      phone: phone ?? this.phone,
      errorMessage: errorMessage,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    checkAuth();
  }

  /// Vérifie si une session existe au démarrage de l'app
  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      // Tente de reconstruire l'utilisateur depuis le stockage
      final phone = await SecureStorage.getUserPhone();
      final id = await SecureStorage.getUserId();
      final user = (phone != null && id != null)
          ? AppUser(id: id, phone: phone)
          : null;
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Envoie un OTP SMS → passe en état otpSent si succès
  Future<void> requestOtp(String phone) async {
    state = AuthState(status: AuthStatus.loading, phone: phone);
    try {
      await _repo.requestOtp(phone);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.otpSent, phone: phone);
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        phone: phone,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Vérifie le code OTP → passe en authenticated si succès
  Future<void> verifyOtp(String phone, String code) async {
    state = AuthState(status: AuthStatus.verifying, phone: phone);
    try {
      final result = await _repo.verifyOtp(phone, code);
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user ?? AppUser(id: '', phone: phone),
        phone: phone,
      );
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        phone: phone,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Permet de retenter l'envoi OTP depuis l'écran OTP (timer expiré)
  Future<void> resendOtp() async {
    final phone = state.phone;
    if (phone == null) return;
    await requestOtp(phone);
  }

  /// Réinitialise l'état d'erreur tout en conservant le numéro
  void clearError() {
    state = state.copyWith(
      status: state.phone != null ? AuthStatus.otpSent : AuthStatus.unauthenticated,
    );
  }

  /// Déconnexion complète
  Future<void> logout() async {
    await _repo.logout();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _parseError(Object e) {
    final msg = e.toString();
    // Retire le préfixe Exception/ApiException pour afficher proprement
    if (msg.contains(':')) {
      return msg.split(':').skip(1).join(':').trim();
    }
    return msg;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
