import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../data/repositories/supabase_products_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import 'product_visibility_provider.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return SupabaseProductsRepository(
    ref.watch(supabaseClientProvider),
    includeProductsWithoutImage: ref.watch(showProductsWithoutImageProvider),
  );
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products = await ref.watch(productsRepositoryProvider).fetchProducts();
  return products.availableFor(includeWithoutImage: includeWithoutImage);
});

const featuredProductsLimit = 20;

/// A fresh random pick for the home screen's «منتجات مختارة» row.
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products = await ref
      .watch(productsRepositoryProvider)
      .fetchRandomProducts(limit: featuredProductsLimit);
  return products.availableFor(includeWithoutImage: includeWithoutImage);
});

const offerProductsLimit = 15;

/// How recently a product must have been added to count as new.
const newProductsWindow = Duration(days: 3);

/// Every product on offer, mixed across categories; «عرض الكل» for offers.
final allOfferProductsProvider = FutureProvider<List<Product>>((ref) async {
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products =
      await ref.watch(productsRepositoryProvider).fetchOfferProducts();
  final offers = products
      .availableFor(includeWithoutImage: includeWithoutImage)
      .where((product) => product.hasActiveOffer);
  return mixOffersByCategory(offers, limit: offers.length);
});

/// Discounted rows read for the home row: a few times what it shows, so
/// there is enough to mix categories without paging the whole offers table.
const offerProductsFetchRows = 60;

/// The home screen's «عروض رائجة» row: [offerProductsLimit] offers from the
/// first [offerProductsFetchRows] discounted rows. Reuses «عرض الكل»'s full
/// list when that has already been loaded.
final offerProductsProvider = FutureProvider<List<Product>>((ref) async {
  if (ref.exists(allOfferProductsProvider)) {
    final all = await ref.watch(allOfferProductsProvider.future);
    return all.take(offerProductsLimit).toList();
  }
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final products = await ref
      .watch(productsRepositoryProvider)
      .fetchOfferProducts(maxRows: offerProductsFetchRows);
  final offers = products
      .availableFor(includeWithoutImage: includeWithoutImage)
      .where((product) => product.hasActiveOffer);
  return mixOffersByCategory(offers, limit: offerProductsLimit);
});

const newProductsLimit = 20;

/// «منتجات جديدة» in full, for «عرض الكل». Admins get every product in the
/// store that still needs a photo ([missingImageProductsProvider]), so they
/// can fix them from one screen; everyone else gets the products added
/// within [newProductsWindow] that have one ([recentProductsProvider]).
final allNewProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(showProductsWithoutImageProvider)
      ? ref.watch(missingImageProductsProvider.future)
      : ref.watch(recentProductsProvider.future);
});

/// The home screen's «منتجات جديدة» row: the first [newProductsLimit] of
/// [allNewProductsProvider].
final newProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(allNewProductsProvider.future);
  return products.take(newProductsLimit).toList();
});

/// What the database says still needs a photo, across all categories and
/// whether in stock or not.
final productsWithoutImageProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productsRepositoryProvider).fetchProductsWithoutImage();
});

/// For admins: [productsWithoutImageProvider] plus the products whose link
/// failed to load this session (see [productsNeedingImage]). A product whose
/// photo was just replaced leaves at once: while the database list reloads,
/// the previous one is used without it.
final missingImageProductsProvider = FutureProvider<List<Product>>((ref) async {
  final failedToLoad = ref.watch(brokenImageProductsProvider);
  final replaced = ref.watch(replacedProductImagesProvider);
  final List<Product> stored =
      ref.watch(productsWithoutImageProvider).valueOrNull ??
          await ref.watch(productsWithoutImageProvider.future);
  return productsNeedingImage(
    stored: stored,
    failedToLoad: failedToLoad.values,
    replaced: replaced,
  );
});

/// Products added within [newProductsWindow], newest first.
final recentProductsProvider = FutureProvider<List<Product>>((ref) async {
  final includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
  final since = DateTime.now().subtract(newProductsWindow);
  final products = await ref
      .watch(productsRepositoryProvider)
      .fetchNewProducts(since: since);
  return [
    for (final product
        in products.availableFor(includeWithoutImage: includeWithoutImage))
      if (product.createdAt?.isAfter(since) ?? false) product,
  ]..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
});

/// Deals [offers] out one category at a time (A, B, C, A, B, C, ...) so no
/// single category fills the row. Each category leads with its deepest
/// discount, and categories take their turns in order of their best one.
List<Product> mixOffersByCategory(
  Iterable<Product> offers, {
  required int limit,
}) {
  int deepestFirst(Product a, Product b) =>
      b.discountPercentage.compareTo(a.discountPercentage);

  final byCategory = <String, List<Product>>{};
  for (final product in offers) {
    final group = product.category ?? product.categoryId ?? '';
    byCategory.putIfAbsent(group, () => []).add(product);
  }
  final queues = [
    for (final group in byCategory.values) group..sort(deepestFirst),
  ]..sort((a, b) => deepestFirst(a.first, b.first));

  final mixed = <Product>[];
  for (var round = 0; mixed.length < limit; round++) {
    final dealt = [
      for (final queue in queues)
        if (round < queue.length) queue[round],
    ];
    if (dealt.isEmpty) break;
    mixed.addAll(dealt.take(limit - mixed.length));
  }
  return mixed;
}
