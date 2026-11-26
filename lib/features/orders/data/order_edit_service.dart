import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/postgrest_helpers.dart';
import '../../../core/network/supabase_providers.dart';
import '../../admin/domain/product_search_filter.dart';
import '../../home/data/models/product_model.dart';
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
          'id, quantity, price_at_time, weight_in_grams, notes, product_id, '
          'products(id, name, barcode, price, discount_price, image_url, '
          'stock_quantity, unit, is_weight_based)',
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
      final unit = '${product['unit'] ?? Product.defaultUnit}'.trim();
      final flaggedWeight = product['is_weight_based'] == true;
      final grams = switch (row['weight_in_grams']) {
        final num g when g > 0 => g.round(),
        _ => null,
      };
      final byWeight = flaggedWeight ||
          unit == Product.weightUnit ||
          name.contains(Product.weightUnit) ||
          grams != null;
      return OrderEditLine(
        productId: productId,
        productName: name.isEmpty ? 'منتج' : name,
        barcode: _textOrNull(product['barcode']),
        imageUrl: _textOrNull(product['image_url']),
        listPrice: listPrice > 0 ? listPrice : null,
        stockQuantity: switch (product['stock_quantity']) {
          final num n => n.round(),
          _ => 0,
        },
        unitPrice: charged > 0
            ? charged
            : (discount > 0 && discount < listPrice ? discount : listPrice),
        quantity: byWeight ? 1 : _num(row['quantity']).round().clamp(1, 9999),
        weightInGrams: grams,
        notes: _textOrNull(row['notes']),
        isWeightBased: byWeight,
        unit: unit.isEmpty ? Product.defaultUnit : unit,
        existingItemId: '${row['id']}',
      );
    }).where((l) => l.productId.isNotEmpty).toList();
  }

  Future<List<Product>> searchCatalog(
    String query, {
    ProductSearchFilterMode filter = ProductSearchFilterMode.inStock,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    var request = _client.from('products').select(
          'id, name, barcode, price, discount_price, image_url, '
          'category, category_id, stock_quantity, unit, is_active, '
          'is_weight_based',
        );
    request = switch (filter) {
      ProductSearchFilterMode.inStock => request.inStock(),
      // «كل الأصناف»: no stock / is_active filters — show exact stock.
      ProductSearchFilterMode.allItems => request,
      ProductSearchFilterMode.offers => request
          .not('is_active', 'is', false)
          .not('discount_price', 'is', null)
          .gt('discount_price', 0),
    };
    final words =
        q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String escapeLike(String value) => value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_')
        .replaceAll(',', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
    if (RegExp(r'^\d{4,}$').hasMatch(q)) {
      final code = escapeLike(q);
      // PostgREST `or=` filters use `*` as the LIKE wildcard (not `%`).
      request = request.or('name.ilike.*$code*,barcode.ilike.*$code*');
    } else {
      for (final word in words) {
        final escaped = escapeLike(word);
        request =
            request.or('name.ilike.*$escaped*,barcode.ilike.*$escaped*');
      }
    }
    final rows = await request.order('name').limit(80);
    var products = rows.map(ProductModel.fromJson).toList();
    if (filter == ProductSearchFilterMode.offers) {
      products = [for (final p in products) if (p.hasActiveOffer) p];
    }
    if (words.length > 1) {
      products = [
        for (final p in products)
          if (words.every((w) =>
              arabicSearchContains(p.name, w) ||
              arabicSearchContains(p.barcode ?? '', w)))
            p,
      ];
    }
    return products;
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
