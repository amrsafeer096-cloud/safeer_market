import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/core/notifications/new_order_notifier.dart';
import 'package:safeer_market/core/routing/app_router.dart';
import 'package:safeer_market/core/routing/app_routes.dart';
import 'package:safeer_market/features/driver/domain/entities/driver_order.dart';
import 'package:safeer_market/features/driver/domain/repositories/driver_orders_repository.dart';
import 'package:safeer_market/features/driver/domain/services/driver_location_service.dart';
import 'package:safeer_market/features/driver/presentation/screens/driver_dashboard_screen.dart';
import 'package:safeer_market/features/driver/presentation/screens/order_map_screen.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';

import 'test_helpers.dart';

/// Kilometres per degree of latitude for R = 6371 km.
const _kmPerDegree = 111.19492664455873;

final _order = DriverOrder(
  id: 'f00dcafe-1111-2222-3333-444455556666',
  createdAt: DateTime(2026, 10, 4, 18, 30),
  status: 'ready_for_delivery',
  totalAmount: 165,
  deliveryFee: 35,
  customerName: 'منى حسن',
  customerPhone: '01098765432',
  addressDetails: 'المنزل: شارع مكرم عبيد، عمارة 7 - مدينة نصر',
  latitude: StoreLocation.latitude + 2.75 / _kmPerDegree,
  longitude: StoreLocation.longitude,
);

FakeProfileRepository _driverProfile() => FakeProfileRepository(
      const UserProfile(id: 'user-1', fullName: 'كريم السائق'),
      UserRole.driver,
    );

Future<FakeDriverOrdersRepository> _openDashboard(
  WidgetTester tester, {
  DriverFailure? acceptFailure,
  FakePushNotificationService? push,
}) async {
  final orders = FakeDriverOrdersRepository(
    available: [_order],
    acceptFailure: acceptFailure,
  );
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    profileRepository: _driverProfile(),
    driverOrdersRepository: orders,
    pushNotificationService: push,
  );
  await skipSplash(tester);
  return orders;
}

void main() {
  group('role redirect', () {
    test('drivers are confined to their dashboard', () {
      expect(roleRedirect(AppRoutes.home, UserRole.driver), AppRoutes.driver);
      expect(roleRedirect(AppRoutes.cart, UserRole.driver), AppRoutes.driver);
      expect(roleRedirect(AppRoutes.driver, UserRole.driver), isNull);
      expect(roleRedirect(AppRoutes.driverMap, UserRole.driver), isNull);
    });

    test('warehouse staff are confined to their dashboard', () {
      expect(
        roleRedirect(AppRoutes.home, UserRole.warehouse),
        AppRoutes.warehouse,
      );
      expect(
        roleRedirect(AppRoutes.driver, UserRole.warehouse),
        AppRoutes.warehouse,
      );
      expect(roleRedirect(AppRoutes.warehouse, UserRole.warehouse), isNull);
      expect(
        roleRedirect(AppRoutes.goodsReceipt, UserRole.warehouse),
        isNull,
      );
      expect(
        roleRedirect(AppRoutes.warehouse, UserRole.driver),
        AppRoutes.driver,
      );
    });

    test('customers and guests are kept out of the staff areas', () {
      expect(
        roleRedirect(AppRoutes.warehouse, UserRole.customer),
        AppRoutes.home,
      );
      expect(
        roleRedirect(AppRoutes.goodsReceipt, UserRole.customer),
        AppRoutes.home,
      );
      expect(
        roleRedirect(AppRoutes.goodsReceipt, UserRole.driver),
        AppRoutes.driver,
      );
      expect(roleRedirect(AppRoutes.warehouse, null), AppRoutes.home);
      expect(roleRedirect(AppRoutes.driver, UserRole.customer), AppRoutes.home);
      expect(
          roleRedirect(AppRoutes.driverMap, UserRole.customer), AppRoutes.home);
      expect(roleRedirect(AppRoutes.driver, null), AppRoutes.home);
      expect(roleRedirect(AppRoutes.cart, UserRole.customer), isNull);
      expect(roleRedirect(AppRoutes.home, null), isNull);
    });

    test('the splash screen is never interrupted', () {
      expect(roleRedirect(AppRoutes.splash, UserRole.driver), isNull);
    });
  });

  testWidgets('a driver session opens the dashboard with ready orders', (
    tester,
  ) async {
    await _openDashboard(tester);

    expect(find.byType(DriverDashboardScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('أهلاً يا كريم السائق'), findsOneWidget);
    expect(find.text('طلبات متاحة (1)'), findsOneWidget);

    expect(find.text('طلب #f00dca'), findsOneWidget);
    expect(find.textContaining('منى حسن'), findsOneWidget);
    expect(find.textContaining('شارع مكرم عبيد'), findsOneWidget);
    expect(find.textContaining('2.8 كم من الفرع'), findsOneWidget);
    expect(find.textContaining('35.00'), findsOneWidget);
    expect(find.textContaining('165.00'), findsOneWidget);
    // The phone number stays hidden until the driver accepts.
    expect(find.textContaining('01098765432'), findsNothing);
    expect(find.text('قبول الطلب'), findsOneWidget);
    expect(find.text('عرض الخريطة والموقع'), findsOneWidget);
  });

  testWidgets('the map button opens the store and customer markers', (
    tester,
  ) async {
    await _openDashboard(tester);

    await tester.tap(find.text('عرض الخريطة والموقع'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderMapScreen), findsOneWidget);
    expect(find.byKey(const Key('store-marker')), findsOneWidget);
    expect(find.byKey(const Key('customer-marker')), findsOneWidget);
    expect(find.text('الفرع'), findsOneWidget);
    expect(find.text('العميل'), findsOneWidget);
    expect(find.text('ابدأ التوجيه'), findsOneWidget);
  });

  group('ابدأ التوجيه', () {
    Future<List<Uri>> tapNavigate(
      WidgetTester tester, {
      required Set<String> handledSchemes,
    }) async {
      final launched = <Uri>[];
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        profileRepository: _driverProfile(),
        driverOrdersRepository: FakeDriverOrdersRepository(available: [_order]),
        overrides: [
          externalUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return handledSchemes.contains(uri.scheme);
          }),
        ],
      );
      await skipSplash(tester);
      await tester.tap(find.text('عرض الخريطة والموقع'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابدأ التوجيه'));
      await tester.pumpAndSettle();
      return launched;
    }

    final lat = _order.latitude!;
    final lng = _order.longitude!;

    testWidgets('opens Google Maps turn-by-turn navigation', (tester) async {
      final launched =
          await tapNavigate(tester, handledSchemes: {'google.navigation'});
      expect(launched, [Uri.parse('google.navigation:q=$lat,$lng')]);
    });

    testWidgets('falls back to the directions link', (tester) async {
      final launched = await tapNavigate(tester, handledSchemes: {'https'});
      expect(launched, [
        Uri.parse('google.navigation:q=$lat,$lng'),
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        ),
      ]);
    });

    testWidgets('explains when nothing can open maps', (tester) async {
      final launched = await tapNavigate(tester, handledSchemes: {});
      expect(launched, hasLength(2));
      expect(find.text('تعذر فتح خرائط جوجل على هذا الجهاز'), findsOneWidget);
    });
  });

  testWidgets('accepting moves the order to «طلباتي»', (tester) async {
    final orders = await _openDashboard(tester);

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();

    expect(orders.available, isEmpty);
    expect(orders.mine.single.id, _order.id);
    expect(
        find.text('تم قبول الطلب #f00dca، تجده في «طلباتي»'), findsOneWidget);
    expect(find.text('لا توجد طلبات متاحة الآن\nاسحب للتحديث'), findsOneWidget);

    await tester.tap(find.text('طلباتي (1)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('01098765432'), findsOneWidget);
    expect(find.text('في الطريق'), findsOneWidget);

    await tester.tap(find.text('تم التوصيل'));
    await tester.pumpAndSettle();
    expect(orders.delivered, [_order.id]);
    expect(find.text('لا توجد طلبات قيد التوصيل'), findsOneWidget);
  });

  testWidgets('streams the GPS while delivering and stops on «تم التوصيل»', (
    tester,
  ) async {
    final gps = FakeDriverLocationService();
    final orders = FakeDriverOrdersRepository(available: [_order]);
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: _driverProfile(),
      driverOrdersRepository: orders,
      driverLocationService: gps,
    );
    await skipSplash(tester);
    expect(gps.permissionRequests, 0);
    expect(gps.isStreaming, isFalse);

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();
    expect(gps.permissionRequests, 1);
    expect(gps.isStreaming, isTrue);

    gps.move(30.07, 31.33);
    await tester.pump();
    expect(orders.locationUpdates, [(_order.id, 30.07, 31.33)]);

    await tester.tap(find.text('طلباتي (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم التوصيل'));
    await tester.pumpAndSettle();
    expect(orders.delivered, [_order.id]);
    expect(gps.isStreaming, isFalse);

    gps.move(30.06, 31.34);
    await tester.pump();
    expect(orders.locationUpdates, hasLength(1));
  });

  testWidgets('a rejected location update is shown to the driver once', (
    tester,
  ) async {
    final gps = FakeDriverLocationService();
    const failure = DriverFailure('تعذر إرسال موقعك للعميل: مرفوض');
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: _driverProfile(),
      driverOrdersRepository: FakeDriverOrdersRepository(
        available: [_order],
        locationFailure: failure,
      ),
      driverLocationService: gps,
    );
    await skipSplash(tester);
    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();

    gps.move(30.07, 31.33);
    await tester.pumpAndSettle();
    expect(find.text(failure.message), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text(failure.message), findsNothing);
    gps.move(30.06, 31.34);
    await tester.pumpAndSettle();
    expect(find.text(failure.message), findsNothing);
    expect(gps.isStreaming, isTrue);
  });

  testWidgets('a refused location permission is explained', (tester) async {
    final gps = FakeDriverLocationService(
      failure: const DriverLocationFailure('إذن الموقع مرفوض'),
    );
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: _driverProfile(),
      driverOrdersRepository: FakeDriverOrdersRepository(available: [_order]),
      driverLocationService: gps,
    );
    await skipSplash(tester);

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('إذن الموقع مرفوض'), findsOneWidget);
    expect(gps.isStreaming, isFalse);

    await tester.tap(find.text('طلباتي (1)'));
    await tester.pumpAndSettle();
    expect(find.text('جاري بث الموقع...'), findsNothing);

    gps.failure = null;
    await tester.tap(find.byKey(const Key('start-location-sharing')));
    await tester.pumpAndSettle();
    expect(gps.isStreaming, isTrue);
    expect(find.text('جاري بث الموقع...'), findsOneWidget);
    expect(find.byKey(const Key('start-location-sharing')), findsNothing);

    gps.move(30.07, 31.33);
    await tester.pumpAndSettle();
    expect(find.textContaining('جاري بث الموقع... آخر إرسال'), findsOneWidget);
  });

  testWidgets('an order taken by another driver explains and disappears', (
    tester,
  ) async {
    await _openDashboard(
      tester,
      acceptFailure:
          const DriverFailure('عذراً، تم قبول هذا الطلب من سائق آخر'),
    );

    await tester.tap(find.text('قبول الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('عذراً، تم قبول هذا الطلب من سائق آخر'), findsOneWidget);
    expect(find.text('قبول الطلب'), findsNothing);
  });

  testWidgets('a new-order push refreshes the open dashboard', (tester) async {
    final push = FakePushNotificationService(token: 'tok');
    final orders = await _openDashboard(tester, push: push);
    orders.available.add(
      DriverOrder(
        id: 'beef0000-0000',
        createdAt: DateTime(2026, 10, 4, 19),
        status: 'ready_for_delivery',
        totalAmount: 80,
        deliveryFee: 25,
      ),
    );

    push.messages.add({'type': 'new_order', 'order_id': 'beef0000-0000'});
    await tester.pumpAndSettle();

    expect(find.text('طلب جديد متاح للتوصيل!'), findsOneWidget);
    expect(find.text('طلبات متاحة (2)'), findsOneWidget);
    expect(find.textContaining('غير محددة'), findsOneWidget);
  });

  testWidgets('drivers join the drivers topic and leave it on sign-out', (
    tester,
  ) async {
    final push = FakePushNotificationService(token: 'tok');
    await _openDashboard(tester, push: push);
    expect(push.topics, {driversTopic: true});

    await tester.tap(find.byTooltip('تسجيل الخروج'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(push.topics, {driversTopic: false});
    expect(find.byType(DriverDashboardScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('customers land on the store and never join the topic', (
    tester,
  ) async {
    final push = FakePushNotificationService(token: 'tok');
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      pushNotificationService: push,
    );
    await skipSplash(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(DriverDashboardScreen), findsNothing);
    expect(push.topics, isEmpty);
  });

  testWidgets('a driver logging in is taken to the dashboard', (tester) async {
    await pumpApp(
      tester,
      profileRepository: _driverProfile(),
      driverOrdersRepository: FakeDriverOrdersRepository(available: [_order]),
    );
    await skipSplash(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('سجل دخولك'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'البريد الإلكتروني'),
      'driver@safeer.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'كلمة المرور'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.byType(DriverDashboardScreen), findsOneWidget);
    expect(find.text('قبول الطلب'), findsOneWidget);
  });
}
