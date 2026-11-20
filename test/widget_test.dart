import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';
import 'package:safeer_market/features/home/presentation/screens/product_list_screen.dart';
import 'package:safeer_market/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_card.dart';
import 'package:safeer_market/features/home/presentation/widgets/promo_carousel.dart';
import 'package:safeer_market/features/search/presentation/providers/barcode_scanner_provider.dart';
import 'package:safeer_market/features/search/presentation/screens/search_screen.dart';
import 'package:safeer_market/features/splash/presentation/screens/splash_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('app starts on the splash screen then opens home', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('سفير ماركت'), findsOneWidget);

    await skipSplash(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('home screen renders RTL storefront with products', (
    tester,
  ) async {
    const product = Product(id: '1', name: 'تفاح أحمر', price: 12.5);
    await pumpApp(tester, products: const [product]);
    await skipSplash(tester);

    expect(find.text('التوصيل إلى · مدينة نصر'), findsOneWidget);
    expect(find.text('اختر عنوانك'), findsOneWidget);
    expect(find.text('توصيل خلال 30 - 45 دقيقة'), findsOneWidget);
    expect(find.text('العب واكسب'), findsOneWidget);
    expect(find.text('استكشف سفير'), findsOneWidget);
    expect(find.text('منتجات مختارة'), findsOneWidget);
    expect(find.text('تفاح أحمر'), findsOneWidget);
    expect(find.textContaining('ج.م'), findsWidgets);
    expect(find.text('الرئيسية'), findsOneWidget);
    // Rows with nothing to show stay hidden.
    expect(find.text('عروض رائجة'), findsNothing);
    expect(find.text('منتجات جديدة'), findsNothing);

    final context = tester.element(find.byType(HomeScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('offers and new products rows follow the featured row', (
    tester,
  ) async {
    const featured = Product(id: '1', name: 'تفاح أحمر', price: 12.5);
    const offer =
        Product(id: '2', name: 'زيت عباد الشمس', price: 80, discountPrice: 65);
    const latest = Product(id: '3', name: 'عسل نحل', price: 120);
    await pumpApp(
      tester,
      products: const [featured],
      offerProducts: const [offer],
      newProducts: const [latest],
    );
    await skipSplash(tester);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('منتجات مختارة'), lessThan(top('عروض رائجة')));
    expect(top('عروض رائجة'), lessThan(top('زيت عباد الشمس')));
    expect(top('زيت عباد الشمس'), lessThan(top('منتجات جديدة')));
    expect(top('منتجات جديدة'), lessThan(top('عسل نحل')));
  });

  group('quick actions', () {
    testWidgets('sit above the carousel and product rows', (tester) async {
      await pumpApp(tester);
      await skipSplash(tester);

      final actions = find.byType(HomeQuickActions);
      expect(actions, findsOneWidget);
      expect(find.text('أحدث المنتجات'), findsOneWidget);
      expect(find.text('العب واكسب'), findsOneWidget);
      expect(
        tester.getBottomLeft(actions).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(PromoCarousel)).dy),
      );
    });

    testWidgets('أحدث المنتجات explains when nothing is new', (tester) async {
      await pumpApp(tester);
      await skipSplash(tester);

      await tester.tap(find.text('أحدث المنتجات'));
      await tester.pump();
      expect(find.text('لا توجد منتجات جديدة خلال آخر 3 أيام'), findsOneWidget);
    });

    testWidgets('أحدث المنتجات scrolls to the new products row', (
      tester,
    ) async {
      await pumpApp(
        tester,
        newProducts: const [Product(id: 'n1', name: 'عسل نحل', price: 120)],
      );
      tester.view.physicalSize = const Size(450, 800);
      await skipSplash(tester);

      final header = find.text('منتجات جديدة');
      final scroll = find.byType(CustomScrollView);
      // Built, but below the fold.
      expect(header, findsNothing);
      expect(
        find.text('منتجات جديدة', skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.text('أحدث المنتجات'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(header).dy,
        greaterThanOrEqualTo(tester.getTopLeft(scroll).dy),
      );
      expect(
        tester.getBottomLeft(find.text('عسل نحل')).dy,
        lessThanOrEqualTo(tester.getBottomLeft(scroll).dy),
      );
    });

    testWidgets('العروض explains when there are no offers', (tester) async {
      await pumpApp(tester);
      await skipSplash(tester);

      await tester.tap(find.text('العروض'));
      await tester.pump();
      expect(find.text('لا توجد عروض حالياً'), findsOneWidget);
    });

    testWidgets('only the NEW pill pulses and the game icon floats', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester, animateQuickActions: true);
      await skipSplash(tester);

      final actions = find.byType(HomeQuickActions);
      expect(
        find.descendant(of: actions, matching: find.byType(RotationTransition)),
        findsNothing,
      );
      final pulse = find.descendant(
        of: actions,
        matching: find.byType(ScaleTransition),
      );
      expect(pulse, findsOneWidget);
      expect(
        find.descendant(of: pulse, matching: find.text('NEW')),
        findsOneWidget,
      );
      double scale() => tester.widget<ScaleTransition>(pulse).scale.value;
      double float() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byIcon(Icons.extension_outlined),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .y;

      // Reduced motion: everything at rest.
      expect(scale(), 1.0);
      expect(float(), 0.0);

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(scale(), inExclusiveRange(1.0, 1.06));
      expect(float().abs(), inInclusiveRange(0.01, 2.0));
    });
  });

  group('home header', () {
    testWidgets('the search pill opens the search tab', (tester) async {
      await pumpApp(tester);
      await skipSplash(tester);

      await tester.tap(find.text('ابحث عن منتج أو ماركة'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('the barcode icon opens search with the scanner', (
      tester,
    ) async {
      var scans = 0;
      await pumpApp(
        tester,
        overrides: [
          barcodeScannerProvider.overrideWithValue((_) async {
            scans++;
            return null;
          }),
        ],
      );
      await skipSplash(tester);

      await tester.tap(find.byTooltip('مسح الباركود'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(scans, 1);
    });
  });

  testWidgets('عرض الكل opens every offer in a grid', (tester) async {
    const offers = [
      Product(id: 'o1', name: 'زيت عباد الشمس', price: 80, discountPrice: 65),
      Product(id: 'o2', name: 'أرز مصري', price: 40, discountPrice: 32),
    ];
    await pumpApp(tester, offerProducts: offers);
    await skipSplash(tester);

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('عروض رائجة'),
          matching: find.byType(Row),
        ),
        matching: find.text('عرض الكل'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductListScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProductListScreen),
        matching: find.byType(ProductCard),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('adding to the cart updates the badge without rebuilding home', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: const [
        Product(id: 'p1', name: 'أرز مصري', price: 30),
        Product(id: 'p2', name: 'سكر', price: 25),
      ],
      authRepository: FakeAuthRepository(user: testUser),
    );
    await skipSplash(tester);

    CustomScrollView homeScroll() =>
        tester.widget<CustomScrollView>(find.byType(CustomScrollView).first);
    final before = homeScroll();

    await tester.tap(
      find
          .descendant(
            of: find.byType(ProductCard).first,
            matching: find.byIcon(Icons.add_rounded),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(identical(homeScroll(), before), isTrue,
        reason: 'only the cart badge and the tapped card rebuild');
  });

  group('promo deck', () {
    const first = 'عروض سفير ما بتنتهيش';
    const second = 'سفير... محل التوفير';
    const last = 'توصيل مجاني';

    /// The banner on top of the deck: the only title a tap can reach.
    String front(WidgetTester tester) =>
        [first, second, 'خصومات الافتتاح', last].singleWhere((title) => find
            .descendant(
              of: find.byType(PromoCarousel),
              matching: find.text(title),
            )
            .hitTestable()
            .evaluate()
            .isNotEmpty);

    Future<void> open(WidgetTester tester) async {
      await pumpApp(tester);
      await skipSplash(tester);
    }

    testWidgets('shows the front banner with two more stacked behind', (
      tester,
    ) async {
      await open(tester);

      expect(front(tester), first);
      expect(find.byType(PageView), findsNothing, reason: 'no paged carousel');
      // Front + two peeking cards, each with its own «تسوق الآن».
      expect(
        find.descendant(
          of: find.byType(PromoCarousel),
          matching: find.text('تسوق الآن'),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('auto-plays to the next banner every 4 seconds', (
      tester,
    ) async {
      await open(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(front(tester), second);
    });

    testWidgets('swipes both ways in RTL and loops past the ends', (
      tester,
    ) async {
      await open(tester);
      final deck = find.byType(PromoCarousel);

      // RTL: dragging right brings the next banner.
      await tester.drag(deck, const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(front(tester), second);

      await tester.drag(deck, const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(front(tester), first);

      // Back past the first banner loops to the last one.
      await tester.drag(deck, const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(front(tester), last);

      // A short drag springs back.
      await tester.drag(deck, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(front(tester), last);
    });

    testWidgets('a finger on the deck pauses auto-play until released', (
      tester,
    ) async {
      await open(tester);

      final finger = await tester
          .startGesture(tester.getCenter(find.byType(PromoCarousel)));
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(front(tester), first);

      await finger.up();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(front(tester), second);
    });
  });
}
