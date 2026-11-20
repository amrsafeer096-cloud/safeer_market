import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:safeer_market/features/wallet/presentation/widgets/add_card_sheet.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<FakeWalletRepository> _openWallet(
  WidgetTester tester, {
  bool signedIn = true,
  double balance = 0,
}) async {
  final wallet = FakeWalletRepository(balance);
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: signedIn ? testUser : null),
    walletRepository: wallet,
  );
  await skipSplash(tester);
  await tester.tap(find.text('المحفظة'));
  await tester.pumpAndSettle();
  return wallet;
}

void main() {
  testWidgets('wallet tab shows the profile balance and saved-cards section', (
    tester,
  ) async {
    final wallet = await _openWallet(tester, balance: 150.5);

    expect(find.byType(WalletScreen), findsOneWidget);
    expect(wallet.requestedFor, testUser.id);
    expect(find.text('رصيد محفظتك في التطبيق'), findsOneWidget);
    expect(find.textContaining('150.50'), findsOneWidget);
    expect(find.textContaining('ج.م'), findsOneWidget);
    expect(find.text('البطاقات المحفوظة'), findsOneWidget);
    expect(find.text('إضافة بطاقة بنكية'), findsOneWidget);

    final context = tester.element(find.byType(WalletScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('a zero balance is formatted as 0.00 ج.م', (tester) async {
    await _openWallet(tester);
    expect(find.textContaining('0.00'), findsOneWidget);
  });

  testWidgets('add-card sheet validates and saves a masked card', (
    tester,
  ) async {
    await _openWallet(tester);

    await tester.tap(find.text('إضافة بطاقة بنكية'));
    await tester.pumpAndSettle();
    expect(find.byType(AddCardSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'حفظ البطاقة'));
    await tester.pump();
    expect(find.text('أدخل رقم البطاقة'), findsOneWidget);
    expect(find.text('أدخل التاريخ MM/YY'), findsOneWidget);

    await tester.enterText(_field('رقم البطاقة'), '4242424242424242');
    await tester.enterText(_field('تاريخ الانتهاء'), '1230');
    await tester.enterText(_field('CVV'), '123');
    await tester.enterText(_field('اسم حامل البطاقة'), 'Amr Ahmed');
    await tester.pump();

    expect(find.text('4242 4242 4242 4242'), findsWidgets);
    expect(find.text('12/30'), findsWidgets);
    expect(find.text('Visa'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'حفظ البطاقة'));
    await tester.pumpAndSettle();

    expect(find.byType(AddCardSheet), findsNothing);
    expect(find.text('تم حفظ البطاقة بنجاح'), findsOneWidget);
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(find.text('4242 4242 4242 4242'), findsNothing);
  });

  testWidgets('invalid card number and expired date are rejected', (
    tester,
  ) async {
    await _openWallet(tester);
    await tester.tap(find.text('إضافة بطاقة بنكية'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('رقم البطاقة'), '4242424242424241');
    await tester.enterText(_field('تاريخ الانتهاء'), '0120');
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ البطاقة'));
    await tester.pump();

    expect(find.text('رقم البطاقة غير صحيح'), findsOneWidget);
    expect(find.text('البطاقة منتهية'), findsOneWidget);
  });

  testWidgets('guests are asked to log in for balance and cards', (
    tester,
  ) async {
    await _openWallet(tester, signedIn: false);

    expect(find.text('سجل دخولك لعرض رصيدك'), findsOneWidget);
    await tester.tap(find.text('إضافة بطاقة بنكية'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
