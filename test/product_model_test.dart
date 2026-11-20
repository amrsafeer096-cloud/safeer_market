import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/l10n/l10n.dart';
import 'package:safeer_market/features/cart/presentation/providers/cart_providers.dart';
import 'package:safeer_market/features/home/data/models/product_model.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_card.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_price.dart';

import 'test_helpers.dart';

const _oil = Product(
  id: 'o1',
  name: 'زيت عباد الشمس',
  price: 100,
  unit: 'كرتونة',
  discountPrice: 85,
);
const _rice = Product(id: 'r1', name: 'أرز مصري', price: 30);

Future<void> _pumpCard(WidgetTester tester, Product product) async {
  await pumpApp(
    tester,
    products: [product],
    authRepository: FakeAuthRepository(user: testUser),
  );
  await skipSplash(tester);
  expect(find.byType(ProductCard), findsOneWidget);
}

void main() {
  group('ProductModel.fromJson', () {
    test('maps the products table columns', () {
      final product = ProductModel.fromJson({
        'id': 'b5c1e0a2-0000-4000-8000-000000000001',
        'name': 'جبنة رومي',
        'price': 240,
        'stock_quantity': 12,
        'discount_price': '199.5',
        'is_active': true,
        'category_id': 'c0ffee00-0000-4000-8000-000000000002',
        'barcode': ' 6221111 ',
        'unit': ' وزن ',
      });

      expect(product.id, 'b5c1e0a2-0000-4000-8000-000000000001');
      expect(product.price, 240);
      expect(product.stockQuantity, 12);
      expect(product.discountPrice, 199.5);
      expect(product.isActive, isTrue);
      expect(product.categoryId, 'c0ffee00-0000-4000-8000-000000000002');
      expect(product.barcode, '6221111');
      expect(product.inStock, isTrue);
      expect(product.hasActiveOffer, isTrue);
      expect(product.effectivePrice, 199.5);
      expect(product.unit, 'وزن');
      expect(product.displayUnit, 'كيلو');
    });

    test('stock_quantity decides availability', () {
      Product parse(Object? stock) => ProductModel.fromJson({
            'id': 1,
            'name': 'شاي',
            'price': 9,
            if (stock != 'missing') 'stock_quantity': stock,
          });

      for (final stock in [1, 40, '7']) {
        expect(parse(stock).inStock, isTrue, reason: 'stock_quantity: $stock');
      }
      for (final stock in [0, -3, null, 'missing', 'n/a', '0']) {
        expect(parse(stock).stockQuantity, lessThanOrEqualTo(0));
        expect(parse(stock).inStock, isFalse, reason: 'stock_quantity: $stock');
      }
      expect(parse('5').stockQuantity, 5);
    });

    test('is_active defaults to true and false hides the product', () {
      Product parse(Object? value) => ProductModel.fromJson({
            'id': 1,
            'name': 'أ',
            'price': 1,
            'stock_quantity': 10,
            if (value != 'missing') 'is_active': value,
          });

      expect(parse('missing').isActive, isTrue);
      expect(parse(null).isActive, isTrue);
      expect(parse(true).inStock, isTrue);
      expect(parse(false).isActive, isFalse);
      expect(parse('false').isActive, isFalse);
      expect(parse(false).inStock, isFalse);
    });

    test('a row without discount_price or category_id', () {
      final product = ProductModel.fromJson({
        'id': 1,
        'name': 'سكر',
        'price': '32.5',
        'stock_quantity': 3,
      });

      expect(product.discountPrice, isNull);
      expect(product.hasActiveOffer, isFalse);
      expect(product.effectivePrice, 32.5);
      expect(product.categoryId, isNull);
      expect(product.unit, 'قطعة');
    });

    test('a name with وزن implies the weight unit', () {
      final product = ProductModel.fromJson({
        'id': 4,
        'name': 'زيتون وزن',
        'price': 90,
      });
      expect(product.unit, 'وزن');
    });
  });

  group('discount_price', () {
    test('only counts when it is below the regular price', () {
      expect(_oil.hasActiveOffer, isTrue);
      expect(_oil.discountPercentage, 15);
      expect(
        const Product(id: 'a', name: 'a', price: 10).hasActiveOffer,
        isFalse,
      );
      expect(
        const Product(id: 'b', name: 'b', price: 10, discountPrice: 12)
            .effectivePrice,
        10,
      );
      expect(
        const Product(id: 'c', name: 'c', price: 10, discountPrice: 10)
            .hasActiveOffer,
        isFalse,
      );
    });

    test('effective price, old price and percentage follow the offer', () {
      expect(_oil.effectivePrice, 85);
      expect(_oil.oldPrice, 100);
      expect(_oil.discountPercentage, 15);

      expect(_rice.effectivePrice, 30);
      expect(_rice.oldPrice, isNull);
      expect(_rice.discountPercentage, 0);
    });

    test('a zero discount_price is not an offer, so nothing is free', () {
      const zero = Product(id: 'z', name: 'z', price: 10, discountPrice: 0);
      expect(zero.hasActiveOffer, isFalse);
      expect(zero.effectivePrice, 10);
      expect(zero.oldPrice, isNull);
    });
  });

  testWidgets('category grid cards show the same offer as search', (
    tester,
  ) async {
    const oil = Product(
      id: 'o2',
      name: 'زيت ذرة',
      price: 100,
      discountPrice: 85,
      category: 'زيوت',
    );
    await pumpApp(
      tester,
      catalogRepository: FakeCatalogRepository(catalogProducts: [oil]),
    );
    await skipSplash(tester);
    await tester.tap(find.text('بقالة وزيوت'));
    await tester.pumpAndSettle();

    final card = find.byType(ProductCard);
    expect(card, findsOneWidget);
    Finder inCard(Finder finder) => find.descendant(of: card, matching: finder);
    final original = tester
        .widget<Text>(inCard(find.byKey(const Key('product-original-price'))));
    expect(original.data, contains('100.00'));
    expect(original.style!.decoration, TextDecoration.lineThrough);
    final price =
        tester.widget<Text>(inCard(find.byKey(const Key('product-price'))));
    expect(price.textSpan!.toPlainText(), contains('85.00'));
    expect(inCard(find.text('خصم 15%')), findsOneWidget);
  });

  testWidgets('adding an offer from a home card charges the offer price', (
    tester,
  ) async {
    await _pumpCard(tester, _oil);

    await tester.tap(
      find.descendant(
        of: find.byType(ProductCard),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    await tester.pumpAndSettle();

    final cart = ProviderScope.containerOf(
      tester.element(find.byType(ProductCard)),
    ).read(cartProvider);
    expect(cart.single.unitPrice, 85);
    expect(cart.single.total, 85);
  });

  group('units', () {
    Product withUnit(String unit) =>
        Product(id: 'u', name: 'منتج', price: 10, unit: unit);

    test('the stored unit is shown in the app language', () {
      expect(withUnit('قطعة').displayUnit, 'قطعة');
      expect(withUnit('قطعه').displayUnit, 'قطعة');
      expect(withUnit('علبة').displayUnit, 'علبة');
      expect(withUnit('كرتونة').displayUnit, 'كرتونة');
      expect(withUnit('كيلو').displayUnit, 'كيلو');
      expect(withUnit('طقم').displayUnit, 'طقم');
      // Codes an import might use.
      expect(withUnit('box').displayUnit, 'علبة');
      expect(withUnit(' KG ').displayUnit, 'كيلو');
      expect(withUnit('CTN').displayUnit, 'كرتونة');
      expect(withUnit('set').displayUnit, 'طقم');
      // Unknown units show as stored.
      expect(withUnit('دستة').displayUnit, 'دستة');
    });

    test('the ERP carton code reads as a box of N pieces', () {
      // Spellings found in the products table.
      expect(withUnit('ك * 12').displayUnit, 'علبة 12 قطعة');
      expect(withUnit('ك*65').displayUnit, 'علبة 65 قطعة');
      expect(withUnit('ك *  288').displayUnit, 'علبة 288 قطعة');
      expect(withUnit('ك * 12').piecesPerCarton, 12);
      expect(withUnit('قطعة').piecesPerCarton, isNull);
      expect(withUnit('كيلوجرام').displayUnit, 'كيلو');
      expect(withUnit('').displayUnit, 'قطعة');
    });

    test('English shows English units', () {
      addTearDown(() => L10n.setLocale(const Locale('ar')));
      L10n.setLocale(const Locale('en'));
      expect(withUnit('طقم').displayUnit, 'set');
      expect(withUnit('علبة').displayUnit, 'box');
      expect(withUnit('كيلو').displayUnit, 'kg');
      expect(withUnit('ك * 36').displayUnit, 'Box of 36');
      expect(withUnit('قطعة').displayUnit, 'piece');
      expect(withUnit('').displayUnit, 'piece');
    });

    Product parse(Map<String, Object?> json) =>
        ProductModel.fromJson({'id': 1, 'price': 5, ...json});

    test('the database unit wins over the name', () {
      expect(
        parse({'name': 'تونة صن شاين علبة', 'unit': 'قطعة'}).displayUnit,
        'قطعة',
      );
    });

    test('a uom column works when unit is missing', () {
      expect(parse({'name': 'تونة', 'uom': 'box'}).displayUnit, 'علبة');
    });

    test('without a unit, only a whole word in the name counts', () {
      expect(parse({'name': 'تونة صن شاين علبة'}).unit, 'علبة');
      expect(parse({'name': 'مناديل مبللة - كرتونة * 24 قطعة'}).unit, 'كرتونة');
      expect(parse({'name': 'طقم كاسات 6 قطع'}).unit, 'طقم');
      expect(parse({'name': 'سكر الأسرة 1 كيلو'}).unit, 'كيلو');
      // «كيلوجز» (Kellogg's) is not a kilo.
      expect(parse({'name': 'كيلوجز كورن فليكس 500 جم'}).unit, 'قطعة');
      expect(parse({'name': 'شاي العروسة 40 فتلة'}).unit, 'قطعة');
    });
  });

  testWidgets('card shows a box unit next to the price', (tester) async {
    await _pumpCard(
      tester,
      const Product(id: 'b1', name: 'تونة صن شاين', price: 45, unit: 'علبة'),
    );

    final price = tester.widget<Text>(find.byKey(const Key('product-price')));
    expect(price.textSpan!.toPlainText(), contains('/ علبة'));
    expect(price.textSpan!.toPlainText(), isNot(contains('قطعة')));
  });

  testWidgets('card shows a carton code as a box of N pieces', (tester) async {
    await _pumpCard(
      tester,
      const Product(id: 'c1', name: 'بسكويت', price: 170, unit: 'ك * 36'),
    );

    final price = tester.widget<Text>(find.byKey(const Key('product-price')));
    expect(price.textSpan!.toPlainText(), contains('/ علبة 36 قطعة'));
    expect(price.textSpan!.toPlainText(), isNot(contains('*')));
  });

  testWidgets('card shows the unit next to the price', (tester) async {
    await _pumpCard(tester, _rice);

    final price = tester.widget<Text>(find.byKey(const Key('product-price')));
    expect(price.textSpan!.toPlainText(), contains('/ قطعة'));
    expect(price.textSpan!.toPlainText(), contains('30.00'));
    expect(find.byKey(const Key('product-original-price')), findsNothing);
    expect(find.textContaining('خصم'), findsNothing);
  });

  testWidgets('card strikes the old price and highlights the discount', (
    tester,
  ) async {
    await _pumpCard(tester, _oil);

    final original =
        tester.widget<Text>(find.byKey(const Key('product-original-price')));
    expect(original.data, contains('100.00'));
    expect(original.style!.decoration, TextDecoration.lineThrough);

    final price = tester.widget<Text>(find.byKey(const Key('product-price')));
    final offerSpan = (price.textSpan! as TextSpan).children!.first as TextSpan;
    expect(offerSpan.text, contains('85.00'));
    expect(offerSpan.style!.color, ProductPrice.offerColor);
    expect(price.textSpan!.toPlainText(), contains('/ كرتونة'));
    expect(find.text('خصم 15%'), findsOneWidget);
  });
}
