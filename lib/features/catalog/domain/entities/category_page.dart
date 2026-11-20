import '../../../home/domain/entities/product.dart';

class CategoryPage {
  const CategoryPage({required this.products, required this.total});

  /// One page, sorted by name.
  final List<Product> products;

  /// Every product matching the filter, across all pages.
  final int total;
}
