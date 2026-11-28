import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/postgrest_helpers.dart';
import '../../../auth/domain/customer_phone.dart';
import '../../../catalog/domain/main_categories.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/phone_order.dart';
import '../../domain/product_search_filter.dart';
import '../../domain/repositories/phone_orders_repository.dart';

/// Customers and orders go through the security-definer functions in
/// 20261111010000_phone_orders.sql (staff only; prices come from
/// `products`); product search reads `products` directly.
class SupabasePhoneOrdersRepository implements PhoneOrdersRepository {
  const SupabasePhoneOrdersRepository(this._client);

  static const productLimit = 40;
  static const receiptsBucket = 'payment_receipts';
  static const _productColumns = 'id, barcode, name, price, discount_price, '
      'unit, category, category_id, stock_quantity, is_active, image_url, '
      'is_weight_based';

  final SupabaseClient _client;

  @override
  Future<List<PhoneOrderCustomer>> searchCustomers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final rows = await _rpc(
      'search_phone_order_customers',
      {'p_query': trimmed, 'p_limit': 20},
    );
    return [for (final row in _rows(rows)) _toCustomer(row)];
  }

  @override
  Future<PhoneOrderCustomer> createCustomer({
    required String fullName,
    required String phone,
    String? address,
    String? zone,
    String? fujitsuZoneId,
    String? phone2,
    String? phone3,
    String? phone4,
    String? phone5,
    String? notes,
    String? branch,
    PhoneOrderCustomerType type = PhoneOrderCustomerType.regular,
    String? governorate,
    String? city,
    String? building,
    String? street,
    String? landmark,
    String? floor,
    String? apartment,
    double? latitude,
    double? longitude,
  }) async {
    final slots = CustomerPhone.fiveSlots([phone, phone2, phone3, phone4, phone5]);
    final rows = _rows(await _rpc('create_phone_order_customer', {
      'p_full_name': fullName,
      'p_phone': slots[0],
      'p_address': address,
      'p_zone': zone,
      if (fujitsuZoneId != null) 'p_fujitsu_zone_id': fujitsuZoneId,
      if (slots[1] != null) 'p_phone2': slots[1],
      if (slots[2] != null) 'p_phone3': slots[2],
      if (slots[3] != null) 'p_phone4': slots[3],
      if (slots[4] != null) 'p_phone5': slots[4],
      if (notes != null) 'p_notes': notes,
      if (branch != null) 'p_branch': branch,
      if (type != PhoneOrderCustomerType.regular) 'p_customer_type': type.value,
      if (governorate != null) 'p_governorate': governorate,
      if (city != null) 'p_city': city,
      if (building != null) 'p_building': building,
      if (street != null) 'p_street': street,
      if (landmark != null) 'p_landmark': landmark,
      if (floor != null) 'p_floor': floor,
      if (apartment != null) 'p_apartment': apartment,
      if (latitude != null && longitude != null) ...{
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    }));
    if (rows.isEmpty) {
      throw PhoneOrderFailure(L10n.current.phoneOrderFailed('no customer'));
    }
    return _toCustomer(rows.first);
  }

  @override
  Future<PhoneOrderCustomerDetails> fetchCustomerDetails(
    PhoneOrderCustomer customer,
  ) async {
    final raw = await _rpc('get_phone_order_customer_details', {
      if (customer.posCustomerId != null)
        'p_pos_customer_id': customer.posCustomerId,
      if (customer.userId != null) 'p_user_id': customer.userId,
    });
    final map = switch (raw) {
      final Map m => Map<String, dynamic>.from(m),
      _ => <String, dynamic>{},
    };
    final custMap = switch (map['customer']) {
      final Map m => Map<String, dynamic>.from(m),
      _ => <String, dynamic>{},
    };
    final addrList = switch (map['addresses']) {
      final List list => list,
      _ => const [],
    };
    return PhoneOrderCustomerDetails(
      customer: _toCustomer({
        ...custMap,
        if (custMap['source'] == null)
          'source': customer.source == PhoneOrderCustomerSource.app
              ? 'app'
              : 'pos',
      }),
      addresses: [
        for (final row in addrList)
          if (row is Map) _toAddress(Map<String, dynamic>.from(row)),
      ],
    );
  }

  @override
  Future<PhoneOrderCustomer> updateCustomerDetails({
    required int posCustomerId,
    String? fullName,
    String? phone,
    String? phone2,
    String? phone3,
    String? phone4,
    String? phone5,
    String? notes,
  }) async {
    final hasPhones = phone != null ||
        phone2 != null ||
        phone3 != null ||
        phone4 != null ||
        phone5 != null;
    final slots = hasPhones
        ? CustomerPhone.fiveSlots([phone, phone2, phone3, phone4, phone5])
        : null;
    final raw = await _rpc('update_phone_order_customer_details', {
      'p_pos_customer_id': posCustomerId,
      if (fullName != null) 'p_full_name': fullName,
      if (slots != null) ...{
        'p_phone': slots[0],
        // Empty string clears optional phones in the RPC.
        'p_phone2': slots[1] ?? '',
        'p_phone3': slots[2] ?? '',
        'p_phone4': slots[3] ?? '',
        'p_phone5': slots[4] ?? '',
      },
      if (notes != null) 'p_notes': notes,
    });
    final map = switch (raw) {
      final Map m => Map<String, dynamic>.from(m),
      _ => <String, dynamic>{},
    };
    return _toCustomer(map);
  }

  @override
  Future<PhoneOrderCustomerAddress> upsertCustomerAddress({
    int? posCustomerId,
    String? userId,
    int? addressId,
    String? address,
    String? zone,
    String? branch,
    String? governorate,
    String? city,
    String? building,
    String? street,
    String? landmark,
    String? floor,
    String? apartment,
    String? notes,
    double? latitude,
    double? longitude,
    String? fujitsuZoneId,
    bool isPrimary = false,
  }) async {
    final raw = await _rpc('upsert_customer_address', {
      if (posCustomerId != null) 'p_pos_customer_id': posCustomerId,
      if (userId != null) 'p_user_id': userId,
      if (addressId != null) 'p_address_id': addressId,
      if (address != null) 'p_address': address,
      if (zone != null) 'p_zone': zone,
      if (branch != null) 'p_branch': branch,
      if (governorate != null) 'p_governorate': governorate,
      if (city != null) 'p_city': city,
      if (building != null) 'p_building': building,
      if (street != null) 'p_street': street,
      if (landmark != null) 'p_landmark': landmark,
      if (floor != null) 'p_floor': floor,
      if (apartment != null) 'p_apartment': apartment,
      if (notes != null) 'p_notes': notes,
      if (latitude != null && longitude != null) ...{
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
      if (fujitsuZoneId != null) 'p_fujitsu_zone_id': fujitsuZoneId,
      'p_is_primary': isPrimary,
    });
    final map = switch (raw) {
      final Map m => Map<String, dynamic>.from(m),
      _ => <String, dynamic>{},
    };
    return _toAddress(map);
  }

  @override
  Future<List<PhoneOrderArea>> fetchAreas({String? city}) async {
    try {
      var request = _client
          .from('delivery_zones')
          .select('fujitsu_zone_id, name, delivery_fee')
          .eq('is_active', true);
      if (city != null) request = request.eq('city', city);
      final rows = await request.order('name');
      return [
        for (final row in rows)
          if ('${row['name'] ?? ''}'.trim().isNotEmpty)
            PhoneOrderArea(
              name: '${row['name']}'.trim(),
              deliveryFee: _asDouble(row['delivery_fee']),
              fujitsuZoneId: row['fujitsu_zone_id'] == null
                  ? null
                  : '${row['fujitsu_zone_id']}',
            ),
      ];
    } on PostgrestException catch (error) {
      // No `delivery_zones` table yet: the zone list simply stays empty.
      debugPrint('Zones read failed: ${error.code} ${error.message}');
      return const [];
    }
  }

  @override
  Future<List<Product>> searchProducts(
    String query, {
    MainCategory? category,
    ProductSearchFilterMode filter = ProductSearchFilterMode.inStock,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty && category == null) return const [];

    var request = _client.from('products').select(_productColumns);
    request = switch (filter) {
      // «المخزون الفعلي»: active + stock > 0 only.
      ProductSearchFilterMode.inStock => request.inStock(),
      // «كل الأصناف»: no stock / is_active filters — show exact stock.
      ProductSearchFilterMode.allItems => request,
      ProductSearchFilterMode.offers => request
          .not('is_active', 'is', false)
          .not('discount_price', 'is', null)
          .gt('discount_price', 0),
    };
    if (category != null) {
      request = request.inFilter('category', [
        for (final name in category.subCategories) ...[name, '$name '],
      ]);
    }
    final words =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isNotEmpty) {
      if (RegExp(r'^\d{4,}$').hasMatch(trimmed)) {
        // Pure numeric query → barcode prefix (also allow name match).
        final code = _escapeLike(trimmed);
        request = request.or('barcode.ilike.$code*,name.ilike.*$code*');
      } else {
        // AND each token across name/barcode so «جهينة 5+1» works in
        // كل الأصناف / العروض (not only المخزون الفعلي). Filtering only the
        // first token + a small LIMIT dropped zero-stock / offer rows that
        // sort later alphabetically among hundreds of «جهينة» matches.
        // PostgREST `or=` filters use `*` as the LIKE wildcard (not `%`).
        for (final word in words) {
          final escaped = _escapeLike(word);
          request = request.or(
            'name.ilike.*$escaped*,barcode.ilike.*$escaped*',
          );
        }
      }
    }

    try {
      final rows = await request.order('name').limit(productLimit * 2);
      var products = rows.map(ProductModel.fromJson).toList();
      if (filter == ProductSearchFilterMode.offers) {
        products = [
          for (final product in products)
            if (product.hasActiveOffer) product,
        ];
      }
      // Client-side Arabic-normalized AND (covers alef/teh variants).
      return products
          .where((product) {
            if (words.isEmpty) return true;
            final name = product.name;
            final barcode = product.barcode ?? '';
            return words.every(
              (word) =>
                  arabicSearchContains(name, word) ||
                  arabicSearchContains(barcode, word),
            );
          })
          .take(productLimit)
          .toList();
    } on PostgrestException catch (error) {
      debugPrint('Phone order product search failed: '
          '${error.code} ${error.message}');
      throw PhoneOrderFailure(
          L10n.current.phoneOrderSearchFailed(error.message));
    }
  }

  @override
  Future<String> placeOrder({
    required PhoneOrderCustomer customer,
    required List<PhoneOrderLine> lines,
    required double deliveryFee,
    PhoneOrderPayment paymentMethod = PhoneOrderPayment.cash,
    PaymentReceiptImage? receipt,
    bool isSupplemental = false,
  }) async {
    String? receiptUrl;
    if (paymentMethod.needsReceipt) {
      if (receipt == null) {
        throw const PhoneOrderFailure('أرفق صورة التحويل لإتمام طلب إنستا باي');
      }
      receiptUrl = await _uploadReceipt(receipt);
    }

    final Object? orderId;
    try {
      orderId = await _rpc('place_phone_order', {
        'p_user_id': customer.userId,
        'p_pos_customer_id': customer.posCustomerId,
        'p_customer_name': customer.fullName,
        'p_customer_phone': customer.phone,
        'p_address': customer.address,
        'p_area': customer.zone,
        'p_items': [
          for (final line in lines)
            {
              'product_id': line.product.id,
              'quantity': line.quantity,
              if (line.weightInGrams case final grams?)
                'weight_in_grams': grams,
              if (line.trimmedNotes case final note?) 'notes': note,
            },
        ],
        'p_delivery_fee': deliveryFee,
        // Cash is the function's default, so a plain order still works on a
        // database that hasn't had the payment migration yet.
        if (paymentMethod != PhoneOrderPayment.cash) ...{
          'p_payment_method': paymentMethod.value,
          'p_payment_status': paymentMethod.paymentStatus,
          if (receiptUrl != null) 'p_receipt_url': receiptUrl,
        },
        if (customer.fujitsuAddressId != null)
          'p_fujitsu_address_id': customer.fujitsuAddressId,
        if (isSupplemental) ...{
          'p_is_supplemental': true,
          'p_admin_note': 'طلب ملحق',
        },
      });
    } catch (_) {
      if (receiptUrl != null) await _removeReceipt(receiptUrl);
      rethrow;
    }
    if (orderId is! String || orderId.isEmpty) {
      throw PhoneOrderFailure(L10n.current.phoneOrderFailed('$orderId'));
    }
    return orderId;
  }

  @override
  Future<bool> hasOrderToday(PhoneOrderCustomer customer) async {
    try {
      final raw = await _rpc('customer_has_order_today', {
        if (customer.posCustomerId != null)
          'p_pos_customer_id': customer.posCustomerId,
        if (customer.userId != null) 'p_user_id': customer.userId,
        if (customer.phone != null) 'p_phone': customer.phone,
      });
      return raw == true;
    } catch (_) {
      return false;
    }
  }

  /// The InstaPay screenshot goes to the public `payment_receipts` bucket,
  /// under the signed-in staff member's folder (what its policy allows).
  Future<String> _uploadReceipt(PaymentReceiptImage receipt) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const PhoneOrderFailure('سجّل الدخول لرفع صورة التحويل');
    }
    final safeName = receipt.fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      final storage = _client.storage.from(receiptsBucket);
      await storage.uploadBinary(
        path,
        receipt.bytes,
        fileOptions: FileOptions(contentType: receipt.contentType),
      );
      return storage.getPublicUrl(path);
    } on StorageException catch (error) {
      debugPrint('Receipt upload failed: ${error.statusCode} ${error.message}');
      throw PhoneOrderFailure('تعذّر رفع صورة التحويل: ${error.message}');
    }
  }

  /// Best effort: an order that failed leaves no orphan image behind.
  Future<void> _removeReceipt(String url) async {
    final marker = '/$receiptsBucket/';
    final index = url.indexOf(marker);
    if (index < 0) return;
    try {
      await _client.storage
          .from(receiptsBucket)
          .remove([Uri.decodeComponent(url.substring(index + marker.length))]);
    } catch (_) {}
  }
  @override
  Future<CustomerPurchaseHistory> fetchCustomerHistory(
    PhoneOrderCustomer customer,
  ) async {
    // Omit nulls so PostgREST matches the defaulted signature cleanly.
    final params = <String, Object?>{
      'p_limit': 40,
      if (customer.userId case final id?) 'p_user_id': id,
      if (customer.posCustomerId case final id?) 'p_pos_customer_id': id,
      if (customer.phone case final phone?
          when phone.trim().isNotEmpty)
        'p_customer_phone': phone.trim(),
    };
    final raw = await _rpc('phone_order_customer_history', params);
    final map = _asHistoryMap(raw);
    return CustomerPurchaseHistory(
      items: [
        for (final row in _rows(map['items']))
          if (_toPurchaseItem(row) case final item?) item,
      ],
      lastOrderLines: [
        for (final row in _rows(map['last_order_items']))
          if (_toHistoryLine(row) case final line?) line,
      ],
    );
  }

  @override
  Future<List<CustomerPastOrderSummary>> fetchCustomerPastOrders(
    PhoneOrderCustomer customer,
  ) async {
    final params = <String, Object?>{
      'p_limit': 40,
      if (customer.userId case final id?) 'p_user_id': id,
      if (customer.posCustomerId case final id?) 'p_pos_customer_id': id,
      if (customer.phone case final phone?
          when phone.trim().isNotEmpty)
        'p_customer_phone': phone.trim(),
    };
    final raw = await _rpc('phone_order_customer_orders', params);
    return [
      for (final row in _rows(raw))
        if (_toPastOrderSummary(row) case final summary?) summary,
    ];
  }

  @override
  Future<CustomerPastOrderDetail> fetchCustomerPastOrderDetail(
    String orderId,
  ) async {
    final raw = await _rpc('phone_order_customer_order_detail', {
      'p_order_id': orderId,
    });
    final map = _asHistoryMap(raw);
    final summary = _toPastOrderSummary({
      'order_id': map['order_id'],
      'fujitsu_order_id': map['fujitsu_order_id'],
      'pos_receipt_number': map['pos_receipt_number'],
      'created_at': map['created_at'],
      'total_amount': map['total_amount'],
      'delivery_fee': map['delivery_fee'],
      'status': map['status'],
      'taker_name': map['taker_name'],
      'preparer_name': map['preparer_name'],
      'driver_name': map['driver_name'],
      'payment_method': map['payment_method'],
      'customer_name': map['customer_name'],
      'customer_phone': map['customer_phone'],
    });
    if (summary == null) {
      throw const PhoneOrderFailure('تعذر تحميل تفاصيل الطلب');
    }
    return CustomerPastOrderDetail(
      summary: summary,
      addressDetails: map['address_details']?.toString(),
      lines: [
        for (final row in _rows(map['items']))
          if (_toHistoryLine(row) case final line?) line,
      ],
    );
  }

  static CustomerPastOrderSummary? _toPastOrderSummary(
    Map<String, dynamic> row,
  ) {
    final id = '${row['order_id'] ?? ''}'.trim();
    if (id.isEmpty) return null;
    final created =
        DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal() ??
            DateTime.now();
    return CustomerPastOrderSummary(
      orderId: id,
      createdAt: created,
      totalAmount: _asDouble(row['total_amount']) ?? 0,
      deliveryFee: _asDouble(row['delivery_fee']) ?? 0,
      fujitsuOrderId: row['fujitsu_order_id']?.toString(),
      posReceiptNumber: row['pos_receipt_number']?.toString(),
      status: row['status']?.toString(),
      takerName: row['taker_name']?.toString(),
      preparerName: row['preparer_name']?.toString(),
      driverName: row['driver_name']?.toString(),
      paymentMethod: row['payment_method']?.toString(),
      customerName: row['customer_name']?.toString(),
      customerPhone: row['customer_phone']?.toString(),
    );
  }

  static Map<String, dynamic> _asHistoryMap(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) return _tryDecodeMap(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      // Rare: PostgREST wrapping a single jsonb object in an array.
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return const {};
  }

  static Map<String, dynamic> _tryDecodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  static CustomerPurchaseItem? _toPurchaseItem(Map<String, dynamic> row) {
    final product = _productFromHistoryRow(row);
    if (product == null) return null;
    final lastAt = DateTime.tryParse('${row['last_ordered_at'] ?? ''}') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return CustomerPurchaseItem(
      product: product,
      timesOrdered: _asInt(row['times_ordered']) ?? 0,
      totalQuantity: _asDouble(row['total_quantity']) ?? 0,
      lastOrderedAt: lastAt.toLocal(),
      lastQuantity: _asInt(row['last_quantity']) ?? 1,
      lastWeightInGrams: _asInt(row['last_weight_in_grams']),
    );
  }

  static PhoneOrderLine? _toHistoryLine(Map<String, dynamic> row) {
    final product = _productFromHistoryRow(row);
    if (product == null) return null;
    final weight = _asInt(row['weight_in_grams']);
    final quantity = _asInt(row['quantity']) ?? 1;
    if (weight != null && weight > 0) {
      return PhoneOrderLine(
        product: product,
        quantity: 1,
        weightInGrams: weight,
      );
    }
    return PhoneOrderLine(product: product, quantity: quantity.clamp(1, 999));
  }

  static Product? _productFromHistoryRow(Map<String, dynamic> row) {
    final id = row['product_id']?.toString();
    if (id == null || id.isEmpty) return null;
    return ProductModel.fromJson({
      'id': id,
      'name': row['name'],
      'price': row['price'],
      'discount_price': row['discount_price'],
      'image_url': row['image_url'],
      'unit': row['unit'],
      'barcode': row['barcode'],
      'stock_quantity': row['stock_quantity'],
      'is_active': row['is_active'],
      'is_weight_based': row['is_weight_based'] == true,
    });
  }

  static int? _asInt(Object? value) => switch (value) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };

  static double? _asDouble(Object? value) => switch (value) {
        final double value => value,
        final num value => value.toDouble(),
        final String value => double.tryParse(value),
        _ => null,
      };

  Future<Object?> _rpc(String function, Map<String, Object?> params) async {
    try {
      return await _client.rpc<Object?>(function, params: params);
    } on PostgrestException catch (error) {
      debugPrint('$function failed: ${error.code} ${error.message} '
          '${error.details ?? ''}');
      throw PhoneOrderFailure(_message(error));
    }
  }

  static String _message(PostgrestException error) {
    final l10n = L10n.current;
    final message = error.message;
    // The function isn't in the database (or PostgREST hasn't reloaded).
    if (error.code == 'PGRST202') {
      final function = RegExp(r'public\.(\w+)').firstMatch(message)?.group(1);
      if (function == 'place_phone_order' && message.contains('p_payment')) {
        return 'طرق الدفع تحتاج ترحيلاً جديداً. شغّل ملف '
            'supabase/migrations/20261119220000_phone_order_payment.sql '
            'من Supabase SQL Editor.';
      }
      if (function == 'create_phone_order_customer' &&
          message.contains('p_fujitsu_zone_id')) {
        return 'ربط العميل بمنطقة Fujitsu يحتاج ترحيلاً جديداً. شغّل ملف '
            'supabase/migrations/20261119210000_delivery_zones_fujitsu.sql '
            'من Supabase SQL Editor.';
      }
      if (function == 'create_phone_order_customer' &&
          RegExp(r'p_(phone2|customer_type|governorate|city|building|floor|'
                  r'apartment|latitude|longitude)')
              .hasMatch(message)) {
        return 'تفاصيل العميل والعنوان تحتاج ترحيلاً جديداً. شغّل ملف '
            'supabase/migrations/20261119000000_phone_order_customer_details.sql '
            'من Supabase SQL Editor.';
      }
      return l10n.phoneOrderSetupMissing(function ?? message);
    }
    if (message.contains('not_allowed')) return l10n.phoneOrderNotAllowed;
    if (message.contains('invalid_phone')) return l10n.phoneOrderPhoneInvalid;
    if (message.contains('name_required')) return l10n.phoneOrderNameRequired;
    if (message.contains('receipt_required')) {
      return 'أرفق صورة التحويل لإتمام طلب إنستا باي';
    }
    if (message.contains('invalid_zone')) {
      return 'المنطقة المختارة غير موجودة في «المناطق». حدّث القائمة وأعد المحاولة.';
    }
    return l10n.phoneOrderFailed('$message (${error.code})');
  }

  static List<Map<String, dynamic>> _rows(Object? data) => [
        if (data is List)
          for (final row in data)
            if (row is Map) Map<String, dynamic>.from(row),
      ];

  static PhoneOrderCustomer _toCustomer(Map<String, dynamic> row) {
    String? text(String key) {
      final value = row[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    int? integer(Object? value) => switch (value) {
          final num id => id.toInt(),
          final String id => int.tryParse(id),
          _ => null,
        };
    final isApp = row['source'] == 'app';
    final slots = CustomerPhone.fiveSlots([
      text('phone'),
      text('phone2'),
      text('phone3'),
      text('phone4'),
      text('phone5'),
    ]);
    return PhoneOrderCustomer(
      source:
          isApp ? PhoneOrderCustomerSource.app : PhoneOrderCustomerSource.pos,
      userId: text('user_id'),
      // Linked app customers carry both ids; bare POS rows may use `id`.
      posCustomerId: integer(row['pos_customer_id']) ??
          (row.containsKey('source') ? null : integer(row['id'])),
      fullName: text('full_name'),
      phone: slots[0],
      phone2: slots[1],
      phone3: slots[2],
      phone4: slots[3],
      phone5: slots[4],
      notes: text('notes'),
      address: text('address'),
      zone: text('zone'),
      fujitsuZoneId: text('fujitsu_zone_id'),
      fujitsuCustomerNo: integer(row['fujitsu_customer_no']),
      fujitsuAddressId: integer(row['fujitsu_address_id']),
      selectedAddressId: text('selected_address_id'),
    );
  }

  static PhoneOrderCustomerAddress _toAddress(Map<String, dynamic> row) {
    String? text(String key) {
      final value = row[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    int? integer(Object? value) => switch (value) {
          final num id => id.toInt(),
          final String id => int.tryParse(id),
          _ => null,
        };
    double? decimal(Object? value) => switch (value) {
          final num n => n.toDouble(),
          final String s => double.tryParse(s),
          _ => null,
        };
    final fromApp = row['source_table'] == 'addresses';
    final id = text('id') ?? '';
    return PhoneOrderCustomerAddress(
      id: id,
      address: text('address') ?? 'بدون عنوان',
      zone: text('zone'),
      branch: text('branch'),
      governorate: text('governorate'),
      city: text('city'),
      building: text('building'),
      street: text('street'),
      landmark: text('landmark'),
      floor: text('floor'),
      apartment: text('apartment'),
      notes: text('notes'),
      latitude: decimal(row['latitude']),
      longitude: decimal(row['longitude']),
      fujitsuZoneId: text('fujitsu_zone_id'),
      fujitsuAddressId: integer(row['fujitsu_address_id']),
      isPrimary: row['is_primary'] == true,
      fromAppAddresses: fromApp,
    );
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_')
      .replaceAll(',', '')
      .replaceAll('(', '')
      .replaceAll(')', '');
}
