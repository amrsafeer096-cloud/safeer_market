import '../../../home/domain/entities/product.dart';
import '../weight_options.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.selectedWeightInGrams,
  });

  final Product product;

  /// Always 1 for weight-based items; their amount is [selectedWeightInGrams].
  final int quantity;
  final int? selectedWeightInGrams;

  bool get isWeightBased => selectedWeightInGrams != null;

  /// Price of one piece, or of the selected weight for weight-based items,
  /// after any offer.
  double get unitPrice => switch (selectedWeightInGrams) {
        final grams? => WeightOptions.priceFor(product.effectivePrice, grams),
        null => product.effectivePrice,
      };

  double get total => unitPrice * quantity;

  CartItem copyWith({int? quantity, int? selectedWeightInGrams}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedWeightInGrams:
          selectedWeightInGrams ?? this.selectedWeightInGrams,
    );
  }
}
