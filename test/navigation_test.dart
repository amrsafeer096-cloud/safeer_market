import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/cart/presentation/screens/cart_screen.dart';
import 'package:safeer_market/features/catalog/presentation/screens/category_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';

import 'test_helpers.dart';

const _milk = Product(
  id: 'm1',
  name: 'لبن جهينة كامل الدسم',
  price: 45.95,
  category: testDairy,
);
const _cheese = Product(
  id: 'c1',
  name: 'جبنة دومتي فيتا',
  price: 35.5,
  category: testDairy,
);
const _snickers = Product(
  id: 's1',
  name: 'شيكولاتة Snickers',
  price: 30,
  category: testSweets,
);

void main() {
  testWidgets('empty cart "تسوق الآن" returns home on the الرئيسية tab', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);

    await tester.tap(find.text('البحث'));
    await tester.pump();
    expect(find.text('استكشف سفير'), findsNothing);

    await tester.tap(find.text('السلة'));
    await tester.pumpAndSettle();
    expect(find.text('سلتك فارغة'), findsOneWidget);

    await tester.tap(find.text('تسوق الآن'));
    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('استكشف سفير'), findsOneWidget);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 0);
  });

  testWidgets('tapping a category opens its filtered products', (
    tester,
  ) async {
    await pumpApp(tester, catalogProducts: const [_milk, _cheese, _snickers]);
    await skipSplash(tester);

    await tester.tap(find.text('ألبان وبيض'));
    await tester.pumpAndSettle();

    final screen = tester.widget<CategoryScreen>(find.byType(CategoryScreen));
    expect(screen.mainCategoryId, 'dairy');
    expect(find.text('2 منتج'), findsOneWidget);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.text('جبنة دومتي فيتا'), findsOneWidget);
    expect(find.text('شيكولاتة Snickers'), findsNothing);

    await tester.tap(find.byTooltip('أضف للسلة').first);
    await tester.pumpAndSettle();
    // The cart badge and the card's quantity selector.
    expect(find.text('1'), findsNWidgets(2));

    final context = tester.element(find.byType(CategoryScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('empty category offers a way back home', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);

    await tester.tap(find.text('حلويات وتسالي'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد منتجات في هذا القسم حالياً'), findsOneWidget);

    await tester.tap(find.text('تسوق من الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
