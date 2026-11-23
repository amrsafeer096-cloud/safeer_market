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
    this.takerName,
    this.preparerName,
    this.customerName,
    this.customerPhone,
    this.customerPhone2,
    this.address,
    this.deliveryArea,
    this.paymentMethod,
    this.posCustomerId,
    this.fujitsuZoneId,
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
  final List<PrepReceiptItem> items;

  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);

  /// Items total without delivery (matches sample «الإجمالي» of products).
  double get itemsTotal =>
      items.fold<double>(0, (s, i) => s + i.lineTotal);

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

    return PrepReceipt(
      orderId: text('order_id') ?? '',
      receiptNumber: text('receipt_number') ?? '',
      qrPayload: text('qr_payload') ?? '',
      storeName: text('store_name') ?? 'سفير ماركت',
      branchName: text('branch_name') ?? 'حي الزهور',
      branchCode: text('branch_code') ?? '001',
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
      takerName: text('taker_name'),
      preparerName: text('preparer_name'),
      customerName: text('customer_name'),
      customerPhone: text('customer_phone'),
      customerPhone2: text('customer_phone2'),
      address: text('address'),
      deliveryArea: text('delivery_area'),
      paymentMethod: text('payment_method'),
      deliveryFee: money(json['delivery_fee']),
      totalAmount: money(json['total_amount']),
      posCustomerId: text('pos_customer_id'),
      fujitsuZoneId: text('fujitsu_zone_id'),
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
