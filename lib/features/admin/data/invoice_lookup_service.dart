import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/prep_receipt.dart';
import 'order_search_service.dart';

/// Columns needed for the reports invoice search hit list.
const _invoiceSearchSelect =
    'id, customer_name, customer_phone, '
    'created_at, status, total_amount, delivery_fee, taker_name, '
    'preparer_name, driver_name, fujitsu_order_id, pos_receipt_number, '
    'address_details, payment_method';

/// Search orders by customer name / phone or order / invoice number.
Future<List<Map<String, dynamic>>> searchReportInvoices(
  SupabaseClient client,
  String raw, {
  int limit = 40,
}) async {
  final q = raw.trim();
  if (q.length < 2) return const [];

  final needle = q.replaceAll('#', '').trim();
  if (needle.isEmpty) return const [];
  final digits = needle.replaceAll(RegExp(r'\D'), '');
  final lower = needle.toLowerCase();

  final byId = <String, Map<String, dynamic>>{};

  void absorb(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      byId['${row['id']}'] = row;
    }
  }

  Future<void> run(Future<dynamic> request) async {
    final rows = await request;
    absorb(List<Map<String, dynamic>>.from(rows as List));
  }

  await run(client
      .from('orders')
      .select(_invoiceSearchSelect)
      .ilike('customer_name', '%$needle%')
      .order('created_at', ascending: false)
      .limit(limit));

  if (digits.length >= 4) {
    await run(client
        .from('orders')
        .select(_invoiceSearchSelect)
        .ilike('customer_phone', '%$digits%')
        .order('created_at', ascending: false)
        .limit(limit));

    // App orders often store the phone only on the profile.
    final profiles = await client
        .from('profiles')
        .select('id')
        .ilike('phone', '%$digits%')
        .limit(80);
    final ids = [
      for (final row in profiles) '${row['id']}',
    ];
    if (ids.isNotEmpty) {
      await run(client
          .from('orders')
          .select(_invoiceSearchSelect)
          .inFilter('user_id', ids)
          .order('created_at', ascending: false)
          .limit(limit));
    }
  }

  await run(client
      .from('orders')
      .select(_invoiceSearchSelect)
      .or(
        'fujitsu_order_id.ilike.%$needle%,'
        'pos_receipt_number.ilike.%$needle%',
      )
      .order('created_at', ascending: false)
      .limit(limit));

  // Short order id / UUID fragment — scan a recent window client-side.
  if (needle.length >= 4 && byId.length < limit) {
    final recent = await client
        .from('orders')
        .select(_invoiceSearchSelect)
        .order('created_at', ascending: false)
        .limit(250);
    for (final row in recent) {
      final map = Map<String, dynamic>.from(row);
      final id = '${map['id']}';
      if (byId.containsKey(id)) continue;
      final fujitsu = '${map['fujitsu_order_id'] ?? ''}'.toLowerCase();
      final receipt = '${map['pos_receipt_number'] ?? ''}'.toLowerCase();
      if (orderMatchesNumber(map, needle) ||
          fujitsu.contains(lower) ||
          receipt.contains(lower)) {
        byId[id] = map;
      }
    }
  }

  final list = byId.values.toList()
    ..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
  return list.take(limit).toList();
}

/// Builds a receipt-style invoice for reports (no cashier QR).
Future<PrepReceipt> loadInvoicePreview(
  SupabaseClient client,
  String orderId,
) async {
  final order = await client.from('orders').select().eq('id', orderId).single();
  final hasPreparer =
      (order['preparer_name']?.toString().trim() ?? '').isNotEmpty;

  if (hasPreparer) {
    try {
      final raw = await client.rpc(
        'get_order_prep_receipt',
        params: {'p_order_id': orderId},
      );
      if (raw is Map) {
        final receipt =
            PrepReceipt.fromJson(Map<String, dynamic>.from(raw));
        return _withDriverNoQr(
          receipt,
          driverName: order['driver_name']?.toString(),
        );
      }
    } catch (_) {
      // Fall through to a direct build (e.g. waiting Fujitsu).
    }
  }

  return _buildFromOrderRow(client, order);
}

PrepReceipt _withDriverNoQr(
  PrepReceipt receipt, {
  String? driverName,
}) {
  return PrepReceipt(
    orderId: receipt.orderId,
    receiptNumber: receipt.receiptNumber,
    qrPayload: '',
    storeName: receipt.storeName,
    branchName: receipt.branchName,
    branchCode: receipt.branchCode,
    createdAt: receipt.createdAt,
    deliveryFee: receipt.deliveryFee,
    totalAmount: receipt.totalAmount,
    items: receipt.items,
    waitingFujitsu: false,
    fujitsuOrderId: receipt.fujitsuOrderId,
    fujitsuCustomerNo: receipt.fujitsuCustomerNo,
    fujitsuAddressId: receipt.fujitsuAddressId,
    takerName: receipt.takerName,
    preparerName: receipt.preparerName,
    driverName: (driverName?.trim().isNotEmpty ?? false)
        ? driverName!.trim()
        : receipt.driverName,
    customerName: receipt.customerName,
    customerPhone: receipt.customerPhone,
    customerPhone2: receipt.customerPhone2,
    address: receipt.address,
    deliveryArea: receipt.deliveryArea,
    paymentMethod: receipt.paymentMethod,
    posCustomerId: receipt.posCustomerId,
    fujitsuZoneId: receipt.fujitsuZoneId,
    orderSource: receipt.orderSource,
    commitPrices: receipt.commitPrices,
    pilotNo: receipt.pilotNo,
  );
}

Future<PrepReceipt> _buildFromOrderRow(
  SupabaseClient client,
  Map<String, dynamic> order,
) async {
  final orderId = '${order['id']}';
  String? phone2;
  final posId = order['pos_customer_id'];
  if (posId != null) {
    try {
      final row = await client
          .from('pos_customers')
          .select('phone2')
          .eq('id', posId)
          .maybeSingle();
      phone2 = row?['phone2']?.toString();
    } catch (_) {}
  }

  final rawItems = await client
      .from('order_items')
      .select(
        'id, quantity, price_at_time, weight_in_grams, '
        'products(name, barcode, price, discount_price, category)',
      )
      .eq('order_id', orderId);

  final items = <PrepReceiptItem>[];
  for (final row in rawItems) {
    final map = Map<String, dynamic>.from(row);
    final product = map['products'];
    final p = product is Map
        ? Map<String, dynamic>.from(product)
        : <String, dynamic>{};
    items.add(PrepReceiptItem.fromJson({
      'product_name': p['name'],
      'barcode': p['barcode'],
      'quantity': map['quantity'],
      'unit_price': map['price_at_time'],
      'list_price': p['price'],
      'discount_price': p['discount_price'],
      'category_name': p['category'],
    }));
  }

  double money(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String t => double.tryParse(t) ?? 0,
        _ => 0,
      };

  String? text(Object? value) {
    final v = value?.toString().trim();
    return v == null || v.isEmpty ? null : v;
  }

  final fujitsuOrderId = text(order['fujitsu_order_id']);
  return PrepReceipt(
    orderId: orderId,
    receiptNumber:
        fujitsuOrderId ?? text(order['pos_receipt_number']) ?? orderId,
    qrPayload: '',
    storeName: 'سفير ماركت',
    branchName: 'حي الزهور',
    branchCode: '001',
    createdAt:
        DateTime.tryParse('${order['created_at']}')?.toLocal() ?? DateTime.now(),
    deliveryFee: money(order['delivery_fee']),
    totalAmount: money(order['total_amount']),
    items: items,
    waitingFujitsu: false,
    fujitsuOrderId: fujitsuOrderId,
    fujitsuCustomerNo: text(order['fujitsu_customer_no']),
    fujitsuAddressId: text(order['fujitsu_address_id']),
    takerName: text(order['taker_name']),
    preparerName: text(order['preparer_name']),
    driverName: text(order['driver_name']),
    customerName: text(order['customer_name']),
    customerPhone: text(order['customer_phone']),
    customerPhone2: text(phone2),
    address: text(order['address_details']),
    deliveryArea: text(order['delivery_area']),
    paymentMethod: text(order['payment_method']),
    posCustomerId: text(order['pos_customer_id']?.toString()),
    fujitsuZoneId: text(order['fujitsu_zone_id']),
    orderSource: PrepReceipt.fujitsuOrderSource(text(order['order_source'])),
  );
}
