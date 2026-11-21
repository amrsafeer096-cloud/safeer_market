import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/support/domain/entities/support_chat.dart';
import 'package:safeer_market/features/support/presentation/providers/support_providers.dart';
import 'package:safeer_market/features/support/presentation/screens/customer_support_chat_screen.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _monaId = '6f1c2a9e-3b7d-4e21-9a55-0c8d7e6f5a41';

/// A message in the open conversation (the chat list shows plain text).
Finder _bubble(String text) => find.widgetWithText(SelectableText, text);

void main() {
  group('customer live chat', () {
    Future<FakeSupportRepository> openLiveChat(
      WidgetTester tester, {
      FakeSupportRepository? support,
    }) async {
      final repository = support ?? FakeSupportRepository();
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        profileRepository: FakeProfileRepository(
          const UserProfile(
              id: 'user-1', fullName: 'منى حسن', phone: '01098765432'),
        ),
        supportRepository: repository,
      );
      await skipSplash(tester);
      await tester.tap(find.text('المزيد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تحدث معنا'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('contact-live-chat')));
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('opens a chat saved with the profile name and phone', (
      tester,
    ) async {
      final support = await openLiveChat(tester);

      expect(find.byType(CustomerSupportChatScreen), findsOneWidget);
      expect(find.textContaining('اكتب سؤالك أو مشكلتك'), findsOneWidget);
      expect(support.opened.single,
          (userId: 'user-1', name: 'منى حسن', phone: '01098765432'));
      expect(support.chats.single.userId, 'user-1');
    });

    testWidgets('sends messages as the customer and shows them live', (
      tester,
    ) async {
      final support = await openLiveChat(tester);
      final chatId = support.chats.single.id;

      await tester.enterText(
          find.byKey(const Key('support-message-field')), '  وين طلبي؟ ');
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();

      expect(support.sent.single,
          (chatId, 'وين طلبي؟', SupportSenderRole.customer));
      expect(find.text('وين طلبي؟'), findsOneWidget);
      expect(support.chats.single.lastMessage, 'وين طلبي؟');
      expect(support.chats.single.unreadAdminCount, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('support-message-field')))
            .controller!
            .text,
        isEmpty,
      );

      // A reply from the dashboard arrives without a refresh.
      await support.sendMessage(
        chatId: chatId,
        message: 'طلبك في الطريق',
        senderRole: SupportSenderRole.admin,
      );
      await tester.pumpAndSettle();
      expect(find.text('طلبك في الطريق'), findsOneWidget);
    });

    testWidgets('reopens the customer\'s existing open chat', (tester) async {
      final support = await openLiveChat(
        tester,
        support: FakeSupportRepository(
          chats: [
            SupportChat(
              id: 'existing',
              userId: 'user-1',
              customerName: 'منى حسن',
              updatedAt: DateTime(2026, 11, 14, 9),
            ),
          ],
          messages: {
            'existing': [
              SupportMessage(
                id: 'm1',
                chatId: 'existing',
                senderRole: SupportSenderRole.customer,
                message: 'مرحباً',
                createdAt: DateTime(2026, 11, 14, 9),
              ),
            ],
          },
        ),
      );

      expect(support.chats, hasLength(1));
      expect(find.text('مرحباً'), findsOneWidget);
    });
  });

  group('admin support center', () {
    SupportChat chat(
      String id, {
      required String name,
      required int unread,
      required String last,
      required int hour,
      String userId = 'other',
    }) =>
        SupportChat(
          id: id,
          userId: userId,
          customerName: name,
          customerPhone: '0100000000$hour',
          lastMessage: last,
          unreadAdminCount: unread,
          updatedAt: DateTime(2026, 11, 14, hour),
        );

    FakeSupportRepository supportWithChats() => FakeSupportRepository(
          chats: [
            chat('mona', name: 'منى حسن', unread: 2, last: 'الطلب ناقص',
                hour: 10, userId: _monaId),
            chat('karim', name: 'كريم علي', unread: 1, last: 'شكراً',
                hour: 11),
          ],
          messages: {
            'mona': [
              SupportMessage(
                id: 'm1',
                chatId: 'mona',
                senderRole: SupportSenderRole.customer,
                message: 'الطلب ناقص',
                createdAt: DateTime(2026, 11, 14, 10),
              ),
            ],
          },
        );

    Future<void> pumpDashboard(
      WidgetTester tester,
      FakeSupportRepository support,
    ) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          userRoleProvider.overrideWith((ref) async => UserRole.admin),
          liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier([
                {
                  'id': 'a1b2c3d4-0000-0000-0000-000000000000',
                  'user_id': _monaId,
                  'status': 'delivered',
                  'total_amount': 165,
                  'created_at': '2026-11-11T10:00:00Z',
                },
              ])),
          adminOrdersRepositoryProvider
              .overrideWithValue(FakeAdminOrdersRepository()),
          supportRepositoryProvider.overrideWithValue(support),
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
    }

    Finder badge(Key key, String count) =>
        find.descendant(of: find.byKey(key), matching: find.text(count));

    testWidgets('the menu and header badges count chats with unread messages', (
      tester,
    ) async {
      await pumpDashboard(tester, supportWithChats());

      expect(find.text('الشكاوى والمحادثات'), findsOneWidget);
      // mona + karim = 2 chats with unread (not the sum of message counts).
      expect(badge(const Key('support-menu-badge'), '2'), findsOneWidget);
      expect(badge(const Key('support-inbox'), '2'), findsOneWidget);
    });

    testWidgets('lists open chats, newest first, and replies as admin', (
      tester,
    ) async {
      final support = supportWithChats();
      await pumpDashboard(tester, support);

      await tester.tap(find.byKey(const Key('admin-menu-6')));
      await tester.pumpAndSettle();

      final karim = tester.getTopLeft(find.byKey(const Key('support-chat-karim')));
      final mona = tester.getTopLeft(find.byKey(const Key('support-chat-mona')));
      expect(karim.dy, lessThan(mona.dy));
      expect(find.text('اختر محادثة من القائمة للرد على العميل'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('support-chat-mona')));
      await tester.pumpAndSettle();

      expect(support.markedRead, ['mona']);
      expect(find.byKey(const Key('support-unread-mona')), findsNothing);
      expect(badge(const Key('support-menu-badge'), '1'), findsOneWidget);
      expect(find.byKey(const Key('support-message-m1')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('support-message-field')), 'نعتذر، سنرسل الباقي');
      await tester.tap(find.byKey(const Key('support-send')));
      await tester.pumpAndSettle();

      expect(support.sent.single,
          ('mona', 'نعتذر، سنرسل الباقي', SupportSenderRole.admin));
      expect(_bubble('نعتذر، سنرسل الباقي'), findsOneWidget);
    });

    testWidgets('latest orders opens the customer\'s order', (tester) async {
      await pumpDashboard(tester, supportWithChats());
      await tester.tap(find.byKey(const Key('admin-menu-6')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('support-chat-mona')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('support-latest-orders')));
      await tester.pumpAndSettle();
      expect(find.text('آخر طلبات منى حسن'), findsOneWidget);

      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('order-customer-name')), findsOneWidget);
    });

    testWidgets('a new customer message shows a toast that opens the chat', (
      tester,
    ) async {
      final support = supportWithChats();
      await pumpDashboard(tester, support);
      expect(find.byKey(const Key('support-toast')), findsNothing);

      await support.sendMessage(
        chatId: 'karim',
        message: 'ممكن أغير العنوان؟',
        senderRole: SupportSenderRole.customer,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('support-toast')), findsOneWidget);
      expect(find.text('رسالة جديدة من كريم علي: ممكن أغير العنوان؟'),
          findsOneWidget);
      // Still two chats with unread (mona + karim).
      expect(badge(const Key('support-inbox'), '2'), findsOneWidget);

      await tester.tap(find.text('فتح المحادثة'));
      await tester.pumpAndSettle();

      expect(support.markedRead, ['karim']);
      expect(_bubble('ممكن أغير العنوان؟'), findsOneWidget);
    });
  });
}
