import 'package:intl/intl.dart';

// ─── Payment ──────────────────────────────────────────────────────────────────

class PaymentModel {
  final String method; // 'orange_money' | 'mtn_momo' | 'cash'
  final String status; // 'pending' | 'paid' | 'failed'
  final String? transactionId;
  final String? phone;

  const PaymentModel({
    required this.method,
    required this.status,
    this.transactionId,
    this.phone,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        method: json['method'] as String? ?? 'cash',
        status: json['status'] as String? ?? 'pending',
        transactionId: json['transactionId'] as String?,
        phone: json['phone'] as String?,
      );

  String get methodLabel {
    switch (method) {
      case 'orange_money':
        return 'Orange Money';
      case 'mtn_momo':
        return 'MTN MoMo';
      default:
        return 'Espèces';
    }
  }
}

// ─── Delivery ─────────────────────────────────────────────────────────────────

class DeliveryModel {
  final String? riderName;
  final String? riderPhone;
  final String? address;
  final String? repere;
  final double? lat;
  final double? lng;
  final DateTime? estimatedAt;
  final DateTime? deliveredAt;

  const DeliveryModel({
    this.riderName,
    this.riderPhone,
    this.address,
    this.repere,
    this.lat,
    this.lng,
    this.estimatedAt,
    this.deliveredAt,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) => DeliveryModel(
        riderName: json['riderName'] as String?,
        riderPhone: json['riderPhone'] as String?,
        address: json['address'] as String?,
        repere: json['repere'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        estimatedAt: json['estimatedAt'] != null
            ? DateTime.tryParse(json['estimatedAt'] as String)
            : null,
        deliveredAt: json['deliveredAt'] != null
            ? DateTime.tryParse(json['deliveredAt'] as String)
            : null,
      );
}

// ─── OrderItem ────────────────────────────────────────────────────────────────

class OrderItemModel {
  final String menuItemId;
  final String name;
  final int priceXaf;
  final int quantity;
  final String? imageUrl;

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.priceXaf,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        menuItemId: json['menuItemId'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        priceXaf: (json['priceXaf'] as num?)?.toInt() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: json['imageUrl'] as String?,
      );

  int get subtotal => priceXaf * quantity;
}

// ─── Review ───────────────────────────────────────────────────────────────────

class ReviewModel {
  final String id;
  final double cookRating;
  final double? riderRating;
  final String? cookComment;
  final String? riderComment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.cookRating,
    this.riderRating,
    this.cookComment,
    this.riderComment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String? ?? '',
        cookRating: (json['cookRating'] as num?)?.toDouble() ?? 0,
        riderRating: (json['riderRating'] as num?)?.toDouble(),
        cookComment: json['cookComment'] as String?,
        riderComment: json['riderComment'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─── OrderStatus ──────────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled;

  static OrderStatus fromString(String? s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'delivering':
        return OrderStatus.delivering;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;
}

// ─── OrderModel ───────────────────────────────────────────────────────────────

class OrderModel {
  final String id;
  final String shortId;
  final OrderStatus status;
  final String cookId;
  final String cookName;
  final String? cookPhone;
  final List<OrderItemModel> items;
  final int subtotalXaf;
  final int deliveryFeeXaf;
  final int totalXaf;
  final PaymentModel payment;
  final DeliveryModel delivery;
  final ReviewModel? review;
  final String? noteForCook;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.shortId,
    required this.status,
    required this.cookId,
    required this.cookName,
    this.cookPhone,
    required this.items,
    required this.subtotalXaf,
    required this.deliveryFeeXaf,
    required this.totalXaf,
    required this.payment,
    required this.delivery,
    this.review,
    this.noteForCook,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as String? ?? '',
      shortId: json['shortId'] as String? ??
          (json['id'] as String? ?? '').substring(0, 8).toUpperCase(),
      status: OrderStatus.fromString(json['status'] as String?),
      cookId: json['cookId'] as String? ?? '',
      cookName: json['cookName'] as String? ?? '',
      cookPhone: json['cookPhone'] as String?,
      items: itemsList,
      subtotalXaf: (json['subtotalXaf'] as num?)?.toInt() ?? 0,
      deliveryFeeXaf: (json['deliveryFeeXaf'] as num?)?.toInt() ?? 0,
      totalXaf: (json['totalXaf'] as num?)?.toInt() ?? 0,
      payment: json['payment'] != null
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : const PaymentModel(method: 'cash', status: 'pending'),
      delivery: json['delivery'] != null
          ? DeliveryModel.fromJson(json['delivery'] as Map<String, dynamic>)
          : const DeliveryModel(),
      review: json['review'] != null
          ? ReviewModel.fromJson(json['review'] as Map<String, dynamic>)
          : null,
      noteForCook: json['noteForCook'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get formattedDate =>
      DateFormat('d MMMM yyyy à HH:mm', 'fr').format(createdAt.toLocal());
}
