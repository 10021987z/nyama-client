import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_auth_service.dart';
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
  final FirebaseAuthService _firebase = FirebaseAuthService.instance;

  /// ID de vérification Firebase (phone auth) — mémorisé entre requestOtp et verifyOtp
  String? _firebaseVerificationId;

  AuthNotifier(this._repo) : super(const AuthState()) {
    checkAuth();
  }

  /// Vérifie si une session existe au démarrage de l'app
  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      // Reconstruit l'utilisateur depuis le stockage local
      final phone = await SecureStorage.getUserPhone();
      final id = await SecureStorage.getUserId();
      final localName = await SecureStorage.getUserName();
      var user = (phone != null && id != null)
          ? AppUser(id: id, phone: phone, name: localName)
          : null;
      state = AuthState(status: AuthStatus.authenticated, user: user);

      // Puis tente de rafraîchir depuis l'API GET /users/me (non bloquant)
      try {
        final remote = await _repo.getProfile();
        if (!mounted) return;
        if (remote != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: remote.copyWith(name: remote.name ?? localName),
          );
          if (remote.name != null && remote.name!.isNotEmpty) {
            await SecureStorage.saveUserName(remote.name!);
          }
        }
      } catch (_) {
        // Si la vérif échoue (401 → interceptor logout, ou offline), on ignore
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Envoie un OTP SMS via Firebase → passe en état otpSent si succès.
  /// Fallback sur l'API NYAMA /auth/otp/request si Firebase échoue.
  Future<void> requestOtp(String phone) async {
    state = AuthState(status: AuthStatus.loading, phone: phone);
    _firebaseVerificationId = null;
    try {
      final completer = <String>[];
      final errors = <String>[];
      await _firebase.verifyPhone(
        phone,
        onCodeSent: (verificationId) {
          _firebaseVerificationId = verificationId;
          completer.add(verificationId);
        },
        onError: (err) {
          errors.add(err);
        },
        onAutoVerify: (_) {
          // Auto-verify Android : ignoré volontairement — on garde le flow manuel
        },
      );
      if (!mounted) return;
      if (_firebaseVerificationId != null) {
        state = AuthState(status: AuthStatus.otpSent, phone: phone);
        return;
      }
      // Firebase KO → fallback API NYAMA (bypass 123456 possible côté serveur)
      if (errors.isNotEmpty) {
        // ignore: avoid_print
      }
      await _repo.requestOtp(phone);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.otpSent, phone: phone);
    } catch (e) {
      // Fallback final : bypass local via repo
      try {
        await _repo.requestOtp(phone);
        if (!mounted) return;
        state = AuthState(status: AuthStatus.otpSent, phone: phone);
      } catch (_) {
        if (!mounted) return;
        state = AuthState(
          status: AuthStatus.error,
          phone: phone,
          errorMessage: _parseError(e),
        );
      }
    }
  }

  /// Vérifie le code OTP.
  /// 1) Si on a un verificationId Firebase → verifyOTP Firebase + sync backend.
  /// 2) Sinon / si Firebase KO → fallback API NYAMA (+ bypass 123456).
  Future<void> verifyOtp(String phone, String code) async {
    state = AuthState(status: AuthStatus.verifying, phone: phone);

    // ─── Path 1 : Firebase ────────────────────────────────────────────────
    if (_firebaseVerificationId != null) {
      try {
        final cred = await _firebase.verifyOTP(_firebaseVerificationId!, code);
        final result = await _syncFirebaseWithBackend(cred.user, phone: phone);
        if (!mounted) return;
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user ?? AppUser(id: cred.user?.uid ?? '', phone: phone),
          phone: phone,
        );
        return;
      } catch (e) {
        // Firebase OTP refusé → on tente le fallback API (bypass 123456)
      }
    }

    // ─── Path 2 : Fallback API NYAMA ──────────────────────────────────────
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

  /// Email/Password — sign in ou sign up + sync backend.
  Future<void> signInWithEmail(
    String email,
    String password, {
    required bool isSignUp,
  }) async {
    state = const AuthState(status: AuthStatus.verifying);
    try {
      final cred = isSignUp
          ? await _firebase.createAccountWithEmail(email, password)
          : await _firebase.signInWithEmail(email, password);
      final result = await _syncFirebaseWithBackend(cred.user, email: email);
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user ?? AppUser(id: cred.user?.uid ?? '', phone: email),
      );
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Google Sign-In + sync backend.
  Future<void> signInWithGoogle() async {
    state = const AuthState(status: AuthStatus.verifying);
    try {
      final cred = await _firebase.signInWithGoogle();
      final result = await _syncFirebaseWithBackend(
        cred.user,
        email: cred.user?.email,
      );
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user ??
            AppUser(
              id: cred.user?.uid ?? '',
              phone: cred.user?.email ?? '',
              name: cred.user?.displayName,
            ),
      );
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Récupère le Firebase ID Token et le transmet au backend.
  /// Fallback : session locale Firebase-only si l'endpoint n'existe pas.
  Future<AuthResult> _syncFirebaseWithBackend(
    User? user, {
    String? phone,
    String? email,
  }) async {
    if (user == null) {
      throw Exception('Utilisateur Firebase nul après authentification');
    }
    final idToken = await user.getIdToken() ?? '';
    AuthResult? result;
    try {
      result = await _repo.exchangeFirebaseToken(
        firebaseToken: idToken,
        phone: phone,
        email: email,
      );
    } catch (_) {
      result = null;
    }
    return result ??
        await _repo.saveFirebaseFallbackSession(
          firebaseToken: idToken,
          phone: phone,
          email: email,
          uid: user.uid,
          name: user.displayName,
        );
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

  /// Déconnexion complète (Firebase + backend + stockage local)
  Future<void> logout() async {
    try {
      await _firebase.signOut();
    } catch (_) {}
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
