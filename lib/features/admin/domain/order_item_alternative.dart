/// A pending / resolved «إرسال بدائل» row for one order line.
class OrderItemAlternative {
  const OrderItemAlternative({
    required this.id,
    required this.orderId,
    required this.originalOrderItemId,
    required this.suggestedProducts,
    required this.status,
    required this.createdAt,
    this.selectedProductId,
    this.createdByStaffId,
    this.originalProductName,
  });

  final String id;
  final String orderId;
  final String originalOrderItemId;
  final List<AlternativeProduct> suggestedProducts;

  /// `pending` | `selected` | `rejected` | `removed`
  final String status;
  final String? selectedProductId;
  final String? createdByStaffId;
  final DateTime createdAt;
  final String? originalProductName;

  bool get isPending => status == 'pending';

  factory OrderItemAlternative.fromRow(Map<String, dynamic> row) {
    final raw = row['suggested_products'];
    final products = <AlternativeProduct>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          products.add(
            AlternativeProduct.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }
    return OrderItemAlternative(
      id: '${row['id']}',
      orderId: '${row['order_id']}',
      originalOrderItemId: '${row['original_order_item_id']}',
      suggestedProducts: products,
      status: '${row['status'] ?? 'pending'}',
      selectedProductId: row['selected_product_id']?.toString(),
      createdByStaffId: row['created_by_staff_id']?.toString(),
      createdAt: DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
      originalProductName: row['original_product_name']?.toString(),
    );
  }
}

class AlternativeProduct {
  const AlternativeProduct({
    required this.productId,
    required this.name,
    required this.price,
    this.barcode,
    this.imageUrl,
  });

  final String productId;
  final String name;
  final double price;
  final String? barcode;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'id': productId,
        'name': name,
        'price': price,
        if (barcode != null) 'barcode': barcode,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    final id = '${json['product_id'] ?? json['id'] ?? ''}';
    final price = switch (json['price']) {
      final num n => n.toDouble(),
      final String t => double.tryParse(t) ?? 0,
      _ => 0.0,
    };
    return AlternativeProduct(
      productId: id,
      name: '${json['name'] ?? ''}',
      price: price,
      barcode: json['barcode']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
    );
  }

  factory AlternativeProduct.fromProductRow(Map<String, dynamic> row) {
    final image = row['image_url']?.toString().trim();
    return AlternativeProduct(
      productId: '${row['id']}',
      name: '${row['name'] ?? ''}',
      price: switch (row['price']) {
        final num n => n.toDouble(),
        final String t => double.tryParse(t) ?? 0,
        _ => 0.0,
      },
      barcode: row['barcode']?.toString(),
      imageUrl: image == null || image.isEmpty ? null : image,
    );
  }
}
