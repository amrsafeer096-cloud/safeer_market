import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../../domain/entities/category_page.dart';
import '../../domain/main_categories.dart';
import 'catalog_providers.dart';

/// A main category, narrowed to one of its sub-categories unless null
/// («الكل»).
typedef CategoryQuery = ({String mainCategoryId, String? subCategory});

const categoryPageSize = 40;

class CategoryProductsState {
  const CategoryProductsState({
    required this.products,
    required this.total,
    required this.fetched,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// Loaded products that can be sold.
  final List<Product> products;

  /// Matches on the server, including pages not loaded yet.
  final int total;

  /// Rows fetched so far, including unavailable ones that were dropped.
  final int fetched;

  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => fetched < total;

  CategoryProductsState copyWith({
    bool? isLoadingMore,
    Object? loadMoreError,
  }) =>
      CategoryProductsState(
        products: products,
        total: total,
        fetched: fetched,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Pages through a [CategoryQuery]'s products, sorted by name.
class CategoryProductsNotifier extends AutoDisposeFamilyAsyncNotifier<
    CategoryProductsState, CategoryQuery> {
  var _disposed = false;
  var _includeWithoutImage = false;

  /// [CategoryProductsState.fetched] still counts every row, so paging
  /// offsets stay right when some are hidden.
  List<Product> _shown(CategoryPage page) =>
      page.products.availableFor(includeWithoutImage: _includeWithoutImage);

  /// How long a category's loaded pages outlive its screen, so coming back
  /// to it (or switching tabs) shows them at once instead of a spinner.
  static const cacheFor = Duration(minutes: 10);

  @override
  Future<CategoryProductsState> build(CategoryQuery arg) async {
    ref.onDispose(() => _disposed = true);
    final link = ref.keepAlive();
    final expiry = Timer(cacheFor, link.close);
    ref.onDispose(expiry.cancel);
    _includeWithoutImage = ref.watch(showProductsWithoutImageProvider);
    final page = await _fetch(offset: 0);
    return CategoryProductsState(
      products: _shown(page),
      total: page.total,
      fetched: page.products.length,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final loading = current.copyWith(isLoadingMore: true);
    state = AsyncData(loading);
    try {
      final page = await _fetch(offset: current.fetched);
      if (_disposed || !identical(state.valueOrNull, loading)) return;
      final fetched = current.fetched + page.products.length;
      state = AsyncData(
        CategoryProductsState(
          products: [...current.products, ..._shown(page)],
          // An empty page means rows were removed since the count was taken.
          total: page.products.isEmpty ? fetched : page.total,
          fetched: fetched,
        ),
      );
    } catch (error) {
      if (_disposed || !identical(state.valueOrNull, loading)) return;
      state = AsyncData(current.copyWith(loadMoreError: error));
    }
  }

  Future<CategoryPage> _fetch({required int offset}) {
    final main = MainCategories.byId(arg.mainCategoryId);
    return ref.read(catalogRepositoryProvider).fetchCategoryProducts(
          categories: switch (arg.subCategory) {
            final sub? => [sub],
            // «الكل»: every subcategory plus the main title (POS sometimes
            // stores `products.category` as «عطارة» instead of «عطارة وزن»).
            null => [
                ...?main?.subCategories,
                if (main != null) main.name,
              ],
          },
          offset: offset,
          limit: categoryPageSize,
        );
  }
}

final categoryProductsProvider = AsyncNotifierProvider.autoDispose
    .family<CategoryProductsNotifier, CategoryProductsState, CategoryQuery>(
  CategoryProductsNotifier.new,
);
