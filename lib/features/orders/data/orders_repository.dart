import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import 'models/order_models.dart';

class CreateOrderRequest {
  final String cookId;
  final List<Map<String, dynamic>> items;
  final String deliveryAddress;
  final String? repere;
  final String? noteForCook;
  final String paymentMethod;
  final String? paymentPhone;
  final double? lat;
  final double? lng;

  const CreateOrderRequest({
    required this.cookId,
    required this.items,
    required this.deliveryAddress,
    this.repere,
    this.noteForCook,
    required this.paymentMethod,
    this.paymentPhone,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    // Defaults Douala centre when GPS missing — backend requires lat/lng.
    final body = <String, dynamic>{
      'cookId': cookId,
      'items': items,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': lat ?? 4.0511,
      'deliveryLng': lng ?? 9.7679,
      'paymentMethod': _normalizeMethod(paymentMethod),
    };
    if (repere != null) body['landmark'] = repere;
    if (noteForCook != null) body['clientNote'] = noteForCook;
    return body;
  }

  static String _normalizeMethod(String method) {
    switch (method.toLowerCase()) {
      case 'mtn_momo':
      case 'mtn':
      case 'falla_momo':
        return 'MTN_MOMO';
      case 'orange_money':
      case 'om':
        return 'ORANGE_MONEY';
      case 'cash':
        return 'CASH';
      default:
        return method.toUpperCase();
    }
  }
}

class OrdersRepository {
  final _client = ApiClient.instance;

  Future<OrderModel> createOrder(CreateOrderRequest request) async {
    final response = await _client.post(
      ApiConstants.orders,
      data: request.toJson(),
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getOrders({String? status, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    final response = await _client.get(
      ApiConstants.orders,
      queryParameters: params,
    );

    final data = response.data;
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    } else {
      list = [];
    }

    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> getOrderDetail(String id) async {
    final response = await _client.get(ApiConstants.orderById(id));
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> createReview({
    required String orderId,
    required double cookRating,
    double? riderRating,
    String? cookComment,
    String? riderComment,
  }) async {
    final body = <String, dynamic>{
      'orderId': orderId,
      'cookRating': cookRating,
    };
    if (riderRating != null) body['riderRating'] = riderRating;
    if (cookComment != null && cookComment.isNotEmpty) {
      body['cookComment'] = cookComment;
    }
    if (riderComment != null && riderComment.isNotEmpty) {
      body['riderComment'] = riderComment;
    }

    await _client.post(ApiConstants.reviews, data: body);
  }

  /// Notation post-livraison (3 notes obligatoires + tags + commentaire).
  ///
  /// Endpoint : POST /orders/:id/rating
  /// Body : { riderStars, restaurantStars, appStars, comment?, tags? }
  ///
  /// Fallback : si l'API renvoie 404/405 (ancien backend), on retombe sur
  /// POST /reviews avec cookRating=restaurantStars et riderRating=riderStars.
  Future<void> submitRating({
    required String orderId,
    required int riderStars,
    required int restaurantStars,
    required int appStars,
    String? comment,
    List<String> tags = const [],
  }) async {
    final body = <String, dynamic>{
      'riderStars': riderStars,
      'restaurantStars': restaurantStars,
      'appStars': appStars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (tags.isNotEmpty) 'tags': tags,
    };

    // ignore: avoid_print
    print('[Rating] POST /orders/$orderId/rating body=$body');

    try {
      final resp =
          await _client.post(ApiConstants.orderRating(orderId), data: body);
      // ignore: avoid_print
      print('[Rating] OK status=${resp.statusCode}');
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[Rating] DioException ${e.type} status=${e.response?.statusCode} '
          'path=${e.requestOptions.path} msg=${e.message} '
          'body=${e.response?.data}');

      final status = e.response?.statusCode;

      // 409 ALREADY_RATED → traiter comme un succès idempotent : l'utilisateur
      // a déjà noté cette commande, inutile de planter l'écran. La notation
      // existe déjà en base, on retourne silencieusement.
      if (status == 409) {
        // ignore: avoid_print
        print('[Rating] ALREADY_RATED — commande déjà notée, on retourne OK');
        return;
      }

      // Fallback /reviews UNIQUEMENT si l'endpoint rating n'existe pas (404/405).
      if (status == 404 || status == 405) {
        final mergedComment = [
          if (comment != null && comment.isNotEmpty) comment,
          if (tags.isNotEmpty) tags.join(', '),
          'App : $appStars/5',
        ].join(' — ');
        await createReview(
          orderId: orderId,
          cookRating: restaurantStars.toDouble(),
          riderRating: riderStars.toDouble(),
          riderComment: mergedComment,
        );
        return;
      }

      // Propage un ApiException lisible plutôt que le DioException brut —
      // la SnackBar côté UI affichera e.message (vrai message backend).
      final inner = e.error;
      if (inner is ApiException) {
        throw inner;
      }
      throw ApiExceptionHandler.handle(e);
    } on ApiException {
      // Déjà normalisée plus bas dans la chaîne — re-throw tel quel.
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[Rating] erreur inattendue: $e');
      rethrow;
    }
  }
}
