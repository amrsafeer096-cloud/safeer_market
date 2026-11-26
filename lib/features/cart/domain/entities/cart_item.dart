import '../../../home/domain/entities/product.dart';
import '../weight_options.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.selectedWeightInGrams,
    this.notes,
  });

  final Product product;

  /// Always 1 for weight-based items; their amount is [selectedWeightInGrams].
  final int quantity;
  final int? selectedWeightInGrams;

  /// Optional per-item instruction («ملاحظة للصنف»).
  final String? notes;

  bool get isWeightBased => selectedWeightInGrams != null;

  String? get trimmedNotes {
    final t = notes?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Price of one piece, or of the selected weight for weight-based items,
  /// after any offer.
  double get unitPrice => switch (selectedWeightInGrams) {
        final grams? => WeightOptions.priceFor(product.effectivePrice, grams),
        null => product.effectivePrice,
      };

  double get total => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    int? selectedWeightInGrams,
    String? notes,
    bool clearNotes = false,
  }) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedWeightInGrams:
          selectedWeightInGrams ?? this.selectedWeightInGrams,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
