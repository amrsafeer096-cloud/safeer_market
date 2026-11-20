import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../../../home/presentation/providers/products_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';
import '../../data/repositories/supabase_catalog_repository.dart';
import '../../data/repositories/supabase_product_image_repository.dart';
import 'category_providers.dart';
import '../../domain/product_search.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/similar_products_query.dart';

final productImageRepositoryProvider =
    Provider<SupabaseProductImageRepository>((ref) {
  return SupabaseProductImageRepository(ref.watch(supabaseClientProvider));
});

/// After a product's photo is saved as [imageUrl]: the admin «بدون صورة»
/// list and its count drop it at once, cards still holding its old link
/// can't report it broken again, and every product list reloads so
/// customers start seeing it. Takes the [container] rather than a widget's
/// ref so it still runs after the admin has left the product screen.
void refreshAfterImageChange(
  ProviderContainer container,
  String productId,
  String imageUrl,
) {
  container
    ..read(replacedProductImagesProvider.notifier).record(productId, imageUrl)
    ..read(brokenImageProductsProvider.notifier).forget(productId)
    ..invalidate(productByIdProvider(productId))
    ..invalidate(productsWithoutImageProvider)
    ..invalidate(productsProvider)
    ..invalidate(featuredProductsProvider)
    ..invalidate(allOfferProductsProvider)
    ..invalidate(recentProductsProvider)
    ..invalidate(categoryProductsProvider)
    ..invalidate(productSearchProvider)
    ..invalidate(similarProductsProvider)
    ..invalidate(favoriteProductsProvider);
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SupabaseCatalogRepository(
    ref.watch(supabaseClientProvider),
    includeProductsWithoutImage: ref.watch(showProductsWithoutImageProvider),
  );
});

/// Serves both typed and scanned queries. Includes out-of-stock matches so a
/// scanned barcode can say «غير متوفر» instead of "not found"; lists show
/// only `.available`.
final productSearchProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products =
      await ref.watch(catalogRepositoryProvider).searchProducts(trimmed);
  return ProductSearch.filter(
    products.withImageUnless(includeWithoutImage),
    trimmed,
  );
});

/// Not filtered by stock or photo: deep links, the cart and favorites still
/// open the product, which then shows as unavailable if it is.
final productByIdProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, id) {
  return ref.watch(catalogRepositoryProvider).fetchProductById(id);
});

const similarProductsLimit = 12;

/// «منتجات مشابهة» for a product: what [CatalogRepository.fetchSimilarProducts]
/// relates to it (same sub-category, category, or leading name word). Only
/// when nothing in the catalog relates to it does the row fall back to the
/// home screen's random pick, so it is never empty.
final similarProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, SimilarProductsQuery>((ref, query) async {
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final similar =
      await ref.watch(catalogRepositoryProvider).fetchSimilarProducts(
            query: query,
            limit: similarProductsLimit,
          );
  final available =
      similar.availableFor(includeWithoutImage: includeWithoutImage);
  if (available.isNotEmpty) return available;

  final featured = await ref.watch(featuredProductsProvider.future);
  return featured
      .where((product) => product.id != query.productId)
      .take(similarProductsLimit)
      .toList();
});
