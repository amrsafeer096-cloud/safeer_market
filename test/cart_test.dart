import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/core/providers/settings_providers.dart';
import 'package:safeer_market/features/addresses/domain/entities/address.dart';
import 'package:safeer_market/features/addresses/presentation/screens/map_picker_screen.dart';
import 'package:safeer_market/features/cart/domain/entities/cart_item.dart';
import 'package:safeer_market/features/cart/domain/weight_options.dart';
import 'package:safeer_market/features/cart/presentation/providers/cart_providers.dart';
import 'package:safeer_market/features/cart/presentation/screens/cart_screen.dart';
import 'package:safeer_market/features/checkout/domain/checkout_pricing.dart';
import 'package:safeer_market/features/checkout/domain/payment_method.dart';
import 'package:safeer_market/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:safeer_market/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:safeer_market/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:safeer_market/features/checkout/presentation/screens/payment_screen.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';

import 'test_helpers.dart';

const _apple = Product(id: '1', name: 'تفاح أحمر', price: 12.5);
const _milk = Product(id: '2', name: 'لبن كامل الدسم', price: 30);
const _cheese = Product(id: '3', name: 'جبنة رومي وزن', price: 250);

/// Kilometres per degree of latitude for R = 6371 km.
const _kmPerDegree = 111.19492664455873;

Address _address({
  String id = 'addr-1',
  String title = 'المنزل',
  double? kmNorthOfStore,
}) {
  return Address(
    id: id,
    title: title,
    area: 'مدينة نصر، الحي السادس',
    street: 'شارع 9',
    building: '12',
    floorApt: '3 / 7',
    landmark: 'بجوار مسجد الرحمن',
    latitude: kmNorthOfStore == null
        ? null
        : StoreLocation.latitude + kmNorthOfStore / _kmPerDegree,
    longitude: kmNorthOfStore == null ? null : StoreLocation.longitude,
  );
}

/// 1.45 km from the store: the 2 km / 30 EGP bracket.
final _home = _address(kmNorthOfStore: 1.45);

class _FakeCheckoutRepository implements CheckoutRepository {
  _FakeCheckoutRepository({this.failure});

  final CheckoutFailure? failure;
  List<CartItem>? placedItems;
  String? placedBy;
  String? addressDetails;
  String? deliveryArea;
  double? deliveryFee;
  double? deliveryLatitude;
  PaymentMethod? paymentMethod;

  @override
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String addressDetails,
    required String deliveryArea,
    required double deliveryFee,
    required PaymentMethod paymentMethod,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String paymentStatus = 'unpaid',
    String? paymentMethodOverride,
    String? receiptUrl,
  }) async {
    if (failure != null) throw failure!;
    placedBy = userId;
    placedItems = items;
    this.addressDetails = addressDetails;
    this.deliveryArea = deliveryArea;
    this.deliveryFee = deliveryFee;
    this.deliveryLatitude = deliveryLatitude;
    this.paymentMethod = paymentMethod;
    return 'a1b2c3d4-0000-0000-0000-000000000000';
  }

  @override
  Future<String> uploadPaymentReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    return 'https://example.com/receipts/$fileName';
  }
}

Future<void> _openCart(WidgetTester tester) async {
  await tester.tap(find.byTooltip('أضف للسلة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('السلة'));
  await tester.pumpAndSettle();
}

Future<void> _continueToCheckout(WidgetTester tester) async {
  await tester.tap(find.text('متابعة الطلب'));
  await tester.pumpAndSettle();
  expect(find.byType(CheckoutScreen), findsOneWidget);
}

Future<void> _openCheckoutWith(
  WidgetTester tester,
  List<Address> addresses, {
  CheckoutRepository? repository,
  List<Override> overrides = const [],
}) async {
  await pumpApp(
    tester,
    products: const [_apple],
    authRepository: FakeAuthRepository(user: testUser),
    addressesRepository: FakeAddressesRepository(addresses),
    overrides: [
      checkoutRepositoryProvider.overrideWithValue(
        repository ?? _FakeCheckoutRepository(),
      ),
      ...overrides,
    ],
  );
  await skipSplash(tester);
  await _openCart(tester);
  await _continueToCheckout(tester);
}

Future<void> _selectAddress(WidgetTester tester,
    [String title = 'المنزل']) async {
  await tester.tap(find.widgetWithText(FilledButton, 'اختر العنوان'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(title).last);
  await tester.pumpAndSettle();
}

Finder _totalText() => find.byKey(const Key('checkout-total'));

Future<void> _fillCard(
  WidgetTester tester, {
  String number = '4242424242424242',
}) async {
  Finder field(String label) => find.widgetWithText(TextFormField, label);
  await tester.enterText(field('رقم البطاقة'), number);
  await tester.enterText(field('تاريخ الانتهاء'), '1230');
  await tester.enterText(field('CVV'), '123');
  await tester.enterText(field('اسم حامل البطاقة'), 'Amr Ahmed');
  await tester.pump();
}

void main() {
  group('CartNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('adding the same product increases its quantity', () {
      final cart = container.read(cartProvider.notifier);
      cart
        ..add(_apple)
        ..add(_apple)
        ..add(_milk);

      final items = container.read(cartProvider);
      expect(items, hasLength(2));
      expect(items.first.quantity, 2);
      expect(container.read(cartItemCountProvider), 3);
      expect(container.read(cartTotalProvider), 55);
    });

    test('quantity of zero removes the item', () {
      final cart = container.read(cartProvider.notifier)..add(_apple);
      cart.updateQuantity(_apple.id, 0);

      expect(container.read(cartProvider), isEmpty);
      expect(container.read(cartTotalProvider), 0);
    });

    test('weight-based items are priced per gram and replace their weight', () {
      final cart = container.read(cartProvider.notifier)
        ..add(_apple)
        ..setWeight(_cheese, 250);

      var cheese = container.read(cartProvider).last;
      expect(cheese.quantity, 1);
      expect(cheese.selectedWeightInGrams, 250);
      expect(cheese.total, 62.5);
      expect(container.read(cartItemCountProvider), 2);
      expect(container.read(cartTotalProvider), 75);

      cart.setWeight(_cheese, 750);
      cheese = container.read(cartProvider).last;
      expect(container.read(cartProvider), hasLength(2));
      expect(cheese.total, 187.5);

      cart.setWeight(_cheese, 0);
      expect(container.read(cartProvider).single.product, _apple);
    });

    test('offers are charged at the offer price, by piece and by weight', () {
      const onOffer = Product(
        id: 'o1',
        name: 'زيت عباد',
        price: 100,
        discountPrice: 80,
      );
      const cheeseOffer = Product(
        id: 'o2',
        name: 'جبنة',
        price: 200,
        unit: 'وزن',
        discountPrice: 160,
      );
      container.read(cartProvider.notifier)
        ..add(onOffer)
        ..add(onOffer)
        ..setWeight(cheeseOffer, 250);

      expect(container.read(cartProvider).first.total, 160);
      expect(container.read(cartProvider).last.total, 40);
      expect(container.read(cartTotalProvider), 200);
    });

    test('add never puts a whole kilo of a weight-based product', () {
      container.read(cartProvider.notifier).add(_cheese);

      final cheese = container.read(cartProvider).single;
      expect(cheese.selectedWeightInGrams, WeightOptions.defaultGrams);
      expect(cheese.quantity, 1);
    });

    test('cart survives a new ProviderContainer via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(first.dispose);
      first.read(cartProvider.notifier)
        ..add(_apple)
        ..add(_apple)
        ..setWeight(_cheese, 250);
      await Future<void>.delayed(Duration.zero);

      final second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      final restored = second.read(cartProvider);

      expect(restored, hasLength(2));
      expect(restored.first.product.id, _apple.id);
      expect(restored.first.quantity, 2);
      expect(restored.last.product.id, _cheese.id);
      expect(restored.last.selectedWeightInGrams, 250);
    });
  });

  group('WeightOptions', () {
    test('products are weight-based by flag or by name', () {
      expect(_cheese.isWeightBased, isTrue);
      expect(_apple.isWeightBased, isFalse);
      expect(
        const Product(id: '9', name: 'بن', price: 400, isWeightBased: true)
            .isWeightBased,
        isTrue,
      );
    });

    test('steps through presets, then by half a kilo', () {
      expect(WeightOptions.next(250), 500);
      expect(WeightOptions.next(1000), 1500);
      expect(WeightOptions.previous(1500), 1000);
      expect(WeightOptions.previous(200), 100);
      expect(WeightOptions.previous(100), 0);
    });

    test('price is (price per kilo / 1000) × grams, to the piaster', () {
      expect(WeightOptions.priceFor(250, 250), 62.5);
      expect(WeightOptions.priceFor(99.99, 100), 10);
      expect(WeightOptions.priceFor(180, 750), 135);
    });

    test('labels use grams below a kilo', () {
      expect(WeightOptions.label(250), '250 جرام');
      expect(WeightOptions.label(1000), '1 كيلو');
      expect(WeightOptions.label(1500), '1.5 كيلو');
    });
  });

  testWidgets('adding a weight-based product asks for the weight first', (
    tester,
  ) async {
    final repository = _FakeCheckoutRepository();
    await pumpApp(
      tester,
      products: const [_cheese],
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: FakeAddressesRepository([_home]),
      overrides: [checkoutRepositoryProvider.overrideWithValue(repository)],
    );
    await skipSplash(tester);

    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    expect(find.text('اختر الوزن'), findsOneWidget);

    await tester.tap(find.text('500 جرام'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('weight-sheet-price'))).data,
      contains('125.00'),
    );
    await tester.tap(find.text('250 جرام'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'أضف للسلة'));
    await tester.pumpAndSettle();
    expect(
      find.text('تمت إضافة 250 جرام من جبنة رومي وزن إلى السلة'),
      findsOneWidget,
    );

    await tester.tap(find.text('السلة'));
    await tester.pumpAndSettle();
    expect(find.text('250 جرام'), findsOneWidget);
    expect(find.textContaining('/ كيلو'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      contains('62.50'),
    );

    await tester.tap(find.byTooltip('زيادة الوزن'));
    await tester.pump();
    expect(find.text('500 جرام'), findsOneWidget);
    expect(find.text('المجموع (1 منتج)'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      contains('125.00'),
    );

    await _continueToCheckout(tester);
    await _selectAddress(tester);
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    final placed = repository.placedItems!.single;
    expect(placed.quantity, 1);
    expect(placed.selectedWeightInGrams, 500);
    expect(placed.unitPrice, 125);
  });

  testWidgets('dismissing the weight sheet adds nothing', (tester) async {
    await pumpApp(tester, products: const [_cheese]);
    await skipSplash(tester);

    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('اختر الوزن'), findsNothing);
    expect(find.textContaining('تمت إضافة'), findsNothing);
  });

  test('address is formatted as one line for the order', () {
    expect(
      _home.formatted,
      'المنزل: شارع 9، عمارة 12، الدور/الشقة 3 / 7 - مدينة نصر، الحي السادس'
      ' - علامة مميزة: بجوار مسجد الرحمن',
    );
  });

  test('arrival is estimated 45 minutes from now', () {
    expect(
      CheckoutPricing.estimatedArrival(DateTime(2026, 10, 4, 21, 50)),
      DateTime(2026, 10, 4, 22, 35),
    );
  });

  testWidgets('cart shows only the subtotal and no address or delivery fee', (
    tester,
  ) async {
    await pumpApp(
      tester,
      products: const [_apple],
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: FakeAddressesRepository([_home]),
    );
    await skipSplash(tester);
    await _openCart(tester);
    expect(find.byType(CartScreen), findsOneWidget);

    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pump();

    expect(find.text('المجموع (2 منتج)'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal'))).data,
      contains('25.00'),
    );
    expect(find.textContaining('رسوم التوصيل ('), findsNothing);
    expect(find.text('الإجمالي النهائي'), findsNothing);
    expect(find.text('عنوان التوصيل'), findsNothing);
    expect(find.text('إتمام الطلب'), findsNothing);
    expect(find.text('متابعة الطلب'), findsOneWidget);
  });

  testWidgets('checkout charges the fee for the address and places the order', (
    tester,
  ) async {
    final repository = _FakeCheckoutRepository();
    final driverAlerts = FakeNewOrderNotifier();
    await pumpApp(
      tester,
      products: const [_apple],
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: FakeAddressesRepository([_home]),
      newOrderNotifier: driverAlerts,
      overrides: [checkoutRepositoryProvider.overrideWithValue(repository)],
    );
    await skipSplash(tester);

    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pump();
    expect(find.text('تمت إضافة تفاح أحمر إلى السلة'), findsOneWidget);
    await tester.tap(find.byTooltip('أضف للسلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السلة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pump();

    await _continueToCheckout(tester);
    expect(find.text('رسوم التوصيل'), findsOneWidget);
    expect(find.text('اختر العنوان'), findsWidgets);
    expect(tester.widget<Text>(_totalText()).data, contains('37.50'));

    await _selectAddress(tester);
    expect(find.text('رسوم التوصيل (1.5 كم)'), findsOneWidget);
    expect(find.textContaining('30.00'), findsOneWidget);
    expect(tester.widget<Text>(_totalText()).data, contains('67.50'));

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    expect(repository.placedBy, testUser.id);
    expect(repository.placedItems!.single.quantity, 3);
    expect(repository.addressDetails, _home.formatted);
    expect(repository.deliveryArea, _home.area);
    expect(repository.deliveryFee, 30);
    expect(repository.deliveryLatitude, _home.latitude);
    expect(repository.paymentMethod, PaymentMethod.cashOnDelivery);
    // Drivers hear about it once the warehouse marks it ready, not now.
    expect(driverAlerts.notifiedOrders, isEmpty);
    expect(
      find.text('تم استلام طلبك بنجاح • رقم الطلب #a1b2c3d4'),
      findsOneWidget,
    );
    expect(find.byType(CheckoutScreen), findsNothing);
    expect(find.byType(CartScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('card orders are placed only after paying on the card screen', (
    tester,
  ) async {
    final repository = _FakeCheckoutRepository();
    await _openCheckoutWith(tester, [_home], repository: repository);

    expect(find.text('كاش عند الاستلام'), findsOneWidget);
    expect(find.text('بطاقة بنكية (فيزا/ماستركارد)'), findsOneWidget);
    await tester.tap(find.text('بطاقة بنكية (فيزا/ماستركارد)'));
    await tester.pump();
    await _selectAddress(tester);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(repository.placedBy, isNull);
    // 12.50 items + 30.00 delivery.
    expect(
      tester.widget<Text>(find.byKey(const Key('payment-amount'))).data,
      contains('42.50'),
    );

    await _fillCard(tester);
    await tester.tap(find.textContaining('ادفع الآن'));
    await tester.pump();
    expect(repository.placedBy, isNull);

    await tester.pump(PaymentScreen.processingDelay);
    await tester.pumpAndSettle();

    expect(find.byType(PaymentScreen), findsNothing);
    expect(repository.placedBy, testUser.id);
    expect(repository.paymentMethod, PaymentMethod.card);
    expect(
      find.text('تم استلام طلبك بنجاح • رقم الطلب #a1b2c3d4'),
      findsOneWidget,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(container.read(cartProvider), isEmpty);
  });

  testWidgets('leaving the card screen places no order and keeps the cart', (
    tester,
  ) async {
    final repository = _FakeCheckoutRepository();
    await _openCheckoutWith(tester, [_home], repository: repository);
    await tester.tap(find.text('بطاقة بنكية (فيزا/ماستركارد)'));
    await tester.pump();
    await _selectAddress(tester);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(repository.placedBy, isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CheckoutScreen)),
    );
    expect(container.read(cartProvider), hasLength(1));
  });

  testWidgets('an invalid card is rejected without paying', (tester) async {
    final repository = _FakeCheckoutRepository();
    await _openCheckoutWith(tester, [_home], repository: repository);
    await tester.tap(find.text('بطاقة بنكية (فيزا/ماستركارد)'));
    await tester.pump();
    await _selectAddress(tester);
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    await _fillCard(tester, number: '4242424242424241');
    await tester.tap(find.textContaining('ادفع الآن'));
    await tester.pump(PaymentScreen.processingDelay);
    await tester.pumpAndSettle();

    expect(find.text('رقم البطاقة غير صحيح'), findsOneWidget);
    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(repository.placedBy, isNull);
  });

  testWidgets('estimated arrival is now + 45 min in 12-hour Arabic time', (
    tester,
  ) async {
    await _openCheckoutWith(
      tester,
      [_home],
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 4, 21, 45)),
      ],
    );

    expect(find.text('وقت الوصول المتوقع:'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('estimated-arrival'))).data,
      '10:30 م',
    );
  });

  testWidgets('each distance bracket sets the matching fee', (tester) async {
    final cases = <(double, String, String)>[
      (0.6, '0.6 كم', '25.00'),
      (1.8, '1.8 كم', '30.00'),
      (3.2, '3.2 كم', '35.00'),
      (4.7, '4.7 كم', '40.00'),
      (6.3, '6.3 كم', '45.00'),
    ];
    await _openCheckoutWith(tester, [
      for (final (km, _, _) in cases)
        _address(id: 'km-$km', title: 'عنوان $km', kmNorthOfStore: km),
    ]);

    for (final (km, distance, fee) in cases) {
      await tester.tap(
        km == cases.first.$1
            ? find.widgetWithText(FilledButton, 'اختر العنوان')
            : find.text('تغيير'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('عنوان $km').last);
      await tester.pumpAndSettle();

      expect(find.text('رسوم التوصيل ($distance)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('رسوم التوصيل ($distance)'),
            matching: find.byType(Row),
          ),
          matching: find.textContaining(fee),
        ),
        findsOneWidget,
        reason: '$km km should cost $fee',
      );
    }
  });

  testWidgets('addresses beyond 6.5 km block checkout', (tester) async {
    final repository = _FakeCheckoutRepository();
    await _openCheckoutWith(
      tester,
      [_address(kmNorthOfStore: 7.2)],
      repository: repository,
    );
    await _selectAddress(tester);

    expect(find.text('خارج نطاق التوصيل'), findsOneWidget);
    expect(
      find.text('عذراً، العنوان يبعد 7.2 كم وخارج نطاق التوصيل (حتى 6.5 كم)'),
      findsOneWidget,
    );

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    expect(repository.placedBy, isNull);
    expect(
      find.text('عذراً، العنوان يبعد 7.2 كم وخارج نطاق التوصيل (حتى 6.5 كم)'),
      findsNWidgets(2),
    );
  });

  testWidgets('an unpinned address is pinned from checkout, then priced', (
    tester,
  ) async {
    final addresses = FakeAddressesRepository([_address()]);
    final repository = _FakeCheckoutRepository();
    await pumpApp(
      tester,
      products: const [_apple],
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: addresses,
      overrides: [checkoutRepositoryProvider.overrideWithValue(repository)],
    );
    await skipSplash(tester);
    await _openCart(tester);
    await _continueToCheckout(tester);
    await _selectAddress(tester);

    expect(find.text('حدد الموقع'), findsWidgets);
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();
    expect(repository.placedBy, isNull);
    expect(find.byType(MapPickerScreen), findsOneWidget);

    // The map opens on the store, so confirming right away is 0 km.
    await tester.tap(find.text('تأكيد الموقع'));
    await tester.pumpAndSettle();

    expect(addresses.addresses.single.latitude, StoreLocation.latitude);
    expect(find.text('رسوم التوصيل (0.0 كم)'), findsOneWidget);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();
    expect(repository.deliveryFee, 25);
  });

  testWidgets('confirming without an address asks the user to pick one', (
    tester,
  ) async {
    final repository = _FakeCheckoutRepository();
    await _openCheckoutWith(tester, [_home], repository: repository);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    expect(repository.placedBy, isNull);
    expect(find.text('اختر عنوان التوصيل أولاً لإتمام طلبك'), findsOneWidget);
    expect(find.text('اختر عنوان التوصيل'), findsOneWidget);
  });

  testWidgets('home app bar shows the selected address and its fee', (
    tester,
  ) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      addressesRepository: FakeAddressesRepository([_home]),
    );
    await skipSplash(tester);

    expect(find.text('التوصيل إلى · مدينة نصر'), findsOneWidget);
    await tester.tap(find.text('اختر عنوانك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المنزل').last);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').startsWith('المنزل · ') &&
            widget.data!.contains('30.00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('checkout failure shows the error and keeps the cart', (
    tester,
  ) async {
    await _openCheckoutWith(
      tester,
      [_home],
      repository: _FakeCheckoutRepository(
        failure: const CheckoutFailure('RLS'),
      ),
    );
    await _selectAddress(tester);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر إتمام الطلب: RLS'), findsOneWidget);
    expect(find.byType(CheckoutScreen), findsOneWidget);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('تفاح أحمر'), findsOneWidget);
  });
}
