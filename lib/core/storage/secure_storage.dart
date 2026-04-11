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

  static Future<void> removeSearchItem(String query) async {
    final current = await getSearchHistory();
    current.removeWhere((s) => s.toLowerCase() == query.toLowerCase());
    await _storage.write(
        key: _kSearchHistory, value: current.join('\u0001'));
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

  // Moyens de paiement (numéros MoMo/Orange/Falla, séparés par \u0001)
  // Format: "provider|phoneMasked|isDefault"
  static const _kPaymentMethods = 'payment_methods';

  static Future<List<String>> getPaymentMethods() async {
    final raw = await _storage.read(key: _kPaymentMethods);
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\u0001').where((s) => s.isNotEmpty).toList();
  }

  static Future<void> addPaymentMethod(String entry) async {
    final list = await getPaymentMethods();
    list.add(entry);
    await _storage.write(
        key: _kPaymentMethods, value: list.join('\u0001'));
  }

  static Future<void> removePaymentMethod(int index) async {
    final list = await getPaymentMethods();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _storage.write(
        key: _kPaymentMethods, value: list.join('\u0001'));
  }

  static Future<void> setDefaultPaymentMethod(int index) async {
    final list = await getPaymentMethods();
    if (index < 0 || index >= list.length) return;
    final updated = <String>[];
    for (var i = 0; i < list.length; i++) {
      final parts = list[i].split('|');
      if (parts.length < 2) continue;
      final provider = parts[0];
      final phone = parts[1];
      updated.add('$provider|$phone|${i == index ? '1' : '0'}');
    }
    await _storage.write(
        key: _kPaymentMethods, value: updated.join('\u0001'));
  }

  // Adresses sauvegardées (JSON compact, séparées par \u0001)
  // Format de chaque entrée : "label|address|isDefault"
  static const _kSavedAddresses = 'saved_addresses';

  static Future<List<String>> getSavedAddresses() async {
    final raw = await _storage.read(key: _kSavedAddresses);
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\u0001').where((s) => s.isNotEmpty).toList();
  }

  static Future<void> addSavedAddress(String label, String address) async {
    final list = await getSavedAddresses();
    list.add('$label|$address|0');
    await _storage.write(key: _kSavedAddresses, value: list.join('\u0001'));
  }

  static Future<void> removeSavedAddress(int index) async {
    final list = await getSavedAddresses();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _storage.write(key: _kSavedAddresses, value: list.join('\u0001'));
  }

  static Future<void> setDefaultSavedAddress(int index) async {
    final list = await getSavedAddresses();
    if (index < 0 || index >= list.length) return;
    final updated = <String>[];
    for (var i = 0; i < list.length; i++) {
      final parts = list[i].split('|');
      if (parts.length < 2) continue;
      final label = parts[0];
      final address = parts[1];
      updated.add('$label|$address|${i == index ? '1' : '0'}');
    }
    await _storage.write(key: _kSavedAddresses, value: updated.join('\u0001'));
  }

  // Efface tout (déconnexion)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
