import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../../core/notifications/order_push_dispatcher.dart';
import '../../../addresses/domain/entities/address.dart';
import '../../../addresses/presentation/providers/addresses_providers.dart';
import '../../../auth/domain/egyptian_phone.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../data/repositories/supabase_checkout_repository.dart';
import '../../domain/checkout_pricing.dart';
import '../../domain/delivery_pricing.dart';
import '../../domain/payment_method.dart';
import '../../domain/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return SupabaseCheckoutRepository(ref.watch(supabaseClientProvider));
});

/// Current time; overridden in tests to pin the estimated arrival.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final selectedPaymentMethodProvider =
    StateProvider<PaymentMethod>((ref) => PaymentMethod.cashOnDelivery);

/// Delivery mobile typed / autofilled on the checkout screen (`01xxxxxxxxx`).
final checkoutDeliveryPhoneProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Prefills [checkoutDeliveryPhoneProvider] from profile / last order once.
final checkoutPhoneBootstrapProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  String? suggested;
  final profile = await ref.watch(userProfileProvider.future);
  final fromProfile = EgyptianPhone.normalize(profile?.phone ?? '');
  if (EgyptianPhone.isValid(fromProfile)) {
    suggested = fromProfile;
  } else {
    final fromAuth = EgyptianPhone.normalize(user.phone ?? '');
    if (EgyptianPhone.isValid(fromAuth)) {
      suggested = fromAuth;
    } else {
      suggested = await ref
          .read(checkoutRepositoryProvider)
          .fetchSuggestedDeliveryPhone(user.id);
    }
  }

  if (suggested != null &&
      EgyptianPhone.isValid(suggested) &&
      ref.read(checkoutDeliveryPhoneProvider).trim().isEmpty) {
    ref.read(checkoutDeliveryPhoneProvider.notifier).state = suggested;
  }
  return suggested;
});

/// InstaPay transfer screenshot selected at checkout (before upload).
class InstaPayReceiptDraft {
  const InstaPayReceiptDraft({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

final instaPayReceiptProvider =
    StateProvider.autoDispose<InstaPayReceiptDraft?>((ref) => null);

/// Fee for the selected address, priced by its distance from the store; 0
/// for subscribers (Prime or Pro/VIP). Null until an address is chosen.
final deliveryQuoteProvider = Provider<DeliveryQuote?>((ref) {
  final address = ref.watch(selectedAddressProvider);
  if (address == null) return null;
  return DeliveryPricing.quote(
    latitude: address.latitude,
    longitude: address.longitude,
    freeDelivery: ref.watch(hasPaidPlanProvider),
  );
});

/// Subtotal plus the delivery fee (0 while delivery can't be priced).
final checkoutTotalProvider = Provider<double>((ref) {
  final fee = switch (ref.watch(deliveryQuoteProvider)) {
    DeliveryAvailable(:final fee) => fee,
    _ => 0.0,
  };
  return CheckoutPricing.grandTotal(ref.watch(cartTotalProvider), fee);
});

final checkoutControllerProvider =
    AsyncNotifierProvider.autoDispose<CheckoutController, void>(
  CheckoutController.new,
);

class CheckoutController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// The plan as stored now, so the fee charged matches the profile even if
  /// the plan in memory is still loading.
  Future<bool> _hasPaidPlan() async {
    try {
      return !(await ref.read(subscriptionProvider.future)).isFree();
    } catch (_) {
      return false;
    }
  }

  /// Returns the new order id, or null if checkout did not complete.
  Future<String?> placeOrder(
    Address address, {
    required PaymentMethod paymentMethod,
    required String customerPhone,
    bool clearCart = true,
    String paymentStatus = 'unpaid',
    String? paymentMethodOverride,
    String? receiptUrl,
    InstaPayReceiptDraft? receipt,
  }) async {
    final items = ref.read(cartProvider);
    if (items.isEmpty || state.isLoading) return null;
    final l10n = ref.read(appLocalizationsProvider);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError(
        CheckoutFailure(l10n.pleaseSignInFirst),
        StackTrace.current,
      );
      return null;
    }

    final phone = EgyptianPhone.normalize(customerPhone);
    if (!EgyptianPhone.isValid(phone)) {
      state = AsyncError(
        CheckoutFailure(l10n.authEnterValidEgyptianPhone),
        StackTrace.current,
      );
      return null;
    }

    final quote = DeliveryPricing.quote(
      latitude: address.latitude,
      longitude: address.longitude,
      freeDelivery: await _hasPaidPlan(),
    );
    if (quote is! DeliveryAvailable) {
      state = AsyncError(
        CheckoutFailure(switch (quote) {
          DeliveryOutOfRange() => l10n.checkoutAddressOutOfRange,
          _ => l10n.checkoutPinAddressFirst,
        }),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      var uploadedReceiptUrl = receiptUrl;
      if (receipt != null) {
        uploadedReceiptUrl = await repo.uploadPaymentReceipt(
          userId: user.id,
          bytes: receipt.bytes,
          fileName: receipt.fileName,
          contentType: receipt.contentType,
        );
      }

      final profile = ref.read(userProfileProvider).valueOrNull;
      final customerName = (profile?.fullName ?? user.fullName)?.trim();

      final orderId = await repo.placeOrder(
        userId: user.id,
        items: items,
        addressDetails: address.formatted,
        deliveryArea: address.area,
        deliveryFee: quote.fee,
        paymentMethod: paymentMethod,
        customerPhone: phone,
        customerName: customerName,
        deliveryLatitude: address.latitude,
        deliveryLongitude: address.longitude,
        paymentStatus: paymentStatus,
        paymentMethodOverride: paymentMethodOverride,
        receiptUrl: uploadedReceiptUrl,
      );
      // Push to admin/taker devices even if the DB webhook is not configured.
      unawaited(
        ref.read(orderPushDispatcherProvider).notifyOrderCreated(orderId),
      );
      ref.invalidate(userProfileProvider);
      if (clearCart) {
        ref.read(cartProvider.notifier).clear();
      }
      ref.read(instaPayReceiptProvider.notifier).state = null;
      state = const AsyncData(null);
      return orderId;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clearCart() => ref.read(cartProvider.notifier).clear();
}
