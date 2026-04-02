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
    final body = <String, dynamic>{
      'cookId': cookId,
      'items': items,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
    };
    if (repere != null) body['repere'] = repere;
    if (noteForCook != null) body['noteForCook'] = noteForCook;
    if (paymentPhone != null) body['paymentPhone'] = paymentPhone;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    return body;
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
}
