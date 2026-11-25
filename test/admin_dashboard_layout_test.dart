import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/core/widgets/resizable_columns.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'package:safeer_market/features/admin/presentation/widgets/phone_order_column.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

Future<void> _pumpDashboard(WidgetTester tester,
    {required double width}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      overrideStaffSession(),
      userRoleProvider.overrideWith((ref) async => UserRole.admin),
      liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier(const <Map<String, dynamic>>[]),
      ),
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

void main() {
  testWidgets('تلقي الطلبات: wide 3-column RTL layout', (tester) async {
    await _pumpDashboard(tester, width: 1400);

    expect(find.byType(PhoneOrderColumn), findsOneWidget);
    expect(find.text('طلبات اليوم'), findsOneWidget);
    expect(find.text('الطلبات السابقة'), findsOneWidget);
    expect(find.text('أصناف العميل'), findsOneWidget);
    expect(find.text('حالة الطلب'), findsOneWidget);
    expect(find.text('تلقي الطلبات'), findsWidgets);
  });

  testWidgets('حالة الطلب: orders list + details, no phone column', (
    tester,
  ) async {
    await _pumpDashboard(tester, width: 1400);
    await tester.tap(find.byKey(const Key('admin-tab-1')));
    await tester.pumpAndSettle();

    expect(find.byType(PhoneOrderColumn), findsNothing);
    expect(find.byType(ResizableColumns), findsOneWidget);
    expect(
        find.byKey(const Key('admin-order-status-handle-0')), findsOneWidget);
    expect(find.byKey(const Key('filter-delayed')), findsOneWidget);
    expect(find.text('متأخر'), findsOneWidget);
  });

  testWidgets('☰ hides and shows the sidebar, giving content its width', (
    tester,
  ) async {
    await _pumpDashboard(tester, width: 1400);
    final sidebar = find.byKey(const Key('admin-sidebar'));
    final content = find.byType(PhoneOrderColumn);
    expect(tester.getSize(sidebar).width, 220);
    final before = tester.getSize(content).width;

    await tester.tap(find.byKey(const Key('admin-menu-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 0);
    expect(tester.getSize(content).width, before + 220);

    await tester.tap(find.byKey(const Key('admin-menu-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(sidebar).width, 220);
  });

  testWidgets('narrow screens still open تلقي الطلبات from the menu', (
    tester,
  ) async {
    await _pumpDashboard(tester, width: 1000);

    expect(find.byKey(const Key('open-phone-order')), findsNothing);
    expect(find.byType(PhoneOrderColumn), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneOrderColumn), findsNothing);
  });

  testWidgets('five main sections are tabs under the AppBar', (tester) async {
    await _pumpDashboard(tester, width: 1400);

    final tabs = find.byKey(const Key('admin-top-tabs'));
    expect(tabs, findsOneWidget);
    for (final label in const [
      'تلقي الطلبات',
      'حالة الطلب',
      'بحث',
      'التقارير واليومية',
      'إدارة النظام',
    ]) {
      expect(find.descendant(of: tabs, matching: find.text(label)),
          findsOneWidget,
          reason: label);
    }
    // Right under the AppBar.
    expect(tester.getTopLeft(tabs).dy, kToolbarHeight);

    await tester.tap(find.byKey(const Key('admin-tab-9')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-filter-bar')), findsOneWidget);
    expect(find.byType(PhoneOrderColumn), findsNothing);

    await tester.tap(find.byKey(const Key('admin-tab-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-filter-bar')), findsNothing);
  });

  testWidgets('secondary sections stay in the side menu', (tester) async {
    await _pumpDashboard(tester, width: 1400);

    final sidebar = find.byKey(const Key('admin-sidebar'));
    for (final menu in AdminMenu.secondary) {
      expect(
        find.descendant(
            of: sidebar, matching: find.byKey(Key('admin-menu-$menu'))),
        findsOneWidget,
        reason: 'menu $menu',
      );
    }
    // The main sections are not duplicated there.
    for (final menu in AdminMenu.tabs) {
      expect(
        find.descendant(
            of: sidebar, matching: find.byKey(Key('admin-menu-$menu'))),
        findsNothing,
        reason: 'menu $menu',
      );
    }
  });
}
