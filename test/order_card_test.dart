import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/orders/domain/entities/customer_order.dart';

import 'test_helpers.dart';

const _onTheWay = 'aaaa1111-0000-0000-0000-000000000001';
const _ready = 'bbbb2222-0000-0000-0000-000000000002';
const _odd = 'cccc3333-0000-0000-0000-000000000003';

CustomerOrder _order(String id, String status, {int day = 14}) => CustomerOrder(
      id: id,
      createdAt: DateTime(2026, 11, day, 18),
      totalAmount: 120,
      status: status,
      addressDetails: 'المنزل: شارع مكرم عبيد، مدينة نصر',
      deliveryLatitude: 30.0560,
      deliveryLongitude: 31.3460,
    );

Future<FakeOrdersRepository> _openMyOrders(
  WidgetTester tester,
  List<CustomerOrder> orders,
) async {
  final repository = FakeOrdersRepository(orders, {
    _ready: const [
      CustomerOrderItem(
          productName: 'جبنة دومتي فيتا', quantity: 2, unitPrice: 25),
      CustomerOrderItem(
        productName: 'طماطم',
        quantity: 1,
        unitPrice: 12.5,
        weightInGrams: 500,
      ),
    ],
  });
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
  return repository;
}

Finder _inCard(String id, Finder finder) =>
    find.descendant(of: find.byKey(Key('order-card-$id')), matching: finder);

void main() {
  testWidgets("the dashboard's camelCase statuses get Arabic labels", (
    tester,
  ) async {
    await _openMyOrders(tester, [
      _order(_onTheWay, 'outForDelivery', day: 14),
      _order(_ready, 'readyForDelivery', day: 13),
    ]);

    expect(find.text('outForDelivery'), findsNothing);
    expect(find.text('readyForDelivery'), findsNothing);
    expect(_inCard(_onTheWay, find.text('حالة الطلب: الطلب في الطريق إليك!')),
        findsOneWidget);
    expect(_inCard(_ready, find.text('حالة الطلب: في انتظار مندوب التوصيل')),
        findsOneWidget);
    expect(_inCard(_ready, find.text('جاهز')), findsOneWidget);

    final chipText =
        tester.widget<Text>(_inCard(_onTheWay, find.text('في الطريق')).first);
    expect(chipText.style?.color, const Color(0xFF1565C0));
  });

  testWidgets(
      'an order on the way opens with the tracking button '
      'right below the steps', (tester) async {
    useFakeGoogleMaps();
    await _openMyOrders(tester, [_order(_onTheWay, 'outForDelivery')]);

    final progress =
        _inCard(_onTheWay, find.byKey(const Key('order-progress')));
    final track = _inCard(_onTheWay, find.text('تتبع الطلب على الخريطة'));
    expect(progress, findsOneWidget);
    expect(track, findsOneWidget);
    expect(tester.getTopLeft(track).dy,
        greaterThan(tester.getBottomLeft(progress).dy));

    await tester.tap(track);
    await tester.pumpAndSettle();
    expect(find.text('تتبع الطلب #aaaa1111'), findsOneWidget);
  });

  testWidgets('tapping a ready order shows its steps and products', (
    tester,
  ) async {
    final repository =
        await _openMyOrders(tester, [_order(_ready, 'readyForDelivery')]);
    expect(
        _inCard(_ready, find.byKey(const Key('order-progress'))), findsNothing);
    expect(repository.itemRequests, isEmpty);

    await tester.tap(find.byKey(const Key('order-card-$_ready')));
    await tester.pumpAndSettle();

    expect(_inCard(_ready, find.byKey(const Key('order-progress'))),
        findsOneWidget);
    expect(repository.itemRequests, [_ready]);
    expect(find.text('جبنة دومتي فيتا'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('طماطم'), findsOneWidget);
    expect(find.text('المنزل: شارع مكرم عبيد، مدينة نصر'), findsOneWidget);
    expect(find.text('تتبع الطلب على الخريطة'), findsNothing);

    await tester.tap(find.byKey(const Key('order-card-$_ready')));
    await tester.pumpAndSettle();
    expect(
        _inCard(_ready, find.byKey(const Key('order-progress'))), findsNothing);
  });

  testWidgets('an order with an unknown status still opens', (tester) async {
    await _openMyOrders(tester, [_order(_odd, 'on_hold')]);

    expect(find.text('on_hold'), findsNothing);
    await tester.tap(find.byKey(const Key('order-card-$_odd')));
    await tester.pumpAndSettle();

    expect(
        _inCard(_odd, find.byKey(const Key('order-progress'))), findsOneWidget);
    expect(find.text('لا توجد منتجات مسجلة لهذا الطلب'), findsOneWidget);
  });
}
