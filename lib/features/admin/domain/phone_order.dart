import 'dart:typed_data';

import '../../cart/domain/weight_options.dart';
import '../../home/domain/entities/product.dart';

/// Where a phone-order customer comes from: an app account (`profiles`) or
/// the POS customer list (`pos_customers`, which also holds callers added
/// from the dashboard).
enum PhoneOrderCustomerSource { app, pos }

/// How a phone order is paid («طريقة الدفع»).
///
/// [value] is stored in orders.payment_method.
enum PhoneOrderPayment {
  cash('cash', 'كاش عند الاستلام'),

  /// Only flags the order so the driver brings the POS machine.
  visaOnDelivery('visa_on_delivery', 'فيزا عند الاستلام'),

  /// Paid by transfer: needs the receipt image, and the order is paid.
  instaPay('instapay', 'إنستا باي');

  const PhoneOrderPayment(this.value, this.label);

  final String value;
  final String label;

  /// orders.payment_status for a new order.
  String get paymentStatus => this == instaPay ? 'paid' : 'unpaid';

  bool get needsReceipt => this == instaPay;
}

/// The InstaPay transfer screenshot picked for an order.
class PaymentReceiptImage {
  const PaymentReceiptImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// «عادي» / «VIP» for a customer added from the dashboard.
enum PhoneOrderCustomerType {
  regular('regular'),
  vip('vip');

  const PhoneOrderCustomerType(this.value);

  /// Stored in `pos_customers.customer_type`.
  final String value;
}

/// A delivery zone (`delivery_zones` row) with its delivery fee.
class PhoneOrderArea {
  const PhoneOrderArea({
    required this.name,
    this.deliveryFee,
    this.fujitsuZoneId,
  });

  final String name;
  final double? deliveryFee;

  /// The zone's code in Fujitsu (`delivery_zones.fujitsu_zone_id`), saved
  /// with the customer.
  final String? fujitsuZoneId;

  /// Identifies the zone in dropdowns.
  String get id => fujitsuZoneId ?? name;
}

class PhoneOrderCustomer {
  const PhoneOrderCustomer({
    required this.source,
    this.userId,
    this.posCustomerId,
    this.fullName,
    this.phone,
    this.address,
    this.zone,
    this.fujitsuZoneId,
  });

  final PhoneOrderCustomerSource source;

  /// Set for app customers: the order shows up in their app too.
  final String? userId;
  final int? posCustomerId;
  final String? fullName;
  final String? phone;
  final String? address;
  final String? zone;

  /// Fujitsu code of the customer's delivery zone, when one was chosen.
  final String? fujitsuZoneId;

  /// Stable across searches, for list keys and "is this the same caller".
  String get key => userId ?? 'pos-$posCustomerId';
}

class PhoneOrderLine {
  const PhoneOrderLine({
    required this.product,
    required this.quantity,
    this.weightInGrams,
  });

  final Product product;

  /// Always 1 for weight-based lines; their amount is [weightInGrams].
  final int quantity;

  /// Grams chosen for a weight-based product; null for unit products.
  final int? weightInGrams;

  bool get isWeightBased => weightInGrams != null;

  /// Line total: proportional kilo price when weighed, else unit × quantity.
  double get total => switch (weightInGrams) {
        final grams? => WeightOptions.priceFor(product.effectivePrice, grams),
        null => product.effectivePrice * quantity,
      };

  /// Unit price stored on the order item (price of the chosen weight, or
  /// the per-piece price).
  double get unitPrice => switch (weightInGrams) {
        final grams? => WeightOptions.priceFor(product.effectivePrice, grams),
        null => product.effectivePrice,
      };

  PhoneOrderLine withQuantity(int quantity) => PhoneOrderLine(
        product: product,
        quantity: quantity,
        weightInGrams: weightInGrams,
      );

  PhoneOrderLine withWeight(int grams) => PhoneOrderLine(
        product: product,
        quantity: 1,
        weightInGrams: grams,
      );
}

/// One catalog product the caller has bought before, with frequency and
/// last-order amounts for the «مشتريات العميل» panel.
class CustomerPurchaseItem {
  const CustomerPurchaseItem({
    required this.product,
    required this.timesOrdered,
    required this.totalQuantity,
    required this.lastOrderedAt,
    required this.lastQuantity,
    this.lastWeightInGrams,
  });

  final Product product;
  final int timesOrdered;
  final double totalQuantity;
  final DateTime lastOrderedAt;
  final int lastQuantity;
  final int? lastWeightInGrams;

  bool get isWeightBased =>
      product.isWeightBased || lastWeightInGrams != null;
}

/// Aggregated history plus the lines of the caller's most recent order.
class CustomerPurchaseHistory {
  const CustomerPurchaseHistory({
    this.items = const [],
    this.lastOrderLines = const [],
  });

  const CustomerPurchaseHistory.empty()
      : items = const [],
        lastOrderLines = const [];

  final List<CustomerPurchaseItem> items;
  final List<PhoneOrderLine> lastOrderLines;

  bool get isEmpty => items.isEmpty && lastOrderLines.isEmpty;

  /// Ranked by times ordered, then most recent.
  List<CustomerPurchaseItem> get mostFrequent {
    final ranked = [...items]..sort((a, b) {
        final byCount = b.timesOrdered.compareTo(a.timesOrdered);
        if (byCount != 0) return byCount;
        return b.lastOrderedAt.compareTo(a.lastOrderedAt);
      });
    return ranked;
  }

  /// Ranked by last ordered date (newest first).
  List<CustomerPurchaseItem> get mostRecent {
    final ranked = [...items]..sort((a, b) {
        final byDate = b.lastOrderedAt.compareTo(a.lastOrderedAt);
        if (byDate != 0) return byDate;
        return b.timesOrdered.compareTo(a.timesOrdered);
      });
    return ranked;
  }
}

class PhoneOrderState {
  const PhoneOrderState({
    this.customer,
    this.lines = const [],
    this.deliveryFee = defaultDeliveryFee,
    this.submitting = false,
    this.paymentMethod = PhoneOrderPayment.cash,
    this.receipt,
    this.id = 1,
    this.nextId = 2,
    this.parked = const [],
  });

  /// The first distance bracket; staff change it per call.
  static const defaultDeliveryFee = 25.0;

  static const maxQuantity = 999;

  /// The order being taken (the active draft).
  final PhoneOrderCustomer? customer;
  final List<PhoneOrderLine> lines;
  final double deliveryFee;
  final bool submitting;
  final PhoneOrderPayment paymentMethod;

  /// The InstaPay transfer image (kept only while paying by InstaPay).
  final PaymentReceiptImage? receipt;

  /// Identifies this draft among the open orders.
  final int id;

  /// The id the next draft gets.
  final int nextId;

  /// The other open (parked) drafts, oldest first. Parked drafts themselves
  /// have an empty [parked] list.
  final List<PhoneOrderState> parked;

  double get itemsTotal => lines.fold(0, (sum, line) => sum + line.total);
  double get total => itemsTotal + deliveryFee;
  int get itemCount => lines.fold(
        0,
        (sum, line) => sum + (line.isWeightBased ? 1 : line.quantity),
      );

  /// Whether this draft has neither a caller nor a cart.
  bool get isBlank => customer == null && lines.isEmpty;

  bool get hasReceipt => receipt != null;

  bool get canSubmit =>
      customer != null &&
      lines.isNotEmpty &&
      !submitting &&
      (!paymentMethod.needsReceipt || hasReceipt);

  /// Every open order — the parked ones and this one — by creation.
  List<PhoneOrderState> get openOrders =>
      [...parked, this]..sort((a, b) => a.id.compareTo(b.id));

  int quantityOf(String productId) =>
      lines
          .where((line) => line.product.id == productId)
          .firstOrNull
          ?.quantity ??
      0;

  int? weightOf(String productId) => lines
      .where((line) => line.product.id == productId)
      .firstOrNull
      ?.weightInGrams;

  PhoneOrderLine? lineOf(String productId) =>
      lines.where((line) => line.product.id == productId).firstOrNull;

  PhoneOrderState copyWith({
    PhoneOrderCustomer? customer,
    bool clearCustomer = false,
    List<PhoneOrderLine>? lines,
    double? deliveryFee,
    bool? submitting,
    PhoneOrderPayment? paymentMethod,
    PaymentReceiptImage? receipt,
    bool clearReceipt = false,
    int? id,
    int? nextId,
    List<PhoneOrderState>? parked,
  }) =>
      PhoneOrderState(
        customer: clearCustomer ? null : customer ?? this.customer,
        lines: lines ?? this.lines,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        submitting: submitting ?? this.submitting,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        receipt: clearReceipt ? null : receipt ?? this.receipt,
        id: id ?? this.id,
        nextId: nextId ?? this.nextId,
        parked: parked ?? this.parked,
      );
}