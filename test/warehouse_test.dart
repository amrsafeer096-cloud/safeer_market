import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/home/presentation/screens/home_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/search/presentation/providers/barcode_scanner_provider.dart';
import 'package:safeer_market/features/warehouse/domain/entities/receipt_line.dart';
import 'package:safeer_market/features/warehouse/domain/entities/receipt_product.dart';
import 'package:safeer_market/features/warehouse/domain/entities/receipt_type.dart';
import 'package:safeer_market/features/warehouse/domain/entities/supplier.dart';
import 'package:safeer_market/features/warehouse/domain/entities/warehouse_order.dart';
import 'package:safeer_market/features/warehouse/domain/repositories/goods_receipts_repository.dart';
import 'package:safeer_market/features/warehouse/domain/repositories/warehouse_orders_repository.dart';
import 'package:safeer_market/features/warehouse/presentation/providers/goods_receipt_providers.dart';
import 'package:safeer_market/features/warehouse/presentation/screens/goods_receipt_screen.dart';
import 'package:safeer_market/features/warehouse/presentation/screens/warehouse_dashboard_screen.dart';

import 'test_helpers.dart';

final _newOrder = WarehouseOrder(
  id: 'aaaa1111-0000-0000-0000-000000000000',
  createdAt: DateTime(2026, 10, 4, 18, 0),
  status: 'pending',
  totalAmount: 120,
  customerName: 'منى حسن',
  addressDetails: 'المنزل: شارع مكرم عبيد، عمارة 7',
  items: const [
    WarehouseOrderItem(productName: 'لبن جهينة', quantity: 2),
    WarehouseOrderItem(productName: 'عيش بلدي', quantity: 5),
  ],
);

final _preparingOrder = WarehouseOrder(
  id: 'bbbb2222-0000-0000-0000-000000000000',
  createdAt: DateTime(2026, 10, 4, 17, 30),
  status: 'preparing',
  totalAmount: 60,
  items: const [WarehouseOrderItem(productName: 'جبنة رومي', quantity: 1)],
);

Future<({FakeWarehouseOrdersRepository orders, FakeNewOrderNotifier alerts})>
    _openDashboard(
  WidgetTester tester, {
  List<WarehouseOrder>? orders,
  WarehouseFailure? failure,
}) async {
  final repository = FakeWarehouseOrdersRepository(
    orders: orders ?? [_newOrder, _preparingOrder],
    failure: failure,
  );
  final alerts = FakeNewOrderNotifier();
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    profileRepository: FakeProfileRepository(
      const UserProfile(id: 'user-1', fullName: 'سامي المخزن'),
      UserRole.warehouse,
    ),
    warehouseOrdersRepository: repository,
    newOrderNotifier: alerts,
  );
  await skipSplash(tester);
  return (orders: repository, alerts: alerts);
}

void main() {
  testWidgets('warehouse staff land on their dashboard with new orders', (
    tester,
  ) async {
    await _openDashboard(tester);

    expect(find.byType(WarehouseDashboardScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('أهلاً يا سامي المخزن'), findsOneWidget);
    expect(find.text('طلبات جديدة (1)'), findsOneWidget);
    expect(find.text('قيد التجهيز (1)'), findsOneWidget);

    expect(find.text('طلب #aaaa11'), findsOneWidget);
    expect(find.text('المنتجات (7)'), findsOneWidget);
    expect(find.text('لبن جهينة'), findsOneWidget);
    expect(find.text('×5'), findsOneWidget);
    expect(find.text('العميل: منى حسن'), findsOneWidget);
    expect(find.text('بدء التجهيز'), findsOneWidget);
    expect(find.text('جاهز للتوصيل'), findsNothing);
  });

  testWidgets('بدء التجهيز moves a pending order to preparing', (
    tester,
  ) async {
    final (:orders, :alerts) = await _openDashboard(tester);

    await tester.tap(find.text('بدء التجهيز'));
    await tester.pumpAndSettle();

    expect(orders.transitions, [(_newOrder.id, 'preparing')]);
    expect(
      find.text('بدأ تجهيز الطلب #aaaa11، تجده في «قيد التجهيز»'),
      findsOneWidget,
    );
    expect(find.text('لا توجد طلبات جديدة\nاسحب للتحديث'), findsOneWidget);
    expect(find.text('قيد التجهيز (2)'), findsOneWidget);
    expect(alerts.notifiedOrders, isEmpty);
  });

  testWidgets('جاهز للتوصيل hands the order to drivers and notifies them', (
    tester,
  ) async {
    final (:orders, :alerts) = await _openDashboard(tester);

    await tester.tap(find.text('قيد التجهيز (1)'));
    await tester.pumpAndSettle();
    expect(find.text('طلب #bbbb22'), findsOneWidget);
    expect(find.text('جبنة رومي'), findsOneWidget);

    await tester.tap(find.text('جاهز للتوصيل'));
    await tester.pumpAndSettle();

    expect(orders.transitions, [(_preparingOrder.id, 'ready_for_delivery')]);
    expect(alerts.notifiedOrders, [_preparingOrder.id]);
    expect(
      find.text('الطلب #bbbb22 جاهز، تم إشعار مناديب التوصيل'),
      findsOneWidget,
    );
    expect(find.text('لا توجد طلبات قيد التجهيز'), findsOneWidget);
  });

  testWidgets('a realtime change refreshes the queue', (tester) async {
    final (:orders, alerts: _) = await _openDashboard(
      tester,
      orders: [_preparingOrder],
    );
    expect(find.text('لا توجد طلبات جديدة\nاسحب للتحديث'), findsOneWidget);

    orders.orders.add(_newOrder);
    orders.emitChange();
    await tester.pumpAndSettle();

    expect(find.text('طلب #aaaa11'), findsOneWidget);
    expect(find.text('طلبات جديدة (1)'), findsOneWidget);
  });

  testWidgets('a failed update is explained', (tester) async {
    await _openDashboard(
      tester,
      failure: const WarehouseFailure(
        'تعذر تحديث الطلب، ربما تم تحديثه بالفعل',
      ),
    );

    await tester.tap(find.text('بدء التجهيز'));
    await tester.pumpAndSettle();

    expect(
      find.text('تعذر تحديث الطلب، ربما تم تحديثه بالفعل'),
      findsOneWidget,
    );
  });

  testWidgets('customers do not see goods receipt', (tester) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
    );
    await skipSplash(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('استلام بضاعة'), findsNothing);
  });

  testWidgets('warehouse staff submit a scanned receipt', (tester) async {
    final receipts = await _openGoodsReceipt(tester);

    await tester.enterText(
      find.byKey(const Key('goods-receipt-supplier')),
      '204',
    );
    await tester.pumpAndSettle();
    expect(find.text('مورد الدلتا'), findsNothing);
    await tester.tap(find.text('مورد النيل'));
    await tester.pumpAndSettle();
    expect(find.text('204 - مورد النيل'), findsOneWidget);

    await _fillInvoiceAndScan(tester);

    expect(find.text('لبن جهينة 1 لتر'), findsOneWidget);
    expect(find.text('6221111'), findsOneWidget);
    expect(find.text('الكمية: 4'), findsOneWidget);

    await tester.tap(find.text('إرسال أمر الاستلام'));
    await tester.pumpAndSettle();

    final today = DateUtils.dateOnly(DateTime.now());
    expect(receipts.submitted, hasLength(1));
    final receipt = receipts.submitted.single;
    expect(receipt.type, ReceiptType.receive);
    expect(receipt.supplier.number, 204);
    expect(receipt.supplier.name, 'مورد النيل');
    expect(receipt.invoiceNumber.trim(), 'INV-77');
    expect(receipt.invoiceDate, today);
    expect(receipt.items, hasLength(1));
    expect(receipt.items.single.barcode, '6221111');
    expect(receipt.items.single.quantity, 4);
    expect(find.byType(WarehouseDashboardScreen), findsOneWidget);
    expect(find.text('تم حفظ أمر الاستلام'), findsOneWidget);
  });

  testWidgets('a document needs an invoice number and date', (tester) async {
    final receipts = await _openGoodsReceipt(tester);

    await tester.enterText(
      find.byKey(const Key('goods-receipt-supplier')),
      'الدلتا',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('مورد الدلتا'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إرسال أمر الاستلام'));
    await tester.pumpAndSettle();

    expect(find.text('رقم الفاتورة مطلوب'), findsOneWidget);
    expect(find.text('تاريخ الفاتورة مطلوب'), findsOneWidget);
    expect(find.text('اختر المورد'), findsNothing);
    expect(receipts.submitted, isEmpty);
    expect(find.byType(GoodsReceiptScreen), findsOneWidget);
  });

  testWidgets('a return is saved with its document type', (tester) async {
    final receipts = await _openGoodsReceipt(tester);

    await tester.tap(find.text('استرجاع'));
    await tester.pumpAndSettle();
    expect(find.text('استرجاع بضاعة'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('goods-receipt-supplier')),
      '204',
    );
    await tester.pumpAndSettle();
    await _fillInvoiceAndScan(tester);
    await tester.tap(find.text('إرسال أمر الاسترجاع'));
    await tester.pumpAndSettle();

    expect(receipts.submitted, hasLength(1));
    expect(receipts.submitted.single.type, ReceiptType.supplierReturn);
    expect(find.text('تم حفظ أمر الاسترجاع'), findsOneWidget);
  });

  testWidgets('a typed number of a listed supplier is accepted', (
    tester,
  ) async {
    final receipts = await _openGoodsReceipt(tester);

    await tester.enterText(
      find.byKey(const Key('goods-receipt-supplier')),
      '315',
    );
    await tester.pumpAndSettle();
    await _fillInvoiceAndScan(tester);
    await tester.tap(find.text('إرسال أمر الاستلام'));
    await tester.pumpAndSettle();

    expect(receipts.submitted, hasLength(1));
    expect(receipts.submitted.single.supplier.number, 315);
    expect(receipts.submitted.single.supplier.name, 'مورد الدلتا');
    expect(find.byType(WarehouseDashboardScreen), findsOneWidget);
  });

  testWidgets('a supplier that is not in the list is rejected', (
    tester,
  ) async {
    final receipts = await _openGoodsReceipt(tester);

    await tester.enterText(
      find.byKey(const Key('goods-receipt-supplier')),
      '454',
    );
    await tester.pumpAndSettle();
    await _fillInvoiceAndScan(tester);
    await tester.tap(find.text('إرسال أمر الاستلام'));
    await tester.pumpAndSettle();

    expect(find.text('اختر المورد من القائمة'), findsOneWidget);
    expect(receipts.submitted, isEmpty);
  });

  testWidgets('the supplier field cannot be left empty', (tester) async {
    final receipts = await _openGoodsReceipt(tester);

    await _fillInvoiceAndScan(tester);
    await tester.tap(find.text('إرسال أمر الاستلام'));
    await tester.pumpAndSettle();

    expect(find.text('اختر المورد'), findsOneWidget);
    expect(receipts.submitted, isEmpty);
  });
}

Future<void> _fillInvoiceAndScan(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('goods-receipt-invoice-number')),
    ' INV-77 ',
  );
  await tester.tap(find.byKey(const Key('goods-receipt-invoice-date')));
  await tester.pumpAndSettle();
  await _confirmDatePicker(tester);

  await tester.tap(find.byTooltip('مسح الباركود'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('goods-receipt-quantity')), '4');
  await tester.tap(find.text('إضافة'));
  await tester.pumpAndSettle();
}

const _suppliers = [
  Supplier(number: 204, name: 'مورد النيل'),
  Supplier(number: 315, name: 'مورد الدلتا'),
];

Future<_FakeGoodsReceiptsRepository> _openGoodsReceipt(
  WidgetTester tester,
) async {
  final receipts = _FakeGoodsReceiptsRepository();
  await pumpApp(
    tester,
    authRepository: FakeAuthRepository(user: testUser),
    profileRepository: FakeProfileRepository(
      const UserProfile(id: 'user-1', fullName: 'سامي المخزن'),
      UserRole.warehouse,
    ),
    overrides: [
      goodsReceiptsRepositoryProvider.overrideWithValue(receipts),
      barcodeScannerProvider.overrideWithValue((_) async => ' 6221111 '),
    ],
  );
  await skipSplash(tester);

  expect(find.text('استلام بضاعة'), findsOneWidget);
  await tester.tap(find.text('استلام بضاعة'));
  await tester.pumpAndSettle();
  expect(find.byType(GoodsReceiptScreen), findsOneWidget);
  return receipts;
}

Future<void> _confirmDatePicker(WidgetTester tester) async {
  final dialog = find.byType(DatePickerDialog);
  expect(dialog, findsOneWidget);
  final ok = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
  await tester.tap(find.descendant(of: dialog, matching: find.text(ok)));
  await tester.pumpAndSettle();
}

class _FakeGoodsReceiptsRepository implements GoodsReceiptsRepository {
  final submitted = <({
    ReceiptType type,
    Supplier supplier,
    String invoiceNumber,
    DateTime invoiceDate,
    List<ReceiptLine> items,
  })>[];

  @override
  Future<List<Supplier>> fetchSuppliers() async => _suppliers;

  @override
  Future<ReceiptProduct> lookupProduct(String barcode) async =>
      ReceiptProduct(name: barcode == '6221111' ? 'لبن جهينة 1 لتر' : null);

  @override
  Future<String> submit({
    required ReceiptType type,
    required Supplier supplier,
    required String invoiceNumber,
    required DateTime invoiceDate,
    required List<ReceiptLine> items,
  }) async {
    submitted.add((
      type: type,
      supplier: supplier,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      items: items,
    ));
    return 'receipt-1';
  }
}
