import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Service de paiement NotchPay — initiation + vérification.
///
/// Passe par l'endpoint backend `/payments/initiate` qui relaie la demande
/// à NotchPay, puis ouvre l'`authorization_url` retournée dans un navigateur
/// externe. Après le retour dans l'app, on interroge `/payments/verify/:ref`.
class PaymentService {
  PaymentService._();

  static const String _baseUrl = ApiConstants.baseUrl;

  /// Méthodes supportées côté NotchPay.
  static const String methodMtnMomo = 'MTN_MOMO';
  static const String methodOrangeMoney = 'ORANGE_MONEY';
  static const String methodFallaMobileMoney = 'FALLA_MOBILE_MONEY';

  /// Convertit un identifiant interne (ex: `mtn_momo`) en méthode NotchPay.
  static String normalizeMethod(String method) {
    switch (method) {
      case 'mtn_momo':
        return methodMtnMomo;
      case 'orange_money':
        return methodOrangeMoney;
      case 'falla_momo':
      case 'falla_mobile_money':
        return methodFallaMobileMoney;
      default:
        return method.toUpperCase();
    }
  }

  /// POST /payments/initiate
  ///
  /// Retourne le corps JSON décodé tel que renvoyé par l'API :
  /// `{ reference, status, raw: { authorization_url } }`.
  static Future<Map<String, dynamic>> initiatePayment({
    required String orderId,
    required int amount,
    required String phone,
    required String method,
  }) async {
    final token = await SecureStorage.getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'amount': amount,
        'phone': phone,
        'method': method,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const FormatException(
        'Réponse de paiement invalide (format inattendu)',
      );
    }
    throw Exception('Erreur de paiement: ${response.body}');
  }

  /// POST /payments/:paymentId/test-complete
  ///
  /// Sandbox-only : force le Payment à SUCCESS sans passer par NotchPay.
  /// L'endpoint backend refuse l'appel en production (403).
  static Future<Map<String, dynamic>> testComplete(String paymentId) async {
    final token = await SecureStorage.getAccessToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/$paymentId/test-complete'),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw Exception('test-complete échoué: ${response.body}');
  }

  /// GET /payments/verify/:reference
  ///
  /// Retourne le corps JSON décodé. Le champ `status` peut être :
  /// `complete` | `pending` | `failed`.
  static Future<Map<String, dynamic>> verifyPayment(String reference) async {
    final token = await SecureStorage.getAccessToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/verify/$reference'),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw Exception('Vérification de paiement échouée: ${response.body}');
  }
}
