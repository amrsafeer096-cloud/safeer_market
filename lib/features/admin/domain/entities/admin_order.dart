class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.receiptUrl,
    this.customerName,
    this.customerPhone,
    this.addressDetails,
    this.deliveryFee = 0,
  });

  final String id;
  final DateTime createdAt;

  /// Grand total, including [deliveryFee].
  final double totalAmount;
  final double deliveryFee;
  final String? addressDetails;

  /// Raw `orders.status` value, kept as-is so unknown values still display.
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;

  /// Public URL of an InstaPay transfer screenshot (`orders.receipt_url`).
  final String? receiptUrl;
  final String? customerName;
  final String? customerPhone;

  String get shortId => id.length > 6 ? id.substring(0, 6) : id;

  double get itemsTotal => totalAmount - deliveryFee;

  AdminOrder copyWith({String? status}) => AdminOrder(
        id: id,
        createdAt: createdAt,
        totalAmount: totalAmount,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        receiptUrl: receiptUrl,
        customerName: customerName,
        customerPhone: customerPhone,
        addressDetails: addressDetails,
        deliveryFee: deliveryFee,
      );
}

/// Who an order is for, from their `profiles` row.
class OrderCustomer {
  const OrderCustomer({this.fullName, this.phone});

  final String? fullName;
  final String? phone;
}

class AdminOrderItem {
  const AdminOrderItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.weightInGrams,
  });

  final String id;
  final String productName;
  final String? imageUrl;
  final int quantity;

  /// Unit price at the time of the order (price of the chosen weight when
  /// [weightInGrams] is set).
  final double price;

  /// Grams for a weight-based line; null for unit products.
  final int? weightInGrams;

  double get total => price * quantity;
}
