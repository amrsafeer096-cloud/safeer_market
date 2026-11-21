import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/notifications/order_push_dispatcher.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/admin_orders_repository.dart';

class SupabaseAdminOrdersRepository implements AdminOrdersRepository {
  const SupabaseAdminOrdersRepository(this._client);

  static const _orderColumns = '*, profiles!user_id(full_name, phone)';

  final SupabaseClient _client;

  @override
  Future<List<AdminOrder>> fetchAllOrders() async {
    final rows = await _client
        .from('orders')
        .select(_orderColumns)
        .order('created_at', ascending: false);
    return rows.map(_toOrder).toList();
  }

  @override
  Future<AdminOrder?> fetchOrder(String orderId) async {
    final row = await _client
        .from('orders')
        .select(_orderColumns)
        .eq('id', orderId)
        .maybeSingle();
    return row == null ? null : _toOrder(row);
  }

  @override
  Future<List<AdminOrderItem>> fetchOrderItems(String orderId) async {
    final rows = await _client
        .from('order_items')
        // التعديل هنا: طلبنا منه يسحب عمود الباركود من جدول المنتجات
        .select('*, products(name, image_url, barcode)')
        .eq('order_id', orderId);

    return rows.map((row) {
      final product = _single(row['products']);
      final imageUrl = (product?['image_url'] as String?)?.trim();

      // هنا بياخد الباركود الحقيقي، ولو ملقاهوش بياخد الـ ID كبديل مؤقت
      final realBarcode =
          product?['barcode']?.toString() ?? row['product_id'].toString();

      final weight = row['weight_in_grams'];
      return AdminOrderItem(
        id: realBarcode,
        productName: (product?['name'] as String?)?.trim() ??
            L10n.current.deletedProduct,
        imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
        quantity: _toNum(row['quantity']).toInt(),
        price: _toNum(row['price_at_time']).toDouble(),
        weightInGrams: switch (weight) {
          final num grams => grams.toInt(),
          final String text => int.tryParse(text),
          _ => null,
        },
      );
    }).toList();
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      final existing = await _client
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();
      final previousStatus =
          (existing?['status'] ?? 'pending').toString();
      final updated = await _client
          .from('orders')
          .update({'status': status.value})
          .eq('id', orderId)
          .select('id');
      if (updated.isEmpty) {
        throw AdminFailure(L10n.current.noPermissionToEditOrder);
      }
      unawaited(
        OrderPushDispatcher(_client).notifyStatusChanged(
          orderId,
          previousStatus: previousStatus,
        ),
      );
    } on PostgrestException catch (error) {
      throw AdminFailure(L10n.current.adminStatusUpdateFailed(error.message));
    }
  }

  @override
  Future<Map<String, OrderCustomer>> fetchCustomers(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.toSet().toList();
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('profiles')
        .select('id, full_name, phone')
        .inFilter('id', ids);
    return {
      for (final row in rows)
        row['id'].toString(): OrderCustomer(
          fullName: _text(row['full_name']),
          phone: _text(row['phone']),
        ),
    };
  }

  static AdminOrder _toOrder(Map<String, dynamic> row) {
    final profile = _single(row['profiles']);
    return AdminOrder(
      id: row['id'].toString(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      totalAmount: _toNum(row['total_amount']).toDouble(),
      status: (row['status'] ?? 'pending').toString(),
      paymentMethod: row['payment_method'] as String?,
      paymentStatus: row['payment_status'] as String?,
      receiptUrl: _text(row['receipt_url']),
      customerName: _text(profile?['full_name']),
      customerPhone: _text(profile?['phone']),
      addressDetails: _text(row['address_details']),
      deliveryFee: _toNum(row['delivery_fee']).toDouble(),
    );
  }

  static Map<String, dynamic>? _single(Object? embedded) => switch (embedded) {
        final Map<String, dynamic> map => map,
        [final Map<String, dynamic> first, ...] => first,
        _ => null,
      };

  static num _toNum(Object? value) => switch (value) {
        final num number => number,
        final String text => num.tryParse(text) ?? 0,
        _ => 0,
      };

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
