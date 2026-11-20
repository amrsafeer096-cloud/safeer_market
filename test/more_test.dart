import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show AssetMapBitmap;

import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/orders/domain/entities/customer_order.dart';
import 'package:safeer_market/features/orders/presentation/providers/orders_providers.dart';
import 'package:safeer_market/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/presentation/screens/settings_screen.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

final _signedInProfile = FakeProfileRepository(
  const UserProfile(id: 'user-1', fullName: 'عمرو أحمد', phone: '01012345678'),
);

void main() {
  testWidgets('guest sees "سجل دخولك" in the header and can log in', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);

    expect(find.byTooltip('حسابي'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'سجل دخولك'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    await tester.tap(find.text('المتابعة بالبريد الإلكتروني'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('البريد الإلكتروني'), 'amr@example.com');
    await tester.enterText(_field('كلمة المرور'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(find.text('تم تسجيل الدخول بنجاح'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'سجل دخولك'), findsNothing);
    expect(find.byTooltip('حسابي'), findsOneWidget);
  });

  testWidgets('المزيد tab greets guests and offers login instead of logout', (
    tester,
  ) async {
    await pumpApp(tester);
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();

    expect(find.text('أهلاً بك يا ضيفنا'), findsOneWidget);
    expect(find.text('المنتجات المفضلة'), findsOneWidget);
    expect(find.text('تحدث معنا'), findsOneWidget);
    expect(find.text('المساعدة'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'سجل دخولك'), findsOneWidget);
  });

  testWidgets('المزيد tab greets the user by profile name and logs out', (
    tester,
  ) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: _signedInProfile,
    );
    await skipSplash(tester);

    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بك يا عمرو أحمد'), findsOneWidget);
    expect(find.text('amr@example.com'), findsOneWidget);

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(find.text('تم تسجيل الخروج'), findsOneWidget);
    expect(find.text('أهلاً بك يا ضيفنا'), findsOneWidget);
  });

  testWidgets('settings lists the placeholders and a delete-account button', (
    tester,
  ) async {
    await pumpApp(tester, authRepository: FakeAuthRepository(user: testUser));
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    for (final label in [
      'البيانات الشخصية',
      'البريد الإلكتروني',
      'العناوين المحفوظة',
      'البطاقات المحفوظة',
      'تنبيهات الرسائل والرسائل النصية',
      'اللغة',
      'سياسة الخصوصية والشروط',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('amr@example.com'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'حذف الحساب'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('orders list shows date, total and status', (tester) async {
    final orders = FakeOrdersRepository([
      CustomerOrder(
        id: 'b7e1c2d3-1111-2222-3333-444444444444',
        createdAt: DateTime(2026, 10, 2, 18, 5),
        totalAmount: 107.40,
        status: 'pending',
      ),
      CustomerOrder(
        id: 'a1a1a1a1-5555-6666-7777-888888888888',
        createdAt: DateTime(2026, 9, 28, 11, 30),
        totalAmount: 45.95,
        status: 'delivered',
      ),
    ]);
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      ordersRepository: orders,
    );
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();

    expect(find.byType(MyOrdersScreen), findsOneWidget);
    expect(orders.requestedFor, testUser.id);
    expect(find.text('طلب #b7e1c2d3'), findsOneWidget);
    expect(find.text('حالة الطلب: تم استلام الطلب'), findsOneWidget);
    expect(find.text('حالة الطلب: تم التوصيل'), findsOneWidget);
    expect(find.textContaining('107.40'), findsOneWidget);
    expect(find.textContaining('2026'), findsNWidgets(2));

    final context = tester.element(find.byType(MyOrdersScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('status updates live through the whole lifecycle', (
    tester,
  ) async {
    useFakeGoogleMaps();
    final createdAt = DateTime(2026, 10, 2, 18, 5);
    CustomerOrder order(String status) => CustomerOrder(
          id: 'b7e1c2d3-1111-2222-3333-444444444444',
          createdAt: createdAt,
          totalAmount: 107.40,
          status: status,
          deliveryLatitude: 30.0560,
          deliveryLongitude: 31.3460,
        );
    late void Function(List<CustomerOrder>) emit;
    final stream = Stream<List<CustomerOrder>>.multi((listener) {
      emit = listener.addSync;
      listener.addSync([order('pending')]);
    }, isBroadcast: true);
    const track = 'تتبع الطلب على الخريطة';

    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      overrides: [
        customerOrdersStreamOverrideProvider.overrideWith((ref) => stream),
      ],
    );
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();

    expect(find.text('حالة الطلب: تم استلام الطلب'), findsOneWidget);
    expect(find.text(track), findsNothing);

    for (final (status, label) in [
      ('preparing', 'جاري التجهيز في المخزن'),
      ('ready_for_delivery', 'في انتظار مندوب التوصيل'),
    ]) {
      emit([order(status)]);
      await tester.pump();
      expect(find.text('حالة الطلب: $label'), findsOneWidget);
      expect(find.text(track), findsNothing);
    }

    emit([order('out_for_delivery')]);
    await tester.pump();
    expect(find.text('حالة الطلب: الطلب في الطريق إليك!'), findsOneWidget);

    // The card opens by itself to reveal the tracking button.
    await tester.pumpAndSettle();
    await tester.tap(find.text(track));
    await tester.pumpAndSettle();
    expect(find.text('تتبع الطلب #b7e1c2d3'), findsOneWidget);
    expect(find.byKey(const Key('fake-google-map')), findsOneWidget);
    expect(
      find.byKey(const Key('driver-location-placeholder')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    emit([order('delivered')]);
    await tester.pump();
    expect(find.text('حالة الطلب: تم التوصيل'), findsOneWidget);
    expect(find.text(track), findsNothing);
  });

  testWidgets('the tracking map follows the driver live', (tester) async {
    final maps = useFakeGoogleMaps();
    const orderId = 'b7e1c2d3-1111-2222-3333-444444444444';
    CustomerOrder order(
      String status, {
      double? driverLatitude,
      double? driverLongitude,
    }) =>
        CustomerOrder(
          id: orderId,
          createdAt: DateTime(2026, 10, 2, 18, 5),
          totalAmount: 107.40,
          status: status,
          deliveryLatitude: 30.0560,
          deliveryLongitude: 31.3460,
          driverLatitude: driverLatitude,
          driverLongitude: driverLongitude,
        );
    final tracked = StreamController<CustomerOrder?>.broadcast();
    addTearDown(tracked.close);
    String? trackedId;

    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      overrides: [
        customerOrdersStreamOverrideProvider.overrideWith(
          (ref) => Stream.value([order('out_for_delivery')]),
        ),
        trackedOrderStreamOverrideProvider.overrideWith((ref, id) {
          trackedId = id;
          return tracked.stream;
        }),
      ],
    );
    await skipSplash(tester);
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تتبع الطلب على الخريطة'));
    await tester.pumpAndSettle();

    Iterable<String> markerIds() =>
        maps.lastMapObjects.markers.map((marker) => marker.markerId.value);
    (double, double) driverMarker() {
      final marker = maps.lastMapObjects.markers
          .singleWhere((marker) => marker.markerId.value == 'driver');
      return (marker.position.latitude, marker.position.longitude);
    }

    List<(double, double)> routeLine() {
      final line = maps.lastMapObjects.polylines.single;
      expect(line.polylineId.value, 'route');
      expect(line.width, 5);
      return [
        for (final point in line.points) (point.latitude, point.longitude),
      ];
    }

    expect(trackedId, orderId);
    expect(markerIds(), unorderedEquals(['store', 'destination']));
    expect(maps.lastMapObjects.polylines, isEmpty);
    expect(
      find.byKey(const Key('driver-location-placeholder')),
      findsOneWidget,
    );

    tracked.add(
      order('out_for_delivery', driverLatitude: 30.07, driverLongitude: 31.33),
    );
    await tester.pumpAndSettle();
    expect(markerIds(), unorderedEquals(['store', 'destination', 'driver']));
    expect(driverMarker(), (30.07, 31.33));
    expect(routeLine(), [(30.07, 31.33), (30.0560, 31.3460)]);
    expect(find.byKey(const Key('driver-location-live')), findsOneWidget);
    expect(
      find.byKey(const Key('driver-location-placeholder')),
      findsNothing,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    final icon = maps.lastMapObjects.markers
        .singleWhere((marker) => marker.markerId.value == 'driver')
        .icon;
    expect(icon, isA<AssetMapBitmap>());
    expect((icon as AssetMapBitmap).assetName, 'assets/images/motorcycle.png');

    // Each update moves the marker straight to the new position.
    for (final (latitude, longitude) in [
      (30.06, 31.34),
      (30.059, 31.342),
      (30.058, 31.343),
    ]) {
      tracked.add(
        order(
          'out_for_delivery',
          driverLatitude: latitude,
          driverLongitude: longitude,
        ),
      );
      await tester.pumpAndSettle();
      expect(driverMarker(), (latitude, longitude));
      expect(routeLine(), [(latitude, longitude), (30.0560, 31.3460)]);
    }

    tracked.add(
      order('delivered', driverLatitude: 30.056, driverLongitude: 31.346),
    );
    await tester.pumpAndSettle();
    expect(markerIds(), unorderedEquals(['store', 'destination']));
    expect(maps.lastMapObjects.polylines, isEmpty);
    expect(find.text('تم توصيل طلبك، بالهناء والشفاء!'), findsOneWidget);
  });
}
