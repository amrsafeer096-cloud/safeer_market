import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/postgrest_helpers.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/entities/category_page.dart';
import '../../domain/main_categories.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/similar_products_query.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(
    this._client, {
    this.includeProductsWithoutImage = false,
  });

  static const _searchLimit = 30;

  final SupabaseClient _client;

  /// False for customers: category pages, search and similar products then
  /// leave out products with no photo. [fetchProductById] never does.
  final bool includeProductsWithoutImage;

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _products() => _client
      .from('products')
      .select()
      .withImageUnless(includeProductsWithoutImage);

  // ----------------------------------------------------
  // Reverting to the exact safe version that handles duplicates
  // and includes unit in the unique key without breaking dependencies
  // ----------------------------------------------------
  List<Product> _removeDuplicates(List<Product> products) {
    final uniqueMap = <String, Product>{};
    for (final product in products) {
      final nameKey = '${product.name.trim().toLowerCase()}_${product.unit}';

      if (!uniqueMap.containsKey(nameKey)) {
        uniqueMap[nameKey] = product;
      } else {
        if (uniqueMap[nameKey]!.imageUrl == null && product.imageUrl != null) {
          uniqueMap[nameKey] = product;
        }
      }
    }
    return uniqueMap.values.toList();
  }

  @override
  Future<CategoryPage> fetchCategoryProducts({
    required List<String> categories,
    required int offset,
    required int limit,
  }) async {
    final spellings = MainCategories.querySpellingsFor(categories);

    final fetchLimit = limit + 25;

    final response = await _products()
        .inFilter('category', spellings)
        .inStock()
        .order('name')
        .order('id')
        .range(offset, offset + fetchLimit - 1)
        .count(CountOption.exact);

    final rawProducts = response.data.map(ProductModel.fromJson).toList();
    final uniqueProducts = _removeDuplicates(rawProducts);

    return CategoryPage(
      products: uniqueProducts.take(limit).toList(),
      total: response.count,
    );
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final escaped = query
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    if (escaped.isEmpty) return [];

    final words =
        escaped.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final firstPart = words.isNotEmpty ? words.first : escaped;

    // Customer search is in-stock only (stock > 0 + active).
    final [barcodeRows, nameRows] = await Future.wait([
      _products().inStock().ilike('barcode', escaped).limit(100),
      _products()
          .inStock()
          .ilike('name', '%$firstPart%')
          .order('name')
          .limit(100),
    ]);

    final raw = [...barcodeRows, ...nameRows];
    final rawProducts = raw.map(ProductModel.fromJson).toList();
    return _removeDuplicates(rawProducts);
  }

  /// Barcode lookup that may return OOS rows — used only to show
  /// «غير متوفر» after an in-stock search misses. Never listed in grids.
  Future<Product?> lookupBarcodeAnyStock(String barcode) async {
    final escaped = barcode
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (escaped.isEmpty) return null;
    final row = await _client
        .from('products')
        .select()
        .ilike('barcode', escaped)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return ProductModel.fromJson(row);
  }

  @override
  Future<Product?> fetchProductById(String id) async {
    final response =
        await _client.from('products').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  @override
  Future<List<Product>> fetchSimilarProducts({
    required SimilarProductsQuery query,
    required int limit,
  }) async {
    // Over-fetch so dedupe can drop same-name rows and still fill [limit].
    final fetchLimit = limit * 3;
    final found = <String, Product>{};

    void keep(List<Map<String, dynamic>> rows) {
      for (final product
          in _removeDuplicates(rows.map(ProductModel.fromJson).toList())) {
        if (product.id == query.productId) continue;
        found.putIfAbsent(product.id, () => product);
      }
    }

    PostgrestFilterBuilder<List<Map<String, dynamic>>> inStockOthers() =>
        _products().neq('id', query.productId).inStock();

    // 1. Same sub-category within the same category: the closest match.
    if (query.categoryId case final categoryId?
        when query.subCategory != null) {
      keep(await inStockOthers()
          .eq('category_id', categoryId)
          .eq('sub_category', query.subCategory!)
          .order('name')
          .limit(fetchLimit));
    }

    // 2. Same category, by `category_id` or else by the `category` group.
    if (found.length < limit) {
      final categoryId = query.categoryId;
      final group = query.category;
      final byCategory = categoryId != null
          ? inStockOthers().eq('category_id', categoryId)
          : group != null
              ? inStockOthers().inFilter('category', [group, '$group '])
              : null;
      if (byCategory != null) {
        keep(await byCategory.order('name').limit(fetchLimit));
      }
    }

    // 3. Same leading word of the name: same brand or kind, ranked by how
    //    many leading words they share with the product.
    if (found.length < limit) {
      if (leadingWord(query.name) case final word?) {
        final escaped = word
            .replaceAll(r'\', r'\\')
            .replaceAll('%', r'\%')
            .replaceAll('_', r'\_');
        final rows = await inStockOthers()
            .ilike('name', '$escaped%')
            .order('name')
            .limit(fetchLimit);
        final byName =
            _removeDuplicates(rows.map(ProductModel.fromJson).toList())
              ..sort((a, b) => sharedLeadingWords(query.name, b.name)
                  .compareTo(sharedLeadingWords(query.name, a.name)));
        for (final product in byName) {
          if (product.id == query.productId) continue;
          found.putIfAbsent(product.id, () => product);
        }
      }
    }

    return found.values.take(limit).toList();
  }
}
