/// What the app knows about a scanned barcode on a goods receipt.
class ReceiptProduct {
  const ReceiptProduct({this.name, this.category, this.imageUrl});

  /// `products.name`, or null when the barcode is not in `products`.
  final String? name;

  /// Raw `products.category`, used only for the placeholder icon.
  final String? category;

  /// Public URL of `<barcode>.jpg` in the `product_images` bucket.
  final String? imageUrl;
}
