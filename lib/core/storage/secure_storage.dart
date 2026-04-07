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
