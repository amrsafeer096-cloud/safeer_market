import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/services/external_url_launcher.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:safeer_market/features/wallet/presentation/screens/wallet_screen.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<FakeProfileRepository> _openSettings(WidgetTester tester) async {
  final profiles = FakeProfileRepository(
    const UserProfile(
        id: 'user-1', fullName: 'عمرو أحمد', phone: '01012345678'),
  );
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    profileRepository: profiles,
  );
  await skipSplash(tester);
  await tester.tap(find.text('المزيد'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();
  return profiles;
}

void main() {
  testWidgets('personal data edits name and phone in profiles', (
    tester,
  ) async {
    final profiles = await _openSettings(tester);

    await tester.tap(find.text('البيانات الشخصية'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('عمرو أحمد'), findsOneWidget);

    await tester.enterText(_field('رقم الهاتف'), '123');
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pump();
    expect(find.text('أدخل رقم هاتف مصري صحيح'), findsOneWidget);

    await tester.enterText(_field('الاسم بالكامل'), 'عمرو محمود');
    await tester.enterText(_field('رقم الهاتف'), '01198765432');
    await tester.tap(find.text('حفظ التغييرات'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('تم حفظ بياناتك بنجاح'), findsOneWidget);
    expect(profiles.profile!.fullName, 'عمرو محمود');
    expect(profiles.profile!.phone, '01198765432');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بك يا عمرو محمود'), findsOneWidget);
  });

  testWidgets('email shows a read-only dialog with a support note', (
    tester,
  ) async {
    await _openSettings(tester);

    await tester.tap(find.text('البريد الإلكتروني'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('amr@example.com'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('لتغيير البريد الإلكتروني يرجى التواصل مع الدعم'),
      findsOneWidget,
    );
    await tester.tap(find.text('حسناً'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('saved cards opens the wallet', (tester) async {
    await _openSettings(tester);

    await tester.tap(find.text('البطاقات المحفوظة'));
    await tester.pumpAndSettle();

    expect(find.byType(WalletPage), findsOneWidget);
    expect(find.text('رصيد محفظتك في التطبيق'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('notification toggles keep their state for the session', (
    tester,
  ) async {
    await _openSettings(tester);

    await tester.tap(find.text('تنبيهات الرسائل والرسائل النصية'));
    await tester.pumpAndSettle();
    expect(find.text('إشعارات التطبيق'), findsOneWidget);

    SwitchListTile tile(String label) =>
        tester.widget(find.widgetWithText(SwitchListTile, label));
    expect(tile('إشعارات التطبيق').value, isTrue);
    expect(tile('رسائل SMS').value, isFalse);

    await tester.tap(find.text('رسائل SMS'));
    await tester.pumpAndSettle();
    expect(tile('رسائل SMS').value, isTrue);

    await tester.tapAt(const Offset(225, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تنبيهات الرسائل والرسائل النصية'));
    await tester.pumpAndSettle();
    expect(tile('رسائل SMS').value, isTrue);
  });

  testWidgets('language sheet offers Arabic and English', (tester) async {
    await _openSettings(tester);

    await tester.tap(find.text('اللغة'));
    await tester.pumpAndSettle();
    expect(
        find.widgetWithText(RadioListTile<String>, 'العربية'), findsOneWidget);
    expect(
        find.widgetWithText(RadioListTile<String>, 'English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('country is replaced by the privacy policy dialog', (
    tester,
  ) async {
    await _openSettings(tester);

    expect(find.text('البلد'), findsNothing);
    await tester.tap(find.text('سياسة الخصوصية والشروط'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('نحترم خصوصيتك'), findsOneWidget);
  });

  group('contact us', () {
    Future<List<Uri>> openContactSheet(WidgetTester tester) async {
      final launched = <Uri>[];
      await pumpApp(tester, overrides: [
        externalUrlLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ]);
      await skipSplash(tester);
      await tester.tap(find.text('المزيد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحدث معنا'));
      await tester.pumpAndSettle();
      return launched;
    }

    testWidgets('offers call, WhatsApp and live chat', (tester) async {
      await openContactSheet(tester);

      expect(find.widgetWithText(ListTile, 'الاتصال بنا'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'واتساب'), findsOneWidget);
      expect(
        find.widgetWithText(ListTile, 'محادثة فورية مع خدمة العملاء'),
        findsOneWidget,
      );
    });

    testWidgets('WhatsApp opens a chat with the official number', (
      tester,
    ) async {
      final launched = await openContactSheet(tester);

      await tester.tap(find.byKey(const Key('contact-whatsapp')));
      await tester.pumpAndSettle();

      expect(launched, [
        Uri.parse('https://wa.me/201066208383?text='
            '${Uri.encodeComponent('مرحباً سفير ماركت، أحتاج إلى مساعدة بخصوص...')}'),
      ]);
      expect(launched.single.queryParameters['text'],
          'مرحباً سفير ماركت، أحتاج إلى مساعدة بخصوص...');
    });

    testWidgets('call us dials the official number', (tester) async {
      final launched = await openContactSheet(tester);

      await tester.tap(find.byKey(const Key('contact-call')));
      await tester.pumpAndSettle();

      expect(launched, [Uri.parse('tel:01066208383')]);
    });

    testWidgets('explains when no app can open the link', (tester) async {
      await pumpApp(tester, overrides: [
        externalUrlLauncherProvider.overrideWithValue((uri) async => false),
      ]);
      await skipSplash(tester);
      await tester.tap(find.text('المزيد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحدث معنا'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('contact-whatsapp')));
      await tester.pumpAndSettle();

      expect(find.text('تعذر فتح التطبيق، يمكنك الاتصال بنا على 01066208383'),
          findsOneWidget);
    });
  });

  testWidgets('help links guests to the live chat after signing in', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المساعدة'));
    await tester.pumpAndSettle();
    expect(find.text('كيف يمكننا مساعدتك؟'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('تحدث معنا'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('سجّل دخولك لتبدأ محادثة مع خدمة العملاء.'),
        findsOneWidget);
  });
}
