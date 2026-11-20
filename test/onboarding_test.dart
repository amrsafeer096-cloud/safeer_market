import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safeer_market/core/providers/settings_providers.dart';
import 'package:safeer_market/core/widgets/theme_selector.dart';
import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/auth/presentation/widgets/sign_in_prompt.dart';
import 'package:safeer_market/features/cart/presentation/providers/cart_providers.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';
import 'package:safeer_market/features/home/presentation/widgets/product_card.dart';
import 'package:safeer_market/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:safeer_market/features/orders/presentation/screens/my_orders_screen.dart';

import 'test_helpers.dart';

const _rice = Product(id: 'r1', name: 'أرز مصري', price: 30);

ThemeMode _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).last);
  await tester.pumpAndSettle();
}

Future<void> _signInWithEmail(WidgetTester tester) async {
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
}

Finder _promptButton(String text) => find.descendant(
      of: find.byType(SignInPromptSheet),
      matching: find.text(text),
    );

void main() {
  group('first launch', () {
    testWidgets('opens onboarding instead of the store', (tester) async {
      await pumpApp(tester, firstLaunch: true);
      await skipSplash(tester);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('اختر لغتك'), findsOneWidget);
    });

    testWidgets('language and theme apply at once and are saved', (
      tester,
    ) async {
      await pumpApp(tester, firstLaunch: true);
      await skipSplash(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your language'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(OnboardingScreen))),
        TextDirection.ltr,
      );
      expect((await _prefs()).getString(SettingsKeys.locale), 'en');

      await _next(tester);
      expect(find.text('Choose how the app looks'), findsOneWidget);
      expect(find.byType(ThemeSelectorWidget), findsOneWidget);
      expect(_appThemeMode(tester), ThemeMode.light, reason: 'the default');

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(_appThemeMode(tester), ThemeMode.dark);
      expect((await _prefs()).getString(SettingsKeys.themeMode), 'dark');
    });

    testWidgets('«تصفح التطبيق أولاً» goes home as a guest, for good', (
      tester,
    ) async {
      await pumpApp(tester, firstLaunch: true);
      await skipSplash(tester);
      await _next(tester);
      await _next(tester);

      expect(find.text('تسجيل الدخول أو إنشاء حساب'), findsOneWidget);
      expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
      await tester.tap(find.text('تصفح التطبيق أولاً'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect((await _prefs()).getBool(SettingsKeys.onboardingDone), isTrue);
    });

    testWidgets('signing in from onboarding lands on home', (tester) async {
      await pumpApp(tester, firstLaunch: true);
      await skipSplash(tester);
      await _next(tester);
      await _next(tester);

      await tester.tap(find.text('تسجيل الدخول أو إنشاء حساب'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await _signInWithEmail(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect((await _prefs()).getBool(SettingsKeys.onboardingDone), isTrue);
    });

    testWidgets('returning users go straight to the store', (tester) async {
      await pumpApp(
        tester,
        preferences: {
          SettingsKeys.locale: 'en',
          SettingsKeys.themeMode: 'dark',
        },
      );
      await skipSplash(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Home'), findsWidgets, reason: 'saved language');
      expect(_appThemeMode(tester), ThemeMode.dark, reason: 'saved theme');
    });
  });

  group('guests', () {
    testWidgets('are asked to sign in before adding to the cart', (
      tester,
    ) async {
      await pumpApp(tester, products: const [_rice]);
      await skipSplash(tester);
      Future<void> tapAdd() async {
        await tester.tap(
          find.descendant(
            of: find.byType(ProductCard),
            matching: find.byIcon(Icons.add_rounded),
          ),
        );
        await tester.pumpAndSettle();
      }

      List<Object> cart() => ProviderScope.containerOf(
            tester.element(find.byType(HomeScreen)),
          ).read(cartProvider);

      await tapAdd();
      expect(find.text('سجّل دخولك للمتابعة'), findsOneWidget);
      await tester.tap(_promptButton('لاحقاً'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPromptSheet), findsNothing);
      expect(cart(), isEmpty);

      // Signing in from the prompt finishes adding the product.
      await tapAdd();
      await tester.tap(_promptButton('سجل دخولك'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await _signInWithEmail(tester);

      expect(find.byType(AuthScreen), findsNothing);
      expect(cart(), hasLength(1));
    });

    testWidgets('are asked to sign in before opening their orders', (
      tester,
    ) async {
      await pumpApp(tester);
      await skipSplash(tester);
      await tester.tap(find.text('المزيد'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('طلباتي'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPromptSheet), findsOneWidget);
      expect(find.byType(MyOrdersScreen), findsNothing);
    });
  });

  testWidgets('settings offer the theme selector and language', (
    tester,
  ) async {
    await pumpApp(tester, authRepository: FakeAuthRepository(user: testUser));
    await skipSplash(tester);
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemeSelectorWidget), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);

    await tester.tap(find.text('حسب النظام'));
    await tester.pumpAndSettle();
    expect(_appThemeMode(tester), ThemeMode.system);
    expect((await _prefs()).getString(SettingsKeys.themeMode), 'system');
  });
}
