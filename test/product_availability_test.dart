import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/cart/presentation/providers/cart_providers.dart';
import 'package:safeer_market/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:safeer_market/features/catalog/presentation/providers/category_providers.dart';
import 'package:safeer_market/features/home/data/models/product_model.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/domain/repositories/products_repository.dart';
import 'package:safeer_market/features/home/presentation/providers/product_visibility_provider.dart';
import 'package:safeer_market/features/home/presentation/providers/products_providers.dart';
import 'package:safeer_market/features/search/presentation/providers/barcode_scanner_provider.dart';
import 'package:safeer_market/features/search/presentation/screens/search_screen.dart';

import 'test_helpers.dart';

const _groceries = 'c0ffee00-0000-4000-8000-000000000001';
const _groceryGroup = 'ارز';
const _plenty = Product(
  id: '1',
  name: 'أرز مصري',
  price: 30,
  categoryId: _groceries,
  category: _groceryGroup,
);
const _stocked = Product(
  id: '2',
  name: 'أرز بسمتي',
  price: 80,
  stockQuantity: 4,
  categoryId: _groceries,
  category: _groceryGroup,
);
const _soldOut = Product(
  id: '3',
  name: 'أرز ياسمين',
  price: 95,
  stockQuantity: 0,
  barcode: '6229999',
  categoryId: _groceries,
  category: _groceryGroup,
);
const _negative = Product(
  id: '4',
  name: 'أرز بني',
  price: 70,
  stockQuantity: -2,
  categoryId: _groceries,
  category: _groceryGroup,
);
const _inactive = Product(
  id: '5',
  name: 'أرز أبيض',
  price: 25,
  stockQuantity: 10,
  isActive: false,
  categoryId: _groceries,
  category: _groceryGroup,
);

const _all = [_plenty, _stocked, _soldOut, _negative, _inactive];

class _FakeProductsRepository implements ProductsRepository {
  _FakeProductsRepository([this.products = _all]);

  final List<Product> products;

  @override
  Future<List<Product>> fetchProducts() async => products;

  @override
  Future<List<Product>> fetchRandomProducts({required int limit}) async =>
      products.take(limit).toList();

  @override
  Future<List<Product>> fetchOfferProducts({int? maxRows}) async =>
      products.where((p) => p.discountPrice != null).toList();

  /// Unfiltered, so the provider's own date check is what's under test.
  @override
  Future<List<Product>> fetchNewProducts({required DateTime since}) async =>
      products;

  @override
  Future<List<Product>> fetchProductsWithoutImage() async => products;
}

Future<void> _scan(WidgetTester tester, String barcode) async {
  await pumpApp(
    tester,
    catalogRepository: FakeCatalogRepository(products: _all),
    overrides: [
      barcodeScannerProvider.overrideWithValue((_) async => barcode),
    ],
  );
  await skipSplash(tester);
  await tester.tap(find.text('البحث'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('مسح الباركود'));
  await tester.pumpAndSettle();
}

void main() {
  test('in stock means is_active and stock_quantity above zero', () {
    expect(_plenty.inStock, isTrue);
    expect(_stocked.inStock, isTrue);
    expect(_soldOut.inStock, isFalse);
    expect(_negative.inStock, isFalse);
    expect(_inactive.inStock, isFalse);
    expect(_all.available, [_plenty, _stocked]);
  });

  test('home and category lists hide out-of-stock products', () async {
    final container = ProviderContainer(
      overrides: [
        // Photo-less fixtures: only the stock rules are under test here.
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(_FakeProductsRepository()),
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(products: _all),
        ),
      ],
    );
    addTearDown(container.dispose);

    final expected = [_plenty, _stocked];
    expect(await container.read(productsProvider.future), expected);
    expect(await container.read(featuredProductsProvider.future), expected);
    final category = await container.read(
      categoryProductsProvider(
        (mainCategoryId: 'pasta-rice', subCategory: _groceryGroup),
      ).future,
    );
    expect(category.products, unorderedEquals(expected));
  });

  test('the offers row keeps only in-stock products below their price',
      () async {
    const onOffer =
        Product(id: 'o1', name: 'أرز', price: 40, discountPrice: 30);
    const notCheaper =
        Product(id: 'o2', name: 'سكر', price: 30, discountPrice: 30);
    const soldOut = Product(
      id: 'o3',
      name: 'شاي',
      price: 50,
      discountPrice: 45,
      stockQuantity: 0,
    );
    const fullPrice = Product(id: 'o4', name: 'ملح', price: 5);
    final container = ProviderContainer(
      overrides: [
        // Photo-less fixtures: only the stock rules are under test here.
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository(
            const [onOffer, notCheaper, soldOut, fullPrice],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(offerProductsProvider.future), [onOffer]);
  });

  test('the offers row deals categories in turn, deepest discount first', () {
    Product offer(String id, String category, double discountPrice) => Product(
          id: id,
          name: id,
          price: 100,
          discountPrice: discountPrice,
          category: category,
        );
    final dairy = [offer('a1', 'ألبان', 90), offer('a2', 'ألبان', 50)];
    final drinks = [offer('b1', 'مشروبات', 70), offer('b2', 'مشروبات', 80)];
    final snacks = [offer('c1', 'تسالي', 85)];

    final mixed =
        mixOffersByCategory([...dairy, ...drinks, ...snacks], limit: 15);
    // ألبان leads with a2 (50%), then مشروبات (b1, 30%), then تسالي.
    expect(mixed.map((p) => p.id), ['a2', 'b1', 'c1', 'a1', 'b2']);

    expect(
      mixOffersByCategory([...dairy, ...drinks, ...snacks], limit: 2)
          .map((p) => p.id),
      ['a2', 'b1'],
    );
  });

  test('for admins «منتجات جديدة» gathers every product needing a photo',
      () async {
    final inStock = [
      for (var i = 0; i < 25; i++)
        Product(id: 'in$i', name: 'a${i.toString().padLeft(2, '0')}', price: 1),
    ];
    final soldOut = [
      for (var i = 0; i < 5; i++)
        Product(id: 'out$i', name: 'a$i', price: 1, stockQuantity: 0),
    ];
    // The database found its Storage file missing.
    const deadLink = Product(
      id: 'dead',
      name: 'b',
      price: 1,
      imageUrl: 'https://x.supabase.co/storage/v1/object/public/p/1.jpg',
    );
    // Its link looked fine but failed to load on this device.
    const failedOnDevice = Product(
      id: 'failed',
      name: 'c',
      price: 1,
      imageUrl: 'https://x.supabase.co/storage/v1/object/public/p/2.jpg',
    );
    final container = ProviderContainer(
      overrides: [
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository([...soldOut, ...inStock, deadLink]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(brokenImageProductsProvider.notifier).report(failedOnDevice);
    // Failures are published in batches.
    await Future<void>.delayed(BrokenImageProducts.flushDelay);

    final all = await container.read(allNewProductsProvider.future);
    expect(all, hasLength(32), reason: 'no 20-item cap for admins');
    expect(
        all.take(27).map((p) => p.id),
        [
          for (var i = 0; i < 25; i++) 'in$i',
          'dead',
          'failed',
        ],
        reason: 'in stock first, then by name');
    expect(
        all.skip(27).map((p) => p.id), [for (var i = 0; i < 5; i++) 'out$i']);
    expect(all.every((p) => p.imageUrl == null), isTrue,
        reason: 'cards show «بدون صورة» without retrying dead links');

    final row = await container.read(newProductsProvider.future);
    expect(row.map((p) => p.id), all.take(newProductsLimit).map((p) => p.id));
  });

  test('for customers the new-products row keeps the usual 20-item cap',
      () async {
    final now = DateTime.now();
    final recent = [
      for (var i = 0; i < 25; i++)
        Product(
          id: 'r$i',
          name: 'r$i',
          price: 1,
          imageUrl: 'https://cdn.example.com/r$i.png',
          createdAt: now.subtract(Duration(minutes: i)),
        ),
    ];
    final container = ProviderContainer(
      overrides: [
        showProductsWithoutImageProvider.overrideWithValue(false),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository(recent),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(newProductsProvider.future),
        hasLength(newProductsLimit));
    expect(await container.read(allNewProductsProvider.future), hasLength(25));
  });

  test('for customers the new-products row is the recently added products',
      () async {
    final now = DateTime.now();
    final fresh = Product(
      id: 'fresh',
      name: 'fresh',
      price: 10,
      imageUrl: 'https://cdn.example.com/fresh.png',
      createdAt: now.subtract(const Duration(hours: 2)),
    );
    final old = Product(
      id: 'old',
      name: 'old',
      price: 10,
      imageUrl: 'https://cdn.example.com/old.png',
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final container = ProviderContainer(
      overrides: [
        showProductsWithoutImageProvider.overrideWithValue(false),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository([fresh, old]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final products = await container.read(newProductsProvider.future);
    expect(products.map((p) => p.id), ['fresh']);
  });

  test('recent products are only those added in the last 3 days', () async {
    final now = DateTime.now();
    Product added(String id, Duration ago) =>
        Product(id: id, name: id, price: 10, createdAt: now.subtract(ago));
    final container = ProviderContainer(
      overrides: [
        // Photo-less fixtures: only the stock rules are under test here.
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository([
            added('2 days', const Duration(days: 2)),
            added('4 days', const Duration(days: 4)),
            added('1 hour', const Duration(hours: 1)),
            added('just over 3 days', const Duration(days: 3, minutes: 1)),
            const Product(id: 'undated', name: 'undated', price: 10),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final fresh = await container.read(recentProductsProvider.future);
    expect(fresh.map((p) => p.id), ['1 hour', '2 days']);
  });

  test('created_at is parsed into a DateTime', () {
    final product = ProductModel.fromJson({
      'id': 1,
      'name': 'خبز',
      'price': 5,
      'created_at': '2026-10-24T18:30:00+00:00',
    });
    expect(product.createdAt, DateTime.utc(2026, 10, 24, 18, 30));
    expect(ProductModel.fromJson({'id': 2, 'name': 'x', 'price': 1}).createdAt,
        isNull);
  });

  test('rows with stock_quantity 0 or null are hidden from home', () async {
    final products = [
      {'id': 10, 'name': 'مكرونة', 'price': 12, 'stock_quantity': 0},
      {'id': 11, 'name': 'دقيق', 'price': 25, 'stock_quantity': null},
      {'id': 12, 'name': 'خل', 'price': 8, 'stock_quantity': 6},
    ].map(ProductModel.fromJson).toList();
    final container = ProviderContainer(
      overrides: [
        // Photo-less fixtures: only the stock rules are under test here.
        showProductsWithoutImageProvider.overrideWithValue(true),
        productsRepositoryProvider.overrideWithValue(
          _FakeProductsRepository(products),
        ),
      ],
    );
    addTearDown(container.dispose);

    final home = await container.read(featuredProductsProvider.future);
    expect(home.map((p) => p.name), ['خل']);
  });

  testWidgets('search results leave out sold-out products', (tester) async {
    await pumpApp(
      tester,
      catalogRepository: FakeCatalogRepository(products: _all),
    );
    await skipSplash(tester);
    await tester.tap(find.text('البحث'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'أرز');
    await tester.pump(SearchScreen.debounce);
    await tester.pumpAndSettle();

    expect(find.text('2 نتيجة لـ «أرز»'), findsOneWidget);
    expect(find.text('أرز ياسمين'), findsNothing);
    expect(find.text('أرز بني'), findsNothing);
    expect(find.text('أرز أبيض'), findsNothing);
  });

  testWidgets('scanning a product with stock_quantity 0 says غير متوفر', (
    tester,
  ) async {
    await _scan(tester, _soldOut.barcode!);

    expect(find.text('هذا المنتج غير متوفر حالياً'), findsOneWidget);
    expect(find.text(_soldOut.name), findsOneWidget);
    expect(find.byTooltip('أضف للسلة'), findsNothing);
  });

  testWidgets('scanning an unknown barcode still says not found', (
    tester,
  ) async {
    await _scan(tester, '0000000');

    expect(find.text('هذا المنتج غير متوفر حالياً'), findsNothing);
    expect(find.text('لا يوجد منتج بالباركود «0000000»'), findsOneWidget);
  });

  testWidgets('+ on an out-of-stock card explains instead of adding', (
    tester,
  ) async {
    await pumpApp(tester, products: const [_soldOut]);
    await skipSplash(tester);

    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pump();

    expect(find.text('هذا المنتج غير متوفر حالياً'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(container.read(cartProvider), isEmpty);
  });
}
