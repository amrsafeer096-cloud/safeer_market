import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/catalog/presentation/screens/product_details_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';

import 'test_helpers.dart';

const _milk = Product(id: 'm1', name: 'لبن جهينة كامل الدسم', price: 45.95);
const _exitHint = 'اضغط مرة أخرى للخروج من التطبيق';

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

int _currentTab(WidgetTester tester) => tester
    .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
    .currentIndex;

void main() {
  late List<String> exits;

  setUp(() => exits = []);

  /// Records `SystemNavigator.pop` calls, i.e. attempts to close the app.
  void watchExits(WidgetTester tester) {
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits.add(call.method);
        return null;
      },
    );
  }

  testWidgets('back on a pushed screen pops to the previous screen', (
    tester,
  ) async {
    await pumpApp(tester, products: const [_milk]);
    await skipSplash(tester);
    watchExits(tester);

    await tester.tap(find.text(_milk.name));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await _pressBack(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(_exitHint), findsNothing);
    expect(exits, isEmpty);
  });

  testWidgets('back on another tab switches to the home tab', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);
    watchExits(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 4);

    await _pressBack(tester);
    await tester.pumpAndSettle();

    expect(_currentTab(tester), 0);
    expect(find.text('استكشف سفير'), findsOneWidget);
    expect(find.text(_exitHint), findsNothing);
    expect(exits, isEmpty);
  });

  testWidgets('double back within 2 seconds on home exits the app', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);
    watchExits(tester);

    await _pressBack(tester);
    expect(find.text(_exitHint), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(exits, isEmpty);

    await _pressBack(tester);
    expect(exits, ['SystemNavigator.pop']);
  });

  testWidgets('a second back after 2 seconds only shows the hint again', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);
    watchExits(tester);

    await _pressBack(tester);
    expect(find.text(_exitHint), findsOneWidget);

    await tester.runAsync(
      () => Future<void>.delayed(
        HomeScreen.exitWindow + const Duration(milliseconds: 200),
      ),
    );

    await _pressBack(tester);
    expect(find.text(_exitHint), findsOneWidget);
    expect(exits, isEmpty);

    await _pressBack(tester);
    expect(exits, ['SystemNavigator.pop']);
  });
}
