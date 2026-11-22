import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'package:safeer_market/features/home/presentation/screens/product_list_screen.dart';
import 'package:safeer_market/features/magazines/presentation/providers/magazines_provider.dart';
import 'package:safeer_market/features/magazines/presentation/screens/magazines_screen.dart';
import 'package:safeer_market/features/notifications/domain/entities/app_notification.dart';
import 'package:safeer_market/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:safeer_market/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:safeer_market/features/notifications/presentation/widgets/notification_card.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/support/presentation/providers/support_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

AppNotification _notification(
  String id, {
  required Duration age,
  AppNotificationType type = AppNotificationType.general,
  String? title,
  String? targetUserId,
}) =>
    AppNotification(
      id: id,
      title: title ?? 'إشعار $id',
      body: 'تفاصيل $id',
      type: type,
      targetUserId: targetUserId,
      createdAt: DateTime.now().subtract(age),
    );

bool _redDotShown(WidgetTester tester) => tester
    .widget<Badge>(find.byKey(const Key('home-notifications-dot')))
    .isLabelVisible;

Future<void> _openHome(
  WidgetTester tester, {
  List<AppNotification> notifications = const [],
  FakeNotificationsRepository? repository,
  Map<String, Object> preferences = const {},
}) async {
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    notificationsRepository:
        repository ?? FakeNotificationsRepository(notifications),
    preferences: preferences,
    overrides: [magazinesProvider.overrideWith((ref) async => const [])],
  );
  await skipSplash(tester);
}

Future<void> _tapBell(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-notifications')));
  await tester.pumpAndSettle();
}

void main() {
  group('home bell', () {
    testWidgets('no red dot and an empty state when there is nothing new', (
      tester,
    ) async {
      await _openHome(tester);
      expect(_redDotShown(tester), isFalse);

      await _tapBell(tester);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
      expect(find.text('لا توجد إشعارات جديدة'), findsOneWidget);
      expect(find.text('سنقوم بإشعارك فور توفر عروض أو مجلات جديدة من سفير ماركت'),
          findsOneWidget);
    });

    testWidgets('a new notification lights the dot until the list is opened', (
      tester,
    ) async {
      await _openHome(tester, notifications: [
        _notification('offer',
            age: const Duration(hours: 2, minutes: 5),
            type: AppNotificationType.promo,
            title: 'خصم 20% على الألبان'),
      ]);
      expect(_redDotShown(tester), isTrue);

      await _tapBell(tester);
      expect(find.text('خصم 20% على الألبان'), findsOneWidget);
      expect(find.text('منذ ساعتين'), findsOneWidget);
      expect(find.text('عروض وخصومات'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(_redDotShown(tester), isFalse);

      final prefs = await SharedPreferences.getInstance();
      final saved = DateTime.parse(
          prefs.getString(NotificationPrefsKeys.lastReadAt)!);
      expect(DateTime.now().difference(saved).inMinutes, 0);
    });

    testWidgets('notifications read on an earlier visit leave no dot', (
      tester,
    ) async {
      await _openHome(
        tester,
        notifications: [_notification('old', age: const Duration(days: 1))],
        preferences: {
          NotificationPrefsKeys.lastReadAt: DateTime.now()
              .subtract(const Duration(hours: 1))
              .toUtc()
              .toIso8601String(),
        },
      );

      expect(_redDotShown(tester), isFalse);
    });

    testWidgets('a notification sent while the app is open lights the dot', (
      tester,
    ) async {
      final repository = FakeNotificationsRepository();
      await _openHome(tester, repository: repository);
      expect(_redDotShown(tester), isFalse);

      repository.push(_notification('live', age: Duration.zero));
      await tester.pumpAndSettle();

      expect(_redDotShown(tester), isTrue);
    });

    testWidgets("other customers' notifications are not shown", (
      tester,
    ) async {
      await _openHome(tester, notifications: [
        _notification('mine',
            age: const Duration(minutes: 5),
            type: AppNotificationType.order,
            targetUserId: testUser.id),
        _notification('theirs',
            age: const Duration(minutes: 1), targetUserId: 'someone-else'),
      ]);

      await _tapBell(tester);

      expect(find.text('إشعار mine'), findsOneWidget);
      expect(find.text('إشعار theirs'), findsNothing);
    });
  });

  group('opening a notification', () {
    testWidgets('a magazine notification opens «المجلات»', (tester) async {
      await _openHome(tester, notifications: [
        _notification('mag',
            age: const Duration(minutes: 3),
            type: AppNotificationType.magazine),
      ]);
      await _tapBell(tester);

      await tester.tap(find.byKey(const Key('notification-mag')));
      await tester.pumpAndSettle();

      expect(find.byType(MagazinesScreen), findsOneWidget);
    });

    testWidgets('a promo notification opens the offers', (tester) async {
      await _openHome(tester, notifications: [
        _notification('promo',
            age: const Duration(minutes: 3), type: AppNotificationType.promo),
      ]);
      await _tapBell(tester);

      await tester.tap(find.byKey(const Key('notification-promo')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductListScreen), findsOneWidget);
      expect(find.text('العروض'), findsOneWidget);
    });
  });

  test('relative times read naturally in Arabic', () {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    final now = DateTime(2026, 11, 14, 20);
    String ago(Duration age) =>
        notificationTimeAgo(l10n, now.subtract(age), now: now);

    expect(ago(const Duration(seconds: 20)), 'الآن');
    expect(ago(const Duration(minutes: 1)), 'منذ دقيقة');
    expect(ago(const Duration(minutes: 5)), 'منذ 5 دقائق');
    expect(ago(const Duration(minutes: 45)), 'منذ 45 دقيقة');
    expect(ago(const Duration(hours: 2)), 'منذ ساعتين');
    expect(ago(const Duration(days: 3)), 'منذ 3 أيام');
  });

  group('admin «إرسال إشعارات»', () {
    Future<FakeNotificationsRepository> openPanel(
      WidgetTester tester, {
      List<AppNotification> sent = const [],
    }) async {
      tester.view.physicalSize = const Size(1500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeNotificationsRepository(sent);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          overrideStaffSession(),
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(user: testUser)),
          userRoleProvider.overrideWith((ref) async => UserRole.admin),
          liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier(const <Map<String, dynamic>>[])),
          adminOrdersRepositoryProvider
              .overrideWithValue(FakeAdminOrdersRepository()),
          supportRepositoryProvider.overrideWithValue(FakeSupportRepository()),
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const UnifiedDashboardScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-menu-7')));
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('broadcasts a magazine notification to every customer', (
      tester,
    ) async {
      final repository = await openPanel(tester);
      expect(find.text('لم يتم إرسال أي إشعارات بعد'), findsOneWidget);

      await tester.tap(find.byKey(const Key('send-notification')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب عنوان الإشعار'), findsOneWidget);
      expect(repository.broadcasts, isEmpty);

      await tester.enterText(find.byKey(const Key('notification-title-field')),
          'مجلة عروض الشهر نزلت الآن! 🔥');
      await tester.enterText(find.byKey(const Key('notification-body-field')),
          'تصفح أحدث العروض والخصومات الحصرية في سفير ماركت');
      await tester.tap(find.byKey(const Key('notification-type-magazine')));
      await tester.enterText(
          find.byKey(const Key('notification-image-field')), 'not a link');
      await tester.tap(find.byKey(const Key('send-notification')));
      await tester.pumpAndSettle();
      expect(find.text('أدخل رابطاً صحيحاً يبدأ بـ https://'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('notification-image-field')),
          'https://example.com/magazine.jpg');
      await tester.tap(find.byKey(const Key('send-notification')));
      await tester.pumpAndSettle();

      expect(repository.broadcasts.single, (
        title: 'مجلة عروض الشهر نزلت الآن! 🔥',
        body: 'تصفح أحدث العروض والخصومات الحصرية في سفير ماركت',
        type: AppNotificationType.magazine,
        imageUrl: 'https://example.com/magazine.jpg',
      ));
      expect(find.text('تم إرسال الإشعار لجميع العملاء'), findsOneWidget);
      expect(find.byKey(const Key('notification-sent-1')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
                find.byKey(const Key('notification-title-field')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('deletes a sent notification after confirming', (
      tester,
    ) async {
      final repository = await openPanel(tester, sent: [
        _notification('old', age: const Duration(days: 2), title: 'عرض قديم'),
      ]);
      expect(find.text('عرض قديم'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete-notification-old')));
      await tester.pumpAndSettle();
      expect(find.textContaining('«عرض قديم»'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('حذف')));
      await tester.pumpAndSettle();

      expect(repository.deleted, ['old']);
      expect(find.text('عرض قديم'), findsNothing);
      expect(find.text('لم يتم إرسال أي إشعارات بعد'), findsOneWidget);
    });
  });
}
