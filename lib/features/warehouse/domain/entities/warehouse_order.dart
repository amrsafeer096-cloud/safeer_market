import '../../../admin/domain/entities/order_status.dart';

class WarehouseOrderItem {
  const WarehouseOrderItem({required this.productName, required this.quantity});

  final String productName;
  final int quantity;
}

class WarehouseOrder {
  const WarehouseOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    this.items = const [],
    this.customerName,
    this.addressDetails,
  });

  final String id;
  final DateTime createdAt;

  /// Raw `orders.status`: `pending` or `preparing` while in the queue.
  final String status;
  final double totalAmount;
  final List<WarehouseOrderItem> items;
  final String? customerName;
  final String? addressDetails;

  String get shortId => id.length > 6 ? id.substring(0, 6) : id;

  bool get isPending => OrderStatus.fromValue(status) == OrderStatus.pending;

  bool get isPreparing =>
      OrderStatus.fromValue(status) == OrderStatus.preparing;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
