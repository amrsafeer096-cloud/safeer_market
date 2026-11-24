import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../home/domain/entities/product.dart';
import '../domain/order_editability.dart';

final orderEditServiceProvider = Provider<OrderEditService>((ref) {
  return OrderEditService(ref.watch(supabaseClientProvider));
});

class OrderEditFailure implements Exception {
  const OrderEditFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class OrderEditService {
  OrderEditService(this._client);

  final SupabaseClient _client;

  Future<List<OrderEditLine>> fetchEditableItems(String orderId) async {
    final rows = await _client
        .from('order_items')
        .select(
          'id, quantity, price_at_time, weight_in_grams, '
          'product_id, products(id, name, barcode, price, discount_price)',
        )
        .eq('order_id', orderId);

    return rows.map((row) {
      final product = switch (row['products']) {
        final Map map => Map<String, dynamic>.from(map),
        [final Map first, ...] => Map<String, dynamic>.from(first),
        _ => <String, dynamic>{},
      };
      final productId =
          '${row['product_id'] ?? product['id'] ?? ''}'.trim();
      final name = '${product['name'] ?? ''}'.trim();
      final listPrice = _num(product['price']);
      final discount = _num(product['discount_price']);
      final charged = _num(row['price_at_time']);
      return OrderEditLine(
        productId: productId,
        productName: name.isEmpty ? 'منتج' : name,
        barcode: _textOrNull(product['barcode']),
        unitPrice: charged > 0
            ? charged
            : (discount > 0 && discount < listPrice ? discount : listPrice),
        quantity: _num(row['quantity']).round().clamp(1, 9999),
        weightInGrams: switch (row['weight_in_grams']) {
          final num g when g > 0 => g.round(),
          _ => null,
        },
        existingItemId: '${row['id']}',
      );
    }).where((l) => l.productId.isNotEmpty).toList();
  }

  Future<List<Product>> searchCatalog(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('products')
        .select(
          'id, name, barcode, price, discount_price, image_url, '
          'category, stock_quantity, unit',
        )
        .or('name.ilike.%$q%,barcode.ilike.%$q%')
        .limit(30);
    return [
      for (final row in rows)
        Product(
          id: '${row['id']}',
          name: '${row['name'] ?? 'منتج'}',
          price: _num(row['price']),
          discountPrice: switch (_num(row['discount_price'])) {
            final d when d > 0 => d,
            _ => null,
          },
          barcode: _textOrNull(row['barcode']),
          imageUrl: _textOrNull(row['image_url']),
          category: _textOrNull(row['category']),
          stockQuantity: switch (row['stock_quantity']) {
            final num n => n.round(),
            _ => 0,
          },
          unit: '${row['unit'] ?? Product.defaultUnit}',
        ),
    ];
  }

  Future<void> beginEdit({
    required String orderId,
    required String startedBy,
  }) async {
    try {
      await _client.rpc(
        'begin_order_edit',
        params: {
          'p_order_id': orderId,
          'p_started_by': startedBy,
        },
      );
    } on PostgrestException catch (e) {
      throw OrderEditFailure(e.message);
    }
  }

  Future<void> cancelEdit(String orderId) async {
    try {
      await _client.rpc(
        'cancel_order_edit',
        params: {'p_order_id': orderId},
      );
    } on PostgrestException catch (e) {
      throw OrderEditFailure(e.message);
    }
  }

  Future<void> applyEdit({
    required String orderId,
    required List<OrderEditLine> lines,
  }) async {
    if (lines.isEmpty) {
      throw const OrderEditFailure(
        'يجب أن يحتوي الطلب على صنف واحد على الأقل',
      );
    }
    try {
      await _client.rpc(
        'apply_order_edit',
        params: {
          'p_order_id': orderId,
          'p_items': [for (final line in lines) line.toRpcJson()],
        },
      );
    } on PostgrestException catch (e) {
      throw OrderEditFailure(e.message);
    }
  }

  static double _num(Object? value) => switch (value) {
        final num n => n.toDouble(),
        final String t => double.tryParse(t) ?? 0,
        _ => 0,
      };

  static String? _textOrNull(Object? value) {
    final t = value?.toString().trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
