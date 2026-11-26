import '../../admin/domain/entities/order_status.dart';
import '../../home/domain/entities/product.dart';

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
    this.imageUrl,
    this.listPrice,
    this.stockQuantity = 0,
    this.weightInGrams,
    this.isWeightBased = false,
    this.unit = Product.defaultUnit,
    this.existingItemId,
  });

  final String productId;
  final String productName;
  final String? barcode;
  final String? imageUrl;

  /// Shelf / list price (for offer badge when [unitPrice] is discounted).
  final double? listPrice;
  final int stockQuantity;
  double unitPrice;
  int quantity;
  int? weightInGrams;
  final bool isWeightBased;
  final String unit;
  final String? existingItemId;

  bool get soldByWeight =>
      isWeightBased || (weightInGrams != null && weightInGrams! > 0);

  double get lineTotal {
    final grams = weightInGrams;
    if (grams != null && grams > 0) {
      return unitPrice * grams / 1000.0;
    }
    return unitPrice * quantity;
  }

  Map<String, dynamic> toRpcJson() => {
        'product_id': productId,
        'quantity': soldByWeight ? 1 : (quantity < 1 ? 1 : quantity),
        'price_at_time': unitPrice,
        if (weightInGrams != null && weightInGrams! > 0)
          'weight_in_grams': weightInGrams,
      };

  Product toProduct() {
    final shelf = listPrice;
    final onOffer =
        shelf != null && shelf > unitPrice && unitPrice > 0;
    return Product(
      id: productId,
      name: productName,
      price: onOffer ? shelf : unitPrice,
      discountPrice: onOffer ? unitPrice : null,
      barcode: barcode,
      imageUrl: imageUrl,
      stockQuantity: stockQuantity,
      unit: soldByWeight ? Product.weightUnit : unit,
      isWeightBased: soldByWeight,
    );
  }

  OrderEditLine copyWith({
    int? quantity,
    double? unitPrice,
    int? weightInGrams,
    bool clearWeight = false,
  }) =>
      OrderEditLine(
        productId: productId,
        productName: productName,
        barcode: barcode,
        imageUrl: imageUrl,
        listPrice: listPrice,
        stockQuantity: stockQuantity,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        weightInGrams:
            clearWeight ? null : (weightInGrams ?? this.weightInGrams),
        isWeightBased: isWeightBased,
        unit: unit,
        existingItemId: existingItemId,
      );
}
