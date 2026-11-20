import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';

import 'test_helpers.dart';

const _milk = Product(id: 'p1', name: 'لبن كامل الدسم', price: 32.5);
const _cheese = Product(id: 'p2', name: 'جبنة رومي', price: 120);

Finder get _addFavorite => find.byTooltip('أضف للمفضلة');
Finder get _removeFavorite => find.byTooltip('إزالة من المفضلة');

Future<void> _openFavorites(WidgetTester tester) async {
  await tester.tap(find.text('المزيد'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('المنتجات المفضلة'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('heart toggles the favorite in Supabase and fills red', (
    tester,
  ) async {
    final favorites = FakeFavoritesRepository(catalog: [_milk, _cheese]);
    await pumpApp(
      tester,
      products: [_milk, _cheese],
      authRepository: FakeAuthRepository(user: testUser),
      favoritesRepository: favorites,
    );
    await skipSplash(tester);

    expect(_addFavorite, findsNWidgets(2));
    await tester.tap(_addFavorite.first);
    await tester.pumpAndSettle();

    expect(favorites.ids, {'p1'});
    expect(_removeFavorite, findsOneWidget);
    final heart = tester.widget<Icon>(
      find.descendant(of: _removeFavorite, matching: find.byType(Icon)),
    );
    expect(heart.icon, Icons.favorite_rounded);

    await tester.tap(_removeFavorite);
    await tester.pumpAndSettle();
    expect(favorites.ids, isEmpty);
    expect(_addFavorite, findsNWidgets(2));
  });

  testWidgets('favorites screen lists saved products and drops unhearted', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: [_milk, _cheese],
      authRepository: FakeAuthRepository(user: testUser),
      favoritesRepository: FakeFavoritesRepository(
        catalog: [_milk, _cheese],
        ids: {'p2'},
      ),
    );
    await skipSplash(tester);
    await _openFavorites(tester);

    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('جبنة رومي'), findsOneWidget);
    expect(find.text('لبن كامل الدسم'), findsNothing);

    await tester.tap(_removeFavorite);
    await tester.pumpAndSettle();
    expect(find.text('جبنة رومي'), findsNothing);
    expect(find.text('لا توجد منتجات مفضلة بعد'), findsOneWidget);
  });

  testWidgets('guest tapping the heart logs in, then saves the favorite', (
    tester,
  ) async {
    final favorites = FakeFavoritesRepository(catalog: [_milk]);
    await pumpApp(tester, products: [_milk], favoritesRepository: favorites);
    await skipSplash(tester);

    await tester.tap(_addFavorite);
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      'amr@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كلمة المرور'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(favorites.ids, {'p1'});
    expect(_removeFavorite, findsOneWidget);
  });

  testWidgets('a rejected toggle rolls back and explains the error', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: [_milk],
      authRepository: FakeAuthRepository(user: testUser),
      favoritesRepository: FakeFavoritesRepository(fail: true),
    );
    await skipSplash(tester);

    await tester.tap(_addFavorite);
    await tester.pumpAndSettle();

    expect(_addFavorite, findsOneWidget);
    expect(find.text('تعذر تحديث المفضلة، حاول مرة أخرى'), findsOneWidget);
  });
}
