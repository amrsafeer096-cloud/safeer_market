import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../auth/domain/egyptian_phone.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/payment_method.dart';
import '../../domain/repositories/checkout_repository.dart';

class SupabaseCheckoutRepository implements CheckoutRepository {
  SupabaseCheckoutRepository(this._client);

  static const _initialStatus = 'pending';
  static const _receiptsBucket = 'payment_receipts';

  final SupabaseClient _client;

  @override
  Future<String?> fetchSuggestedDeliveryPhone(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('phone')
          .eq('id', userId)
          .maybeSingle();
      final fromProfile = EgyptianPhone.normalize('${profile?['phone'] ?? ''}');
      if (EgyptianPhone.isValid(fromProfile)) return fromProfile;

      final lastOrder = await _client
          .from('orders')
          .select('customer_phone')
          .eq('user_id', userId)
          .not('customer_phone', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final fromOrder =
          EgyptianPhone.normalize('${lastOrder?['customer_phone'] ?? ''}');
      if (EgyptianPhone.isValid(fromOrder)) return fromOrder;
    } catch (_) {
      // Prefill is best-effort; checkout still requires a typed number.
    }
    return null;
  }

  @override
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String addressDetails,
    required String deliveryArea,
    required double deliveryFee,
    required PaymentMethod paymentMethod,
    required String customerPhone,
    String? customerName,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String paymentStatus = 'unpaid',
    String? paymentMethodOverride,
    String? receiptUrl,
  }) async {
    if (items.isEmpty) {
      throw CheckoutFailure(L10n.current.cartEmpty);
    }

    final phone = EgyptianPhone.normalize(customerPhone);
    if (!EgyptianPhone.isValid(phone)) {
      throw CheckoutFailure(L10n.current.authEnterValidEgyptianPhone);
    }

    final itemsTotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final name = customerName?.trim();

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
            'customer_phone': phone,
            if (name != null && name.isNotEmpty) 'customer_name': name,
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
              if (item.trimmedNotes case final note?) 'notes': note,
            },
        ]);
      } catch (_) {
        await _deleteOrder(orderId);
        rethrow;
      }

      // Persist for auto-fill on every future checkout.
      try {
        await _client.from('profiles').upsert({
          'id': userId,
          'phone': phone,
          if (name != null && name.isNotEmpty) 'full_name': name,
        });
      } catch (_) {
        try {
          await _client
              .from('profiles')
              .update({'phone': phone})
              .eq('id', userId);
        } catch (_) {}
      }

      // Link / merge into existing POS customer with the same phone.
      try {
        final linked = await _client.rpc(
          'link_profile_to_pos_customer',
          params: {'p_user_id': userId},
        );
        final posId = switch (linked) {
          final int id => id,
          final num id => id.toInt(),
          final String id => int.tryParse(id),
          _ => null,
        };
        if (posId != null) {
          await _client
              .from('orders')
              .update({'pos_customer_id': posId})
              .eq('id', orderId);
        }
      } catch (_) {}

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
