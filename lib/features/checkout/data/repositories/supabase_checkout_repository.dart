import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/payment_method.dart';
import '../../domain/repositories/checkout_repository.dart';

class SupabaseCheckoutRepository implements CheckoutRepository {
  SupabaseCheckoutRepository(this._client);

  static const _initialStatus = 'pending';
  static const _receiptsBucket = 'payment_receipts';

  final SupabaseClient _client;

  @override
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String addressDetails,
    required String deliveryArea,
    required double deliveryFee,
    required PaymentMethod paymentMethod,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String paymentStatus = 'unpaid',
    String? paymentMethodOverride,
    String? receiptUrl,
  }) async {
    if (items.isEmpty) {
      throw CheckoutFailure(L10n.current.cartEmpty);
    }

    final itemsTotal = items.fold<double>(0, (sum, item) => sum + item.total);

    try {
      final order = await _client
          .from('orders')
          .insert({
            'user_id': userId,
            'total_amount': itemsTotal + deliveryFee,
            'delivery_area': deliveryArea,
            'delivery_fee': deliveryFee,
            'address_details': addressDetails,
            'delivery_latitude': deliveryLatitude,
            'delivery_longitude': deliveryLongitude,
            'status': _initialStatus,
            'payment_method': paymentMethodOverride ?? paymentMethod.value,
            'payment_status': paymentStatus,
            if (receiptUrl != null && receiptUrl.isNotEmpty)
              'receipt_url': receiptUrl,
          })
          .select('id')
          .single();
      final Object orderId = order['id'];

      try {
        await _client.from('order_items').insert([
          for (final item in items)
            {
              'order_id': orderId,
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price_at_time': item.unitPrice,
              if (item.selectedWeightInGrams case final grams?)
                'weight_in_grams': grams,
            },
        ]);
      } catch (_) {
        await _deleteOrder(orderId);
        rethrow;
      }

      return orderId.toString();
    } on PostgrestException catch (e) {
      throw CheckoutFailure(e.message);
    } on CheckoutFailure {
      rethrow;
    } catch (_) {
      throw CheckoutFailure(L10n.current.serverConnectionError);
    }
  }

  @override
  Future<String> uploadPaymentReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      final storage = _client.storage.from(_receiptsBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
      return storage.getPublicUrl(path);
    } on StorageException catch (e) {
      throw CheckoutFailure(e.message);
    } catch (_) {
      throw CheckoutFailure(L10n.current.serverConnectionError);
    }
  }

  Future<void> _deleteOrder(Object orderId) async {
    try {
      await _client.from('orders').delete().eq('id', orderId);
    } catch (_) {}
  }
}
