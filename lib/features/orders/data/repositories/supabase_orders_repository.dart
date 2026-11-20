import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/orders_repository.dart';

class SupabaseOrdersRepository implements OrdersRepository {
  SupabaseOrdersRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CustomerOrder>> fetchOrders(String userId) async {
    final rows = await _client
        .from('orders')
        .select(
          'id, created_at, total_amount, status, address_details, '
          'delivery_latitude, delivery_longitude',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map(CustomerOrder.fromRow).toList();
  }

  /// Readable by the order's customer: 20261114230000_customer_order_items.sql.
  @override
  Future<List<CustomerOrderItem>> fetchOrderItems(String orderId) async {
    final rows = await _client
        .from('order_items')
        .select('quantity, price_at_time, weight_in_grams, products(name)')
        .eq('order_id', orderId);

    return rows.map((row) {
      final product = switch (row['products']) {
        final Map<String, dynamic> map => map,
        [final Map<String, dynamic> first, ...] => first,
        _ => null,
      };
      final name = product?['name']?.toString().trim();
      return CustomerOrderItem(
        productName:
            name == null || name.isEmpty ? L10n.current.deletedProduct : name,
        quantity: _toNum(row['quantity']).toInt(),
        unitPrice: _toNum(row['price_at_time']).toDouble(),
        weightInGrams: switch (row['weight_in_grams']) {
          final num grams when grams > 0 => grams.toInt(),
          _ => null,
        },
      );
    }).toList();
  }

  @override
  Future<void> cancelOrder(
    String orderId,
    OrderCancellationReason reason,
  ) async {
    try {
      // `select` returns the changed rows; without it an update that row
      // level security filters out "succeeds" while changing nothing.
      final updated = await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason.value,
          })
          .eq('id', orderId)
          .inFilter('status', const ['pending', 'new', 'preparing'])
          .select('id');
      if (updated.isEmpty) {
        throw OrdersFailure(L10n.current.orderCancelTooLate);
      }
    } on PostgrestException catch (error) {
      debugPrint('Cancel order: ${error.code} ${error.message}');
      if (error.code == 'PGRST205' ||
          error.message.contains('cancellation_reason')) {
        throw OrdersFailure(L10n.current.orderCancelSetupMissing);
      }
      if (error.code == '42501') {
        throw OrdersFailure(L10n.current.orderCancelTooLate);
      }
      throw OrdersFailure(
        L10n.current.orderCancelFailed('${error.message} (${error.code})'),
      );
    }
  }

  static num _toNum(Object? value) => switch (value) {
        final num number => number,
        final String text => num.tryParse(text) ?? 0,
        _ => 0,
      };
}
