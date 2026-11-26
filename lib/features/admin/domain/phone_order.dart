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

/// One saved delivery address (Supabase `customer_addresses` or app `addresses`).
class PhoneOrderCustomerAddress {
  const PhoneOrderCustomerAddress({
    required this.id,
    required this.address,
    this.zone,
    this.branch,
    this.governorate,
    this.city,
    this.building,
    this.floor,
    this.apartment,
    this.latitude,
    this.longitude,
    this.fujitsuZoneId,
    this.fujitsuAddressId,
    this.isPrimary = false,
    this.fromAppAddresses = false,
  });

  /// String form of the row id (bigint or uuid).
  final String id;
  final String address;
  final String? zone;
  final String? branch;
  final String? governorate;
  final String? city;
  final String? building;
  final String? floor;
  final String? apartment;
  final double? latitude;
  final double? longitude;
  final String? fujitsuZoneId;
  final int? fujitsuAddressId;
  final bool isPrimary;

  /// True when this row came from the app `addresses` table (read-only edit).
  final bool fromAppAddresses;

  int? get customerAddressId =>
      fromAppAddresses ? null : int.tryParse(id);

  String get displayLine {
    final parts = [
      address,
      if (zone != null && zone!.trim().isNotEmpty && !address.contains(zone!))
        zone,
      if (branch != null && branch!.trim().isNotEmpty) 'فرع: $branch',
    ];
    return parts.whereType<String>().join(' — ');
  }
}

/// Bundle returned by `get_phone_order_customer_details`.
class PhoneOrderCustomerDetails {
  const PhoneOrderCustomerDetails({
    required this.customer,
    this.addresses = const [],
  });

  final PhoneOrderCustomer customer;
  final List<PhoneOrderCustomerAddress> addresses;
}

class PhoneOrderCustomer {
  const PhoneOrderCustomer({
    required this.source,
    this.userId,
    this.posCustomerId,
    this.fullName,
    this.phone,
    this.phone2,
    this.phone3,
    this.phone4,
    this.phone5,
    this.notes,
    this.address,
    this.zone,
    this.fujitsuZoneId,
    this.fujitsuCustomerNo,
    this.fujitsuAddressId,
    this.selectedAddressId,
  });

  final PhoneOrderCustomerSource source;

  /// Set for app customers: the order shows up in their app too.
  final String? userId;
  final int? posCustomerId;
  final String? fullName;
  final String? phone;
  final String? phone2;
  final String? phone3;
  final String? phone4;
  final String? phone5;
  final String? notes;
  final String? address;
  final String? zone;

  /// Fujitsu code of the customer's delivery zone, when one was chosen.
  final String? fujitsuZoneId;

  /// Linked Fujitsu `Customers.CustomerNo`, when known.
  final int? fujitsuCustomerNo;

  /// Fujitsu `CustomerAddresses.AddressId` chosen for this order.
  final int? fujitsuAddressId;

  /// Supabase `customer_addresses.id` chosen for this order (as string).
  final String? selectedAddressId;

  /// All non-empty phone slots in order (up to 5).
  List<String?> get phoneSlots => [phone, phone2, phone3, phone4, phone5];

  /// Stable across searches, for list keys and "is this the same caller".
  String get key => userId ?? 'pos-$posCustomerId';

  PhoneOrderCustomer copyWith({
    String? fullName,
    String? phone,
    String? phone2,
    String? phone3,
    String? phone4,
    String? phone5,
    String? notes,
    String? address,
    String? zone,
    String? fujitsuZoneId,
    int? fujitsuCustomerNo,
    int? fujitsuAddressId,
    String? selectedAddressId,
    bool clearPhone2 = false,
    bool clearPhone3 = false,
    bool clearPhone4 = false,
    bool clearPhone5 = false,
    bool clearNotes = false,
    bool clearFujitsuAddressId = false,
  }) =>
      PhoneOrderCustomer(
        source: source,
        userId: userId,
        posCustomerId: posCustomerId,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        phone2: clearPhone2 ? null : phone2 ?? this.phone2,
        phone3: clearPhone3 ? null : phone3 ?? this.phone3,
        phone4: clearPhone4 ? null : phone4 ?? this.phone4,
        phone5: clearPhone5 ? null : phone5 ?? this.phone5,
        notes: clearNotes ? null : notes ?? this.notes,
        address: address ?? this.address,
        zone: zone ?? this.zone,
        fujitsuZoneId: fujitsuZoneId ?? this.fujitsuZoneId,
        fujitsuCustomerNo: fujitsuCustomerNo ?? this.fujitsuCustomerNo,
        fujitsuAddressId: clearFujitsuAddressId
            ? null
            : fujitsuAddressId ?? this.fujitsuAddressId,
        selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      );
}

class PhoneOrderLine {
  const PhoneOrderLine({
    required this.product,
    required this.quantity,
    this.weightInGrams,
    this.notes,
  });

  final Product product;

  /// Always 1 for weight-based lines; their amount is [weightInGrams].
  final int quantity;

  /// Grams chosen for a weight-based product; null for unit products.
  final int? weightInGrams;

  /// Optional per-item instruction («ملاحظة للصنف»).
  final String? notes;

  bool get isWeightBased => weightInGrams != null;

  String? get trimmedNotes {
    final t = notes?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

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
        notes: notes,
      );

  PhoneOrderLine withWeight(int grams, {String? notes}) => PhoneOrderLine(
        product: product,
        quantity: 1,
        weightInGrams: grams,
        notes: notes ?? this.notes,
      );

  PhoneOrderLine withNotes(String? notes) => PhoneOrderLine(
        product: product,
        quantity: quantity,
        weightInGrams: weightInGrams,
        notes: notes,
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

/// One past order row for the left «الطلبات السابقة» tab.
class CustomerPastOrderSummary {
  const CustomerPastOrderSummary({
    required this.orderId,
    required this.createdAt,
    required this.totalAmount,
    this.fujitsuOrderId,
    this.posReceiptNumber,
    this.status,
    this.takerName,
    this.preparerName,
    this.driverName,
    this.paymentMethod,
    this.deliveryFee = 0,
    this.customerName,
    this.customerPhone,
  });

  final String orderId;
  final DateTime createdAt;
  final double totalAmount;
  final String? fujitsuOrderId;
  final String? posReceiptNumber;
  final String? status;
  final String? takerName;
  final String? preparerName;
  final String? driverName;
  final String? paymentMethod;
  final double deliveryFee;
  final String? customerName;
  final String? customerPhone;

  /// Prefer Fujitsu / POS receipt number, else a short internal id.
  String get displayNumber {
    final fj = fujitsuOrderId?.trim();
    if (fj != null && fj.isNotEmpty) return fj;
    final pos = posReceiptNumber?.trim();
    if (pos != null && pos.isNotEmpty) return pos;
    final id = orderId.replaceAll('-', '');
    return id.length <= 8 ? id : id.substring(0, 8);
  }
}

/// Full past-order detail (header + lines) for the repeat-order modal.
class CustomerPastOrderDetail {
  const CustomerPastOrderDetail({
    required this.summary,
    this.lines = const [],
    this.addressDetails,
  });

  final CustomerPastOrderSummary summary;
  final List<PhoneOrderLine> lines;
  final String? addressDetails;
}

class PhoneOrderState {
  const PhoneOrderState({
    this.customer,
    this.lines = const [],
    this.deliveryFee = defaultDeliveryFee,
    this.submitting = false,
    this.paymentMethod = PhoneOrderPayment.cash,
    this.receipt,
    this.isSupplemental = false,
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

  /// «طلب ملحق»: free delivery follow-up on a same-day order.
  final bool isSupplemental;

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

  /// Receipt for InstaPay is attached in the confirm dialog, not the cart body.
  bool get canSubmit =>
      customer != null && lines.isNotEmpty && !submitting;

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
    bool? isSupplemental,
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
        isSupplemental: isSupplemental ?? this.isSupplemental,
        id: id ?? this.id,
        nextId: nextId ?? this.nextId,
        parked: parked ?? this.parked,
      );
}