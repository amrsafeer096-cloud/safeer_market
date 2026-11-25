/// Data for «إيصال تحضير طلب توصيل» + cashier QR (`DlvOrd,…`).
class PrepReceipt {
  const PrepReceipt({
    required this.orderId,
    required this.receiptNumber,
    required this.qrPayload,
    required this.storeName,
    required this.branchName,
    required this.branchCode,
    required this.createdAt,
    required this.deliveryFee,
    required this.totalAmount,
    required this.items,
    this.waitingFujitsu = false,
    this.fujitsuOrderId,
    this.fujitsuCustomerNo,
    this.fujitsuAddressId,
    this.fujitsuSyncError,
    this.takerName,
    this.preparerName,
    this.driverName,
    this.customerName,
    this.customerPhone,
    this.customerPhone2,
    this.address,
    this.deliveryArea,
    this.paymentMethod,
    this.posCustomerId,
    this.fujitsuZoneId,
    this.orderSource = 0,
    this.commitPrices = 0,
    this.pilotNo = 0,
  });

  final String orderId;
  final String receiptNumber;
  final String qrPayload;
  final String storeName;
  final String branchName;
  final String branchCode;
  final DateTime createdAt;
  final String? takerName;
  final String? preparerName;
  final String? driverName;
  final String? customerName;
  final String? customerPhone;
  final String? customerPhone2;
  final String? address;
  final String? deliveryArea;
  final String? paymentMethod;
  final double deliveryFee;
  final double totalAmount;
  final String? posCustomerId;
  final String? fujitsuZoneId;

  /// TrustyDelivery `OrderSource`: 0 = call center, 1 = online/app.
  final int orderSource;

  /// TrustyDelivery `CommitPrices` flag embedded in the cashier QR.
  final int commitPrices;

  /// TrustyDelivery `PilotNo` (0 until a driver is assigned).
  final int pilotNo;

  /// True while the local Python bridge has not yet written [fujitsuOrderId].
  final bool waitingFujitsu;
  final String? fujitsuOrderId;
  final String? fujitsuCustomerNo;
  final String? fujitsuAddressId;
  final String? fujitsuSyncError;

  final List<PrepReceiptItem> items;

  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);

  /// Items total without delivery (matches sample «الإجمالي» of products).
  double get itemsTotal =>
      items.fold<double>(0, (s, i) => s + i.lineTotal);

  bool get hasFujitsuIds =>
      (fujitsuOrderId?.trim().isNotEmpty ?? false) &&
      (fujitsuCustomerNo?.trim().isNotEmpty ?? false) &&
      (fujitsuAddressId?.trim().isNotEmpty ?? false);

  /// Exact cashier QR from Fujitsu ids when available.
  ///
  /// TrustyDelivery `Order.GetQrCodeString`:
  /// `DlvOrd,001,01,{OrderId},{OrderSource},{CommitPrices},{CustomerNo},{AddressId},{PilotNo},{DeliveryFees:N2}`
  String get cashierQrPayload {
    if (!hasFujitsuIds) return qrPayload;
    final fee = deliveryFee.toStringAsFixed(2);
    return 'DlvOrd,001,01,$fujitsuOrderId,$orderSource,$commitPrices,'
        '$fujitsuCustomerNo,$fujitsuAddressId,$pilotNo,$fee';
  }

  /// Maps Supabase `orders.order_source` → Fujitsu OrderSource int.
  static int fujitsuOrderSource(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'phone' || v == 'call' || v == 'call_center' || v == '0') {
      return 0;
    }
    if (v == 'app' || v == 'online' || v == '1') return 1;
    // Default phone/call-center (matches existing Trusty HD traffic).
    return 0;
  }

  String get phonesLabel {
    final a = customerPhone?.trim();
    final b = customerPhone2?.trim();
    if (a != null && a.isNotEmpty && b != null && b.isNotEmpty) {
      return '$a - $b';
    }
    return a ?? b ?? '—';
  }

  String get paymentLabel => switch (paymentMethod) {
        'cash' || 'cash_on_delivery' => 'نقدي',
        'visa_on_delivery' => 'فيزا عند الاستلام',
        'card' || 'visa' => 'ائتمان',
        'instapay' => 'إنستا باي',
        _ => (paymentMethod?.trim().isNotEmpty ?? false)
            ? paymentMethod!.trim()
            : 'نقدي',
      };

  /// Group items under category headers like the POS receipt.
  Map<String, List<PrepReceiptItem>> get byCategory {
    final map = <String, List<PrepReceiptItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.categoryName, () => []).add(item);
    }
    return map;
  }

  factory PrepReceipt.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <PrepReceiptItem>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map<String, dynamic>) {
          items.add(PrepReceiptItem.fromJson(row));
        } else if (row is Map) {
          items.add(PrepReceiptItem.fromJson(Map<String, dynamic>.from(row)));
        }
      }
    }

    String? text(String key) {
      final v = json[key]?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    }

    double money(Object? value) => switch (value) {
          final num n => n.toDouble(),
          final String t => double.tryParse(t) ?? 0,
          _ => 0,
        };

    final waiting = json['waiting_fujitsu'] == true ||
        json['waiting_fujitsu']?.toString().toLowerCase() == 'true';
    final fujitsuOrderId = text('fujitsu_order_id');
    final fujitsuCustomerNo = text('fujitsu_customer_no');
    final fujitsuAddressId = text('fujitsu_address_id');
    final fee = money(json['delivery_fee']);
    final orderSource = switch (json['order_source_code']) {
      final num n => n.toInt(),
      final String t when int.tryParse(t.trim()) != null =>
        int.parse(t.trim()),
      _ => fujitsuOrderSource(text('order_source')),
    };
    final commitPrices = switch (json['commit_prices']) {
      final num n => n.toInt(),
      final String t => int.tryParse(t.trim()) ?? 0,
      _ => 0,
    };
    final pilotNo = switch (json['pilot_no']) {
      final num n => n.toInt(),
      final String t => int.tryParse(t.trim()) ?? 0,
      _ => 0,
    };
    final hasFujitsu = fujitsuOrderId != null &&
        fujitsuCustomerNo != null &&
        fujitsuAddressId != null;
    final builtQr = hasFujitsu
        ? 'DlvOrd,001,01,$fujitsuOrderId,$orderSource,$commitPrices,'
            '$fujitsuCustomerNo,$fujitsuAddressId,$pilotNo,'
            '${fee.toStringAsFixed(2)}'
        : (text('qr_payload') ?? '');

    return PrepReceipt(
      orderId: text('order_id') ?? '',
      receiptNumber: fujitsuOrderId ?? text('receipt_number') ?? '',
      qrPayload: builtQr,
      storeName: text('store_name') ?? 'سفير ماركت',
      branchName: text('branch_name') ?? 'حي الزهور',
      branchCode: text('branch_code') ?? '001',
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
      waitingFujitsu: waiting && !hasFujitsu,
      fujitsuOrderId: fujitsuOrderId,
      fujitsuCustomerNo: fujitsuCustomerNo,
      fujitsuAddressId: fujitsuAddressId,
      fujitsuSyncError: text('fujitsu_sync_error'),
      takerName: text('taker_name'),
      preparerName: text('preparer_name'),
      driverName: text('driver_name'),
      customerName: text('customer_name'),
      customerPhone: text('customer_phone'),
      customerPhone2: text('customer_phone2'),
      address: text('address'),
      deliveryArea: text('delivery_area'),
      paymentMethod: text('payment_method'),
      deliveryFee: fee,
      totalAmount: money(json['total_amount']),
      posCustomerId: text('pos_customer_id'),
      fujitsuZoneId: text('fujitsu_zone_id'),
      orderSource: orderSource,
      commitPrices: commitPrices,
      pilotNo: pilotNo,
      items: items,
    );
  }
}

class PrepReceiptItem {
  const PrepReceiptItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.categoryName,
    this.barcode,
    this.listPrice,
  });

  final String productName;
  final String? barcode;
  final int quantity;
  final double unitPrice;

  /// Shelf / list price when different from charged [unitPrice].
  final double? listPrice;
  final String categoryName;

  double get lineTotal => unitPrice * quantity;

  double get displayPrice =>
      (listPrice != null && listPrice! > 0) ? listPrice! : unitPrice;

  bool get hasDiscount =>
      listPrice != null && listPrice! > unitPrice + 0.001;

  factory PrepReceiptItem.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key]?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    }

    double money(Object? value) => switch (value) {
          final num n => n.toDouble(),
          final String t => double.tryParse(t) ?? 0,
          _ => 0,
        };

    int qty(Object? value) => switch (value) {
          final int n => n,
          final num n => n.round(),
          final String t => int.tryParse(t) ?? 1,
          _ => 1,
        };

    final unit = money(json['unit_price']);
    final list = money(json['list_price']);
    final discount = money(json['discount_price']);
    final charged = discount > 0 && discount < list ? discount : unit;

    return PrepReceiptItem(
      productName: text('product_name') ?? 'منتج',
      barcode: text('barcode'),
      quantity: qty(json['quantity']),
      unitPrice: charged > 0 ? charged : unit,
      listPrice: list > 0 ? list : null,
      categoryName: text('category_name') ?? 'أصناف',
    );
  }
}
