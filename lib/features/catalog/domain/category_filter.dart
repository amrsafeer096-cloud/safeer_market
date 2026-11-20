import '../../home/domain/entities/product.dart';

/// Category matching. The Supabase repository applies the same rules
/// server-side so large categories don't have to be downloaded to be
/// filtered.
abstract final class CategoryFilter {
  /// In-stock products whose trimmed `category` is one of [categories].
  static List<Product> apply(
    Iterable<Product> products, {
    required List<String> categories,
  }) {
    final names = {for (final name in categories) name.trim()};
    return [
      for (final product in products)
        if (product.inStock && names.contains(product.category?.trim()))
          product,
    ];
  }
}
