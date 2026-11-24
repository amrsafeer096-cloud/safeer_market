import '../../admin/domain/entities/order_status.dart';

/// Whether live item editing is still allowed for this order.
bool orderAllowsLiveEdit({
  required String status,
  Object? prepCompletedAt,
}) {
  if (prepCompletedAt != null && '$prepCompletedAt'.trim().isNotEmpty) {
    return false;
  }
  final normalized = OrderStatus.normalize(status);
  return const {
    'pending',
    'new',
    'confirmed',
    'preparing',
  }.contains(normalized);
}

/// Draft line while editing an order before confirming.
class OrderEditLine {
  OrderEditLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.barcode,
    this.weightInGrams,
    this.existingItemId,
  });

  final String productId;
  final String productName;
  final String? barcode;
  double unitPrice;
  int quantity;
  int? weightInGrams;
  final String? existingItemId;

  double get lineTotal {
    final grams = weightInGrams;
    if (grams != null && grams > 0) {
      return unitPrice * grams / 1000.0;
    }
    return unitPrice * quantity;
  }

  Map<String, dynamic> toRpcJson() => {
        'product_id': productId,
        'quantity': quantity < 1 ? 1 : quantity,
        'price_at_time': unitPrice,
        if (weightInGrams != null && weightInGrams! > 0)
          'weight_in_grams': weightInGrams,
      };

  OrderEditLine copyWith({
    int? quantity,
    double? unitPrice,
    int? weightInGrams,
  }) =>
      OrderEditLine(
        productId: productId,
        productName: productName,
        barcode: barcode,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        weightInGrams: weightInGrams ?? this.weightInGrams,
        existingItemId: existingItemId,
      );
}
