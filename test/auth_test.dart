import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/cart/presentation/screens/cart_screen.dart';
import 'package:safeer_market/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:safeer_market/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';

import 'test_helpers.dart';

const _apple = Product(id: '1', name: 'تفاح أحمر', price: 12.5);

Future<void> _openCartWithItem(WidgetTester tester) async {
  await tester.tap(find.byTooltip('أضف للسلة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('السلة'));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _chooseEmail(WidgetTester tester) async {
  await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guest checkout redirects to AuthScreen, login continues on', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: const [_apple],
      overrides: [
        checkoutRepositoryProvider.overrideWith(
          (ref) => throw StateError('checkout must not run for guests'),
        ),
      ],
    );
    await skipSplash(tester);
    await _openCartWithItem(tester);

    await tester.tap(find.text('متابعة الطلب'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    await _chooseEmail(tester);
    expect(find.text('أهلاً بعودتك!'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pump();
    expect(find.text('أدخل بريداً إلكترونياً صحيحاً'), findsOneWidget);
    expect(find.text('كلمة المرور 6 أحرف على الأقل'), findsOneWidget);

    await tester.enterText(_field('البريد الإلكتروني'), 'amr@example.com');
    await tester.enterText(_field('كلمة المرور'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(find.byType(CheckoutScreen), findsOneWidget);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
  });

  testWidgets('sign up collects name, email, phone and password', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      signUpResult: SignUpResult.confirmationRequired,
    );
    await pumpApp(tester, products: const [_apple], authRepository: auth);
    await skipSplash(tester);
    await _openCartWithItem(tester);
    await tester.tap(find.text('متابعة الطلب'));
    await tester.pumpAndSettle();
    await _chooseEmail(tester);

    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();
    expect(find.text('انضم إلى سفير ماركت'), findsOneWidget);

    await tester.enterText(_field('الاسم الكامل'), 'عمرو أحمد');
    await tester.enterText(_field('البريد الإلكتروني'), 'amr@example.com');
    await tester.enterText(_field('رقم الهاتف'), '0123');
    await tester.enterText(_field('كلمة المرور'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء الحساب'));
    await tester.pump();
    expect(find.text('أدخل رقم هاتف مصري صحيح (11 رقماً)'), findsOneWidget);
    expect(auth.lastSignUp, isNull);

    await tester.enterText(_field('رقم الهاتف'), '01012345678');
    await tester.tap(find.widgetWithText(FilledButton, 'إنشاء الحساب'));
    await tester.pumpAndSettle();

    expect(auth.lastSignUp, {
      'fullName': 'عمرو أحمد',
      'email': 'amr@example.com',
      'phone': '01012345678',
    });
    expect(find.textContaining('أرسلنا رابط التأكيد'), findsOneWidget);
    expect(find.text('أهلاً بعودتك!'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('login errors are shown in Arabic', (tester) async {
    await pumpApp(
      tester,
      products: const [_apple],
      authRepository: FakeAuthRepository(
        failure:
            const AuthFailure('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
      ),
    );
    await skipSplash(tester);
    await _openCartWithItem(tester);
    await tester.tap(find.text('متابعة الطلب'));
    await tester.pumpAndSettle();
    await _chooseEmail(tester);

    await tester.enterText(_field('البريد الإلكتروني'), 'amr@example.com');
    await tester.enterText(_field('كلمة المرور'), 'wrong-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(
      find.text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
      findsOneWidget,
    );
    expect(find.byType(AuthScreen), findsOneWidget);

    final context = tester.element(find.byType(AuthScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
