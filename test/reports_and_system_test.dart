import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/data/report_service.dart';
import 'package:safeer_market/features/admin/data/system_admin_service.dart';
import 'package:safeer_market/features/admin/domain/admin_permissions.dart';
import 'package:safeer_market/features/admin/domain/order_rating.dart';
import 'package:safeer_market/features/admin/domain/reports.dart';
import 'package:safeer_market/features/admin/presentation/providers/phone_order_providers.dart';
import 'package:safeer_market/features/admin/presentation/providers/system_admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/admin_reports_view.dart';
import 'package:safeer_market/features/admin/presentation/screens/admin_system_view.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

// ------------------------------------------------------------------ fakes

class _FakeReports implements ReportDataSource {
  _FakeReports(this.orderRows, {this.ratingRows = const []});

  final List<Map<String, dynamic>> orderRows;
  final List<Map<String, dynamic>> itemRows = const [];
  final List<OrderRating> ratingRows;
  final requested = <ReportFilters>[];

  @override
  Future<List<Map<String, dynamic>>> orders(ReportFilters filters) async {
    requested.add(filters);
    return orderRows;
  }

  @override
  Future<List<Map<String, dynamic>>> orderItems(List<String> orderIds) async =>
      itemRows;

  @override
  Future<List<OrderRating>> orderRatings(ReportFilters filters) async {
    requested.add(filters);
    return ratingRows;
  }
}

class _FakeService implements SystemAdminService {
  _FakeService({
    this.permissions = const {},
    List<AdminCustomer>? customers,
    List<DeliveryZone>? zoneRows,
    List<DashboardUser>? users,
  })  : customerRows = customers ?? [],
        zoneRows = zoneRows ?? [],
        userRows = users ?? [];

  final Set<String> permissions;
  final List<AdminCustomer> customerRows;
  final List<DeliveryZone> zoneRows;
  final List<DashboardUser> userRows;
  final staffRows = <StaffMember>[];
  final deletedCustomers = <int>[];
  final savedZones = <String>[];
  final savedPermissions = <String, Set<String>>{};

  @override
  Future<List<AdminCustomer>> searchCustomers(String query) async => [
        for (final c in customerRows)
          if (query.isEmpty ||
              c.name.contains(query) ||
              (c.phone ?? '').contains(query))
            c,
      ];

  @override
  Future<void> deleteCustomer(int id) async {
    deletedCustomers.add(id);
    customerRows.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<StaffMember>> staff({List<String>? roles}) async {
    final filter = roles;
    if (filter == null) return staffRows;
    return [
      for (final s in staffRows)
        if (filter.contains(s.role)) s,
    ];
  }

  @override
  Future<void> addStaff({
    required String name,
    required String role,
    required String phone,
    required String username,
    required String password,
    String? profileId,
  }) async {
    staffRows.add(StaffMember(
      id: '${staffRows.length + 1}',
      name: name,
      role: role,
      phone: phone,
      username: username,
      profileId: profileId,
    ));
  }

  @override
  Future<void> updateStaff({
    required String id,
    String? name,
    String? phone,
    String? username,
    String? password,
  }) async {
    final index = staffRows.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final current = staffRows[index];
    staffRows[index] = StaffMember(
      id: current.id,
      name: name ?? current.name,
      role: current.role,
      phone: phone ?? current.phone,
      username: username ?? current.username,
      profileId: current.profileId,
      isActive: current.isActive,
    );
  }

  @override
  Future<void> setStaffActive({
    required String id,
    required bool active,
  }) async {
    final index = staffRows.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final current = staffRows[index];
    staffRows[index] = StaffMember(
      id: current.id,
      name: current.name,
      role: current.role,
      phone: current.phone,
      username: current.username,
      profileId: current.profileId,
      isActive: active,
    );
  }

  @override
  Future<void> deleteStaff(String id) async =>
      staffRows.removeWhere((s) => s.id == id);

  @override
  Future<List<DashboardUser>> dashboardUsers() async => userRows;

  @override
  Future<List<AccountMatch>> findAccounts(String query) async => const [];

  @override
  Future<void> setUserRole({
    required String userId,
    required String role,
    String? fullName,
    bool disabled = false,
  }) async {}

  @override
  Future<Set<String>> myPermissions() async => permissions;

  @override
  Future<Set<String>> permissionsOf(String userId) async =>
      savedPermissions[userId] ?? {AdminPermission.viewReports.key};

  @override
  Future<void> setPermissions(String userId, Set<String> permissions) async {
    savedPermissions[userId] = permissions;
  }

  @override
  Future<List<DeliveryZone>> zones() async => zoneRows;

  @override
  Future<void> saveZone({
    required String fujitsuZoneId,
    required bool isNew,
    required String governorate,
    required String city,
    required String name,
    double? deliveryFee,
    bool isActive = true,
  }) async {
    savedZones.add('$fujitsuZoneId/$governorate/$city/$name/$deliveryFee');
    zoneRows.add(DeliveryZone(
      fujitsuZoneId: fujitsuZoneId,
      governorate: governorate,
      city: city,
      name: name,
      deliveryFee: deliveryFee,
      isActive: isActive,
    ));
  }

  @override
  Future<void> deleteZone(String fujitsuZoneId) async =>
      zoneRows.removeWhere((z) => z.fujitsuZoneId == fujitsuZoneId);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required UserRole role,
  required _FakeService service,
  ReportDataSource? reports,
  double width = 1300,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      userRoleProvider.overrideWith((ref) async => role),
      systemAdminServiceProvider.overrideWithValue(service),
      if (reports != null) reportDataSourceProvider.overrideWithValue(reports),
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
      home: Scaffold(body: child),
    ),
  ));
  await tester.pumpAndSettle();
}

// ------------------------------------------------------------------- data

final _now = DateTime(2026, 11, 19, 12);

Map<String, dynamic> _order(
  String id, {
  String status = 'delivered',
  double total = 100,
  double fee = 10,
  String? taker = 'منى',
  String? preparer = 'أحمد',
  String? driver = 'سمير',
  String phone = '01000000001',
  String customer = 'علي',
  Duration prep = const Duration(minutes: 10),
  Duration delivery = const Duration(minutes: 40),
}) {
  final created = _now.subtract(const Duration(hours: 2));
  return {
    'id': id,
    'status': status,
    'total_amount': total,
    'delivery_fee': fee,
    'taker_name': taker,
    'preparer_name': preparer,
    'driver_name': driver,
    'customer_phone': phone,
    'customer_name': customer,
    'created_at': created.toIso8601String(),
    'prep_completed_at': created.add(prep).toIso8601String(),
    'updated_at': created.add(delivery).toIso8601String(),
  };
}

String _stat(ReportTable t, String label) =>
    t.summary.firstWhere((s) => s.label == label).value;

void main() {
  group('ReportFilters', () {
    test('limitedTo drops filters the report does not use', () {
      final filters = ReportFilters.today()
          .copyWith(preparer: 'أحمد', driver: 'سمير', status: 'delivered');
      final limited = filters.limitedTo(ReportKind.drivers.filters);
      expect(limited.driver, 'سمير');
      expect(limited.status, 'delivered');
      expect(limited.preparer, isNull);
    });

    test('each report kind exposes date and status filters', () {
      for (final kind in ReportKind.values) {
        expect(kind.filters, contains(ReportFilter.date));
        expect(kind.filters, contains(ReportFilter.status));
      }
      expect(ReportKind.values.length, 8);
    });
  });

  group('buildReport', () {
    final orders = [
      _order('a1', total: 100, fee: 10),
      _order('a2', total: 200, fee: 10, taker: 'منى', preparer: 'ليلى'),
      _order('a3',
          status: 'cancelled', total: 50, taker: 'كريم', driver: 'سمير'),
      _order('a4',
          status: 'pending',
          total: 70,
          driver: null,
          phone: '01000000002',
          customer: 'هدى'),
    ];

    test('delivery orders: counts, sales exclude cancelled, one row each', () {
      final t = buildReport(ReportKind.deliveryOrders, orders, now: _now);
      expect(t.rows.length, 4);
      expect(_stat(t, 'عدد الطلبات'), '4');
      expect(_stat(t, 'ملغي'), '1');
      expect(_stat(t, 'مكتمل'), '2');
      expect(_stat(t, 'إجمالي المبيعات'), contains('370'));
      for (final row in t.rows) {
        expect(row.length, t.columns.length);
      }
    });

    test('delivery items: aggregates per product and skips cancelled', () {
      final t = buildReport(
        ReportKind.deliveryItems,
        orders,
        now: _now,
        items: [
          {
            'order_id': 'a1',
            'product_id': 1,
            'quantity': 2,
            'price_at_time': 10,
            'products': {'name': 'لبن', 'barcode': '111'},
          },
          {
            'order_id': 'a2',
            'product_id': 1,
            'quantity': 3,
            'price_at_time': 10,
            'products': {'name': 'لبن', 'barcode': '111'},
          },
          {
            'order_id': 'a3',
            'product_id': 2,
            'quantity': 9,
            'price_at_time': 5,
            'products': {'name': 'جبن', 'barcode': '222'},
          },
        ],
      );
      expect(t.rows.length, 1);
      expect(t.rows.single.first, 'لبن');
      expect(t.rows.single[2], '2'); // two orders
      expect(t.rows.single[3], '5'); // 2 + 3
      expect(_stat(t, 'عدد الأصناف'), '1');
    });

    test('receivers: grouped by taker with sales per taker', () {
      final t = buildReport(ReportKind.receivers, orders, now: _now);
      final names = t.rows.map((r) => r.first).toList();
      expect(names, containsAll(['منى', 'كريم']));
      final mona = t.rows.firstWhere((r) => r.first == 'منى');
      expect(mona[1], '3'); // a1, a2, a4
      expect(_stat(t, 'عدد المتلقين'), '2');
    });

    test('preparers: average prep time from prep_completed_at', () {
      final t = buildReport(ReportKind.preparers, orders, now: _now);
      final ahmed = t.rows.firstWhere((r) => r.first == 'أحمد');
      expect(ahmed[1], '3');
      expect(ahmed.join(' '), contains('10'));
      expect(_stat(t, 'عدد المحضرين'), '2');
    });

    test('drivers: delivered counts and orders without a driver are skipped',
        () {
      final t = buildReport(ReportKind.drivers, orders, now: _now);
      expect(t.rows.length, 1);
      final row = t.rows.single;
      expect(row.first, 'سمير');
      expect(row[1], '3'); // assigned
      expect(row[2], '2'); // delivered
      expect(row[3], '1'); // cancelled
    });

    test('follow up: a count per status', () {
      final t = buildReport(ReportKind.followUp, orders, now: _now);
      expect(_stat(t, 'الإجمالي'), '4');
      expect(_stat(t, 'جديد'), '1');
      expect(_stat(t, 'مكتمل'), '2');
      expect(_stat(t, 'ملغي'), '1');
      expect(t.rows.length, 4);
    });

    test('customers: grouped by phone, biggest spender first', () {
      final t = buildReport(ReportKind.customers, orders, now: _now);
      expect(t.rows.length, 2);
      expect(t.rows.first.first, 'علي');
    });

    test('empty input builds an empty table for every kind', () {
      for (final kind in ReportKind.values) {
        final t = buildReport(kind, const [], now: _now);
        expect(t.title, kind.label);
        expect(t.rows, isEmpty);
      }
    });
  });

  group('zones feed the address dropdowns', () {
    test('active zones become governorate → cities', () async {
      final container = ProviderContainer(overrides: [
        systemAdminServiceProvider.overrideWithValue(_FakeService(zoneRows: [
          const DeliveryZone(
              fujitsuZoneId: 'F1', governorate: 'الجيزة', city: 'الدقي', name: 'أ'),
          const DeliveryZone(
              fujitsuZoneId: 'F2', governorate: 'الجيزة', city: 'الدقي', name: 'ب'),
          const DeliveryZone(
              fujitsuZoneId: 'F3', governorate: 'الجيزة', city: 'المهندسين', name: 'ج'),
          const DeliveryZone(
              fujitsuZoneId: 'F4',
              governorate: 'الإسكندرية',
              city: 'سموحة',
              name: 'د',
              isActive: false),
        ])),
      ]);
      addTearDown(container.dispose);
      final geo = await container.read(phoneOrderGeoProvider.future);
      expect(geo.governorates, ['الجيزة']);
      expect(geo.citiesOf('الجيزة'), ['الدقي', 'المهندسين']);
    });

    test('without zones the Cairo defaults remain', () async {
      final container = ProviderContainer(overrides: [
        systemAdminServiceProvider.overrideWithValue(_FakeService()),
      ]);
      addTearDown(container.dispose);
      final geo = await container.read(phoneOrderGeoProvider.future);
      expect(geo.governorates, ['القاهرة']);
      expect(geo.citiesOf('القاهرة'), contains('مدينة نصر'));
    });
  });

  group('AdminReportsView', () {
    testWidgets('lists the 7 reports and shows the filters of each',
        (tester) async {
      await _pump(
        tester,
        const AdminReportsView(),
        role: UserRole.admin,
        service: _FakeService(),
        reports: _FakeReports([]),
      );

      for (var i = 0; i < 7; i++) {
        expect(find.byKey(Key('report-menu-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('report-run')), findsOneWidget);
      expect(find.text('عرض التقرير'), findsOneWidget);

      // طلبات التوصيل: every filter.
      expect(find.byKey(const Key('report-preparer')), findsOneWidget);
      expect(find.byKey(const Key('report-receiver')), findsOneWidget);
      expect(find.byKey(const Key('report-driver')), findsOneWidget);
      expect(find.byKey(const Key('report-status')), findsOneWidget);
      expect(find.byKey(const Key('report-from')), findsOneWidget);

      // إنتاجية الطيارين: date, driver, status only.
      await tester.tap(find.byKey(const Key('report-menu-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('report-driver')), findsOneWidget);
      expect(find.byKey(const Key('report-preparer')), findsNothing);
      expect(find.byKey(const Key('report-receiver')), findsNothing);
    });

    testWidgets('«عرض التقرير» renders the summary and table', (tester) async {
      final source = _FakeReports([
        _order('a1', total: 120),
        _order('a2', total: 80, status: 'cancelled'),
      ]);
      await _pump(
        tester,
        const AdminReportsView(),
        role: UserRole.admin,
        service: _FakeService(),
        reports: source,
      );

      expect(find.byKey(const Key('report-result')), findsNothing);
      await tester.tap(find.byKey(const Key('report-run')));
      await tester.pumpAndSettle();

      expect(source.requested, hasLength(1));
      expect(find.byKey(const Key('report-result')), findsOneWidget);
      expect(find.byKey(const Key('report-title')), findsOneWidget);
      expect(find.byKey(const Key('report-summary')), findsOneWidget);
      expect(find.byKey(const Key('report-row-count')), findsOneWidget);
    });

    testWidgets('a user without view_reports sees a locked message',
        (tester) async {
      await _pump(
        tester,
        const AdminReportsView(),
        role: UserRole.customer,
        service: _FakeService(permissions: const {}),
        reports: _FakeReports([]),
      );
      expect(find.byKey(const Key('admin-locked-section')), findsOneWidget);
      expect(find.byKey(const Key('report-run')), findsNothing);
    });

    testWidgets('a granted view_reports permission opens the reports',
        (tester) async {
      await _pump(
        tester,
        const AdminReportsView(),
        role: UserRole.customer,
        service:
            _FakeService(permissions: {AdminPermission.viewReports.key}),
        reports: _FakeReports([]),
      );
      expect(find.byKey(const Key('report-run')), findsOneWidget);
    });
  });

  group('AdminSystemView', () {
    testWidgets('admin sees all 6 sections including الصلاحيات',
        (tester) async {
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: _FakeService(),
      );
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('system-menu-$i')), findsOneWidget);
      }
      expect(find.text('الصلاحيات'), findsWidgets);
    });

    testWidgets('non-admins do not get الصلاحيات', (tester) async {
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.customer,
        service: _FakeService(permissions: const {}),
      );
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('system-menu-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('system-menu-5')), findsNothing);
      expect(find.text('الصلاحيات'), findsNothing);
    });

    testWidgets('customers: search, details, delete with confirmation',
        (tester) async {
      final service = _FakeService(customers: [
        const AdminCustomer(
          id: 7,
          name: 'منى حسن',
          phone: '01012345678',
          address: 'مدينة نصر',
          ordersCount: 0,
        ),
        const AdminCustomer(id: 8, name: 'كريم', phone: '01199999999'),
      ]);
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
      );

      expect(find.byKey(const Key('customer-7')), findsOneWidget);
      expect(find.byKey(const Key('customer-8')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('customers-search')), '0101');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-7')), findsOneWidget);
      expect(find.byKey(const Key('customer-8')), findsNothing);

      await tester.tap(find.byKey(const Key('customer-7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-details')), findsOneWidget);

      await tester.tap(find.byKey(const Key('customer-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();

      expect(service.deletedCustomers, [7]);
      expect(find.byKey(const Key('customer-7')), findsNothing);
    });

    testWidgets('customers: no delete button without the permission',
        (tester) async {
      final service = _FakeService(
        permissions: {AdminPermission.manageCustomers.key},
        customers: [const AdminCustomer(id: 7, name: 'منى', phone: '010')],
      );
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.customer,
        service: service,
      );
      await tester.tap(find.byKey(const Key('customer-7')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-details')), findsOneWidget);
      expect(find.byKey(const Key('customer-delete')), findsNothing);
      expect(find.byKey(const Key('customers-add')), findsOneWidget);
    });

    testWidgets('preparers: add and delete', (tester) async {
      final service = _FakeService();
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
      );
      await tester.tap(find.byKey(const Key('system-menu-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('staff-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('staff-name')), 'أحمد');
      await tester.enterText(find.byKey(const Key('staff-phone')), '01012345678');
      await tester.enterText(find.byKey(const Key('staff-username')), 'ahmed');
      await tester.enterText(find.byKey(const Key('staff-password')), '1234');
      await tester.tap(find.byKey(const Key('staff-save')));
      await tester.pumpAndSettle();

      expect(service.staffRows.single.role, 'preparer');
      expect(find.byKey(const Key('staff-1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('staff-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-ok')));
      await tester.pumpAndSettle();
      expect(service.staffRows, isEmpty);
    });

    testWidgets('preparers: productivity report of one preparer',
        (tester) async {
      final service = _FakeService();
      service.staffRows
          .add(const StaffMember(id: '1', name: 'أحمد', role: 'preparer'));
      final reports = _FakeReports([_order('a1'), _order('a2')]);
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
        reports: reports,
      );
      await tester.tap(find.byKey(const Key('system-menu-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staff-report-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('staff-report-dialog')), findsOneWidget);
      expect(reports.requested.single.preparer, 'أحمد');
      expect(find.byKey(const Key('report-result')), findsOneWidget);
    });

    testWidgets('drivers: only drivers are listed', (tester) async {
      final service = _FakeService();
      service.staffRows.addAll(const [
        StaffMember(id: '1', name: 'محضر', role: 'preparer'),
        StaffMember(id: '2', name: 'طيار', role: 'driver'),
      ]);
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
      );
      await tester.tap(find.byKey(const Key('system-menu-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staff-2')), findsOneWidget);
      expect(find.byKey(const Key('staff-1')), findsNothing);
    });

    testWidgets('zones: add a zone with its delivery fee', (tester) async {
      final service = _FakeService(zoneRows: [
        const DeliveryZone(
          fujitsuZoneId: 'F1',
          governorate: 'القاهرة',
          city: 'مدينة نصر',
          name: 'الحي الثامن',
          deliveryFee: 20,
        ),
      ]);
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
      );
      await tester.tap(find.byKey(const Key('system-menu-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('zone-F1')), findsOneWidget);
      expect(find.textContaining('Fujitsu: F1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('zones-add')));
      await tester.pumpAndSettle();
      // A Fujitsu id that is already used is refused.
      await tester.enterText(find.byKey(const Key('zone-fujitsu-id')), 'F1');
      await tester.tap(find.byKey(const Key('zone-save')));
      await tester.pumpAndSettle();
      expect(find.text('الرقم مستخدم لمنطقة أخرى'), findsOneWidget);
      expect(service.savedZones, isEmpty);

      await tester.enterText(find.byKey(const Key('zone-fujitsu-id')), 'F9');
      await tester.enterText(
          find.byKey(const Key('zone-governorate')), 'القاهرة');
      await tester.enterText(find.byKey(const Key('zone-city')), 'التجمع');
      await tester.enterText(find.byKey(const Key('zone-name')), 'الأندلس');
      await tester.enterText(find.byKey(const Key('zone-fee')), '35');
      await tester.tap(find.byKey(const Key('zone-save')));
      await tester.pumpAndSettle();

      expect(service.savedZones, ['F9/القاهرة/التجمع/الأندلس/35.0']);
      expect(find.text('الأندلس'), findsOneWidget);
    });

    testWidgets('permissions: toggle and save for a user', (tester) async {
      final service = _FakeService(users: const [
        DashboardUser(id: 'u1', role: 'cashier', name: 'منى'),
        DashboardUser(id: 'u2', role: 'admin', name: 'المدير'),
      ]);
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.admin,
        service: service,
      );
      await tester.tap(find.byKey(const Key('system-menu-5')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('permission-user-u1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('permissions-editor')), findsOneWidget);

      final deleteSwitch = find.byKey(const Key('permission-delete_customers'));
      expect(tester.widget<SwitchListTile>(deleteSwitch).value, isFalse);
      await tester.tap(deleteSwitch);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('permissions-save')));
      await tester.pumpAndSettle();

      expect(service.savedPermissions['u1'],
          {'view_reports', 'delete_customers'});

      // An administrator's permissions are fixed.
      await tester.tap(find.byKey(const Key('permission-user-u2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('permissions-admin-note')), findsOneWidget);
      expect(find.byKey(const Key('permissions-save')), findsNothing);
    });

    testWidgets('users: locked without manage_users', (tester) async {
      await _pump(
        tester,
        const AdminSystemView(),
        role: UserRole.customer,
        service: _FakeService(permissions: {AdminPermission.viewReports.key}),
      );
      await tester.tap(find.byKey(const Key('system-menu-3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-locked-section')), findsOneWidget);
    });
  });
}
