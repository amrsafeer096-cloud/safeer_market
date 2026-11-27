import '../../domain/entities/product.dart';

class ProductModel {
  const ProductModel._();

  /// Maps a `products` row. Availability comes from `stock_quantity` (null
  /// counts as 0) and `is_active` (true unless the row says otherwise).
  static Product fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    return Product(
      id: json['id'].toString(),
      name: name,
      price: _parseNumber(json['price']) ?? 0,
      imageUrl: _parseText(json['image_url']),
      // `uom` covers imports that name the column that way; a missing column
      // just reads as null.
      unit: _parseText(json['unit']) ??
          _parseText(json['uom']) ??
          Product.unitFromName(name),
      description: _parseText(json['description']),
      categoryId: _parseText(json['category_id']?.toString()),
      category: _parseText(json['category']),
      subCategory: _parseText(json['sub_category']),
      stockQuantity: _parseInt(json['stock_quantity']) ?? 0,
      barcode: _parseText(json['barcode']?.toString()),
      discountPrice: _parseNumber(json['discount_price']),
      isActive: _parseBool(json['is_active']) ?? true,
      createdAt: _parseDate(json['created_at']),
      pieces: (_parseInt(json['pieces']) ?? 1).clamp(1, 999999),
      // Persist DB flag; [Product.isWeightBased] still enforces pieces<=1.
      isWeightBased: json['is_weight_based'] == true,
    );
  }

  /// Column names match the `products` table, so the output round-trips
  /// through [fromJson].
  static Map<String, dynamic> toJson(Product product) => {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'image_url': product.imageUrl,
        'unit': product.unit,
        'description': product.description,
        'category_id': product.categoryId,
        'category': product.category,
        'sub_category': product.subCategory,
        'stock_quantity': product.stockQuantity,
        'barcode': product.barcode,
        'discount_price': product.discountPrice,
        'is_active': product.isActive,
        if (product.createdAt case final createdAt?)
          'created_at': createdAt.toUtc().toIso8601String(),
        'pieces': product.pieces < 1 ? 1 : product.pieces,
        // Store the rule-aware value so caches/offline carts stay consistent.
        'is_weight_based': product.isWeightBased,
      };

  static DateTime? _parseDate(Object? value) => switch (value) {
        final DateTime value => value,
        final String value => DateTime.tryParse(value.trim()),
        _ => null,
      };

  static int? _parseInt(Object? value) => switch (value) {
        final int value => value,
        final num value => value.floor(),
        final String value =>
          int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.floor(),
        _ => null,
      };

  static double? _parseNumber(Object? value) => switch (value) {
        final num value => value.toDouble(),
        final String value => double.tryParse(value.trim()),
        _ => null,
      };

  /// Null when the value is missing or unrecognised.
  static bool? _parseBool(Object? value) => switch (value) {
        final bool value => value,
        final num value => value != 0,
        final String value => switch (value.trim().toLowerCase()) {
            'true' || '1' || 't' => true,
            'false' || '0' || 'f' => false,
            _ => null,
          },
        _ => null,
      };

  static String? _parseText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
