import 'dart:io';

class ApiConstants {
  ApiConstants._();

  // Base URL selon plateforme
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1'; // Android emulator → localhost
    }
    return 'http://localhost:3000/api/v1'; // iOS simulator
  }

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Auth endpoints
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Cooks (cuisinières) endpoints
  static const String cooks = '/cooks';
  static String cookById(String id) => '/cooks/$id';

  // Menu items endpoints
  static const String menuItems = '/menu/items';
  static String menuItemById(String id) => '/menu/items/$id';

  // Orders endpoints
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderTracking(String id) => '/orders/$id/tracking';
  static String orderRating(String id) => '/orders/$id/rating';

  // Reviews
  static const String reviews = '/reviews';

  // Search
  static const String search = '/search';

  // User profile
  static const String profile = '/users/me';
  static const String addresses = '/users/me/addresses';

  // Payments
  static const String initiatePayment = '/payments/initiate';
  static const String verifyPayment = '/payments/verify';

  // WebSocket
  static String get wsUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userPhoneKey = 'user_phone';
  static const String userIdKey = 'user_id';
}
