import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';
import 'connectivity_notifier.dart';

class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      _OfflineInterceptor(),
      _LogInterceptor(),
    ]);

    return dio;
  }

  // Réinitialise l'instance (utile après changement de base URL)
  static void reset() => _instance = null;
}

/// Intercepteur qui injecte le Bearer token et gère le refresh automatique
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ne pas ajouter le token pour les routes auth
    if (_isAuthRoute(options.path)) {
      return handler.next(options);
    }

    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Token expiré → tentative de refresh
    if (_isAuthRoute(err.requestOptions.path)) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Met en attente et retry après refresh
      _pendingRequests.add(err.requestOptions);
      return;
    }

    _isRefreshing = true;

    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        // Retry la requête originale avec le nouveau token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await _dio.fetch(err.requestOptions);

        // Retry les requêtes en attente
        for (final req in _pendingRequests) {
          req.headers['Authorization'] = 'Bearer $newToken';
          _dio.fetch(req).ignore();
        }
        _pendingRequests.clear();

        handler.resolve(response);
      } else {
        await _logout();
        handler.next(err);
      }
    } catch (_) {
      await _logout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String?> _refreshToken() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {}), // Sans Authorization
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
    } catch (_) {
      // Refresh échoué
    }
    return null;
  }

  Future<void> _logout() async {
    await SecureStorage.clearAll();
  }

  bool _isAuthRoute(String path) {
    return path.contains('/auth/');
  }
}

/// Intercepteur hors-ligne — met à jour offlineNotifier
class _OfflineInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    offlineNotifier.value = false;
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      offlineNotifier.value = true;
    } else {
      offlineNotifier.value = false;
    }
    handler.next(err);
  }
}

/// Intercepteur de logs (désactivé en production)
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${response.statusCode} ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
      return true;
    }());
    handler.next(ApiExceptionHandler.handle(err) as DioException? ?? err);
  }
}
