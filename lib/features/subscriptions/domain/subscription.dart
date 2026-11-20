/// The plans a customer can be on, stored in `profiles.subscription_plan`.
enum SubscriptionPlan {
  free('free'),
  prime('prime'),
  pro('pro');

  const SubscriptionPlan(this.value);

  final String value;

  /// Anything missing or unrecognised counts as [free]. 'vip' (the payment
  /// backend's name for «سفير برو (VIP)») is [pro].
  static SubscriptionPlan fromValue(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    if (text == 'vip') return pro;
    for (final plan in values) {
      if (plan.value == text) return plan;
    }
    return free;
  }
}

/// A customer's plan and when it lapses (`subscription_expiry`).
class Subscription {
  const Subscription({this.plan = SubscriptionPlan.free, this.expiry});

  static const free = Subscription();

  /// Reads `subscription_plan` (default 'free') and `subscription_expiry`.
  factory Subscription.fromJson(Map<String, dynamic> json) {
    final expiry = json['subscription_expiry'];
    return Subscription(
      plan: SubscriptionPlan.fromValue(json['subscription_plan']),
      expiry: switch (expiry) {
        final DateTime value => value,
        final String value => DateTime.tryParse(value.trim()),
        _ => null,
      },
    );
  }

  final SubscriptionPlan plan;

  /// Null means the plan doesn't lapse.
  final DateTime? expiry;

  /// The plan that applies at [now]: a lapsed paid plan is back to free.
  SubscriptionPlan activePlan([DateTime? now]) {
    if (plan == SubscriptionPlan.free) return plan;
    final expiry = this.expiry;
    if (expiry != null && !expiry.isAfter(now ?? DateTime.now())) {
      return SubscriptionPlan.free;
    }
    return plan;
  }

  bool isFree([DateTime? now]) => activePlan(now) == SubscriptionPlan.free;
}

/// A plan that can be bought, by the name the payment backend uses: «سفير برو
/// (VIP)» is 'vip' there and is stored as [SubscriptionPlan.pro].
enum PaidTier {
  vip('vip', SubscriptionPlan.pro),
  prime('prime', SubscriptionPlan.prime);

  const PaidTier(this.value, this.plan);

  final String value;
  final SubscriptionPlan plan;
}

enum PaymobMethod {
  card('card'),
  wallet('wallet');

  const PaymobMethod(this.value);

  final String value;
}

/// `payment_transactions.status`.
enum PaymentStatus {
  pending,
  success,
  failed;

  static PaymentStatus fromValue(Object? value) => switch (value) {
        'success' => success,
        'failed' => failed,
        _ => pending,
      };
}

/// Card details for Paymob's direct CARD / Moto pay call.
class PaymobCardSource {
  const PaymobCardSource({
    required this.number,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  /// Digits only (no spaces).
  final String number;
  final String holderName;

  /// Two-digit month, e.g. `09`.
  final String expiryMonth;

  /// Two-digit year, e.g. `29`.
  final String expiryYear;
  final String cvv;
}

/// A started payment and the Paymob page the customer pays on.
class PaymobCheckout {
  const PaymobCheckout({
    required this.transactionId,
    this.paymentUrl,
    this.tier,
    this.orderId,
    this.authToken,
    this.paymobOrderId,
    this.alreadyPaid = false,
  });

  /// Merchant order id we sent to Paymob (grocery order id or sub_* id).
  final String transactionId;

  /// 3DS / iframe URL. Null when [alreadyPaid] is true.
  final Uri? paymentUrl;

  /// Set for subscription checkouts; null for grocery order payments.
  final PaidTier? tier;

  /// Set for grocery order payments; null for subscriptions.
  final String? orderId;

  /// Auth token from Paymob step 1 (optional; used for follow-up inquiry).
  final String? authToken;

  /// Paymob's ecommerce order id from step 2.
  final String? paymobOrderId;

  /// Direct CARD pay already settled — skip the WebView.
  final bool alreadyPaid;
}
