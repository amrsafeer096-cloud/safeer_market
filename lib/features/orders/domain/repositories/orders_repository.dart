import '../entities/customer_order.dart';

abstract class OrdersRepository {
  /// Newest orders first.
  Future<List<CustomerOrder>> fetchOrders(String userId);

  /// The products in one of the customer's orders.
  Future<List<CustomerOrderItem>> fetchOrderItems(String orderId);

  /// Marks the customer's own order cancelled while it is still new or
  /// being prepared. Fails if a driver has already taken it.
  Future<void> cancelOrder(
    String orderId,
    OrderCancellationReason reason,
  );

  /// Saves the post-delivery rating (1–5 for delivery and products).
  Future<void> submitRating({
    required String orderId,
    required int deliveryRating,
    required int productRating,
    String? comment,
  });
}
