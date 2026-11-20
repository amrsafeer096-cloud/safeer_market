import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/product.dart';

/// Whether product lists include products without a photo. Only admins see
/// them (marked «بدون صورة») so they can tell which ones still need an image;
/// customers, other staff and guests — and anyone while the role is still
/// loading — only see products that have one.
final showProductsWithoutImageProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).valueOrNull == UserRole.admin;
});

/// Photos an admin replaced this session: product id to the new, saved
/// `image_url`. A copy of the product still carrying another link is stale —
/// lists loaded before the upload hold one until they reload.
final replacedProductImagesProvider =
    NotifierProvider<ReplacedProductImages, Map<String, String>>(
  ReplacedProductImages.new,
);

class ReplacedProductImages extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void record(String productId, String imageUrl) {
    state = {...state, productId: imageUrl.trim()};
  }

  /// Whether [product] carries a link from before its photo was replaced.
  bool isStale(Product product) => _isStale(state, product);

  static bool _isStale(Map<String, String> replaced, Product product) {
    final current = replaced[product.id];
    return current != null && product.imageUrl?.trim() != current;
  }
}

/// Products whose image link failed to load this session, by id — e.g. an
/// `image_url` naming a Storage file that was never uploaded or has been
/// deleted. Lists leave them out for customers; admins get them in their
/// «منتجات جديدة» list of products that need a photo.
///
/// Reports are batched: failures that arrive while a grid scrolls are
/// collected for [BrokenImageProducts.flushDelay] and published once, so a
/// grid re-lays out once per batch rather than once per broken card.
final brokenImageProductsProvider =
    NotifierProvider<BrokenImageProducts, Map<String, Product>>(
  BrokenImageProducts.new,
);

class BrokenImageProducts extends Notifier<Map<String, Product>> {
  static const flushDelay = Duration(milliseconds: 1500);

  final _pending = <String, Product>{};
  Timer? _flush;

  @override
  Map<String, Product> build() {
    ref.onDispose(() => _flush?.cancel());
    return const {};
  }

  void report(Product product) {
    // A card still showing the old link of a replaced photo.
    if (ref.read(replacedProductImagesProvider.notifier).isStale(product)) {
      return;
    }
    if (_sameLink(state[product.id], product) ||
        _sameLink(_pending[product.id], product)) {
      return;
    }
    _pending[product.id] = product;
    _flush ??= Timer(flushDelay, _publish);
  }

  void _publish() {
    _flush = null;
    if (_pending.isEmpty) return;
    state = {...state, ..._pending};
    _pending.clear();
  }

  /// After the product gets a new photo.
  void forget(String productId) {
    _pending.remove(productId);
    if (!state.containsKey(productId)) return;
    state = {...state}..remove(productId);
  }

  /// A product whose link has since changed counts as a new attempt.
  static bool _sameLink(Product? broken, Product product) =>
      broken != null && broken.imageUrl?.trim() == product.imageUrl?.trim();
}

/// True when [product] has no photo to show: no valid link, or its link
/// failed to load. Watches only this product's entry.
bool productLacksImage(WidgetRef ref, Product product) {
  if (!product.hasValidImageUrl) return true;
  final broken =
      ref.watch(brokenImageProductsProvider.select((all) => all[product.id]));
  return BrokenImageProducts._sameLink(broken, product);
}

/// Whether [product] gets the admin «بدون صورة» border and badge.
bool flagsMissingImage(WidgetRef ref, Product product) =>
    ref.watch(showProductsWithoutImageProvider) &&
    productLacksImage(ref, product);

/// What a product list may show: everything for admins; for everyone else,
/// [products] minus those whose photo is missing or failed to load. Failures
/// arrive in [BrokenImageProducts.flushDelay] batches, so a broken card
/// leaves the list soon after it fails without a rebuild per card.
List<Product> shownProducts(WidgetRef ref, List<Product> products) {
  if (ref.watch(showProductsWithoutImageProvider)) return products;
  final broken = ref.watch(brokenImageProductsProvider);
  return [
    for (final product in products)
      if (product.hasValidImageUrl &&
          !BrokenImageProducts._sameLink(broken[product.id], product))
        product,
  ];
}

/// For admins' «منتجات جديدة»: [stored] (what the database says needs a
/// photo) plus [failedToLoad], minus stale copies of products whose photo
/// was just replaced, in stock first, then by name. Each carries no image
/// link, so its card shows «بدون صورة» right away instead of retrying a
/// dead link.
List<Product> productsNeedingImage({
  required Iterable<Product> stored,
  required Iterable<Product> failedToLoad,
  required Map<String, String> replaced,
}) {
  final byId = <String, Product>{
    for (final product in [...stored, ...failedToLoad])
      if (!ReplacedProductImages._isStale(replaced, product))
        product.id: product.withoutImage(),
  };
  return byId.values.toList()
    ..sort((a, b) {
      if (a.inStock != b.inStock) return a.inStock ? -1 : 1;
      return a.name.compareTo(b.name);
    });
}
