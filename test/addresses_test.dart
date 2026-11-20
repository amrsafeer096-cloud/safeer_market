import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:safeer_market/core/routing/app_routes.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';
import 'package:safeer_market/features/addresses/presentation/screens/add_address_screen.dart';
import 'package:safeer_market/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';

import 'test_helpers.dart';

const _apple = Product(id: '1', name: 'تفاح أحمر', price: 12.5);

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// On the add-address map: confirm the pin, then fill the details sheet.
Future<void> _pinAndFillAddress(WidgetTester tester) async {
  expect(find.byType(AddAddressScreen), findsOneWidget);
  await tester.tap(find.text('تأكيد الموقع'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ChoiceChip, 'العمل'));
  await tester.pump();
  await tester.enterText(_field('رقم العمارة'), '45');
  await tester.enterText(_field('الدور / الشقة (اختياري)'), '5 / 12');
  await tester.enterText(_field('علامة مميزة (اختياري)'), 'أمام سيتي ستارز');
}

void main() {
  testWidgets('settings opens saved addresses and adds a new one', (
    tester,
  ) async {
    final addresses = FakeAddressesRepository();
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: addresses,
    );
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العناوين المحفوظة'));
    await tester.pumpAndSettle();

    expect(find.byType(AddressesScreen), findsOneWidget);
    expect(find.text('لا توجد عناوين محفوظة بعد'), findsOneWidget);

    await tester.tap(find.text('إضافة عنوان جديد'));
    await tester.pumpAndSettle();
    await _pinAndFillAddress(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ العنوان'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAddressScreen), findsNothing);
    expect(find.text('تم حفظ عنوان «العمل»'), findsOneWidget);
    final saved = addresses.addresses.single;
    expect(saved.area, 'مدينة نصر');
    expect(saved.latitude, 30.0560);
    expect(saved.longitude, 31.3460);
    expect(saved.landmark, 'أمام سيتي ستارز');
    expect(find.text('شارع عباس العقاد، عمارة 45، الدور/الشقة 5 / 12'),
        findsOneWidget);
    expect(find.text('علامة مميزة: أمام سيتي ستارز'), findsOneWidget);

    await tester.tap(find.byTooltip('حذف العنوان'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await tester.pumpAndSettle();
    expect(addresses.addresses, isEmpty);
    expect(find.text('لا توجد عناوين محفوظة بعد'), findsOneWidget);
  });

  testWidgets('checkout with no addresses adds one and selects it', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: const [_apple],
      authRepository: FakeAuthRepository(user: testUser),
    );
    await skipSplash(tester);
    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('أضف عنوان التوصيل لإتمام طلبك'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة عنوان'));
    await tester.pumpAndSettle();

    await _pinAndFillAddress(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ العنوان'));
    await tester.pumpAndSettle();

    expect(find.byType(AddAddressScreen), findsNothing);
    expect(find.text('أضف عنوان التوصيل لإتمام طلبك'), findsNothing);
    expect(find.text('العمل'), findsOneWidget);
    expect(find.text('تغيير'), findsOneWidget);
  });

  testWidgets('guests opening checkout see a login hint for the address', (
    tester,
  ) async {
    await pumpApp(tester, products: const [_apple]);
    await skipSplash(tester);
    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(HomeScreen)))
        .push(AppRoutes.checkout);
    await tester.pumpAndSettle();

    expect(find.text('سجّل دخولك لاختيار عنوان التوصيل'), findsOneWidget);
    expect(find.text('إدارة العناوين'), findsNothing);
  });
}
