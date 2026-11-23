import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order_rating.dart';
import '../domain/reports.dart';
import 'order_search_service.dart';

/// Reads the rows a report is built from.
abstract class ReportDataSource {
  /// Newest orders matching [filters] (already limited to the filters that
  /// apply to the report).
  Future<List<Map<String, dynamic>>> orders(ReportFilters filters);

  /// `order_items` rows (with their product) of [orderIds].
  Future<List<Map<String, dynamic>>> orderItems(List<String> orderIds);

  /// Customer ratings in the date window, newest first (joined to orders).
  Future<List<OrderRating>> orderRatings(ReportFilters filters);
}

class SupabaseReportDataSource implements ReportDataSource {
  const SupabaseReportDataSource(this._client);

  static const maxOrders = 5000;
  static const _chunk = 150;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> orders(ReportFilters filters) async {
    var request = _client
        .from('orders')
        .select()
        .gte('created_at', filters.start.toUtc().toIso8601String())
        .lt('created_at', filters.endExclusive.toUtc().toIso8601String());

    final receiver = filters.receiver.trim();
    if (receiver.isNotEmpty) {
      request = request.ilike('taker_name', '%$receiver%');
    }
    if ((filters.preparer ?? '').isNotEmpty) {
      request = request.eq('preparer_name', filters.preparer!);
    }
    if ((filters.driver ?? '').isNotEmpty) {
      request = request.eq('driver_name', filters.driver!);
    }
    if ((filters.status ?? '').isNotEmpty) {
      request =
          request.inFilter('status', orderStatusSpellings(filters.status!));
    }

    final rows =
        await request.order('created_at', ascending: false).limit(maxOrders);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> orderItems(List<String> orderIds) async {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < orderIds.length; i += _chunk) {
      final ids = orderIds.sublist(
          i, i + _chunk > orderIds.length ? orderIds.length : i + _chunk);
      final rows = await _client
          .from('order_items')
          .select(
              'order_id, product_id, quantity, price_at_time, weight_in_grams, products(name, barcode)')
          .inFilter('order_id', ids);
      result.addAll(List<Map<String, dynamic>>.from(rows));
    }
    return result;
  }

  @override
  Future<List<OrderRating>> orderRatings(ReportFilters filters) async {
    final rows = await _client
        .from('order_ratings')
        .select(
          'id, order_id, delivery_rating, product_rating, comment, created_at, '
          'orders(id, customer_name, driver_name)',
        )
        .gte('created_at', filters.start.toUtc().toIso8601String())
        .lt('created_at', filters.endExclusive.toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(maxOrders);
    return [
      for (final row in List<Map<String, dynamic>>.from(rows))
        if (OrderRating.fromRow(row) case final rating?) rating,
    ];
  }
}

/// Runs [kind] over [filters]: reads the orders (and, for the items report,
/// their lines) and builds the table.
Future<ReportTable> generateReport(
  ReportDataSource source,
  ReportKind kind,
  ReportFilters filters, {
  Money? money,
  DateTime? now,
  bool lowRatingsOnly = false,
}) async {
  if (kind == ReportKind.customerRatings) {
    final ratings =
        await source.orderRatings(filters.limitedTo(kind.filters));
    return buildCustomerRatingsReport(ratings, lowOnly: lowRatingsOnly);
  }
  final orders = await source.orders(filters.limitedTo(kind.filters));
  final items = kind == ReportKind.deliveryItems
      ? await source.orderItems([for (final o in orders) '${o['id']}'])
      : const <Map<String, dynamic>>[];
  return buildReport(kind, orders, items: items, money: money, now: now);
}