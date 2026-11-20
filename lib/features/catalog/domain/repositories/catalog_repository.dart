import '../../../home/domain/entities/product.dart';
import '../category_filter.dart';
import '../entities/category_page.dart';
import '../product_search.dart';
import '../similar_products_query.dart';

abstract class CatalogRepository {
  /// A page of in-stock products in any of [categories] (raw
  /// `products.category` values), matched as in [CategoryFilter.apply].
  Future<CategoryPage> fetchCategoryProducts({
    required List<String> categories,
    required int offset,
    required int limit,
  });

  /// Products whose barcode equals [query] or whose name contains it,
  /// case-insensitively. Callers still apply [ProductSearch.filter].
  Future<List<Product>> searchProducts(String query);

  Future<Product?> fetchProductById(String id);

  /// Up to [limit] in-stock products most like [query], excluding its
  /// product: first those sharing its `sub_category`, then its category,
  /// then those whose name starts with the same word (same brand or kind).
  /// Empty when nothing in the catalog relates to it.
  Future<List<Product>> fetchSimilarProducts({
    required SimilarProductsQuery query,
    required int limit,
  });
}
