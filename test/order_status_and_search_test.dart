import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/data/order_search_service.dart';
import 'package:safeer_market/features/admin/domain/entities/admin_order.dart';
import 'package:safeer_market/features/admin/domain/order_prep_timer.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/providers/order_search_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'package:safeer_market/features/admin/presentation/widgets/order_status_widgets.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _customerId = '6f1c2a9e-3b7d-4e21-9a55-0c8d7e6f5a41';

String _ago(Duration age) =>
    DateTime.now().toUtc().subtract(age).toIso8601String();

Map<String, dynamic> _order(
  String id,
  String status, {
  Duration age = const Duration(minutes: 3),
  Map<String, dynamic> extra = const {},
}) =>
    {
      'id': '$id-0000-0000-0000-000000000000',
      'user_id': _customerId,
      'status': status,
      'total_amount': 165,
      'delivery_fee': 15,
      'created_at': _ago(age),
      'address_details': 'مدينة نصر',
      ...extra,
    };

Future<void> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> orders,
  List<Override> overrides = const [],
  double width = 1500,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userRoleProvider.overrideWith((ref) async => UserRole.admin),
      liveOrdersProvider.overrideWith((ref) => Stream.value(orders)),
      adminClockTicksProvider.overrideWithValue(false),
      activeStaffProvider.overrideWith((ref) async => const [
            {'id': '1', 'name': 'سيد', 'role': 'driver'},
            {'id': '2', 'name': 'علاء', 'role': 'preparer'},
          ]),
      adminOrdersRepositoryProvider.overrideWithValue(
        FakeAdminOrdersRepository(
          customers: {
            _customerId: const OrderCustomer(
              fullName: 'منى حسن',
              phone: '01098765432',
            ),
          },
          items: {
            for (final order in orders)
              order['id'] as String: const [
                AdminOrderItem(
                  id: '6221',
                  productName: 'لبن جهينة',
                  quantity: 2,
                  price: 30,
                ),
              ],
          },
        ),
      ),
      ...overrides,
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

Future<void> _openTab(WidgetTester tester, int menu) async {
  await tester.tap(find.byKey(Key('admin-tab-$menu')));
  await tester.pumpAndSettle();
}

Finder _count(String id, String value) => find.descendant(
      of: find.byKey(Key('filter-count-$id')),
      matching: find.text(value),
    );

void main() {
  group('PrepCountdown', () {
    final created = DateTime(2026, 11, 19, 12);
    PrepCountdown at(Duration elapsed) =>
        PrepCountdown.since(created, created.add(elapsed));

    test('counts down from 20:00 and picks the colour band', () {
      expect(at(Duration.zero).label, '20:00');
      expect(at(Duration.zero).band, PrepBand.green);
      expect(at(const Duration(minutes: 9, seconds: 59)).band, PrepBand.green);
      expect(at(const Duration(minutes: 10)).label, '10:00');
      expect(at(const Duration(minutes: 10)).band, PrepBand.yellow);
      expect(at(const Duration(minutes: 14, seconds: 59)).band,
          PrepBand.yellow);
      expect(at(const Duration(minutes: 15)).label, '05:00');
      expect(at(const Duration(minutes: 15)).band, PrepBand.lightRed);
      expect(at(const Duration(minutes: 20)).label, '00:00');
      expect(at(const Duration(minutes: 20)).band, PrepBand.lightRed);
      expect(at(const Duration(minutes: 20)).isOverdue, isFalse);
    });

    test('goes negative and dark red past 20 minutes', () {
      final late = at(const Duration(minutes: 20, seconds: 45));
      expect(late.label, '-00:45');
      expect(late.band, PrepBand.overdue);
      expect(late.isOverdue, isTrue);
      expect(at(const Duration(minutes: 25, seconds: 12)).label, '-05:12');
    });

    test('only new and preparing orders run the clock', () {
      final now = DateTime.now();
      Map<String, dynamic> order(String status, {Object? done}) => {
            'status': status,
            'created_at': now.subtract(const Duration(minutes: 30)).toString(),
            'prep_completed_at': done,
          };
      expect(orderIsDelayed(order('pending'), now: now), isTrue);
      expect(orderIsDelayed(order('preparing'), now: now), isTrue);
      expect(orderIsDelayed(order('ready_for_delivery'), now: now), isFalse);
      expect(orderIsDelayed(order('delivered'), now: now), isFalse);
      // The clock stops once the prep is complete.
      expect(orderIsDelayed(order('preparing', done: 'x'), now: now), isFalse);
    });
  });

  group('order search service', () {
    test('matches the order number inside the id', () {
      final order = {'id': 'a1b2c3d4-0000'};
      expect(orderMatchesNumber(order, '#a1b2'), isTrue);
      expect(orderMatchesNumber(order, 'B2C3'), isTrue);
      expect(orderMatchesNumber(order, 'zzz'), isFalse);
      expect(orderMatchesNumber(order, ''), isTrue);
    });

    test('status is searched in both spellings', () {
      expect(orderStatusSpellings('ready_for_delivery'),
          ['ready_for_delivery', 'readyForDelivery']);
      expect(orderStatusSpellings('preparing'), contains('processing'));
    });
  });

  group('حالة الطلب', () {
    testWidgets('filter tabs show how many orders each holds', (tester) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'pending'),
        _order('bbbbbb', 'pending', age: const Duration(minutes: 25)),
        _order('cccccc', 'preparing'),
        _order('dddddd', 'delivered', age: const Duration(hours: 5)),
      ]);
      await _openTab(tester, 1);

      expect(_count('all', '4'), findsOneWidget);
      expect(_count('pending', '2'), findsOneWidget);
      expect(_count('delayed', '1'), findsOneWidget);
      expect(_count('preparing', '1'), findsOneWidget);
      expect(_count('delivered', '1'), findsOneWidget);
      expect(_count('ready', '0'), findsOneWidget);
      expect(_count('cancelled', '0'), findsOneWidget);

      // Late orders show up under «متأخر».
      await tester.tap(find.byKey(const Key('filter-delayed')));
      await tester.pumpAndSettle();
      expect(find.text('#bbbbbb'), findsOneWidget);
      expect(find.text('#aaaaaa'), findsNothing);
    });

    testWidgets('new and preparing cards show a live countdown bar', (
      tester,
    ) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'pending'),
        _order('bbbbbb', 'preparing', age: const Duration(minutes: 25)),
        _order('dddddd', 'delivered', age: const Duration(hours: 5)),
      ]);
      await _openTab(tester, 1);

      final labels = tester
          .widgetList<Text>(find.byKey(const Key('prep-countdown-label')))
          .map((t) => t.data!)
          .toList();
      expect(labels, hasLength(2));
      expect(labels.any((l) => RegExp(r'^1[67]:\d\d$').hasMatch(l)), isTrue,
          reason: 'about 17:00 left for the new order: $labels');
      expect(labels.any((l) => RegExp(r'^-0[45]:\d\d$').hasMatch(l)), isTrue,
          reason: 'about 5 minutes over for the old one: $labels');
    });

    testWidgets('the wide card lists customer, staff and payment', (
      tester,
    ) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'preparing', extra: {
          'order_source': 'phone',
          'taker_name': 'ريم',
          'preparer_name': 'علاء',
          'driver_name': 'سيد',
          'payment_method': 'cash_on_delivery',
        }),
      ]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('order-info-card'));
      for (final text in const [
        'منى حسن',
        '01098765432',
        'مدينة نصر',
        'المتلقي',
        'ريم',
        'المحضر',
        'علاء',
        'الطيار',
        'سيد',
        'كاش عند الاستلام',
      ]) {
        expect(find.descendant(of: card, matching: find.text(text)),
            findsOneWidget,
            reason: text);
      }
      expect(find.byKey(const Key('order-delivery-fee')), findsOneWidget);
      expect(find.byKey(const Key('order-total')), findsOneWidget);
      expect(find.byKey(const Key('order-products-panel')), findsOneWidget);
      expect(find.byKey(const Key('order-actions-panel')), findsOneWidget);
      expect(find.text('لبن جهينة'), findsOneWidget);
    });

    testWidgets('an InstaPay order has a receipt button', (tester) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'pending', extra: {
          'payment_method': 'instapay',
          'receipt_url': 'https://example.com/r.png',
        }),
      ]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      expect(find.text('إنستا باي'), findsWidgets);
      expect(find.byKey(const Key('order-view-instapay-receipt')),
          findsOneWidget);
    });

    testWidgets('a new order offers «بدء التجهيز» first', (tester) async {
      await _pump(tester, orders: [_order('aaaaaa', 'pending')]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action-start-prep')), findsOneWidget);
      expect(find.byKey(const Key('driver-assigner')), findsNothing);
    });

    testWidgets('delivery can only start after the prep is complete', (
      tester,
    ) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'preparing', extra: {'preparer_name': 'علاء'}),
      ]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action-finish-prep')), findsOneWidget);
      expect(find.byKey(const Key('driver-assigner-locked')), findsOneWidget);
      FilledButton start() => tester.widget<FilledButton>(
          find.byKey(const Key('action-start-delivery')));
      expect(start().onPressed, isNull);
    });

    testWidgets('after the prep, picking a driver enables «بدء التوصيل»', (
      tester,
    ) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'preparing', extra: {
          'preparer_name': 'علاء',
          'prep_completed_at': _ago(const Duration(minutes: 1)),
        }),
      ]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('prep-done-banner')), findsOneWidget);
      expect(find.byKey(const Key('action-finish-prep')), findsNothing);
      expect(find.byKey(const Key('driver-assigner-locked')), findsNothing);
      // The prep clock stopped with the prep.
      expect(find.byKey(const Key('prep-countdown')), findsNothing);

      FilledButton start() => tester.widget<FilledButton>(
          find.byKey(const Key('action-start-delivery')));
      expect(start().onPressed, isNull);

      await tester.tap(find.byKey(const Key('driver-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سيد').last);
      await tester.pumpAndSettle();
      expect(start().onPressed, isNotNull);
    });

    testWidgets('«للطيار» waits for the driver to accept', (tester) async {
      await _pump(tester, orders: [
        _order('aaaaaa', 'readyForDelivery', extra: {'driver_name': 'سيد'}),
      ]);
      await _openTab(tester, 1);
      await tester.tap(find.text('#aaaaaa'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('assigned-driver-banner')), findsOneWidget);
      expect(find.byKey(const Key('action-driver-accept')), findsOneWidget);
    });
  });

  group('بحث', () {
    testWidgets('searches with the filters and shows the selected order', (
      tester,
    ) async {
      final queries = <OrderSearchQuery>[];
      final found = _order('a1b2c3', 'delivered', age: const Duration(days: 2));
      await _pump(
        tester,
        orders: [found],
        overrides: [
          orderSearchProvider.overrideWithValue((query) async {
            queries.add(query);
            return [
              found,
              _order('ffffff', 'cancelled', age: const Duration(days: 3)),
            ];
          }),
        ],
      );
      await _openTab(tester, 9);

      expect(find.byKey(const Key('search-results')), findsOneWidget);
      expect(find.byKey(const Key('search-details-empty')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('search-phone')), '01098765432');
      await tester.enterText(find.byKey(const Key('search-receiver')), 'ريم');
      await tester.tap(find.byKey(const Key('search-submit')));
      await tester.pumpAndSettle();

      expect(queries, hasLength(1));
      expect(queries.single.customerPhone, '01098765432');
      expect(queries.single.receiver, 'ريم');
      expect(queries.single.source, OrderSearchSource.all);
      expect(find.text('النتائج (2)'), findsOneWidget);

      await tester.tap(find.byKey(Key('search-result-${found['id']}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search-details')), findsOneWidget);
      expect(find.byKey(const Key('order-info-card')), findsOneWidget);
      expect(find.text('لبن جهينة'), findsOneWidget);
    });

    testWidgets('the order number narrows the results', (tester) async {
      await _pump(
        tester,
        orders: const [],
        overrides: [
          orderSearchProvider.overrideWithValue((query) async => [
                _order('a1b2c3', 'delivered'),
                _order('ffffff', 'delivered'),
              ]),
        ],
      );
      await _openTab(tester, 9);

      await tester.enterText(
          find.byKey(const Key('search-order-number')), '#a1b2');
      await tester.tap(find.byKey(const Key('search-submit')));
      await tester.pumpAndSettle();

      expect(find.text('النتائج (1)'), findsOneWidget);
      expect(find.text('#a1b2c3'), findsOneWidget);
    });

    testWidgets('no match says so', (tester) async {
      await _pump(
        tester,
        orders: const [],
        overrides: [
          orderSearchProvider.overrideWithValue((query) async => const []),
        ],
      );
      await _openTab(tester, 9);
      await tester.tap(find.byKey(const Key('search-submit')));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد طلبات مطابقة'), findsOneWidget);
    });
  });
}
