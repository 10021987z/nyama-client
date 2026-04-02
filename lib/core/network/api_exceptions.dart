import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Vérifiez votre connexion internet'});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expirée, veuillez vous reconnecter'})
      : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Ressource introuvable'})
      : super(statusCode: 404);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Erreur serveur, réessayez plus tard'})
      : super(statusCode: 500);
}

class ApiExceptionHandler {
  static ApiException handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Délai de connexion dépassé');

      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return const ApiException(message: 'Requête annulée');

      default:
        return ApiException(
          message: error.message ?? 'Une erreur inattendue est survenue',
        );
    }
  }

  static ApiException _handleResponseError(Response? response) {
    if (response == null) {
      return const ServerException();
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Essaie d'extraire le message d'erreur du backend
    String message = _extractMessage(data, statusCode);

    switch (statusCode) {
      case 400:
        return ApiException(message: message, statusCode: 400, data: data);
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ApiException(message: 'Accès non autorisé', statusCode: 403);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ApiException(message: message, statusCode: 409, data: data);
      case 422:
        return ApiException(message: message, statusCode: 422, data: data);
      case 429:
        return const ApiException(message: 'Trop de tentatives, réessayez dans quelques minutes', statusCode: 429);
      case >= 500:
        return const ServerException();
      default:
        return ApiException(message: message, statusCode: statusCode);
    }
  }

  static String _extractMessage(dynamic data, int statusCode) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          _defaultMessage(statusCode);
    }
    return _defaultMessage(statusCode);
  }

  static String _defaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Requête invalide';
      case 401:
        return 'Non authentifié';
      case 403:
        return 'Accès refusé';
      case 404:
        return 'Introuvable';
      case 500:
        return 'Erreur serveur';
      default:
        return 'Une erreur est survenue';
    }
  }
}
