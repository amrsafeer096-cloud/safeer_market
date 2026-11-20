import '../../../home/domain/entities/product.dart';

abstract interface class FavoritesRepository {
  Future<Set<String>> fetchFavoriteIds(String userId);

  /// Favorited products, most recently added first.
  Future<List<Product>> fetchFavoriteProducts(String userId);

  Future<void> addFavorite({required String userId, required String productId});

  Future<void> removeFavorite({
    required String userId,
    required String productId,
  });
}
