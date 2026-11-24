import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/postgrest_helpers.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/repositories/favorites_repository.dart';

class SupabaseFavoritesRepository implements FavoritesRepository {
  const SupabaseFavoritesRepository(
    this._client, {
    this.includeProductsWithoutImage = false,
  });

  static const _table = 'favorites';

  final SupabaseClient _client;

  /// False for customers: the favorites list then leaves out products with
  /// no photo.
  final bool includeProductsWithoutImage;

  @override
  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows =
        await _client.from(_table).select('product_id').eq('user_id', userId);
    return {for (final row in rows) row['product_id'].toString()};
  }

  @override
  Future<List<Product>> fetchFavoriteProducts(String userId) async {
    // `!inner` + stock/active filters drop OOS favorites for customers.
    // Admins (`includeProductsWithoutImage`) still see every favorited row.
    var request = _client
        .from(_table)
        .select('created_at, products!inner(*)')
        .eq('user_id', userId)
        .withImageUnless(
          includeProductsWithoutImage,
          column: 'products.image_url',
        );
    if (!includeProductsWithoutImage) {
      request = request
          .gt('products.stock_quantity', 0)
          .not('products.is_active', 'is', false);
    }
    final rows = await request.order('created_at', ascending: false);

    return [
      for (final row in rows)
        if (row['products'] case final Map<String, dynamic> product)
          ProductModel.fromJson(product),
    ];
  }

  @override
  Future<void> addFavorite({
    required String userId,
    required String productId,
  }) {
    return _client
        .from(_table)
        .insert({'user_id': userId, 'product_id': productId});
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) {
    return _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
