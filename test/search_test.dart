import 'dart:async';

import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/catalog/domain/product_search.dart';
import 'package:safeer_market/features/catalog/presentation/screens/product_details_screen.dart';
import 'package:safeer_market/features/home/data/models/product_model.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/search/presentation/providers/barcode_scanner_provider.dart';
import 'package:safeer_market/features/search/presentation/screens/search_screen.dart';

import 'test_helpers.dart';

const _milk = Product(
  id: 'm1',
  name: 'لبن جهينة كامل الدسم',
  price: 45.95,
  barcode: '6221234567890',
);
const _lowFatMilk = Product(
  id: 'm2',
  name: 'لبن المراعي خالي الدسم',
  price: 42,
  barcode: '6224000111222',
);
const _cheese = Product(id: 'c1', name: 'جبنة دومتي فيتا', price: 35.5);
const _pepsi =
    Product(id: 'p1', name: 'Pepsi Cola 1L', price: 20, barcode: 'ABC-123');

/// Search that never answers, to show what the screen renders meanwhile.
class _PendingCatalogRepository extends FakeCatalogRepository {
  _PendingCatalogRepository({super.products});

  @override
  Future<List<Product>> searchProducts(String query) =>
      Completer<List<Product>>().future;
}

Future<FakeCatalogRepository> _openSearch(
  WidgetTester tester, {
  String? scanResult,
  FakeCatalogRepository? catalog,
  List<Product> homeProducts = const [],
}) async {
  final repository = catalog ??
      FakeCatalogRepository(products: [_milk, _lowFatMilk, _cheese, _pepsi]);
  await pumpApp(
    tester,
    products: homeProducts,
    catalogRepository: repository,
    overrides: [
      barcodeScannerProvider.overrideWithValue((_) async => scanResult),
    ],
  );
  await skipSplash(tester);
  await tester.tap(find.text('البحث'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(SearchScreen.debounce);
  await tester.pumpAndSettle();
}

void main() {
  group('ProductSearch', () {
    test('matches an exact barcode or a name containing the query', () {
      expect(ProductSearch.matches(_milk, '6221234567890'), isTrue);
      expect(ProductSearch.matches(_milk, 'جهينة'), isTrue);
      expect(ProductSearch.matches(_milk, '622123'), isFalse);
      expect(ProductSearch.matches(_cheese, '6221234567890'), isFalse);
      expect(ProductSearch.matches(_milk, '   '), isFalse);
    });

    test('ignores case and surrounding spaces', () {
      expect(ProductSearch.matches(_milk, '  6221234567890 \n'), isTrue);
      expect(ProductSearch.matches(_pepsi, 'abc-123'), isTrue);
      expect(ProductSearch.matches(_pepsi, ' pepsi cola '), isTrue);
      expect(
        ProductSearch.matches(
          const Product(id: 'x', name: 'x', price: 1, barcode: ' 999 '),
          '999',
        ),
        isTrue,
      );
    });

    test('puts barcode hits first and drops duplicates', () {
      const namedLikeBarcode =
          Product(id: 'n1', name: 'عرض 6221234567890', price: 5);
      expect(
        ProductSearch.filter(
          [namedLikeBarcode, _milk, _milk, _cheese],
          '6221234567890',
        ),
        [_milk, namedLikeBarcode],
      );
    });

    test('POS barcodes are trimmed when read', () {
      final product = ProductModel.fromJson({
        'id': 1,
        'name': 'سكر',
        'price': 30,
        'barcode': '6221111   ',
      });
      expect(product.barcode, '6221111');
    });
  });

  testWidgets('typing queries products after a short debounce', (
    tester,
  ) async {
    final catalog = await _openSearch(tester);
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('عمليات بحث شائعة'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ل');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'لبن');
    await tester.pump(const Duration(milliseconds: 100));
    expect(catalog.searches, isEmpty);

    await tester.pump(SearchScreen.debounce);
    await tester.pumpAndSettle();

    expect(catalog.searches, ['لبن']);
    expect(find.text('2 نتيجة لـ «لبن»'), findsOneWidget);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.text('لبن المراعي خالي الدسم'), findsOneWidget);
    expect(find.text('جبنة دومتي فيتا'), findsNothing);
  });

  testWidgets('typing a full barcode finds the product', (tester) async {
    await _openSearch(tester);

    await _type(tester, '  6221234567890  ');

    expect(find.text('1 نتيجة لـ «6221234567890»'), findsOneWidget);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.textContaining('45.95'), findsOneWidget);
  });

  testWidgets('a partial barcode is not a match', (tester) async {
    await _openSearch(tester);

    await _type(tester, '622123');

    expect(find.text('لا توجد نتائج لـ «622123»'), findsOneWidget);
  });

  testWidgets('scanning fills the field and shows the product card', (
    tester,
  ) async {
    await _openSearch(tester, scanResult: ' 6221234567890 ');

    await tester.tap(find.byTooltip('مسح الباركود'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '6221234567890',
    );
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.textContaining('45.95'), findsOneWidget);
    expect(find.text('لبن المراعي خالي الدسم'), findsNothing);
  });

  testWidgets('a scanned barcode ignores letter case', (tester) async {
    await _openSearch(tester, scanResult: 'abc-123');

    await tester.tap(find.byTooltip('مسح الباركود'));
    await tester.pumpAndSettle();

    expect(find.text('Pepsi Cola 1L'), findsOneWidget);
  });

  testWidgets('a scanned product already loaded shows before the server', (
    tester,
  ) async {
    await _openSearch(
      tester,
      scanResult: '6221234567890',
      catalog: _PendingCatalogRepository(products: [_milk]),
      homeProducts: const [_milk, _cheese],
    );

    await tester.tap(find.byTooltip('مسح الباركود'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.textContaining('45.95'), findsOneWidget);
    expect(find.text('جبنة دومتي فيتا'), findsNothing);
  });

  testWidgets('an unknown scanned barcode says so', (tester) async {
    await _openSearch(tester, scanResult: '0000000000000');

    await tester.tap(find.byTooltip('مسح الباركود'));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد منتج بالباركود «0000000000000»'), findsOneWidget);
  });

  testWidgets('cancelling the scanner leaves the search as it was', (
    tester,
  ) async {
    final catalog = await _openSearch(tester, scanResult: '-1');

    await tester.tap(find.byTooltip('مسح الباركود'));
    await tester.pumpAndSettle();

    expect(catalog.searches, isEmpty);
    expect(find.text('عمليات بحث شائعة'), findsOneWidget);
  });

  testWidgets('suggestion chips search and empty results explain why', (
    tester,
  ) async {
    await _openSearch(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'جبنة'));
    await tester.pumpAndSettle();
    expect(find.text('جبنة دومتي فيتا'), findsOneWidget);

    await _type(tester, 'قهوة');
    expect(find.text('لا توجد نتائج لـ «قهوة»'), findsOneWidget);

    await tester.tap(find.byTooltip('مسح'));
    await tester.pumpAndSettle();
    expect(find.text('عمليات بحث شائعة'), findsOneWidget);
  });

  testWidgets('tapping a result opens its details', (tester) async {
    await _openSearch(tester);

    await _type(tester, 'فيتا');
    await tester.tap(find.text('جبنة دومتي فيتا'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
  });

  testWidgets('+ on a result fills the header cart and the toast leaves', (
    tester,
  ) async {
    await _openSearch(tester);
    final headerCart = find.descendant(
      of: find.byType(SearchScreen),
      matching: find.byType(AddToCartIcon),
    );
    expect(headerCart, findsOneWidget);
    // Top-left in RTL.
    expect(
      tester.getCenter(headerCart).dx,
      lessThan(tester.getCenter(find.text('ابحث في سفير')).dx),
    );

    await _type(tester, 'فيتا');
    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pump();
    expect(find.text('تمت إضافة جبنة دومتي فيتا إلى السلة'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SearchScreen), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('تمت إضافة جبنة دومتي فيتا إلى السلة'), findsNothing);
  });
}
