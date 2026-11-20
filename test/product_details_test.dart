import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/catalog/presentation/screens/product_details_screen.dart';
import 'package:safeer_market/features/catalog/presentation/screens/product_image_viewer.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_card.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_image.dart';

import 'test_helpers.dart';

const _milk = Product(
  id: 'm1',
  name: 'لبن جهينة كامل الدسم',
  price: 45.95,
  categoryId: 'dairy',
  stockQuantity: 12,
  description: 'لبن طازج مبستر',
);
const _yogurt = Product(
  id: 'y1',
  name: 'زبادي جهينة',
  price: 8.5,
  categoryId: 'dairy',
);
const _chips = Product(
  id: 's1',
  name: 'شيبسي عائلي',
  price: 15,
  categoryId: 'sweets',
  stockQuantity: 0,
);

Finder get _addToCart => find.widgetWithText(FilledButton, 'إضافة للسلة');

Future<void> _openDetails(WidgetTester tester, String name) async {
  await pumpApp(
    tester,
    products: [_milk, _yogurt, _chips],
    authRepository: FakeAuthRepository(user: testUser),
  );
  await skipSplash(tester);
  await tester.ensureVisible(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(ProductDetailsScreen), findsOneWidget);
}

void main() {
  testWidgets('details show name, price, stock and description', (
    tester,
  ) async {
    await _openDetails(tester, 'لبن جهينة كامل الدسم');

    expect(find.text('لبن جهينة كامل الدسم'), findsWidgets);
    expect(find.textContaining('45.95'), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
    expect(find.text('لبن طازج مبستر'), findsOneWidget);
    expect(find.byTooltip('أضف للمفضلة'), findsWidgets);

    final context = tester.element(find.byType(ProductDetailsScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('add button turns into a quantity selector and back', (
    tester,
  ) async {
    await _openDetails(tester, 'لبن جهينة كامل الدسم');
    Badge cartBadge() => tester.widget<Badge>(
          find.descendant(
            of: find.byTooltip('السلة'),
            matching: find.byType(Badge),
          ),
        );
    String quantity() =>
        tester.widget<Text>(find.byKey(const Key('details-quantity'))).data!;

    await tester.tap(_addToCart);
    await tester.pump();
    expect(
        find.text('تمت إضافة لبن جهينة كامل الدسم إلى السلة'), findsOneWidget);
    expect(_addToCart, findsNothing);
    expect(find.text('في السلة'), findsOneWidget);
    expect(quantity(), '1');

    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pump();
    expect(quantity(), '2');
    expect((cartBadge().label! as Text).data, '2');
    expect(find.textContaining('91.90'), findsOneWidget);

    await tester.tap(find.byTooltip('تقليل الكمية'));
    await tester.pump();
    expect(quantity(), '1');

    await tester.tap(find.byTooltip('تقليل الكمية'));
    await tester.pump();
    expect(find.byKey(const Key('details-quantity')), findsNothing);
    expect(_addToCart, findsOneWidget);
    expect(cartBadge().isLabelVisible, isFalse);

    // Let the fly-to-cart animations started above finish.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('quantity cannot exceed the available stock', (tester) async {
    const lastTwo = Product(
      id: 'l1',
      name: 'جبنة رومي',
      price: 60,
      stockQuantity: 2,
    );
    await pumpApp(
      tester,
      products: const [lastTwo],
      authRepository: FakeAuthRepository(user: testUser),
    );
    await skipSplash(tester);
    await tester.tap(find.text('جبنة رومي'));
    await tester.pumpAndSettle();

    await tester.tap(_addToCart);
    await tester.pump();
    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pump();
    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('details-quantity'))).data,
      '2',
    );

    // Let the fly-to-cart animations started above finish.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('similar products share the category and exclude the current', (
    tester,
  ) async {
    await _openDetails(tester, 'لبن جهينة كامل الدسم');

    expect(find.text('منتجات مشابهة'), findsOneWidget);
    expect(find.text('زبادي جهينة'), findsOneWidget);
    expect(find.text('شيبسي عائلي'), findsNothing);

    await tester.tap(find.text('زبادي جهينة'));
    await tester.pumpAndSettle();
    expect(find.text('زبادي جهينة'), findsWidgets);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
  });

  testWidgets('unrelated products fall back to the featured pick', (
    tester,
  ) async {
    await _openDetails(tester, 'شيبسي عائلي');

    expect(find.text('منتجات مشابهة'), findsOneWidget);
    expect(find.text('لبن جهينة كامل الدسم'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(2));
  });

  testWidgets('out-of-stock products disable the add button', (tester) async {
    await _openDetails(tester, 'شيبسي عائلي');

    expect(find.text('غير متوفر'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'غير متوفر حالياً'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('card quantity selector steps within the stock', (tester) async {
    const lastTwo = Product(
      id: 'l1',
      name: 'جبنة رومي',
      price: 60,
      stockQuantity: 2,
    );
    await pumpApp(tester, products: const [lastTwo]);
    await skipSplash(tester);
    Finder cardText(String text) => find.descendant(
          of: find.byType(ProductCard),
          matching: find.text(text),
        );
    IconButton plus() => tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.add_rounded),
        );

    expect(cardText('0'), findsOneWidget);
    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    expect(cardText('1'), findsOneWidget);

    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    expect(cardText('2'), findsOneWidget);
    expect(plus().onPressed, isNull);

    await tester.tap(find.byTooltip('تقليل الكمية'));
    await tester.pumpAndSettle();
    expect(cardText('1'), findsOneWidget);
    expect(plus().onPressed, isNotNull);
  });

  testWidgets(
      'tapping the image opens a fixed-size viewer with similar products', (
    tester,
  ) async {
    await _openDetails(tester, 'لبن جهينة كامل الدسم');

    await tester.tap(
      find
          .descendant(
            of: find.byType(ProductDetailsScreen),
            matching: find.byType(ProductImage),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductImageViewer), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    final imageBox = tester.getSize(
      find
          .descendant(
            of: find.byType(ProductImageViewer),
            matching: find.byType(ProductImage),
          )
          .first,
    );
    expect(imageBox.width, lessThanOrEqualTo(ProductImageViewer.imageSize));
    expect(imageBox.height, lessThanOrEqualTo(ProductImageViewer.imageSize));
    expect(
      find.descendant(
        of: find.byType(ProductImageViewer),
        matching: find.text('منتجات مشابهة'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ProductImageViewer),
        matching: find.text('زبادي جهينة'),
      ),
      findsOneWidget,
    );
    // No link to copy without a photo URL.
    expect(find.byTooltip('نسخ رابط الصورة'), findsNothing);

    await tester.tap(find.byTooltip('إغلاق'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductImageViewer), findsNothing);
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
  });
}
