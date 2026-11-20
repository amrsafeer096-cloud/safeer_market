import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:safeer_market/core/routing/app_routes.dart';
import 'package:safeer_market/features/catalog/domain/category_filter.dart';
import 'package:safeer_market/features/catalog/domain/main_categories.dart';
import 'package:safeer_market/features/catalog/presentation/providers/category_providers.dart';
import 'package:safeer_market/features/catalog/presentation/screens/category_screen.dart';
import 'package:safeer_market/features/catalog/presentation/widgets/categories_drawer.dart';
import 'package:safeer_market/features/catalog/presentation/widgets/main_category_image.dart';
import 'package:safeer_market/features/home/data/models/product_model.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';

import 'test_helpers.dart';

const _sweetsName = 'حلويات وتسالي';
const _chocolate = 'شيكولاتة';
const _biscuits = 'بسكويت';

const _galaxy = Product(
  id: 'g1',
  name: 'جالاكسي',
  price: 30,
  category: _chocolate,
);
const _kitkat =
    Product(id: 'k1', name: 'كيت كات', price: 20, category: _chocolate);
const _soldOutChocolate = Product(
  id: 'k2',
  name: 'شيكولاتة نفدت',
  price: 20,
  stockQuantity: 0,
  category: _chocolate,
);
const _oreo = Product(id: 'o1', name: 'أوريو', price: 15, category: _biscuits);
const _persil = Product(
  id: 'c1',
  name: 'برسيل',
  price: 120,
  category: 'مساحيق ومنعمات',
);

const _catalog = [_galaxy, _kitkat, _soldOutChocolate, _oreo, _persil];

Finder _tab(String label) =>
    find.descendant(of: find.byType(TabBar), matching: find.text(label));

Finder _inDrawer(Finder finder) =>
    find.descendant(of: find.byType(CategoriesDrawer), matching: finder);

Future<FakeCatalogRepository> _openHome(
  WidgetTester tester, {
  List<Product> catalog = _catalog,
}) async {
  final repository = FakeCatalogRepository(catalogProducts: catalog);
  await pumpApp(tester, catalogRepository: repository);
  await skipSplash(tester);
  return repository;
}

void main() {
  group('MainCategories', () {
    test('has 10-12 categories with unique ids, names and images', () {
      final all = MainCategories.all;
      expect(all.length, inInclusiveRange(10, 12));
      expect({for (final c in all) c.id}.length, all.length);
      expect({for (final c in all) c.name}.length, all.length);
      expect({for (final c in all) c.imageUrl}.length, all.length);
      for (final category in all) {
        expect(
          category.isAssetImage ||
              Uri.parse(category.imageUrl).isScheme('https'),
          isTrue,
        );
      }
    });

    test('maps every raw category to exactly one main category', () {
      final raw = [
        for (final c in MainCategories.all) ...c.subCategories,
        ...MainCategories.unlisted,
      ];
      expect(raw.toSet().length, raw.length);
      for (final name in raw) {
        expect(name, name.trim());
      }
    });

    test('حلويات وتسالي keeps packaged sweets only', () {
      expect(
        MainCategories.byId('sweets')!.subCategories,
        containsAll([
          'بسكويت',
          'شيكولاتة',
          'حلويات',
          'مقرمشات و محمصات',
        ]),
      );
      expect(
        MainCategories.byId('sweets')!.subCategories,
        isNot(contains('تسالي و مكسرات وزن')),
      );
      expect(
        MainCategories.byId('sweets')!.subCategories,
        isNot(contains('ياميش رمضان')),
      );
    });

    test('عطارة owns spices, nuts and baking supplies', () {
      final attara = MainCategories.byId('attara')!;
      expect(attara.name, 'عطارة');
      expect(
        attara.subCategories,
        containsAll([
          'عطارة وزن',
          'علافة وزن',
          'مستلزمات حلويات وبودر',
          'تسالي و مكسرات وزن',
          'ياميش رمضان',
        ]),
      );
      expect(MainCategories.byProductCategory('تسالي ومكسرات وزن'), attara);
      expect(MainCategories.byProductCategory('عطارة وزن'), attara);
      expect(
        MainCategories.byId('pantry')!.subCategories,
        isNot(contains('عطارة وزن')),
      );
    });

    test('diapers live under عناية شخصية, not عالم الطفل', () {
      expect(
        MainCategories.byId('personal-care')!.subCategories,
        contains('حافضات و فوط صحية'),
      );
      expect(
        MainCategories.byId('baby')!.subCategories,
        isNot(contains('حافضات و فوط صحية')),
      );
      expect(
        MainCategories.byProductCategory('حفاضات و فوط صحية')?.id,
        'personal-care',
      );
    });
  });

  group('category column', () {
    test('ProductModel reads a trimmed category', () {
      final product = ProductModel.fromJson({
        'id': 1,
        'name': 'كيت كات',
        'price': 20,
        'category': '$_chocolate ',
      });
      expect(product.category, _chocolate);
      expect(
          ProductModel.toJson(product), containsPair('category', _chocolate));
    });

    test('CategoryFilter keeps in-stock products of the given categories', () {
      expect(
        CategoryFilter.apply(_catalog, categories: [_chocolate, _biscuits]),
        [_galaxy, _kitkat, _oreo],
      );
      expect(CategoryFilter.apply(_catalog, categories: const []), isEmpty);
    });
  });

  testWidgets('home shows a card for every main category', (tester) async {
    await _openHome(tester);

    for (final category in MainCategories.all) {
      expect(find.text(category.name), findsOneWidget);
    }

    final sweetsTile = find
        .ancestor(of: find.text(_sweetsName), matching: find.byType(Column))
        .first;
    final cover = tester
        .widgetList<Image>(
          find.descendant(of: sweetsTile, matching: find.byType(Image)),
        )
        .single
        .image;
    // Decoded at tile size, not the full photo.
    final resized = cover as ResizeImage;
    expect(resized.width, mainCategoryImageWidth);
    expect(
      (resized.imageProvider as AssetImage).assetName,
      MainCategories.byId('sweets')!.imageUrl,
    );
  });

  testWidgets('a main category opens with الكل, then filters by tab', (
    tester,
  ) async {
    final repository = await _openHome(tester);

    await tester.tap(find.text(_sweetsName));
    await tester.pumpAndSettle();

    final screen = tester.widget<CategoryScreen>(find.byType(CategoryScreen));
    expect(screen.mainCategoryId, 'sweets');
    expect(_tab('الكل'), findsOneWidget);
    for (final sub in MainCategories.byId('sweets')!.subCategories) {
      expect(_tab(sub), findsOneWidget);
    }
    expect(repository.categoryRequests.single.$1,
        MainCategories.byId('sweets')!.subCategories);
    expect(find.text('3 منتج'), findsOneWidget);
    expect(find.text(_oreo.name), findsOneWidget);
    expect(find.text(_soldOutChocolate.name), findsNothing);
    expect(find.text(_persil.name), findsNothing);

    await tester.tap(_tab(_chocolate));
    await tester.pumpAndSettle();

    expect(repository.categoryRequests.last.$1, [_chocolate]);
    expect(repository.categoryRequests.last.$2, 0);
    expect(find.text('2 منتج'), findsOneWidget);
    expect(find.text(_galaxy.name), findsOneWidget);
    expect(find.text(_kitkat.name), findsOneWidget);
    expect(find.text(_oreo.name), findsNothing);
  });

  testWidgets('the drawer lists only the main categories', (tester) async {
    await _openHome(tester);

    await tester.tap(find.byTooltip('الأقسام'));
    await tester.pumpAndSettle();

    for (final category in MainCategories.all) {
      expect(_inDrawer(find.text(category.name)), findsOneWidget);
    }
    expect(_inDrawer(find.text(_chocolate)), findsNothing);

    await tester.tap(_inDrawer(find.text('منظفات وعناية')));
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesDrawer), findsNothing);
    expect(
      tester.widget<CategoryScreen>(find.byType(CategoryScreen)).mainCategoryId,
      'cleaning',
    );
    expect(find.text(_persil.name), findsOneWidget);
  });

  testWidgets('large categories load the next page on scroll', (
    tester,
  ) async {
    final many = [
      for (var i = 0; i < categoryPageSize + 5; i++)
        Product(
          id: 'p$i',
          name: 'منتج ${i.toString().padLeft(2, '0')}',
          price: 10,
          category: _chocolate,
        ),
    ];
    final repository = await _openHome(tester, catalog: many);
    await tester.tap(find.text(_sweetsName));
    await tester.pumpAndSettle();

    expect(find.text('${many.length} منتج'), findsOneWidget);
    expect(repository.categoryRequests.map((r) => r.$2), [0]);

    await tester.scrollUntilVisible(
      find.text(many.last.name),
      600,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(repository.categoryRequests.map((r) => r.$2), [0, categoryPageSize]);
    expect(find.text(many.last.name), findsOneWidget);
  });

  testWidgets('an unknown category id says so', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);
    GoRouter.of(tester.element(find.byType(HomeScreen)))
        .push(AppRoutes.category('nope'));
    await tester.pumpAndSettle();

    expect(find.text('هذا القسم غير موجود'), findsOneWidget);
  });
}
