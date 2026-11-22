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
    this.productId,
    this.barcode,
    this.imageUrl,
    this.unit,
    this.weightInGrams,
    this.isWeightBased = false,
  });

  /// `order_items.id`.
  final String id;
  final String? productId;
  final String productName;
  final String? barcode;
  final String? imageUrl;

  /// Product unit label from `products.unit` (قطعة / علبة / …).
  final String? unit;
  final int quantity;

  /// Unit price at the time of the order (price of the chosen weight when
  /// [weightInGrams] is set).
  final double price;

  /// Grams for a weight-based line; null / ≤0 for unit products.
  final int? weightInGrams;
  final bool isWeightBased;

  /// True only when this line has a positive gram amount (never «0 جرام»).
  bool get isWeighted => weightInGrams != null && weightInGrams! > 0;

  double get total => price * quantity;

  /// Badge / subtitle for preparers: weight label or «1 قطعة».
  String get quantityLabel {
    if (isWeighted) {
      final grams = weightInGrams!;
      if (grams < 1000) return '$grams جرام';
      final kilos = grams / 1000;
      final text = kilos == kilos.truncateToDouble()
          ? '${kilos.toInt()}'
          : '$kilos';
      return '$text كجم';
    }
    final u = (unit ?? '').trim();
    if (u.isEmpty || _looksLikeWeightUnit(u)) return '$quantity قطعة';
    return '$quantity $u';
  }

  static bool _looksLikeWeightUnit(String unit) {
    final u = unit.toLowerCase();
    return u.contains('كجم') ||
        u.contains('كيلو') ||
        u.contains('جرام') ||
        u.contains('وزن') ||
        u.contains('kg') ||
        u.contains('gram');
  }
}
