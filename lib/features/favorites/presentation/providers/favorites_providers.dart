import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../../data/repositories/supabase_favorites_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return SupabaseFavoritesRepository(
    ref.watch(supabaseClientProvider),
    includeProductsWithoutImage: ref.watch(showProductsWithoutImageProvider),
  );
});

/// Product ids the signed-in user has favorited; empty for guests.
final favoriteIdsProvider =
    AsyncNotifierProvider<FavoriteIdsNotifier, Set<String>>(
  FavoriteIdsNotifier.new,
);

class FavoriteIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const {};
    return ref.watch(favoritesRepositoryProvider).fetchFavoriteIds(user.id);
  }

  /// Optimistically flips the heart, rolling back if Supabase rejects it.
  /// Returns whether the product is now a favorite.
  Future<bool> toggle(String productId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Sign in to manage favorites');

    final repository = ref.read(favoritesRepositoryProvider);
    final previous = state.valueOrNull ?? const <String>{};
    final adding = !previous.contains(productId);

    state = AsyncData(
      adding ? {...previous, productId} : ({...previous}..remove(productId)),
    );
    try {
      if (adding) {
        await repository.addFavorite(userId: user.id, productId: productId);
      } else {
        await repository.removeFavorite(userId: user.id, productId: productId);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
    return adding;
  }
}

final favoriteProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products = await ref
      .watch(favoritesRepositoryProvider)
      .fetchFavoriteProducts(user.id);
  // Customers: in-stock only. Admins may still see OOS favorites.
  return includeWithoutImage
      ? products.withImageUnless(true)
      : products.availableFor(includeWithoutImage: false);
});
