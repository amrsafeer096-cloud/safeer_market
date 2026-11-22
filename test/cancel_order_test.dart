import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/orders/domain/entities/customer_order.dart';
import 'package:safeer_market/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/support/presentation/providers/support_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _pendingId = 'pending11-0000-0000-0000-000000000001';
const _readyId = 'ready2222-0000-0000-0000-000000000002';
const _onWayId = 'onway3333-0000-0000-0000-000000000003';

CustomerOrder _order(String id, String status) => CustomerOrder(
      id: id,
      createdAt: DateTime(2026, 11, 14, 18),
      totalAmount: 120,
      status: status,
      addressDetails: 'مدينة نصر',
    );

Future<FakeOrdersRepository> _openOrders(
  WidgetTester tester,
  List<CustomerOrder> orders, {
  Exception? cancelFailure,
}) async {
  final repository = FakeOrdersRepository(orders)..cancelFailure = cancelFailure;
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    ordersRepository: repository,
  );
  await skipSplash(tester);
  await tester.tap(find.text('المزيد'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('طلباتي'));
  await tester.pumpAndSettle();
  expect(find.byType(MyOrdersScreen), findsOneWidget);
  return repository;
}

void main() {
  group('customer cancel order', () {
    testWidgets('shows cancel only while the order is new or preparing', (
      tester,
    ) async {
      await _openOrders(tester, [
        _order(_pendingId, 'pending'),
        _order(_readyId, 'readyForDelivery'),
        _order(_onWayId, 'outForDelivery'),
      ]);

      await tester.tap(find.byKey(Key('order-card-$_pendingId')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('cancel-order-$_pendingId')), findsOneWidget);

      await tester.tap(find.byKey(Key('order-card-$_readyId')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('cancel-order-$_readyId')), findsNothing);

      // Out for delivery opens by itself.
      expect(find.byKey(Key('cancel-order-$_onWayId')), findsNothing);
      expect(find.byKey(Key('track-order-$_onWayId')), findsOneWidget);
    });

    testWidgets('confirming with a reason cancels the order live', (
      tester,
    ) async {
      final repository = await _openOrders(tester, [
        _order(_pendingId, 'preparing'),
      ]);

      await tester.tap(find.byKey(Key('order-card-$_pendingId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('cancel-order-$_pendingId')));
      await tester.pumpAndSettle();

      expect(find.text('هل أنت متأكد من إلغاء الطلب؟'), findsOneWidget);
      expect(find.byKey(const Key('cancel-order-confirm')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('cancel-order-confirm')))
            .onPressed,
        isNull,
        reason: 'confirm stays disabled until a reason is picked',
      );

      await tester.tap(find.byKey(const Key('cancel-reason-delivery_delay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-order-confirm')));
      await tester.pumpAndSettle();

      expect(repository.cancellations, [
        (_pendingId, OrderCancellationReason.deliveryDelay),
      ]);
      expect(repository.orders.single.status, 'cancelled');
      expect(find.text('تم إلغاء الطلب بنجاح'), findsOneWidget);
      expect(find.text('تم إلغاء هذا الطلب'), findsOneWidget);
      expect(find.text('سبب الإلغاء: تأخير في التوصيل'), findsOneWidget);
      expect(find.byKey(Key('cancel-order-$_pendingId')), findsNothing);
    });

    testWidgets('dismissing the dialog changes nothing', (tester) async {
      final repository = await _openOrders(tester, [
        _order(_pendingId, 'pending'),
      ]);

      await tester.tap(find.byKey(Key('order-card-$_pendingId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('cancel-order-$_pendingId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-reason-changed_mind')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cancel-order-dismiss')));
      await tester.pumpAndSettle();

      expect(repository.cancellations, isEmpty);
      expect(repository.orders.single.status, 'pending');
      expect(find.byKey(Key('cancel-order-$_pendingId')), findsOneWidget);
    });

    testWidgets('a refused cancel is explained', (tester) async {
      await _openOrders(
        tester,
        [_order(_pendingId, 'pending')],
        cancelFailure: const OrdersFailure(
            'تعذر إلغاء الطلب لأن تجهيزه اكتمل أو خرج للتوصيل'),
      );

      await tester.tap(find.byKey(Key('order-card-$_pendingId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('cancel-order-$_pendingId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-reason-other')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cancel-order-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('تعذر إلغاء الطلب لأن تجهيزه اكتمل أو خرج للتوصيل'),
        findsOneWidget,
      );
      expect(find.byKey(Key('cancel-order-$_pendingId')), findsOneWidget);
    });
  });

  group('admin cancelled order', () {
    testWidgets('shows a red ملغي pill and the cancellation reason', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          overrideStaffSession(),
          authRepositoryProvider
              .overrideWithValue(FakeAuthRepository(user: testUser)),
          userRoleProvider.overrideWith((ref) async => UserRole.admin),
          liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier([
                {
                  'id': 'a1b2c3d4-0000-0000-0000-000000000000',
                  'user_id': testUser.id,
                  'status': 'cancelled',
                  'total_amount': 165,
                  'created_at': '2026-11-11T10:00:00Z',
                  'address_details': 'مدينة نصر',
                  'cancellation_reason': 'ordered_by_mistake',
                },
              ])),
          adminOrdersRepositoryProvider
              .overrideWithValue(FakeAdminOrdersRepository()),
          supportRepositoryProvider.overrideWithValue(FakeSupportRepository()),
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
      await tester.tap(find.byKey(const Key('admin-tab-1')));
      await tester.pumpAndSettle();

      // The tab and the card's pill both read «ملغي».
      expect(find.widgetWithText(DashboardStatusBadge, 'ملغي'),
          findsOneWidget);
      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('order-cancellation-reason')), findsOneWidget);
      expect(find.text('سبب الإلغاء: طلبت بالخطأ'), findsOneWidget);
    });
  });
}
