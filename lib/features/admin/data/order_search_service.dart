import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/order_status.dart';

/// Where an order came from (`orders.order_source`).
enum OrderSearchSource { all, app, phone }

/// The filters of the advanced order search; empty ones are ignored.
class OrderSearchQuery {
  const OrderSearchQuery({
    this.customerPhone = '',
    this.source = OrderSearchSource.all,
    this.date,
    this.receiver = '',
    this.preparer,
    this.driver,
    this.status,
    this.orderNumber = '',
  });

  final String customerPhone;
  final OrderSearchSource source;
  final DateTime? date;

  /// Who took the order (`orders.taker_name`), matched by part of the name.
  final String receiver;
  final String? preparer;
  final String? driver;

  /// An [OrderStatus.value], or null for any status.
  final String? status;

  /// Part of the order number (the start of the order id).
  final String orderNumber;

  bool get isEmpty =>
      customerPhone.trim().isEmpty &&
      source == OrderSearchSource.all &&
      date == null &&
      receiver.trim().isEmpty &&
      (preparer ?? '').isEmpty &&
      (driver ?? '').isEmpty &&
      (status ?? '').isEmpty &&
      orderNumber.trim().isEmpty;
}

typedef OrderSearchFn = Future<List<Map<String, dynamic>>> Function(
  OrderSearchQuery query,
);

/// Whether [order]'s number («#a1b2c3», Fujitsu id, or POS receipt) contains
/// [needle].
bool orderMatchesNumber(Map<String, dynamic> order, String needle) {
  final text = needle.trim().replaceAll('#', '').toLowerCase();
  if (text.isEmpty) return true;
  final id = '${order['id']}'.toLowerCase();
  final fujitsu = '${order['fujitsu_order_id'] ?? ''}'.toLowerCase();
  final receipt = '${order['pos_receipt_number'] ?? ''}'.toLowerCase();
  return id.contains(text) ||
      fujitsu.contains(text) ||
      receipt.contains(text);
}

/// The values `orders.status` may hold for [status]: the app and warehouse
/// write snake_case, the admin dashboard camelCase.
List<String> orderStatusSpellings(String status) {
  final value = OrderStatus.normalize(status);
  final parts = value.split('_');
  final camel = parts.first +
      parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
  return {
    value,
    camel,
    if (value == OrderStatus.preparing.value) 'processing',
    if (value == OrderStatus.pending.value) 'new',
  }.toList();
}

/// Newest [limit] orders matching [query]. The order number is not filtered
/// here (ids are uuids, which can't be pattern matched in SQL); see
/// [orderMatchesNumber].
Future<List<Map<String, dynamic>>> searchOrdersInSupabase(
  SupabaseClient client,
  OrderSearchQuery query, {
  int limit = 500,
}) async {
  var request = client.from('orders').select();

  var phone = query.customerPhone.replaceAll(RegExp(r'\D'), '');
  if (phone.startsWith('0020')) phone = '0${phone.substring(4)}';
  if (phone.length > 10 && phone.startsWith('20')) {
    phone = '0${phone.substring(2)}';
  }
  if (phone.isNotEmpty) {
    // Phone orders store the number on the order; app orders only have it
    // on the customer's profile. Digit needles also match Fujitsu customer nos.
    final profiles = await client
        .from('profiles')
        .select('id')
        .ilike('phone', '%$phone%')
        .limit(200);
    final ids = [for (final row in profiles) '${row['id']}'];
    final posCustomers = await client
        .from('pos_customers')
        .select('id')
        .or(
          'fujitsu_customer_no.eq.$phone,'
          'phone.ilike.%$phone%,'
          'phone2.ilike.%$phone%,'
          'phone3.ilike.%$phone%',
        )
        .limit(200);
    final posIds = [for (final row in posCustomers) '${row['id']}'];
    request = request.or([
      'customer_phone.ilike.%$phone%',
      'fujitsu_customer_no.eq.$phone',
      if (ids.isNotEmpty) 'user_id.in.(${ids.join(',')})',
      if (posIds.isNotEmpty) 'pos_customer_id.in.(${posIds.join(',')})',
    ].join(','));
  }

  switch (query.source) {
    case OrderSearchSource.all:
      break;
    case OrderSearchSource.phone:
      request = request.eq('order_source', 'phone');
    case OrderSearchSource.app:
      request = request.or('order_source.is.null,order_source.neq.phone');
  }

  if (query.date case final date?) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    request = request
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String());
  }

  final receiver = query.receiver.trim();
  if (receiver.isNotEmpty) request = request.ilike('taker_name', '%$receiver%');
  if ((query.preparer ?? '').isNotEmpty) {
    request = request.eq('preparer_name', query.preparer!);
  }
  if ((query.driver ?? '').isNotEmpty) {
    request = request.eq('driver_name', query.driver!);
  }
  if ((query.status ?? '').isNotEmpty) {
    request = request.inFilter('status', orderStatusSpellings(query.status!));
  }

  // Fujitsu / POS receipt numbers are searchable server-side (digits).
  final orderNo = query.orderNumber.trim().replaceAll('#', '');
  final digitsOnly = orderNo.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length >= 6 && RegExp(r'^\d+$').hasMatch(digitsOnly)) {
    request = request.or(
      'fujitsu_order_id.ilike.%$digitsOnly%,'
      'pos_receipt_number.ilike.%$digitsOnly%',
    );
  }

  final rows = await request.order('created_at', ascending: false).limit(limit);
  return List<Map<String, dynamic>>.from(rows);
}
