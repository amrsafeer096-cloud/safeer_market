import 'dart:typed_data';

import '../../../cart/domain/entities/cart_item.dart';
import '../payment_method.dart';

abstract class CheckoutRepository {
  /// Creates the order and its items, returning the new order id.
  /// The stored total is the items total plus [deliveryFee].
  /// Also writes [customerPhone] on the order and the user's `profiles` row.
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

    /// `orders.payment_status` — defaults to unpaid for COD.
    String paymentStatus = 'unpaid',

    /// Overrides the stored `orders.payment_method` (e.g. `visa` for Paymob).
    String? paymentMethodOverride,

    /// Public URL of an InstaPay transfer screenshot (`orders.receipt_url`).
    String? receiptUrl,
  });

  /// Best phone to prefill at checkout: `profiles.phone`, else last order.
  Future<String?> fetchSuggestedDeliveryPhone(String userId);

  /// Uploads an InstaPay receipt image and returns its public Storage URL.
  Future<String> uploadPaymentReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });
}

class CheckoutFailure implements Exception {
  const CheckoutFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
