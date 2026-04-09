import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  /// Demande l'envoi d'un OTP SMS au numéro camerounais
  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post(
        ApiConstants.requestOtp,
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Vérifie le code OTP → retourne le résultat auth + persiste les tokens
  Future<AuthResult> verifyOtp(String phone, String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'code': code},
      );

      final data = response.data as Map<String, dynamic>;
      final result = AuthResult.fromJson(data);

      await SecureStorage.saveAccessToken(result.accessToken);
      await SecureStorage.saveRefreshToken(result.refreshToken);
      await SecureStorage.saveUserPhone(phone);
      if (result.user?.id != null) {
        await SecureStorage.saveUserId(result.user!.id);
      }

      return result;
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Rafraîchit le token d'accès via le refresh token
  Future<String?> refreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}),
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;

      if (newAccessToken != null) {
        await SecureStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }
        return newAccessToken;
      }
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
    return null;
  }

  /// Déconnexion : invalide le token côté serveur + efface le stockage local
  Future<void> logout() async {
    try {
      final rt = await SecureStorage.getRefreshToken();
      if (rt != null) {
        await _dio.post(
          ApiConstants.logout,
          data: {'refreshToken': rt},
        );
      }
    } catch (_) {
      // On déconnecte quand même localement si le serveur est injoignable
    } finally {
      await SecureStorage.clearAll();
    }
  }

  /// Échange un Firebase ID Token contre un JWT NYAMA via le backend.
  /// Si l'endpoint n'existe pas encore, retourne null pour permettre le fallback.
  Future<AuthResult?> exchangeFirebaseToken({
    required String firebaseToken,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/firebase',
        data: {
          'firebaseToken': firebaseToken,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final result = AuthResult.fromJson(data);
      await SecureStorage.saveAccessToken(result.accessToken);
      await SecureStorage.saveRefreshToken(result.refreshToken);
      if (phone != null) await SecureStorage.saveUserPhone(phone);
      if (result.user?.id != null) {
        await SecureStorage.saveUserId(result.user!.id);
      }
      return result;
    } on DioException catch (e) {
      // Endpoint pas encore dispo côté backend → fallback géré par l'appelant
      if (e.response?.statusCode == 404) return null;
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fallback : sauvegarde locale d'une session "Firebase-only" quand le
  /// backend n'a pas encore l'endpoint /auth/firebase. On stocke le token
  /// Firebase comme accessToken et on reconstitue un AppUser minimal.
  Future<AuthResult> saveFirebaseFallbackSession({
    required String firebaseToken,
    String? phone,
    String? email,
    String? uid,
    String? name,
  }) async {
    await SecureStorage.saveAccessToken(firebaseToken);
    await SecureStorage.saveRefreshToken(firebaseToken);
    if (phone != null) await SecureStorage.saveUserPhone(phone);
    if (uid != null) await SecureStorage.saveUserId(uid);
    if (name != null) await SecureStorage.saveUserName(name);
    return AuthResult(
      accessToken: firebaseToken,
      refreshToken: firebaseToken,
      user: AppUser(id: uid ?? '', phone: phone ?? email ?? '', name: name),
    );
  }

  /// Vérifie si un access token existe en stockage (session active)
  Future<bool> isLoggedIn() => SecureStorage.isLoggedIn();

  /// Récupère le profil utilisateur depuis l'API (GET /users/me)
  Future<AppUser?> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AppUser.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

// ─── Modèles ───────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final String phone;
  final String? name;

  const AppUser({required this.id, required this.phone, this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      name: json['name'] as String?,
    );
  }

  AppUser copyWith({String? id, String? phone, String? name}) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
    );
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser? user;
  final bool isNewUser;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    this.user,
    this.isNewUser = false,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;
    return AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: userData != null ? AppUser.fromJson(userData) : null,
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }
}
