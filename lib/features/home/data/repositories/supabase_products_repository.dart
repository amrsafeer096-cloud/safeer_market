import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/postgrest_helpers.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../models/product_model.dart';

class SupabaseProductsRepository implements ProductsRepository {
  SupabaseProductsRepository(
    this._client, {
    Random? random,
    this.includeProductsWithoutImage = false,
  }) : _random = random ?? Random();

  /// Random windows the fallback sample is drawn from, so the pick spans the
  /// catalog instead of one run of neighbouring rows.
  static const _sampleWindows = 4;

  final SupabaseClient _client;
  final Random _random;

  /// False for customers: lists then leave out products with no photo.
  final bool includeProductsWithoutImage;

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _products([
    String columns = '*',
  ]) =>
      _client
          .from('products')
          .select(columns)
          .withImageUnless(includeProductsWithoutImage);

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _products();
    return rows
        .map((row) => ProductModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<List<Product>> fetchRandomProducts({required int limit}) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'random_products',
        params: {
          'p_limit': limit,
          if (!includeProductsWithoutImage) 'p_with_image': true,
        },
      );
      return rows
          .map((row) => ProductModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (error) {
      if (!isMissingFunction(error)) rethrow;
      return _sampleInStock(limit);
    }
  }

  @override
  Future<List<Product>> fetchOfferProducts({int? maxRows}) async {
    // PostgREST can't compare discount_price with price, so rows with any
    // discount are paged in and the real offers kept here.
    final offers = <Product>[];
    for (var start = 0;; start += postgrestMaxRows) {
      final pageSize = maxRows == null
          ? postgrestMaxRows
          : min(postgrestMaxRows, maxRows - start);
      if (pageSize <= 0) return offers;
      final rows = await _products()
          .inStock()
          .not('discount_price', 'is', null)
          .order('id')
          .range(start, start + pageSize - 1);
      offers.addAll(_toProducts(rows).where((p) => p.hasActiveOffer));
      if (rows.length < pageSize) return offers;
    }
  }

  /// Most rows «منتجات جديدة» ever needs: the home row shows 20 and «عرض
  /// الكل» a screenful more.
  static const newProductsMaxRows = 100;

  @override
  Future<List<Product>> fetchNewProducts({required DateTime since}) async {
    try {
      return _toProducts(
        await _products()
            .inStock()
            .gt('created_at', since.toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(newProductsMaxRows),
      );
    } on PostgrestException catch (error) {
      // Without created_at nothing can be dated as new.
      if (!isMissingColumn(error)) rethrow;
      return const [];
    }
  }

  @override
  Future<List<Product>> fetchProductsWithoutImage() async {
    try {
      return await _allPages(
        (from, to) => _client
            .rpc<List<dynamic>>('products_missing_image')
            .range(from, to),
      );
    } on PostgrestException catch (error) {
      if (!isMissingFunction(error)) rethrow;
    }

    // Without products_missing_image(): links that are missing or not
    // http(s). Dead Storage links then only show up once they fail to load.
    final [missing, invalid] = await Future.wait([
      _allPages(
        (from, to) => _client
            .from('products')
            .select()
            .isFilter('image_url', null)
            .order('id')
            .range(from, to),
      ),
      _allPages(
        (from, to) => _client
            .from('products')
            .select()
            .not('image_url', 'imatch', r'^\s*https?://[^\s/]')
            .order('id')
            .range(from, to),
      ),
    ]);
    return [...missing, ...invalid]..sort((a, b) {
        final stock = (b.inStock ? 1 : 0) - (a.inStock ? 1 : 0);
        return stock != 0 ? stock : a.name.compareTo(b.name);
      });
  }

  /// Every row of [page], fetched [postgrestMaxRows] at a time.
  static Future<List<Product>> _allPages(
    Future<List<dynamic>> Function(int from, int to) page,
  ) async {
    final products = <Product>[];
    for (var start = 0;; start += postgrestMaxRows) {
      final rows = await page(start, start + postgrestMaxRows - 1);
      products.addAll([
        for (final row in rows)
          ProductModel.fromJson(Map<String, dynamic>.from(row as Map)),
      ]);
      if (rows.length < postgrestMaxRows) return products;
    }
  }

  static List<Product> _toProducts(List<Map<String, dynamic>> rows) =>
      rows.map(ProductModel.fromJson).toList();

  /// Without `random_products()` (or its `p_with_image` parameter): a few
  /// random windows of in-stock rows, shuffled together.
  Future<List<Product>> _sampleInStock(int limit) async {
    final total =
        (await _products('id').inStock().limit(1).count(CountOption.exact))
            .count;
    if (total == 0) return const [];

    final perWindow = (limit / _sampleWindows).ceil();
    final lastStart = max(0, total - perWindow);
    final starts = {
      for (var i = 0; i < _sampleWindows; i++) _random.nextInt(lastStart + 1),
    };
    final pages = await Future.wait([
      for (final start in starts)
        _products().inStock().order('id').range(start, start + perWindow - 1),
    ]);
    final byId = <String, Product>{};
    for (final row in pages.expand((page) => page)) {
      final product = ProductModel.fromJson(row);
      byId[product.id] = product;
    }
    return (byId.values.toList()..shuffle(_random)).take(limit).toList();
  }
}
