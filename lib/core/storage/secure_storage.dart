import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: ApiConstants.accessTokenKey);
  }

  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: ApiConstants.refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: ApiConstants.refreshTokenKey);
  }

  // User Phone
  static Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: ApiConstants.userPhoneKey, value: phone);
  }

  static Future<String?> getUserPhone() async {
    return _storage.read(key: ApiConstants.userPhoneKey);
  }

  // User ID
  static Future<void> saveUserId(String id) async {
    await _storage.write(key: ApiConstants.userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: ApiConstants.userIdKey);
  }

  // Quartier choisi (Phase 2 onboarding)
  static const _kQuartier = 'user_quartier';
  static const _kCity = 'user_city';

  static Future<void> saveQuartier(String city, String quartier) async {
    await _storage.write(key: _kCity, value: city);
    await _storage.write(key: _kQuartier, value: quartier);
  }

  static Future<String?> getQuartier() => _storage.read(key: _kQuartier);
  static Future<String?> getCity() => _storage.read(key: _kCity);

  // Langue de l'interface ("fr" | "en" | "pidgin")
  static const _kLanguage = 'language';
  static Future<void> saveLanguage(String code) =>
      _storage.write(key: _kLanguage, value: code);
  static Future<String?> getLanguage() => _storage.read(key: _kLanguage);

  // Token FCM
  static const _kFcmToken = 'fcm_token';
  static Future<void> saveFcmToken(String token) =>
      _storage.write(key: _kFcmToken, value: token);
  static Future<String?> getFcmToken() => _storage.read(key: _kFcmToken);

  // Nom de l'utilisateur (éditable dans le profil)
  static const _kUserName = 'user_name';
  static Future<void> saveUserName(String name) =>
      _storage.write(key: _kUserName, value: name);
  static Future<String?> getUserName() => _storage.read(key: _kUserName);

  // Chemin local de la photo de profil
  static const _kAvatarPath = 'user_avatar_path';
  static Future<void> saveAvatarPath(String path) =>
      _storage.write(key: _kAvatarPath, value: path);
  static Future<String?> getAvatarPath() => _storage.read(key: _kAvatarPath);

  // Historique de recherche (max 10 items, séparés par \u0001)
  static const _kSearchHistory = 'search_history';
  static Future<List<String>> getSearchHistory() async {
    final raw = await _storage.read(key: _kSearchHistory);
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\u0001').where((s) => s.isNotEmpty).toList();
  }

  static Future<void> addSearchHistory(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final current = await getSearchHistory();
    current.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
    current.insert(0, q);
    final trimmed = current.take(10).toList();
    await _storage.write(
        key: _kSearchHistory, value: trimmed.join('\u0001'));
  }

  static Future<void> clearSearchHistory() =>
      _storage.delete(key: _kSearchHistory);

  // Authentification biométrique activée
  static const _kBiometricEnabled = 'biometric_enabled';
  static Future<void> setBiometricEnabled(bool v) =>
      _storage.write(key: _kBiometricEnabled, value: v ? '1' : '0');
  static Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == '1';
  }

  // Vérifie si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Efface tout (déconnexion)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
