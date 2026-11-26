import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/widgets/google_logo.dart';
import 'package:safeer_market/features/auth/domain/egyptian_phone.dart';
import 'package:safeer_market/features/auth/domain/entities/app_user.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/auth/presentation/widgets/phone_auth_sheet.dart';

import 'test_helpers.dart';

const _googleUser = AppUser(
  id: 'google-1',
  email: 'amr@gmail.com',
  fullName: 'عمرو أحمد',
  avatarUrl: 'https://example.com/amr.png',
);

Future<void> _openLogin(WidgetTester tester) async {
  await skipSplash(tester);
  await tester.tap(find.widgetWithText(TextButton, 'سجل دخولك'));
  await tester.pumpAndSettle();
  expect(find.byType(AuthScreen), findsOneWidget);
}

Future<void> _openPhoneSheet(WidgetTester tester) async {
  await tester.tap(find.text('المتابعة برقم الهاتف'));
  await tester.pumpAndSettle();
  expect(find.byType(PhoneAuthSheet), findsOneWidget);
}

final _phoneOn = phoneAuthEnabledProvider.overrideWithValue(true);

Finder _sheetField() => find.descendant(
      of: find.byType(PhoneAuthSheet),
      matching: find.byType(TextField),
    );

void main() {
  testWidgets('login leads with Google and phone, email stays available', (
    tester,
  ) async {
    await pumpApp(tester, overrides: [_phoneOn]);
    await _openLogin(tester);

    expect(find.text('أهلاً بك في سفير ماركت'), findsOneWidget);
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.text('المتابعة برقم الهاتف'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'كلمة المرور'), findsNothing);
    expect(
      Directionality.of(tester.element(find.byType(AuthScreen))),
      TextDirection.rtl,
    );

    await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بعودتك!'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'كلمة المرور'), findsOneWidget);

    await tester.tap(find.text('طرق دخول أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
  });

  testWidgets('Google sign-in closes login and saves name and photo', (
    tester,
  ) async {
    final profiles = FakeProfileRepository();
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(googleUser: _googleUser),
      profileRepository: profiles,
    );
    await _openLogin(tester);

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(profiles.signInSyncs, [
      (
        userId: 'google-1',
        fullName: 'عمرو أحمد',
        phone: null,
        avatarUrl: 'https://example.com/amr.png',
      ),
    ]);
  });

  testWidgets('closing Google account picker keeps login open quietly', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openLogin(tester);

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a Google error is shown on the login screen', (tester) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(
        failure: const AuthFailure('طريقة تسجيل الدخول هذه غير متاحة حالياً'),
      ),
    );
    await _openLogin(tester);

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();

    expect(
        find.text('طريقة تسجيل الدخول هذه غير متاحة حالياً'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('phone sign-in texts a code, rejects a wrong one, then signs in',
      (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    await pumpApp(
      tester,
      authRepository: auth,
      profileRepository: profiles,
      overrides: [_phoneOn],
    );
    await _openLogin(tester);
    await _openPhoneSheet(tester);

    await tester.enterText(_sheetField(), '0101234');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pump();
    expect(find.text('أدخل رقم هاتف مصري صحيح (11 رقماً)'), findsOneWidget);
    expect(auth.codesSentTo, isEmpty);

    await tester.enterText(_sheetField(), '01012345678');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();
    expect(auth.codesSentTo, ['+201012345678']);
    expect(find.text('أدخل رمز التحقق'), findsOneWidget);
    expect(find.textContaining('01012345678'), findsOneWidget);
    expect(find.text('إعادة الإرسال بعد 60 ث'), findsOneWidget);

    // A complete code is verified without pressing the button.
    await tester.enterText(_sheetField(), '000000');
    await tester.pumpAndSettle();
    expect(find.text('الرمز غير صحيح أو انتهت صلاحيته'), findsOneWidget);
    expect(find.byType(PhoneAuthSheet), findsOneWidget);

    await tester.enterText(_sheetField(), FakeAuthRepository.validOtp);
    await tester.pumpAndSettle();

    expect(find.byType(PhoneAuthSheet), findsNothing);
    expect(find.byType(AuthScreen), findsNothing);
    expect(profiles.signInSyncs.single.userId, 'phone-user');
    expect(profiles.signInSyncs.single.phone, '01012345678');
  });

  testWidgets('the code can be resent after the countdown', (tester) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, authRepository: auth, overrides: [_phoneOn]);
    await _openLogin(tester);
    await _openPhoneSheet(tester);

    await tester.enterText(_sheetField(), '01112345678');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();

    final resend = find.widgetWithText(TextButton, 'إعادة إرسال الرمز');
    expect(resend, findsNothing);
    await tester.pump(PhoneAuthSheet.resendDelay);
    await tester.pump();
    await tester.tap(resend);
    await tester.pumpAndSettle();

    expect(auth.codesSentTo, ['+201112345678', '+201112345678']);
    expect(find.text('تم إرسال رمز جديد'), findsOneWidget);

    await tester.tap(find.text('تغيير الرقم'));
    await tester.pumpAndSettle();
    expect(find.text('إرسال الرمز'), findsOneWidget);
    expect(find.text('01112345678'), findsOneWidget);

    await tester.tap(find.byTooltip('إغلاق').last);
    await tester.pumpAndSettle();
    expect(find.byType(PhoneAuthSheet), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('an SMS failure is explained inside the sheet', (tester) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(
        failure: const AuthFailure(
          'تعذر إرسال رسالة التحقق، تأكد من الرقم وحاول مرة أخرى',
        ),
      ),
      overrides: [_phoneOn],
    );
    await _openLogin(tester);
    await _openPhoneSheet(tester);

    await tester.enterText(_sheetField(), '01012345678');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PhoneAuthSheet),
        matching: find.text(
          'تعذر إرسال رسالة التحقق، تأكد من الرقم وحاول مرة أخرى',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('إرسال الرمز'), findsOneWidget);
  });

  testWidgets('phone sign-in is hidden until an SMS provider is set up', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openLogin(tester);

    expect(find.text('المتابعة برقم الهاتف'), findsNothing);
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
    expect(find.text('المتابعة بالبريد الإلكتروني'), findsOneWidget);
  });

  test('Egyptian numbers are sent to Supabase in E.164', () {
    expect(EgyptianPhone.isValid('01040067954'), isTrue);
    expect(EgyptianPhone.toE164('01040067954'), '+201040067954');
    expect(EgyptianPhone.toLocal('201040067954'), '01040067954');
    expect(EgyptianPhone.isValidCustomerPhone('022852226'), isTrue);
    expect(EgyptianPhone.isValidCustomerPhone('2852226'), isTrue);
    expect(EgyptianPhone.isValidCustomerPhone('01040067954'), isTrue);
    expect(EgyptianPhone.isValidCustomerPhone('01999999999'), isFalse);
    expect(EgyptianPhone.isValid('022852226'), isFalse);
  });

  testWidgets('login closes when a browser sign-in comes back signed in', (
    tester,
  ) async {
    // Google in the browser: the button's future returns before the session.
    final auth = FakeAuthRepository();
    await pumpApp(tester, authRepository: auth);
    await _openLogin(tester);

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    // The deep link delivers the session.
    await auth.signIn(email: 'amr@gmail.com', password: 'unused');
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsNothing);
  });
}
