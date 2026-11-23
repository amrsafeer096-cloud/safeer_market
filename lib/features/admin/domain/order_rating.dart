/// A customer rating row from `order_ratings` (optionally joined to orders).
class OrderRating {
  const OrderRating({
    required this.id,
    required this.orderId,
    required this.deliveryRating,
    required this.productRating,
    required this.createdAt,
    this.comment,
    this.customerName,
    this.driverName,
  });

  final String id;
  final String orderId;
  final int deliveryRating;
  final int productRating;
  final String? comment;
  final DateTime createdAt;
  final String? customerName;
  final String? driverName;

  /// True when either score is 3 or below (follow-up filter).
  bool get isLow => deliveryRating <= 3 || productRating <= 3;

  String get shortOrderId {
    final text = orderId;
    return '#${text.length > 6 ? text.substring(0, 6) : text}';
  }

  static OrderRating? fromRow(Map<String, dynamic>? row) {
    if (row == null || row.isEmpty) return null;
    final orderId = row['order_id']?.toString();
    if (orderId == null || orderId.isEmpty) return null;
    final delivery = _int(row['delivery_rating']);
    final product = _int(row['product_rating']);
    if (delivery == null || product == null) return null;

    Map<String, dynamic>? order;
    final rawOrder = row['orders'];
    if (rawOrder is Map<String, dynamic>) {
      order = rawOrder;
    } else if (rawOrder is List && rawOrder.isNotEmpty) {
      final first = rawOrder.first;
      if (first is Map<String, dynamic>) order = first;
    }

    String? text(Object? value) {
      final t = value?.toString().trim();
      return t == null || t.isEmpty ? null : t;
    }

    return OrderRating(
      id: row['id']?.toString() ?? orderId,
      orderId: orderId,
      deliveryRating: delivery,
      productRating: product,
      comment: text(row['comment']),
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ?? DateTime.now(),
      customerName: text(order?['customer_name']),
      driverName: text(order?['driver_name']),
    );
  }

  static int? _int(Object? value) => switch (value) {
        final int n => n,
        final num n => n.round(),
        final String t => int.tryParse(t),
        _ => null,
      };
}

/// Aggregates for the «تقييمات العملاء» report summary.
class OrderRatingsSummary {
  const OrderRatingsSummary({
    required this.ratings,
    required this.avgDelivery,
    required this.avgProduct,
  });

  final List<OrderRating> ratings;
  final double avgDelivery;
  final double avgProduct;

  int get total => ratings.length;

  factory OrderRatingsSummary.from(List<OrderRating> ratings) {
    if (ratings.isEmpty) {
      return const OrderRatingsSummary(
        ratings: [],
        avgDelivery: 0,
        avgProduct: 0,
      );
    }
    final delivery =
        ratings.fold<int>(0, (s, r) => s + r.deliveryRating) / ratings.length;
    final product =
        ratings.fold<int>(0, (s, r) => s + r.productRating) / ratings.length;
    return OrderRatingsSummary(
      ratings: ratings,
      avgDelivery: delivery,
      avgProduct: product,
    );
  }
}
