import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/order_item_alternative.dart';

/// Reads / writes `order_item_alternatives` and notifies the right audience.
class OrderAlternativesService {
  const OrderAlternativesService(this._client);

  final SupabaseClient _client;

  Future<List<OrderItemAlternative>> listForOrder(String orderId) async {
    final rows = await _client
        .from('order_item_alternatives')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);
    return [
      for (final row in rows) OrderItemAlternative.fromRow(row),
    ];
  }

  Future<List<OrderItemAlternative>> listPendingForOrders(
    Iterable<String> orderIds,
  ) async {
    final ids = orderIds.toSet().toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('order_item_alternatives')
        .select()
        .inFilter('order_id', ids)
        .eq('status', 'pending');
    return [
      for (final row in rows) OrderItemAlternative.fromRow(row),
    ];
  }

  /// Order ids that currently have at least one pending alternative set.
  Future<Set<String>> pendingOrderIds() async {
    final rows = await _client
        .from('order_item_alternatives')
        .select('order_id')
        .eq('status', 'pending');
    return {for (final row in rows) '${row['order_id']}'};
  }

  Future<AlternativeProduct?> findProductByBarcode(String barcode) async {
    final needle = barcode.trim();
    if (needle.isEmpty) return null;
    final row = await _client
        .from('products')
        .select('id, name, price, barcode, image_url, is_active')
        .eq('barcode', needle)
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    return AlternativeProduct.fromProductRow(row);
  }

  Future<List<AlternativeProduct>> searchProducts(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final rows = await _client
        .from('products')
        .select('id, name, price, barcode, image_url')
        .eq('is_active', true)
        .or('name.ilike.%$q%,barcode.ilike.%$q%')
        .limit(20);
    return [
      for (final row in rows) AlternativeProduct.fromProductRow(row),
    ];
  }

  Future<String> submitAlternatives({
    required String orderId,
    required String orderItemId,
    required List<AlternativeProduct> products,
    String? staffId,
    required bool notifyCustomer,
    String? customerUserId,
  }) async {
    if (products.isEmpty || products.length > 3) {
      throw const OrderAlternativesFailure(
        'يجب اختيار بديل واحد على الأقل وبحد أقصى 3',
      );
    }
    try {
      final id = await _client.rpc(
        'suggest_order_item_alternatives',
        params: {
          'p_order_id': orderId,
          'p_order_item_id': orderItemId,
          'p_products': [for (final p in products) p.toJson()],
          'p_staff_id': staffId,
        },
      );
      await _notify(
        orderId: orderId,
        notifyCustomer: notifyCustomer,
        customerUserId: customerUserId,
      );
      return '$id';
    } on PostgrestException catch (error) {
      throw OrderAlternativesFailure(error.message);
    }
  }

  Future<void> selectAlternative({
    required String alternativeId,
    required String productId,
  }) async {
    try {
      await _client.rpc(
        'select_order_item_alternative',
        params: {
          'p_alternative_id': alternativeId,
          'p_product_id': productId,
        },
      );
    } on PostgrestException catch (error) {
      throw OrderAlternativesFailure(error.message);
    }
  }

  Future<void> removeOriginalItem({required String alternativeId}) async {
    try {
      await _client.rpc(
        'remove_order_item_with_alternative',
        params: {'p_alternative_id': alternativeId},
      );
    } on PostgrestException catch (error) {
      throw OrderAlternativesFailure(error.message);
    }
  }

  Future<void> _notify({
    required String orderId,
    required bool notifyCustomer,
    String? customerUserId,
  }) async {
    const title = 'منتج غير متوفر — اختر بديلاً لطلبك';
    const body =
        'أحد منتجات طلبك غير متوفر. افتح تفاصيل الطلب لاختيار بديل أو حذف المنتج.';
    try {
      if (notifyCustomer && customerUserId != null) {
        // Bell row via SECURITY DEFINER RPC (staff cannot insert for customers).
        try {
          await _client.rpc(
            'log_customer_order_notification',
            params: {
              'p_user_id': customerUserId,
              'p_title': title,
              'p_body': body,
              'p_order_id': orderId,
              'p_type': 'order',
              'p_source': 'order_lifecycle',
            },
          );
        } catch (error) {
          debugPrint('alternatives bell insert failed: $error');
        }
        final response = await _client.functions.invoke(
          'send-push',
          body: {
            'trigger': 'broadcast',
            'title': title,
            'body': body,
            'notification_type': 'order',
            'target_user_id': customerUserId,
            'target': customerUserId,
            'order_id': orderId,
          },
        );
        debugPrint(
          'send-push [alternatives→customer] → '
          'HTTP ${response.status} ${response.data}',
        );
      } else {
        final response = await _client.functions.invoke(
          'send-push',
          body: {
            'trigger': 'staff_alert',
            'title': 'بدائل بانتظار المتلقي',
            'body':
                'محضر أرسل بدائل لمنتج في طلب هاتف — راجع حالة الطلب واتصل بالعميل.',
            'order_id': orderId,
          },
        );
        debugPrint(
          'send-push [alternatives→staff] → '
          'HTTP ${response.status} ${response.data}',
        );
      }
    } catch (error) {
      debugPrint('alternatives notify failed: $error');
    }
  }
}

class OrderAlternativesFailure implements Exception {
  const OrderAlternativesFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
