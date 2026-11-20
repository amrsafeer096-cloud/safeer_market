/// One scanned line on a goods receipt, before it is saved.
class ReceiptLine {
  const ReceiptLine({required this.barcode, required this.quantity});

  final String barcode;
  final int quantity;

  ReceiptLine copyWith({int? quantity}) => ReceiptLine(
        barcode: barcode,
        quantity: quantity ?? this.quantity,
      );
}
