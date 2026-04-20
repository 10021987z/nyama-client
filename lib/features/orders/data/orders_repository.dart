import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
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

  /// Notation simplifiée post-livraison rider (LOT 2 — UI Deliveroo-like).
  ///
  /// Endpoint : POST /orders/:id/rating { stars, comment, tags }.
  /// Si l'API ne supporte pas (404 / 405), on retombe sur l'ancien
  /// `/reviews` avec mapping `riderRating = stars`.
  Future<void> submitRating({
    required String orderId,
    required int stars,
    String? comment,
    List<String> tags = const [],
  }) async {
    final body = <String, dynamic>{
      'stars': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (tags.isNotEmpty) 'tags': tags,
    };
    try {
      await _client.post(ApiConstants.orderRating(orderId), data: body);
    } catch (_) {
      // Fallback /reviews (back-compat avec l'ancien backend) — concatène
      // les tags dans le commentaire pour ne rien perdre côté analytics.
      final mergedComment = [
        if (comment != null && comment.isNotEmpty) comment,
        if (tags.isNotEmpty) tags.join(', '),
      ].join(' — ');
      await createReview(
        orderId: orderId,
        cookRating: stars.toDouble(),
        riderRating: stars.toDouble(),
        riderComment: mergedComment.isEmpty ? null : mergedComment,
      );
    }
  }
}
