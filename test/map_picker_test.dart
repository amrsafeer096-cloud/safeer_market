import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/features/addresses/domain/services/location_service.dart';
import 'package:safeer_market/features/addresses/presentation/screens/add_address_screen.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/address_details_sheet.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/location_picker_scaffold.dart';

import 'test_helpers.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<FakeAddressesRepository> _openAddAddress(
  WidgetTester tester,
  FakeLocationService location,
) async {
  final addresses = FakeAddressesRepository();
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    locationService: location,
    addressesRepository: addresses,
  );
  await skipSplash(tester);
  await tester.tap(find.text('المزيد'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('العناوين المحفوظة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('إضافة عنوان جديد'));
  await tester.pumpAndSettle();
  expect(find.byType(AddAddressScreen), findsOneWidget);
  return addresses;
}

void main() {
  testWidgets('opens a full-screen map on the device location', (
    tester,
  ) async {
    await _openAddAddress(tester, FakeLocationService());

    expect(find.byKey(const Key('fake-center-pin-map')), findsOneWidget);
    expect(find.byKey(const Key('map-center-pin')), findsOneWidget);
    expect(find.text('إضافة عنوان جديد'), findsOneWidget);
    expect(centerPinMap(tester).moves.single, const LatLng(30.0560, 31.3460));
    expect(
      find.textContaining('يبعد 1.9 كم عن الفرع'),
      findsOneWidget,
    );
  });

  testWidgets(
      'dragging, confirming and filling the sheet saves the exact pin '
      'coordinates', (tester) async {
    final location = FakeLocationService();
    final addresses = await _openAddAddress(tester, location);

    // 1 km due north of the store (111.19 km per degree of latitude).
    const pin = LatLng(
      StoreLocation.latitude + 1 / 111.19492664455873,
      StoreLocation.longitude,
    );
    await dragMapTo(tester, pin);
    expect(find.textContaining('يبعد 1.0 كم عن الفرع'), findsOneWidget);

    await tester.tap(find.text('تأكيد الموقع'));
    await tester.pumpAndSettle();

    expect(location.geocodedPoints.single, pin);
    expect(find.byType(AddressDetailsSheet), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_field('المنطقة')).controller!.text,
      'مدينة نصر',
    );
    expect(
      tester.widget<TextFormField>(_field('الشارع')).controller!.text,
      'شارع عباس العقاد',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'حفظ العنوان'));
    await tester.pump();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(addresses.addresses, isEmpty);

    await tester.tap(find.widgetWithText(ChoiceChip, 'العمل'));
    await tester.pump();
    await tester.enterText(_field('رقم العمارة'), '45');
    await tester.enterText(_field('الدور / الشقة (اختياري)'), '5 / 12');
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ العنوان'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAddressScreen), findsNothing);
    final saved = addresses.addresses.single;
    expect(saved.title, 'العمل');
    expect(saved.building, '45');
    expect(saved.floorApt, '5 / 12');
    expect(saved.latitude, pin.latitude);
    expect(saved.longitude, pin.longitude);
    expect(find.text('تم حفظ عنوان «العمل»'), findsOneWidget);
  });

  testWidgets('"تعديل الموقع" closes the sheet and keeps the pin', (
    tester,
  ) async {
    final addresses = await _openAddAddress(tester, FakeLocationService());
    await tester.tap(find.text('تأكيد الموقع'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تعديل الموقع'));
    await tester.pumpAndSettle();

    expect(find.byType(AddressDetailsSheet), findsNothing);
    expect(find.byType(AddAddressScreen), findsOneWidget);
    expect(centerPinMap(tester).center, const LatLng(30.0560, 31.3460));
    expect(addresses.addresses, isEmpty);
  });

  testWidgets('a denied permission on open stays quiet; the button explains', (
    tester,
  ) async {
    await _openAddAddress(
      tester,
      FakeLocationService(
        positionFailure: const LocationFailure(
          LocationFailureReason.denied,
          'لم يتم السماح بالوصول لموقعك، يمكنك تحريك الخريطة يدوياً',
        ),
      ),
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(centerPinMap(tester).center, LocationPickerScaffold.defaultCenter);

    await tester.tap(find.byTooltip('موقعي الحالي'));
    await tester.pumpAndSettle();

    expect(
      find.text('لم يتم السماح بالوصول لموقعك، يمكنك تحريك الخريطة يدوياً'),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'الإعدادات'), findsNothing);
    expect(find.text('تأكيد الموقع'), findsOneWidget);
  });

  testWidgets('permanently denied permission offers to open settings', (
    tester,
  ) async {
    final location = FakeLocationService(
      positionFailure: const LocationFailure(
        LocationFailureReason.deniedForever,
        'إذن الموقع مرفوض، فعّله من إعدادات التطبيق',
      ),
    );
    await _openAddAddress(tester, location);

    await tester.tap(find.byTooltip('موقعي الحالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'الإعدادات'));
    await tester.pumpAndSettle();

    expect(location.openedSettings, [LocationFailureReason.deniedForever]);
  });

  testWidgets('failed reverse geocoding asks to fill the address manually', (
    tester,
  ) async {
    await _openAddAddress(tester, FakeLocationService(placemark: null));

    await tester.tap(find.text('تأكيد الموقع'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
          'تعذر قراءة العنوان من الخريطة، أكمل البيانات يدوياً'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(_field('المنطقة')).controller!.text,
      isEmpty,
    );
    // The pin itself still prices delivery.
    expect(
      find.descendant(
        of: find.byType(AddressDetailsSheet),
        matching: find.textContaining('يبعد 1.9 كم عن الفرع'),
      ),
      findsOneWidget,
    );
  });
}
