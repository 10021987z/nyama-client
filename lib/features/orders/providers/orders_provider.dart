import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_models.dart';
import '../data/orders_repository.dart';

final _repo = OrdersRepository();

/// All orders for a given status filter (null = all)
final ordersListProvider =
    FutureProvider.family<List<OrderModel>, String?>((ref, status) async {
  return _repo.getOrders(status: status);
});

/// Single order detail
final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) async {
  return _repo.getOrderDetail(id);
});

/// Active orders only (pending → delivering)
final activeOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final all = await _repo.getOrders();
  return all.where((o) => o.status.isActive).toList();
});

/// Past orders (delivered + cancelled)
final pastOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final all = await _repo.getOrders();
  return all.where((o) => !o.status.isActive).toList();
});
