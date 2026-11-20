import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/checkout/domain/scanned_card.dart';
import 'package:safeer_market/features/checkout/presentation/screens/payment_screen.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

String _text(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(_field(label)).controller!.text;

Future<void> _pumpPayment(WidgetTester tester) async {
  tester.view.physicalSize = const Size(450, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentScreen(amount: 42.5),
      ),
    ),
  );
}

void main() {
  group('ScannedCard.fromRaw', () {
    test('normalizes number, expiry and name', () {
      final card = ScannedCard.fromRaw(
        number: '4242 4242-4242 4242',
        expiry: '3/2031',
        holderName: '  amr   ahmed ',
      )!;
      expect(card.number, '4242424242424242');
      expect(card.expiry, '03/31');
      expect(card.holderName, 'AMR AHMED');
    });

    test('drops fields it cannot use', () {
      final card = ScannedCard.fromRaw(
        number: '5173949117389006',
        expiry: '13/26',
        holderName: ' ',
      )!;
      expect(card.expiry, isNull);
      expect(card.holderName, isNull);
      expect(ScannedCard.fromRaw(number: '1234'), isNull);
    });
  });

  testWidgets('card form has no camera scan button', (tester) async {
    await _pumpPayment(tester);

    expect(find.byTooltip('مسح البطاقة بالكاميرا'), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    expect(_field('رقم البطاقة'), findsOneWidget);
  });

  testWidgets('manual entry fills card number via autofill-ready field', (
    tester,
  ) async {
    await _pumpPayment(tester);

    await tester.enterText(_field('رقم البطاقة'), '4242424242424242');
    await tester.pump();

    expect(_text(tester, 'رقم البطاقة'), '4242 4242 4242 4242');
  });
}
