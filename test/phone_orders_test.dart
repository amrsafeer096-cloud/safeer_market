import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/admin/data/repositories/supabase_phone_orders_repository.dart';
import 'package:safeer_market/features/admin/domain/phone_order.dart';
import 'package:safeer_market/features/admin/domain/product_search_filter.dart';
import 'package:safeer_market/features/admin/domain/repositories/phone_orders_repository.dart';
import 'package:safeer_market/features/admin/presentation/providers/phone_order_providers.dart';
import 'package:safeer_market/features/admin/presentation/widgets/phone_order_column.dart';
import 'package:safeer_market/features/catalog/domain/main_categories.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

const _milk = Product(
  id: 'p-milk',
  name: 'لبن جهينة 1 لتر',
  price: 40,
  barcode: '6221234500011',
);
const _rice = Product(
  id: 'p-rice',
  name: 'أرز الضحى 1 كيلو',
  price: 50,
  discountPrice: 45,
  barcode: '6221234500028',
  stockQuantity: 15,
);
const _mona = PhoneOrderCustomer(
  source: PhoneOrderCustomerSource.pos,
  posCustomerId: 812,
  fullName: 'منى أحمد',
  phone: '01012345678',
  address: 'مدينة نصر، شارع 9',
  zone: 'مدينة نصر',
);
const _appUser = PhoneOrderCustomer(
  source: PhoneOrderCustomerSource.app,
  userId: '6f1c2a9e-3b7d-4e21-9a55-0c8d7e6f5a41',
  fullName: 'عمرو',
  phone: '+201000000000',
);

class _FakePhoneOrders implements PhoneOrdersRepository {
  final customerQueries = <String>[];
  final created = <Map<String, String?>>[];

  /// Everything createCustomer was given, including the new details.
  final createdDetails = <Map<String, Object?>>[];

  /// Zones per city, for the address dialog's المنطقة dropdown.
  final areas = <String, List<PhoneOrderArea>>{
    'مدينة نصر': const [
      PhoneOrderArea(
          name: 'الحي السابع', deliveryFee: 30, fujitsuZoneId: 'Z7'),
      PhoneOrderArea(name: 'الحي الثامن', fujitsuZoneId: 'Z8'),
    ],
  };

  /// What «مشتريات العميل» shows; empty unless a test sets it.
  CustomerPurchaseHistory history = const CustomerPurchaseHistory.empty();
  final placed = <({
    PhoneOrderCustomer customer,
    List<PhoneOrderLine> lines,
    double fee
  })>[];
  final payments = <PhoneOrderPayment>[];
  final receipts = <PaymentReceiptImage?>[];
  PhoneOrderFailure? placeFailure;

  @override
  Future<List<PhoneOrderCustomer>> searchCustomers(String query) async {
    customerQueries.add(query);
    return query.startsWith('010') ? const [_mona, _appUser] : const [];
  }

  @override
  Future<PhoneOrderCustomer> createCustomer({
    required String fullName,
    required String phone,
    String? address,
    String? zone,
    String? fujitsuZoneId,
    String? phone2,
    String? phone3,
    String? notes,
    String? branch,
    PhoneOrderCustomerType type = PhoneOrderCustomerType.regular,
    String? governorate,
    String? city,
    String? building,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
  }) async {
    created.add({
      'name': fullName,
      'phone': phone,
      'address': address,
      'zone': zone,
    });
    createdDetails.add({
      'fujitsu_zone_id': fujitsuZoneId,
      'phone2': phone2,
      'phone3': phone3,
      'notes': notes,
      'branch': branch,
      'type': type,
      'governorate': governorate,
      'city': city,
      'building': building,
      'floor': floor,
      'apartment': apartment,
      'latitude': latitude,
      'longitude': longitude,
    });
    return PhoneOrderCustomer(
      source: PhoneOrderCustomerSource.pos,
      posCustomerId: 1000000001,
      fullName: fullName,
      phone: phone,
      phone2: phone2,
      phone3: phone3,
      notes: notes,
      address: address,
      zone: zone,
      fujitsuZoneId: fujitsuZoneId,
    );
  }

  @override
  Future<PhoneOrderCustomerDetails> fetchCustomerDetails(
    PhoneOrderCustomer customer,
  ) async {
    return PhoneOrderCustomerDetails(
      customer: customer,
      addresses: [
        if ((customer.address ?? '').trim().isNotEmpty)
          PhoneOrderCustomerAddress(
            id: '1',
            address: customer.address!,
            zone: customer.zone,
            fujitsuZoneId: customer.fujitsuZoneId,
            isPrimary: true,
          ),
      ],
    );
  }

  @override
  Future<PhoneOrderCustomer> updateCustomerDetails({
    required int posCustomerId,
    String? fullName,
    String? phone,
    String? phone2,
    String? phone3,
    String? notes,
  }) async {
    return PhoneOrderCustomer(
      source: PhoneOrderCustomerSource.pos,
      posCustomerId: posCustomerId,
      fullName: fullName,
      phone: phone,
      phone2: phone2?.isEmpty == true ? null : phone2,
      phone3: phone3?.isEmpty == true ? null : phone3,
      notes: notes?.isEmpty == true ? null : notes,
    );
  }

  @override
  Future<PhoneOrderCustomerAddress> upsertCustomerAddress({
    int? posCustomerId,
    String? userId,
    int? addressId,
    String? address,
    String? zone,
    String? branch,
    String? governorate,
    String? city,
    String? building,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
    String? fujitsuZoneId,
    bool isPrimary = false,
  }) async {
    return PhoneOrderCustomerAddress(
      id: '${addressId ?? 99}',
      address: address ?? 'بدون عنوان',
      zone: zone,
      branch: branch,
      governorate: governorate,
      city: city,
      building: building,
      floor: floor,
      apartment: apartment,
      latitude: latitude,
      longitude: longitude,
      fujitsuZoneId: fujitsuZoneId,
      isPrimary: isPrimary,
    );
  }

  @override
  Future<List<Product>> searchProducts(
    String query, {
    MainCategory? category,
    ProductSearchFilterMode filter = ProductSearchFilterMode.inStock,
  }) async =>
      [_milk, _rice]
          .where((p) => p.name.contains(query) || p.barcode == query)
          .toList();

  @override
  Future<String> placeOrder({
    required PhoneOrderCustomer customer,
    required List<PhoneOrderLine> lines,
    required double deliveryFee,
    PhoneOrderPayment paymentMethod = PhoneOrderPayment.cash,
    PaymentReceiptImage? receipt,
    bool isSupplemental = false,
  }) async {
    if (placeFailure != null) throw placeFailure!;
    placed.add((customer: customer, lines: lines, fee: deliveryFee));
    payments.add(paymentMethod);
    receipts.add(receipt);
    return 'a1b2c3d4-0000-0000-0000-000000000000';
  }

  @override
  Future<bool> hasOrderToday(PhoneOrderCustomer customer) async => false;

  @override
  Future<List<PhoneOrderArea>> fetchAreas({String? city}) async => city == null
      ? [for (final zones in areas.values) ...zones]
      : areas[city] ?? const [];

  @override
  Future<CustomerPurchaseHistory> fetchCustomerHistory(
    PhoneOrderCustomer customer,
  ) async =>
      history;
}

Future<void> _confirmCustomerDetails(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('customer-details-sheet')), findsOneWidget);
  await tester.tap(find.byKey(const Key('customer-details-confirm')));
  await tester.pumpAndSettle();
}

Future<void> _confirmAndPlaceOrder(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('phone-order-confirm')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('payment-confirm-dialog')), findsOneWidget);
  await tester.tap(find.byKey(const Key('payment-confirm-submit')));
  await tester.pumpAndSettle();
}

Future<void> _pickCustomer(
  WidgetTester tester,
  PhoneOrderCustomer customer,
) async {
  await tester.tap(find.byKey(Key('phone-order-customer-${customer.key}')));
  await _confirmCustomerDetails(tester);
}

Future<({_FakePhoneOrders repository, List<String> placedIds})> _pumpColumn(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(700, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _FakePhoneOrders();
  final placedIds = <String>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      phoneOrdersRepositoryProvider.overrideWithValue(repository),
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
      home: Scaffold(body: PhoneOrderColumn(onPlaced: placedIds.add)),
    ),
  ));
  return (repository: repository, placedIds: placedIds);
}

Future<void> _type(WidgetTester tester, Key field, String text) async {
  await tester.enterText(find.byKey(field), text);
  await tester.pump(PhoneOrderColumn.searchDebounce);
  await tester.pumpAndSettle();
}

void main() {
  group('PhoneOrderController', () {
    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        phoneOrdersRepositoryProvider.overrideWithValue(_FakePhoneOrders()),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('addFromHistory and replaceLines load past amounts', () {
      final c = container();
      final controller = c.read(phoneOrderControllerProvider.notifier);
      controller.selectCustomer(_mona);
      controller.addFromHistory(_milk, lastQuantity: 3);
      expect(c.read(phoneOrderControllerProvider).quantityOf(_milk.id), 3);
      controller.replaceLines(const [
        PhoneOrderLine(product: _rice, quantity: 2),
      ]);
      final lines = c.read(phoneOrderControllerProvider).lines;
      expect(lines, hasLength(1));
      expect(lines.single.product.id, _rice.id);
      expect(lines.single.quantity, 2);
    });

    test('adds, steps quantities and prices offers like the app', () {
      final c = container();
      final orders = c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_mona)
        ..add(_milk)
        ..add(_rice)
        ..add(_rice)
        ..remove(_milk);
      final state = c.read(phoneOrderControllerProvider);
      expect([for (final l in state.lines) (l.product.id, l.quantity)],
          [('p-rice', 2)]);
      expect(state.itemsTotal, 90, reason: 'offer price 45 × 2');
      expect(state.total, 90 + PhoneOrderState.defaultDeliveryFee);

      orders
        ..setDeliveryFee(0)
        ..setQuantity(_rice, 5000);
      expect(c.read(phoneOrderControllerProvider).lines.single.quantity,
          PhoneOrderState.maxQuantity);
      expect(c.read(phoneOrderControllerProvider).deliveryFee, 0);
    });

    test('a different caller starts an empty cart; the same one keeps it', () {
      final c = container();
      final orders = c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_mona)
        ..add(_milk)
        ..selectCustomer(_mona);
      expect(c.read(phoneOrderControllerProvider).lines, hasLength(1));

      orders.selectCustomer(_appUser);
      expect(c.read(phoneOrderControllerProvider).lines, isEmpty);
    });

    test("selecting a customer applies their zone's delivery fee", () async {
      final c = ProviderContainer(overrides: [
        phoneOrdersRepositoryProvider.overrideWithValue(_FakePhoneOrders()),
      ]);
      addTearDown(c.dispose);
      final orders = c.read(phoneOrderControllerProvider.notifier);

      // Matched by the Fujitsu zone id (Z7 costs 30).
      await orders.selectCustomerWithZoneFee(const PhoneOrderCustomer(
        source: PhoneOrderCustomerSource.pos,
        posCustomerId: 5,
        fullName: 'منى',
        zone: 'اسم قديم',
        fujitsuZoneId: 'Z7',
      ));
      expect(c.read(phoneOrderControllerProvider).deliveryFee, 30);

      // A zone without a fee keeps the current one.
      orders.setDeliveryFee(25);
      await orders.selectCustomerWithZoneFee(const PhoneOrderCustomer(
        source: PhoneOrderCustomerSource.pos,
        posCustomerId: 5,
        fullName: 'منى',
        fujitsuZoneId: 'Z8',
      ));
      expect(c.read(phoneOrderControllerProvider).deliveryFee, 25);
    });

    test('submitting places the order and starts over', () async {
      final repository = _FakePhoneOrders();
      final c = ProviderContainer(overrides: [
        phoneOrdersRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(c.dispose);
      final orders = c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_mona)
        ..add(_milk)
        ..setDeliveryFee(35);

      expect(await orders.submit(), startsWith('a1b2c3d4'));
      expect(repository.placed.single.fee, 35);
      expect(repository.placed.single.customer.posCustomerId, 812);
      expect(c.read(phoneOrderControllerProvider).customer, isNull);
    });

    test('parking keeps every open order; a blank one is not parked', () {
      final c = container();
      final orders = c.read(phoneOrderControllerProvider.notifier);
      PhoneOrderState read() => c.read(phoneOrderControllerProvider);

      orders.parkAndNew();
      expect(read().parked, isEmpty, reason: 'nothing to park yet');

      orders
        ..selectCustomer(_mona)
        ..add(_milk)
        ..setPayment(PhoneOrderPayment.visaOnDelivery)
        ..setDeliveryFee(20)
        ..parkAndNew();
      expect(read().customer, isNull);
      expect(read().lines, isEmpty);
      expect(read().parked, hasLength(1));
      final monaId = read().parked.single.id;
      expect(monaId, isNot(read().id));

      orders
        ..selectCustomer(_appUser)
        ..add(_rice);
      expect(read().openOrders, hasLength(2));

      orders.switchTo(monaId);
      expect(read().customer!.posCustomerId, 812);
      expect(read().paymentMethod, PhoneOrderPayment.visaOnDelivery);
      expect(read().deliveryFee, 20);
      expect(read().quantityOf('p-milk'), 1);
      expect(read().parked.single.customer!.userId, _appUser.userId);
      expect(read().parked.single.quantityOf('p-rice'), 1);

      // Cancelling brings the other order back; cancelling it empties.
      orders.cancelCurrent();
      expect(read().customer!.userId, _appUser.userId);
      expect(read().parked, isEmpty);
      orders.cancelCurrent();
      expect(read().isBlank, isTrue);
      expect(read().paymentMethod, PhoneOrderPayment.cash);
    });

    test('InstaPay needs the receipt; leaving InstaPay drops it', () {
      final c = container();
      final orders = c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_mona)
        ..add(_milk);
      expect(c.read(phoneOrderControllerProvider).paymentMethod,
          PhoneOrderPayment.cash);
      expect(c.read(phoneOrderControllerProvider).canSubmit, isTrue);

      orders.setPayment(PhoneOrderPayment.instaPay);
      expect(c.read(phoneOrderControllerProvider).canSubmit, isFalse);

      orders.setReceipt(PaymentReceiptImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'receipt.png',
        contentType: 'image/png',
      ));
      expect(c.read(phoneOrderControllerProvider).canSubmit, isTrue);

      orders.setPayment(PhoneOrderPayment.visaOnDelivery);
      expect(c.read(phoneOrderControllerProvider).receipt, isNull);
      expect(c.read(phoneOrderControllerProvider).canSubmit, isTrue);
    });

    test('bulk add adds exactly that many on top of the cart', () {
      final c = container();
      c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_mona)
        ..add(_milk)
        ..addQuantity(_milk, 5)
        ..addQuantity(_milk, 0);
      expect(c.read(phoneOrderControllerProvider).quantityOf('p-milk'), 6);
    });

    test('placing sends payment + receipt and promotes a parked order',
        () async {
      final repository = _FakePhoneOrders();
      final c = ProviderContainer(overrides: [
        phoneOrdersRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(c.dispose);
      final orders = c.read(phoneOrderControllerProvider.notifier)
        ..selectCustomer(_appUser)
        ..add(_rice)
        ..parkAndNew()
        ..selectCustomer(_mona)
        ..add(_milk)
        ..setPayment(PhoneOrderPayment.instaPay)
        ..setReceipt(PaymentReceiptImage(
          bytes: Uint8List.fromList([9, 9]),
          fileName: 'receipt.png',
          contentType: 'image/png',
        ));

      await orders.submit();

      expect(repository.payments.single, PhoneOrderPayment.instaPay);
      expect(repository.receipts.single!.fileName, 'receipt.png');
      final state = c.read(phoneOrderControllerProvider);
      expect(state.customer!.userId, _appUser.userId,
          reason: 'the parked order is opened next');
      expect(state.parked, isEmpty);
      expect(state.paymentMethod, PhoneOrderPayment.cash);
    });
  });

  group('SupabasePhoneOrdersRepository', () {
    test('a visa-on-delivery order only flags the payment method', () async {
      final requests = <http.Request>[];
      final recording = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode('a1b2c3d4-0000-0000-0000-000000000000'),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      await SupabasePhoneOrdersRepository(recording).placeOrder(
        customer: _mona,
        lines: const [PhoneOrderLine(product: _milk, quantity: 1)],
        deliveryFee: 30,
        paymentMethod: PhoneOrderPayment.visaOnDelivery,
      );

      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(requests.single.url.path, '/rest/v1/rpc/place_phone_order');
      expect(body['p_payment_method'], 'visa_on_delivery');
      expect(body['p_payment_status'], 'unpaid');
      expect(body.containsKey('p_receipt_url'), isFalse);
    });

    test('an InstaPay order without a receipt is refused before any call',
        () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('"x"', 200, request: request);
        }),
      );
      await expectLater(
        SupabasePhoneOrdersRepository(client).placeOrder(
          customer: _mona,
          lines: const [PhoneOrderLine(product: _milk, quantity: 1)],
          deliveryFee: 30,
          paymentMethod: PhoneOrderPayment.instaPay,
        ),
        throwsA(isA<PhoneOrderFailure>()),
      );
      expect(requests, isEmpty);
    });

    ({SupabasePhoneOrdersRepository repository, List<http.Request> requests})
        repositoryAnswering(Object body, {int status = 200}) {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode(body), status,
              headers: {'content-type': 'application/json'}, request: request);
        }),
      );
      return (
        repository: SupabasePhoneOrdersRepository(client),
        requests: requests,
      );
    }

    test('searches app and POS customers through the staff-only function',
        () async {
      final (:repository, :requests) = repositoryAnswering([
        {
          'source': 'pos',
          'user_id': null,
          'pos_customer_id': 812,
          'full_name': 'منى أحمد',
          'phone': '01012345678',
          'address': 'مدينة نصر',
          'zone': null,
        },
        {
          'source': 'app',
          'user_id': _appUser.userId,
          'pos_customer_id': null,
          'full_name': 'عمرو',
          'phone': '+201000000000',
          'address': null,
          'zone': null,
        },
      ]);

      final customers = await repository.searchCustomers(' 0101 ');

      expect(requests.single.url.path,
          '/rest/v1/rpc/search_phone_order_customers');
      expect(
          jsonDecode(requests.single.body), {'p_query': '0101', 'p_limit': 20});
      expect(customers.first.posCustomerId, 812);
      expect(customers.first.source, PhoneOrderCustomerSource.pos);
      expect(customers.last.userId, _appUser.userId);
      expect(customers.last.source, PhoneOrderCustomerSource.app);
    });

    test('also reads bare pos_customers rows (the hand-made search)', () async {
      final (:repository, requests: _) = repositoryAnswering([
        {
          'id': 812,
          'full_name': 'منى أحمد',
          'phone': '01012345678',
          'address': 'مدينة نصر',
          'zone': null,
          'last_seen': null,
          'source_system': 'Customers',
        },
      ]);

      final customer = (await repository.searchCustomers('0101')).single;
      expect(customer.posCustomerId, 812);
      expect(customer.source, PhoneOrderCustomerSource.pos);
    });

    test('a missing database function says which one and how to add it',
        () async {
      final (:repository, requests: _) = repositoryAnswering({
        'code': 'PGRST202',
        'message': 'Could not find the function public.place_phone_order'
            '(p_address, p_area) in the schema cache',
      }, status: 404);

      await expectLater(
        repository.placeOrder(
          customer: _mona,
          lines: const [PhoneOrderLine(product: _milk, quantity: 1)],
          deliveryFee: 25,
        ),
        throwsA(isA<PhoneOrderFailure>().having(
          (f) => f.message,
          'message',
          allOf(contains('place_phone_order'),
              contains('20261111010000_phone_orders.sql')),
        )),
      );
    });

    test('creating a customer sends the zone\'s Fujitsu id', () async {
      final (:repository, :requests) = repositoryAnswering([
        {
          'source': 'pos',
          'user_id': null,
          'pos_customer_id': 9,
          'full_name': 'سارة',
          'phone': '01198765432',
          'address': 'الحي السابع',
          'zone': 'الحي السابع',
          'fujitsu_zone_id': 'Z7',
        },
      ]);

      final customer = await repository.createCustomer(
        fullName: 'سارة',
        phone: '01198765432',
        zone: 'الحي السابع',
        fujitsuZoneId: 'Z7',
      );

      expect(requests.single.url.path,
          '/rest/v1/rpc/create_phone_order_customer');
      expect(jsonDecode(requests.single.body)['p_fujitsu_zone_id'], 'Z7');
      expect(customer.fujitsuZoneId, 'Z7');
    });

    test('a customer without a zone sends no zone id', () async {
      final (:repository, :requests) = repositoryAnswering([
        {
          'source': 'pos',
          'pos_customer_id': 9,
          'full_name': 'سارة',
          'phone': '01198765432',
        },
      ]);
      await repository.createCustomer(fullName: 'سارة', phone: '01198765432');
      expect(jsonDecode(requests.single.body),
          isNot(contains('p_fujitsu_zone_id')));
    });

    test('zones are read from delivery_zones with their Fujitsu id', () async {
      final (:repository, :requests) = repositoryAnswering([
        {'fujitsu_zone_id': 7, 'name': 'الحي السابع', 'delivery_fee': 30},
        {'fujitsu_zone_id': 'Z8', 'name': 'الحي الثامن', 'delivery_fee': null},
      ]);

      final zones = await repository.fetchAreas(city: 'مدينة نصر');

      expect(requests.single.url.path, '/rest/v1/delivery_zones');
      expect(requests.single.url.queryParameters['city'], 'eq.مدينة نصر');
      expect(zones.map((z) => z.fujitsuZoneId), ['7', 'Z8']);
      expect(zones.first.deliveryFee, 30);
      expect(zones.last.deliveryFee, isNull);
    });

    test('one character is not searched', () async {
      final (:repository, :requests) = repositoryAnswering([]);
      expect(await repository.searchCustomers('0'), isEmpty);
      expect(requests, isEmpty);
    });

    test('places the order with the customer, items and fee', () async {
      final (:repository, :requests) =
          repositoryAnswering('a1b2c3d4-0000-0000-0000-000000000000');

      final id = await repository.placeOrder(
        customer: _mona,
        lines: const [
          PhoneOrderLine(product: _milk, quantity: 2),
          PhoneOrderLine(product: _rice, quantity: 1),
        ],
        deliveryFee: 30,
      );

      expect(id, 'a1b2c3d4-0000-0000-0000-000000000000');
      expect(requests.single.url.path, '/rest/v1/rpc/place_phone_order');
      expect(jsonDecode(requests.single.body), {
        'p_user_id': null,
        'p_pos_customer_id': 812,
        'p_customer_name': 'منى أحمد',
        'p_customer_phone': '01012345678',
        'p_address': 'مدينة نصر، شارع 9',
        'p_area': 'مدينة نصر',
        'p_items': [
          {'product_id': 'p-milk', 'quantity': 2},
          {'product_id': 'p-rice', 'quantity': 1},
        ],
        'p_delivery_fee': 30.0,
      });
    });

    test('staff without the right role are told so', () async {
      final (:repository, requests: _) = repositoryAnswering(
        {'code': '42501', 'message': 'not_allowed'},
        status: 403,
      );
      await expectLater(
        repository.searchCustomers('0101'),
        throwsA(isA<PhoneOrderFailure>().having((f) => f.message, 'message',
            'هذا الحساب غير مصرّح له بتسجيل طلبات التليفون')),
      );
    });

    test('a barcode is matched by prefix, a name by any word', () async {
      final (:repository, :requests) = repositoryAnswering([
        {
          'id': 'p-milk',
          'barcode': '6221234500011',
          'name': 'لبن جهينة 1 لتر',
          'price': 40,
          'stock_quantity': 5,
          'is_active': true,
        },
      ]);

      final byBarcode = await repository.searchProducts('62212345');
      expect(byBarcode.single.id, 'p-milk');
      expect(requests.last.url.queryParameters['or'],
          '(barcode.ilike.62212345*,name.ilike.*62212345*)');
      expect(requests.last.url.queryParameters['stock_quantity'], 'gt.0');

      await repository.searchProducts('جهينة لبن');
      expect(requests.last.url.queryParameters['name'], 'ilike.%جهينة%');

      expect(await repository.searchProducts(''), isEmpty);
      expect(requests, hasLength(2), reason: 'an empty search reads nothing');
    });
  });

  group('PhoneOrderColumn', () {
    testWidgets('find the caller, build the cart, place the order', (
      tester,
    ) async {
      final (:repository, :placedIds) = await _pumpColumn(tester);

      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      expect(repository.customerQueries.last, '0101234');
      expect(find.text('منى أحمد'), findsOneWidget);
      expect(find.text('مدينة نصر، شارع 9'), findsOneWidget);

      await _pickCustomer(tester, _mona);
      expect(
          find.byKey(const Key('phone-order-locked-customer')), findsOneWidget);

      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('phone-order-inc-p-milk')));
      await tester.pump();
      expect(
          tester
              .widget<Text>(find.byKey(const Key('phone-order-qty-p-milk')))
              .data,
          '2');

      await tester.tap(find.byKey(const Key('phone-order-fee-35')));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('phone-order-total'))).data,
        contains('115'),
      );

      await _confirmAndPlaceOrder(tester);

      final order = repository.placed.single;
      expect(order.customer.posCustomerId, 812);
      expect([for (final l in order.lines) (l.product.id, l.quantity)],
          [('p-milk', 2)]);
      expect(order.fee, 35);
      expect(placedIds.single, startsWith('a1b2c3d4'));
      expect(find.text('تم تسجيل الطلب #a1b2c3'), findsOneWidget);
      expect(
          find.byKey(const Key('phone-order-customer-search')), findsOneWidget,
          reason: 'ready for the next call');
    });

    testWidgets('the product results keep room for five or more products', (
      tester,
    ) async {
      await _pumpColumn(tester);
      // Tall enough for the customer-history strip + open cart + results.
      tester.view.physicalSize = const Size(480, 960);
      await tester.pumpAndSettle();
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);
      expect(find.byKey(const Key('phone-order-customer-history')), findsOneWidget);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();

      final list =
          tester.getSize(find.byKey(const Key('phone-order-products')));
      final tile =
          tester.getSize(find.byKey(const Key('phone-order-product-p-milk')));
      expect(list.height / tile.height, greaterThanOrEqualTo(5));

      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();
      final withCartOpen =
          tester.getSize(find.byKey(const Key('phone-order-products')));
      expect(withCartOpen.height, greaterThan(tile.height * 2),
          reason: 'the open cart is capped, so results stay usable');
    });

    testWidgets('a scanned barcode goes straight into the cart', (
      tester,
    ) async {
      await _pumpColumn(tester);
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);

      await tester.enterText(
          find.byKey(const Key('phone-order-product-search')), _rice.barcode!);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<Text>(find.byKey(const Key('phone-order-qty-p-rice')))
              .data,
          '1');
    });

    testWidgets('an unknown caller is added as a new customer', (
      tester,
    ) async {
      final (:repository, placedIds: _) = await _pumpColumn(tester);

      await _type(
          tester, const Key('phone-order-customer-search'), '01198765432');
      expect(find.text('لا يوجد عميل مطابق. أضفه كعميل جديد.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('phone-order-new-customer')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.descendant(
                of: find.byKey(const Key('new-customer-phone')),
                matching: find.byType(EditableText)))
            .controller
            .text,
        '01198765432',
        reason: 'the typed number is carried over',
      );

      await tester.tap(find.byKey(const Key('new-customer-save')));
      await tester.pumpAndSettle();
      expect(find.text('اكتب اسم العميل'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('new-customer-name')), 'سارة علي');
      await tester.tap(find.byKey(const Key('new-customer-save')));
      await tester.pumpAndSettle();
      await _confirmCustomerDetails(tester);

      expect(repository.created.single, {
        'name': 'سارة علي',
        'phone': '01198765432',
        'address': null,
        'zone': null,
      });
      expect(
          find.byKey(const Key('phone-order-locked-customer')), findsOneWidget);
      expect(
          find.textContaining('سارة علي', findRichText: true), findsOneWidget);
    });

    testWidgets('+ عميل جديد: details first, then «إضافة عنوان» in a 2nd modal',
        (tester) async {
      final (:repository, placedIds: _) = await _pumpColumn(tester);

      await tester.tap(find.byKey(const Key('phone-order-new-customer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('new-customer-dialog')), findsOneWidget);
      expect(find.text('رقم الهاتف 1'), findsOneWidget);
      expect(find.text('رقم الهاتف 2 - اختياري'), findsOneWidget);
      expect(find.text('عادي'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      expect(find.byKey(const Key('new-customer-add-address')), findsOneWidget);

      // Step 2 needs a valid name and phone first.
      await tester.tap(find.byKey(const Key('new-customer-add-address')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('customer-address-dialog')), findsNothing);

      await tester.enterText(
          find.byKey(const Key('new-customer-name')), 'سارة علي');
      await tester.enterText(
          find.byKey(const Key('new-customer-phone')), '01198765432');
      await tester.enterText(
          find.byKey(const Key('new-customer-phone2')), '01255555555');
      await tester.tap(find.text('VIP'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-customer-add-address')));
      await tester.pumpAndSettle();

      // The second modal is pre-filled with the name and phone.
      expect(find.byKey(const Key('customer-address-dialog')), findsOneWidget);
      String text(String key) => tester
          .widget<EditableText>(find.descendant(
              of: find.byKey(Key(key)), matching: find.byType(EditableText)))
          .controller
          .text;
      expect(text('address-customer-name'), 'سارة علي');
      expect(text('address-customer-phone'), '01198765432');

      // Right side: building / floor / apartment. Left side: dropdowns.
      expect(find.text('المبنى'), findsOneWidget);
      expect(find.text('الدور'), findsOneWidget);
      expect(find.text('الشقة'), findsOneWidget);
      expect(
        tester.getCenter(find.byKey(const Key('address-building'))).dx,
        greaterThan(
            tester.getCenter(find.byKey(const Key('address-city'))).dx),
        reason: 'RTL: the building side is on the right',
      );
      expect(find.text('القاهرة'), findsOneWidget);
      expect(find.byKey(const Key('address-pick-gps')), findsOneWidget);
      expect(find.text('إضافة موقع العميل (GPS)'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('address-building')), '12');
      await tester.enterText(find.byKey(const Key('address-floor')), '3');
      await tester.enterText(find.byKey(const Key('address-apartment')), '7');

      await tester.tap(find.byKey(const Key('address-city')));
      await tester.pumpAndSettle();
      for (final city in ['مدينة نصر', 'مصر الجديدة', 'التجمع الخامس']) {
        expect(find.text(city), findsWidgets, reason: city);
      }
      await tester.tap(find.text('مدينة نصر').last);
      await tester.pumpAndSettle();

      // The zones come from delivery_zones, with their delivery fee.
      await tester.tap(find.byKey(const ValueKey('address-area-مدينة نصر')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('الحي السابع').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('address-save')));
      await tester.pumpAndSettle();
      await _confirmCustomerDetails(tester);

      expect(repository.created.single['name'], 'سارة علي');
      expect(repository.created.single['phone'], '01198765432');
      expect(repository.created.single['zone'], 'الحي السابع');
      expect(
        repository.created.single['address'],
        'مبنى 12، الدور 3، شقة 7، الحي السابع، مدينة نصر، القاهرة',
      );
      expect(repository.createdDetails.single, {
        // The chosen zone's Fujitsu id is saved with the customer.
        'fujitsu_zone_id': 'Z7',
        'phone2': '01255555555',
        'phone3': null,
        'notes': null,
        'branch': null,
        'type': PhoneOrderCustomerType.vip,
        'governorate': 'القاهرة',
        'city': 'مدينة نصر',
        'building': '12',
        'floor': '3',
        'apartment': '7',
        'latitude': null,
        'longitude': null,
      });
      // Both modals closed; the customer is locked in.
      expect(find.byKey(const Key('customer-address-dialog')), findsNothing);
      expect(find.byKey(const Key('new-customer-dialog')), findsNothing);
      expect(find.byKey(const Key('customer-details-sheet')), findsNothing);
      expect(
          find.byKey(const Key('phone-order-locked-customer')), findsOneWidget);
    });

    testWidgets('product rows: copyable barcode, stock before − / +, no chips',
        (tester) async {
      await _pumpColumn(tester);
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);
      expect(find.byKey(const Key('phone-order-category-all')), findsNothing,
          reason: 'the category chips row is gone');

      await _type(tester, const Key('phone-order-product-search'), 'أرز');

      expect(find.text('المخزون: 15'), findsOneWidget);
      expect(
        tester.getCenter(find.byKey(const Key('phone-order-stock-p-rice'))).dx,
        greaterThan(tester
            .getCenter(find.byKey(const Key('phone-order-add-p-rice')))
            .dx),
        reason: 'RTL: the stock sits right before (to the right of) − / +',
      );

      await tester.tap(find.byKey(const Key('phone-order-barcode-p-rice')));
      await tester.pump();
      expect(clipboard, [_rice.barcode]);
      expect(find.text('تم نسخ الباركود'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      // Copying didn't add the product to the cart.
      expect(
          tester.widget<Text>(find.byKey(const Key('phone-order-total'))).data,
          contains('25'));
    });

    testWidgets('the totals table starts with the item count', (tester) async {
      await _pumpColumn(tester);
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<Text>(find.byKey(const Key('phone-order-items-count')))
              .data,
          '2');
      double top(Finder finder) => tester.getTopLeft(finder).dy;
      final count = top(find.text('عدد المنتجات'));
      final items = top(find.text('إجمالي المنتجات'));
      final fee = top(find.text('رسوم التوصيل').last);
      final total = top(find.text('الإجمالي (سلة العميل)'));
      expect(count, lessThan(items));
      expect(items, lessThan(fee));
      expect(fee, lessThan(total));
    });

    testWidgets('«مشتريات العميل» opens a centered dialog with a close button',
        (tester) async {
      final (:repository, placedIds: _) = await _pumpColumn(tester);
      final now = DateTime.now();
      repository.history = CustomerPurchaseHistory(
        items: [
          CustomerPurchaseItem(
            product: _milk,
            timesOrdered: 5,
            totalQuantity: 9,
            lastOrderedAt: now.subtract(const Duration(days: 2)),
            lastQuantity: 2,
          ),
          CustomerPurchaseItem(
            product: _rice,
            timesOrdered: 2,
            totalQuantity: 2,
            lastOrderedAt: now.subtract(const Duration(days: 90)),
            lastQuantity: 1,
          ),
        ],
        lastOrderLines: const [
          PhoneOrderLine(product: _milk, quantity: 2),
          PhoneOrderLine(product: _rice, quantity: 1),
        ],
      );
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);

      // Nothing inline any more: just the button in the customer bar.
      expect(find.byKey(const Key('phone-order-history-dialog')), findsNothing);
      await tester.tap(find.byKey(const Key('phone-order-customer-history')));
      await tester.pumpAndSettle();

      final dialog = find.byKey(const Key('phone-order-history-dialog'));
      expect(dialog, findsOneWidget);
      expect(
        tester.getCenter(dialog).dx,
        closeTo(tester.view.physicalSize.width / 2, 1),
        reason: 'centered modal',
      );
      expect(find.text('مشتريات العميل المعتادة والسابقة'), findsOneWidget);
      expect(find.text('الأكثر طلباً'), findsWidgets);
      expect(find.byKey(const Key('phone-order-last-order')), findsOneWidget);
      expect(find.byKey(const Key('phone-order-repeat-last')), findsOneWidget);
      expect(find.byKey(const Key('phone-order-history-row-p-milk')),
          findsOneWidget);
      expect(find.byKey(const Key('phone-order-history-row-p-rice')),
          findsOneWidget);

      // Date filter: only the last 7 days keeps the milk.
      await tester.tap(find.byKey(const Key('phone-order-history-date-week')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-history-row-p-milk')),
          findsOneWidget);
      expect(find.byKey(const Key('phone-order-history-row-p-rice')),
          findsNothing);
      await tester.tap(find.byKey(const Key('phone-order-history-date-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-history-row-p-rice')),
          findsOneWidget);

      // Quick re-order loads the last order and closes the dialog.
      await tester.tap(find.byKey(const Key('phone-order-repeat-last')));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(find.text('تم تحميل آخر طلب (2 منتج)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(const Key('phone-order-qty-p-milk')))
              .data,
          '2');

      // «إغلاق» closes it too.
      await tester.tap(find.byKey(const Key('phone-order-customer-history')));
      await tester.pumpAndSettle();
      expect(dialog, findsOneWidget);
      await tester.tap(find.byKey(const Key('phone-order-history-close')));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });

    testWidgets('a refused order keeps the cart and says why', (tester) async {
      final (:repository, placedIds: _) = await _pumpColumn(tester);
      repository.placeFailure =
          const PhoneOrderFailure('تعذّر تسجيل الطلب: product_not_found');
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();

      await _confirmAndPlaceOrder(tester);
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('تعذّر تسجيل الطلب: product_not_found'), findsOneWidget);
      expect(find.byKey(const Key('phone-order-qty-p-milk')), findsOneWidget);
    });

    Future<void> pick(WidgetTester tester, PhoneOrderCustomer who) async {
      await _type(tester, const Key('phone-order-customer-search'), '0101234');
      await _pickCustomer(tester, who);
    }

    Future<void> openCart(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('phone-order-cart-toggle')));
      await tester.pumpAndSettle();
    }

    String qty(WidgetTester tester, String id) =>
        tester.widget<Text>(find.byKey(Key('phone-order-qty-$id'))).data!;

    testWidgets('only + adds one; the row opens details with bulk add', (
      tester,
    ) async {
      await _pumpColumn(tester);
      await pick(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');

      // Tapping the row opens the dialog and adds nothing.
      await tester.tap(find.byKey(const Key('phone-order-product-p-milk')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-details-dialog')), findsOneWidget);
      expect(
        find.descendant(
            of: find.byKey(const Key('product-dialog-barcode')),
            matching: find.text(_milk.barcode!)),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: find.byKey(const Key('product-dialog-stock')),
            matching: find.text('${_milk.stockQuantity}')),
        findsOneWidget,
      );

      // A bad amount stays in the dialog with a hint.
      await tester.enterText(
          find.byKey(const Key('product-dialog-quantity')), '0');
      await tester.tap(find.byKey(const Key('product-dialog-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-details-dialog')), findsOneWidget);
      expect(find.text('أدخل كمية من 1 إلى 999'), findsOneWidget);

      // Enter adds exactly 3 and closes.
      await tester.enterText(
          find.byKey(const Key('product-dialog-quantity')), '3');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-details-dialog')), findsNothing);
      await openCart(tester);
      expect(qty(tester, 'p-milk'), '3');

      // The button adds 2 more on top.
      await tester.tap(find.byKey(const Key('phone-order-product-p-milk')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('product-dialog-quantity')), '2');
      await tester.tap(find.byKey(const Key('product-dialog-add')));
      await tester.pumpAndSettle();
      expect(qty(tester, 'p-milk'), '5');

      // + is one at a time and never opens the dialog; close just closes.
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-details-dialog')), findsNothing);
      expect(qty(tester, 'p-milk'), '6');
      await tester.tap(find.byKey(const Key('phone-order-product-p-milk')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('product-dialog-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-details-dialog')), findsNothing);
      expect(qty(tester, 'p-milk'), '6');
    });

    testWidgets('payment: cash by default, visa only flags the order', (
      tester,
    ) async {
      final (:repository, placedIds: _) = await _pumpColumn(tester);
      await pick(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      await openCart(tester);

      expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const Key('phone-order-payment-cash')))
            .selected,
        isTrue,
      );
      expect(find.byKey(const Key('phone-order-receipt-pick')), findsNothing);

      await tester.tap(find.byKey(const Key('phone-order-payment-visa_on_delivery')));
      await tester.pump();
      expect(find.byKey(const Key('phone-order-receipt-pick')), findsNothing);

      await _confirmAndPlaceOrder(tester);
      expect(repository.payments.single, PhoneOrderPayment.visaOnDelivery);
      expect(repository.receipts.single, isNull);
    });

    testWidgets('InstaPay needs the transfer image, shown as a thumbnail', (
      tester,
    ) async {
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
        'hQGAhKmMIQAAAABJRU5ErkJggg==',
      );
      final (:repository, placedIds: _) = await _pumpColumn(
        tester,
        overrides: [
          phoneOrderReceiptPickerProvider.overrideWithValue(
            () async => PaymentReceiptImage(
              bytes: Uint8List.fromList(png),
              fileName: 'receipt.png',
              contentType: 'image/png',
            ),
          ),
        ],
      );
      await pick(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      await openCart(tester);

      await tester.tap(find.byKey(const Key('phone-order-payment-instapay')));
      await tester.pump();
      expect(find.text('إرفاق صورة التحويل'), findsOneWidget);
      expect(find.byKey(const Key('phone-order-receipt-required')),
          findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('phone-order-confirm')))
            .onPressed,
        isNull,
        reason: 'no receipt yet',
      );

      await tester.tap(find.byKey(const Key('phone-order-receipt-pick')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-receipt-thumb')), findsOneWidget);
      expect(find.byKey(const Key('phone-order-receipt-required')), findsNothing);

      await _confirmAndPlaceOrder(tester);
      expect(repository.payments.single, PhoneOrderPayment.instaPay);
      expect(repository.receipts.single!.fileName, 'receipt.png');
    });

    testWidgets('«إلغاء الطلب» asks first when the cart has items', (
      tester,
    ) async {
      await _pumpColumn(tester);
      await pick(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('phone-order-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-cancel-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('phone-order-cancel-dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-locked-customer')),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('phone-order-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('phone-order-cancel-confirm')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('phone-order-customer-search')), findsOneWidget);
      expect(find.byKey(const Key('phone-order-locked-customer')), findsNothing);
    });

    testWidgets('«إضافة طلب» parks the order; cards switch between orders', (
      tester,
    ) async {
      await _pumpColumn(tester);
      await pick(tester, _mona);
      await _type(tester, const Key('phone-order-product-search'), 'لبن');
      await tester.tap(find.byKey(const Key('phone-order-add-p-milk')));
      await tester.pump();
      expect(find.byKey(const Key('phone-order-open-orders')), findsNothing,
          reason: 'one order needs no list');

      await tester.tap(find.byKey(const Key('phone-order-add-order')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('phone-order-customer-search')), findsOneWidget);
      expect(find.byKey(const Key('phone-order-open-orders')), findsOneWidget);
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-open-1')),
            matching: find.text('منى أحمد')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-open-1')),
            matching: find.text('1 منتج')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-open-2')),
            matching: find.text('طلب جديد')),
        findsOneWidget,
      );

      await pick(tester, _appUser);
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-locked-customer')),
            matching: find.textContaining('عمرو', findRichText: true)),
        findsOneWidget,
      );

      // Back to the first order: its cart is intact.
      await tester.tap(find.byKey(const Key('phone-order-open-1')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-locked-customer')),
            matching: find.textContaining('منى', findRichText: true)),
        findsOneWidget,
      );
      await openCart(tester);
      expect(qty(tester, 'p-milk'), '1');

      // Cancelling it removes it from the list; the other one is left.
      await tester.tap(find.byKey(const Key('phone-order-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('phone-order-cancel-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('phone-order-open-orders')), findsNothing);
      expect(
        find.descendant(
            of: find.byKey(const Key('phone-order-locked-customer')),
            matching: find.textContaining('عمرو', findRichText: true)),
        findsOneWidget,
      );
    });
  });
}
