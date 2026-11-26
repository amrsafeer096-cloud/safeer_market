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

  /// True when [orderSource] is mobile app / online (`1`).
  bool get isAppOrder => orderSource == 1;

  /// Bold receipt line: «مصدر الطلب: …».
  String get orderSourceLabel => isAppOrder
      ? 'مصدر الطلب: عميل تطبيق (أبليكيشن)'
      : 'مصدر الطلب: طلب تليفون';

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

  /// Piece counts + one per weighted line (matches receipt «عدد الأصناف»).
  int get itemCount => items.fold<int>(
        0,
        (s, i) => s + (i.isWeightBased ? 1 : i.quantity),
      );

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
    required this.lineTotal,
    required this.categoryName,
    this.barcode,
    this.listPrice,
    this.weightInGrams,
    this.isWeightBased = false,
  });

  final String productName;
  final String? barcode;

  /// Piece count. Weighted lines keep `1`; use [weightInGrams] / [quantityLabel].
  final int quantity;

  /// Charged unit: per piece, or **per kg** for weighted lines.
  final double unitPrice;

  /// Exact line value (pieces: unit × qty; weight: proportional kilo total).
  final double lineTotal;

  /// Shelf / list unit price (per piece or per kg) when known.
  final double? listPrice;
  final String categoryName;
  final int? weightInGrams;
  final bool isWeightBased;

  /// `500 جم`, `1.3 كجم`, or `5 قطعة`.
  String get quantityLabel {
    if (isWeightBased) {
      final grams = weightInGrams ?? 0;
      if (grams <= 0) return '1';
      // Keep exact decimal kg (e.g. 1300 → 1.3 كجم, 125 → 125 جم).
      if (grams % 1000 == 0) {
        final kg = grams ~/ 1000;
        return kg == 1 ? '1 كجم' : '$kg كجم';
      }
      if (grams > 1000) {
        final kilos = grams / 1000.0;
        var text = kilos.toStringAsFixed(3);
        text = text.replaceFirst(RegExp(r'0+$'), '');
        text = text.replaceFirst(RegExp(r'\.$'), '');
        return '$text كجم';
      }
      return '$grams جم';
    }
    return '$quantity قطعة';
  }

  double get displayPrice =>
      (listPrice != null && listPrice! > 0) ? listPrice! : unitPrice;

  /// Real unit discount only (never treat weight fraction as a خصم).
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

    int? asInt(Object? value) => switch (value) {
          null => null,
          final int n => n,
          final num n => n.round(),
          final String t => int.tryParse(t.trim()),
          _ => null,
        };

    final grams = asInt(json['weight_in_grams']);
    final flaggedWeight = json['is_weight_based'] == true ||
        json['is_weight_based']?.toString().toLowerCase() == 'true';
    final isWeight = (grams != null && grams > 0) || flaggedWeight;
    final qtyRaw = asInt(json['quantity']) ?? 1;
    final stored = money(json['unit_price'] ?? json['price_at_time']);
    final list = money(json['list_price']);
    final hasExplicitLine = json.containsKey('line_total');
    final explicitLine = money(json['line_total']);

    if (isWeight && grams != null && grams > 0) {
      final kg = grams / 1000.0;
      // RPC sends unit_price=per-kg + line_total=line. Raw order_items
      // fallbacks send price_at_time as the line total with quantity=1.
      double unit;
      double line;
      if (hasExplicitLine) {
        line = explicitLine;
        unit = stored;
        // Guard: if unit was still the line total, recover per-kg.
        if (kg > 0 && (unit - line).abs() < 0.05) {
          unit = line / kg;
        }
      } else {
        line = stored;
        unit = kg > 0 ? line / kg : stored;
      }
      return PrepReceiptItem(
        productName: text('product_name') ?? 'منتج',
        barcode: text('barcode'),
        quantity: 1,
        unitPrice: unit,
        lineTotal: line,
        listPrice: list > 0 ? list : null,
        categoryName: text('category_name') ?? 'أصناف',
        weightInGrams: grams,
        isWeightBased: true,
      );
    }

    final unit = stored;
    final line = hasExplicitLine ? explicitLine : unit * qtyRaw;
    return PrepReceiptItem(
      productName: text('product_name') ?? 'منتج',
      barcode: text('barcode'),
      quantity: qtyRaw < 1 ? 1 : qtyRaw,
      unitPrice: unit,
      lineTotal: line,
      listPrice: list > 0 ? list : null,
      categoryName: text('category_name') ?? 'أصناف',
      weightInGrams: null,
      isWeightBased: false,
    );
  }
}
