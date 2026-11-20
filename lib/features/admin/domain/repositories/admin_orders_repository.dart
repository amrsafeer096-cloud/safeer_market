import '../entities/admin_order.dart';
import '../entities/order_status.dart';

abstract interface class AdminOrdersRepository {
  /// Every customer's orders, newest first.
  Future<List<AdminOrder>> fetchAllOrders();

  Future<AdminOrder?> fetchOrder(String orderId);

  Future<List<AdminOrderItem>> fetchOrderItems(String orderId);

  Future<void> updateStatus(String orderId, OrderStatus status);

  /// Name and phone of each customer in [userIds] (`orders.user_id`), by id.
  /// The live orders stream can't embed `profiles`, so the dashboard reads
  /// them here, all in one query.
  Future<Map<String, OrderCustomer>> fetchCustomers(Iterable<String> userIds);
}

class AdminFailure implements Exception {
  const AdminFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
