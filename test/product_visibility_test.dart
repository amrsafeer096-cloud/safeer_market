import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safeer_market/core/network/supabase_providers.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/catalog/data/repositories/supabase_catalog_repository.dart';
import 'package:safeer_market/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:safeer_market/features/catalog/presentation/providers/category_providers.dart';
import 'package:safeer_market/features/favorites/data/repositories/supabase_favorites_repository.dart';
import 'package:safeer_market/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:safeer_market/features/home/data/repositories/supabase_products_repository.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/domain/repositories/products_repository.dart';
import 'package:safeer_market/features/home/presentation/providers/product_visibility_provider.dart';
import 'package:safeer_market/features/home/presentation/providers/products_providers.dart';
import 'package:safeer_market/features/home/presentation/screens/product_list_screen.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_card.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/search/presentation/screens/search_screen.dart';

import 'test_helpers.dart';

const _chocolate = 'شيكولاتة';
const _brokenUrl =
    'https://example.supabase.co/storage/v1/object/public/product_images/1.jpg';

/// Valid link that Storage can't serve (the file was never uploaded).
const _broken = Product(
  id: 'broken',
  name: 'لبن مكسور الصورة',
  price: 20,
  category: _chocolate,
  imageUrl: _brokenUrl,
);
const _photographed = Product(
  id: 'photo',
  name: 'لبن بصورة',
  price: 30,
  category: _chocolate,
  imageUrl: 'https://cdn.example.com/milk.png',
);
const _noImage =
    Product(id: 'none', name: 'لبن بدون صورة', price: 20, category: _chocolate);
const _junkImage = Product(
  id: 'junk',
  name: 'لبن رابط فارغ',
  price: 20,
  category: _chocolate,
  imageUrl: ' NULL ',
);

class _SeededBrokenImages extends BrokenImageProducts {
  @override
  Map<String, Product> build() => {_broken.id: _broken};
}

final _seedBroken =
    brokenImageProductsProvider.overrideWith(_SeededBrokenImages.new);

class _FakeProductsRepository implements ProductsRepository {
  const _FakeProductsRepository(this.products);

  final List<Product> products;

  @override
  Future<List<Product>> fetchProducts() async => products;
  @override
  Future<List<Product>> fetchRandomProducts({required int limit}) async =>
      products;
  @override
  Future<List<Product>> fetchOfferProducts({int? maxRows}) async => products;
  @override
  Future<List<Product>> fetchNewProducts({required DateTime since}) async =>
      products;
  @override
  Future<List<Product>> fetchProductsWithoutImage() async => products;
}

/// Answers the first missing-image fetch with [products]; later ones never
/// finish, like a reload still on its way.
class _ReloadingProductsRepository extends _FakeProductsRepository {
  _ReloadingProductsRepository(super.products);

  var calls = 0;

  @override
  Future<List<Product>> fetchProductsWithoutImage() {
    calls++;
    return calls == 1
        ? Future.value(products)
        : Completer<List<Product>>().future;
  }
}

ProviderContainer _containerFor(UserRole? role) {
  final container = ProviderContainer(
    overrides: [
      userRoleProvider.overrideWith((ref) async => role),
      supabaseClientProvider.overrideWithValue(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Product.hasValidImageUrl', () {
    test('accepts http(s) links', () {
      for (final url in [
        'https://x.supabase.co/storage/v1/object/public/product_images/1.jpg',
        '  http://cdn.example.com/a.png?t=1  ',
      ]) {
        expect(Product.isValidImageUrl(url), isTrue, reason: url);
      }
    });

    test('rejects missing, blank, placeholder text and non-links', () {
      for (final url in [
        null,
        '',
        '   ',
        'null',
        ' NULL ',
        'undefined',
        'None',
        'n/a',
        'N/A',
        'product_images/1.jpg',
        'ftp://example.com/a.png',
        'https://',
      ]) {
        expect(Product.isValidImageUrl(url), isFalse, reason: '$url');
      }
      expect(_junkImage.hasValidImageUrl, isFalse);
      expect(_noImage.hasValidImageUrl, isFalse);
    });
  });

  group('role', () {
    Future<bool> showsAll(UserRole? role) async {
      final container = _containerFor(role);
      await container.read(userRoleProvider.future);
      return container.read(showProductsWithoutImageProvider);
    }

    test('only admins see products without an image', () async {
      expect(await showsAll(UserRole.admin), isTrue);
      expect(await showsAll(UserRole.customer), isFalse);
      expect(await showsAll(UserRole.driver), isFalse);
      expect(await showsAll(UserRole.warehouse), isFalse);
      expect(await showsAll(null), isFalse, reason: 'guest');
    });

    test('home, catalog and favorites queries follow the role', () async {
      for (final (role, includeAll) in [
        (UserRole.admin, true),
        (UserRole.customer, false),
        (null, false),
      ]) {
        final container = _containerFor(role);
        await container.read(userRoleProvider.future);

        final products = container.read(productsRepositoryProvider)
            as SupabaseProductsRepository;
        final catalog = container.read(catalogRepositoryProvider)
            as SupabaseCatalogRepository;
        final favorites = container.read(favoritesRepositoryProvider)
            as SupabaseFavoritesRepository;
        expect(products.includeProductsWithoutImage, includeAll,
            reason: '$role');
        expect(catalog.includeProductsWithoutImage, includeAll,
            reason: '$role');
        expect(favorites.includeProductsWithoutImage, includeAll,
            reason: '$role');
      }
    });
  });

  group('providers also filter in memory', () {
    const mixed = [_photographed, _noImage, _junkImage];

    ProviderContainer containerFor({required bool admin}) {
      final catalog = FakeCatalogRepository(catalogProducts: mixed);
      final favorites = FakeFavoritesRepository(
        catalog: mixed,
        ids: {for (final p in mixed) p.id},
      );
      final container = ProviderContainer(
        overrides: [
          showProductsWithoutImageProvider.overrideWithValue(admin),
          productsRepositoryProvider
              .overrideWithValue(const _FakeProductsRepository(mixed)),
          catalogRepositoryProvider.overrideWithValue(catalog),
          favoritesRepositoryProvider.overrideWithValue(favorites),
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(user: testUser)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<Map<String, List<String>>> lists(ProviderContainer c) async {
      List<String> ids(List<Product> products) =>
          [for (final p in products) p.id]..sort();
      final category = await c.read(
        categoryProductsProvider(
          (mainCategoryId: 'sweets-snacks', subCategory: _chocolate),
        ).future,
      );
      return {
        'all': ids(await c.read(productsProvider.future)),
        'featured': ids(await c.read(featuredProductsProvider.future)),
        'category': ids(category.products),
        'search': ids(await c.read(productSearchProvider('لبن').future)),
        'favorites': ids(await c.read(favoriteProductsProvider.future)),
      };
    }

    test('customers get only products with a valid image link', () async {
      final shown = await lists(containerFor(admin: false));
      for (final MapEntry(:key, :value) in shown.entries) {
        expect(value, ['photo'], reason: key);
      }
    });

    test('admins get every product', () async {
      final shown = await lists(containerFor(admin: true));
      for (final MapEntry(:key, :value) in shown.entries) {
        expect(value, ['junk', 'none', 'photo'], reason: key);
      }
    });
  });

  group('cards', () {
    Finder badges() => find.text('بدون صورة');

    testWidgets('admins see «بدون صورة» on missing and broken photos', (
      tester,
    ) async {
      await pumpApp(
        tester,
        products: const [_noImage, _broken],
        overrides: [_seedBroken],
      );
      await skipSplash(tester);

      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(badges(), findsNWidgets(2));
    });

    testWidgets('customers never see a card whose photo failed to load', (
      tester,
    ) async {
      await pumpApp(
        tester,
        products: const [_broken],
        showProductsWithoutImage: false,
        overrides: [_seedBroken],
      );
      await skipSplash(tester);

      expect(find.text(_broken.name), findsNothing);
      expect(find.byType(ProductCard), findsNothing);
      expect(badges(), findsNothing);
    });

    test('a failed link is remembered per product until the link changes',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(brokenImageProductsProvider.notifier)
        ..report(_broken)
        ..report(_broken);
      await Future<void>.delayed(BrokenImageProducts.flushDelay);
      final first = notifier.state;
      expect(first.keys, [_broken.id]);

      notifier.report(_broken);
      await Future<void>.delayed(BrokenImageProducts.flushDelay);
      expect(identical(notifier.state, first), isTrue);

      const relinked = Product(
        id: 'broken',
        name: 'لبن مكسور الصورة',
        price: 20,
        imageUrl: 'https://cdn.example.com/new.png',
      );
      notifier.report(relinked);
      await Future<void>.delayed(BrokenImageProducts.flushDelay);
      expect(notifier.state[_broken.id]?.imageUrl, relinked.imageUrl);
    });

    test('failures during a scroll are published together, once', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var publishes = 0;
      container.listen(brokenImageProductsProvider, (_, __) => publishes++);
      final notifier = container.read(brokenImageProductsProvider.notifier);

      for (var i = 0; i < 10; i++) {
        notifier.report(Product(
          id: 'p$i',
          name: 'p$i',
          price: 1,
          imageUrl: 'https://cdn.example.com/$i.png',
        ));
      }
      expect(notifier.state, isEmpty, reason: 'nothing rebuilds mid-scroll');

      await Future<void>.delayed(BrokenImageProducts.flushDelay);
      expect(notifier.state, hasLength(10));
      expect(publishes, 1);
    });
  });

  test('customer queries ask the server for an http(s) image link only',
      () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'}, request: request);
      }),
    );

    await SupabaseProductsRepository(client).fetchProducts();
    await SupabaseProductsRepository(client, includeProductsWithoutImage: true)
        .fetchProducts();

    expect(requests.first.url.queryParametersAll['image_url'], [
      'not.is.null',
      'neq.',
      'neq.null',
      'ilike.http%',
      r'imatch.^\s*https?://[^\s/]',
    ]);
    expect(requests.last.url.queryParametersAll['image_url'], isNull,
        reason: 'admins get every product');
  });

  testWidgets('a customer card leaves the list once its photo fails to load', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: const [_broken, _photographed],
      showProductsWithoutImage: false,
    );
    await skipSplash(tester);
    final card = find.widgetWithText(ProductCard, _broken.name);
    expect(card, findsWidgets);

    ProviderScope.containerOf(tester.element(card.first))
        .read(brokenImageProductsProvider.notifier)
        .report(_broken);
    await tester.pump(BrokenImageProducts.flushDelay);
    await tester.pump();

    expect(find.text(_broken.name), findsNothing);
    expect(find.text(_photographed.name), findsWidgets);
  });

  test('a replaced photo leaves the admin list before the reload finishes',
      () async {
    const newLink = 'https://example.supabase.co/storage/v1/object/public/'
        'product_images/none.jpg?t=1';
    final repository =
        _ReloadingProductsRepository(const [_noImage, _junkImage]);
    final container = ProviderContainer(
      overrides: [
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(missingImageProductsProvider, (_, __) {});
    expect(
      [
        for (final p
            in await container.read(missingImageProductsProvider.future))
          p.id
      ],
      ['none', 'junk'],
    );

    container
      ..read(replacedProductImagesProvider.notifier).record('none', newLink)
      ..invalidate(productsWithoutImageProvider);

    expect(
      [
        for (final p
            in await container.read(missingImageProductsProvider.future))
          p.id
      ],
      ['junk'],
    );
    expect(repository.calls, 2, reason: 'the database list still reloads');
  });

  testWidgets('admins see the missing-image count and the full list', (
    tester,
  ) async {
    await pumpApp(
      tester,
      newProducts: const [_noImage, _junkImage],
      overrides: [_seedBroken],
    );
    await skipSplash(tester);

    expect(find.text('منتجات جديدة'), findsOneWidget);
    expect(find.text('بدون صورة: 2'), findsOneWidget);
    const title = 'منتجات جديدة (بدون صورة: 2)';

    final seeAll = find.text('عرض الكل').last;
    await tester.ensureVisible(seeAll);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();

    expect(find.byType(ProductListScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(title),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ProductListScreen),
        matching: find.text('بدون صورة'),
      ),
      findsNWidgets(2),
    );
  });

  group('category and search screens', () {
    const catalog = [_noImage, _junkImage, _broken];

    Future<void> openCategory(WidgetTester tester,
        {required bool admin}) async {
      await pumpApp(
        tester,
        catalogRepository: FakeCatalogRepository(catalogProducts: catalog),
        showProductsWithoutImage: admin,
        overrides: [_seedBroken],
      );
      await skipSplash(tester);
      await tester.tap(find.text('حلويات وتسالي'));
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, {required bool admin}) async {
      await pumpApp(
        tester,
        catalogRepository: FakeCatalogRepository(catalogProducts: catalog),
        showProductsWithoutImage: admin,
        overrides: [_seedBroken],
      );
      await skipSplash(tester);
      await tester.tap(find.text('البحث'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'لبن');
      await tester.pump(SearchScreen.debounce);
      await tester.pumpAndSettle();
    }

    testWidgets('customers see none of them in a category', (tester) async {
      await openCategory(tester, admin: false);
      for (final product in catalog) {
        expect(find.text(product.name), findsNothing, reason: product.id);
      }
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('admins see all of them in a category, badged', (
      tester,
    ) async {
      await openCategory(tester, admin: true);
      expect(find.byType(ProductCard), findsNWidgets(3));
      expect(find.text('بدون صورة'), findsNWidgets(3));
    });

    testWidgets('customers find none of them in search', (tester) async {
      await search(tester, admin: false);
      for (final product in catalog) {
        expect(find.text(product.name), findsNothing, reason: product.id);
      }
      expect(find.text('بدون صورة'), findsNothing);
    });

    testWidgets('admins find all of them in search, badged', (tester) async {
      await search(tester, admin: true);
      expect(find.text('بدون صورة'), findsNWidgets(3));
    });
  });
}
