import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/paymob_config.dart';
import '../domain/pending_subscription.dart';
import '../domain/subscription.dart';

/// Paymob Accept credentials (from [PaymobConfig], overridable in tests).
class PaymobCredentials {
  const PaymobCredentials({
    required this.apiKey,
    required this.integrationId,
    required this.iframeId,
    this.baseUrl = PaymobConfig.baseUrl,
    this.redirectUrl = PaymobConfig.redirectUrl,
  });

  factory PaymobCredentials.fromAppConfig() => const PaymobCredentials(
        apiKey: PaymobConfig.apiKey,
        integrationId: PaymobConfig.integrationId,
        iframeId: PaymobConfig.iframeId,
        baseUrl: PaymobConfig.baseUrl,
        redirectUrl: PaymobConfig.redirectUrl,
      );

  final String apiKey;
  final String integrationId;
  final String iframeId;
  final String baseUrl;
  final String redirectUrl;
}

/// Paymob Accept checkout runs **in the app** (auth → order → payment key).
/// No Supabase Edge Function is invoked for creating payments.
class PaymobService {
  PaymobService(
    this._client, {
    http.Client? httpClient,
    PaymobCredentials? credentials,
  })  : _http = httpClient ?? http.Client(),
        _credentials = credentials ?? PaymobCredentials.fromAppConfig();

  final SupabaseClient _client;
  final http.Client _http;
  final PaymobCredentials _credentials;

  static const _paymentKeyLifetime = 3600;

  /// Plan prices in piasters (must match the former Edge Function).
  static const planPricesCents = <PaidTier, int>{
    PaidTier.vip: 18000,
    PaidTier.prime: 9000,
  };

  static const planNames = <PaidTier, String>{
    PaidTier.vip: 'Safeer Pro (VIP) - 30 days',
    PaidTier.prime: 'Safeer Prime - 30 days',
  };

  Future<PaymobCheckout> createCheckout({
    required PaidTier tier,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) async {
    final amountCents = planPricesCents[tier];
    if (amountCents == null) {
      throw const PaymentFailure('invalid_tier');
    }
    final merchantOrderId =
        'sub_${tier.value}_${DateTime.now().millisecondsSinceEpoch}';
    return _startPaymobCheckout(
      amountCents: amountCents,
      itemName: planNames[tier]!,
      merchantOrderId: merchantOrderId,
      method: method,
      walletPhone: walletPhone,
      tier: tier,
    );
  }

  /// Starts Paymob checkout for an existing grocery [orderId], always ending
  /// on the Accept iframe WebView URL for card payments.
  Future<PaymobCheckout> createOrderCheckout({
    required String orderId,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) async {
    final row = await _client
        .from('orders')
        .select('id, total_amount, user_id')
        .eq('id', orderId)
        .maybeSingle();
    if (row == null) {
      throw const PaymentFailure('order_not_found');
    }
    final total = switch (row['total_amount']) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s) ?? 0,
      _ => 0.0,
    };
    if (total <= 0) {
      throw const PaymentFailure('invalid_order_amount');
    }
    final amountCents = (total * 100).round();
    final shortId =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    // Mark pending Visa while the customer pays.
    try {
      await _client.from('orders').update({
        'payment_status': 'pending',
        'payment_method': 'visa',
      }).eq('id', orderId);
    } catch (e, st) {
      // RLS may block this update; payment still proceeds and mark_order_paid_visa settles.
      debugPrint('Could not set order pending before Paymob: $e\n$st');
    }

    // Paymob rejects retries with the same merchant_order_id (HTTP 422
    // "duplicate"). Append a timestamp so each attempt is unique while
    // [orderId] still identifies the grocery order for settlement.
    final merchantOrderId =
        '${orderId}_${DateTime.now().millisecondsSinceEpoch}';

    return _startPaymobCheckout(
      amountCents: amountCents,
      itemName: 'Safeer Market Order $shortId',
      merchantOrderId: merchantOrderId,
      method: method,
      walletPhone: walletPhone,
      orderId: orderId,
    );
  }

  Future<PaymobCheckout> _startPaymobCheckout({
    required int amountCents,
    required String itemName,
    required String merchantOrderId,
    required PaymobMethod method,
    String? walletPhone,
    PaidTier? tier,
    String? orderId,
  }) async {
    _requirePaymobConfig(method);

    final base = _credentials.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final profile = await _billingProfile();
    final phone = _requirePhone(
      walletPhone?.trim().isNotEmpty == true ? walletPhone : profile.phone,
    );

    try {
      // 1) Authentication
      final authJson = await _postJson('$base/api/auth/tokens', {
        'api_key': _credentials.apiKey,
      });
      final authToken = authJson['token']?.toString();
      if (authToken == null || authToken.isEmpty) {
        throw PaymentFailure(
          'Paymob auth returned no token: ${_bodyText(authJson)}',
        );
      }

      // 2) Order registration
      final orderJson = await _postJson('$base/api/ecommerce/orders', {
        'auth_token': authToken,
        'delivery_needed': false,
        'amount_cents': amountCents,
        'currency': 'EGP',
        'merchant_order_id': merchantOrderId,
        'items': [
          {
            'name': itemName,
            'amount_cents': amountCents,
            'quantity': 1,
            'description': itemName,
          },
        ],
      });
      final paymobOrderId = orderJson['id'];
      if (paymobOrderId == null) {
        throw PaymentFailure(
          'Paymob order returned no id: ${_bodyText(orderJson)}',
        );
      }

      // 3) Payment key — every billing field must be non-empty for Paymob.
      final integrationId = int.tryParse(_credentials.integrationId) ?? 0;
      final keyJson = await _postJson('$base/api/acceptance/payment_keys', {
        'auth_token': authToken,
        'amount_cents': amountCents,
        'expiration': _paymentKeyLifetime,
        'order_id': paymobOrderId,
        'currency': 'EGP',
        'integration_id': integrationId,
        'lock_order_when_paid': true,
        'redirection_url':
            '${_credentials.redirectUrl}?transaction_id=${Uri.encodeQueryComponent(merchantOrderId)}',
        'billing_data': {
          'first_name': _requireField(profile.firstName, 'Safeer'),
          'last_name': _requireField(profile.lastName, 'Customer'),
          'email': _requireField(profile.email, 'customer@safeermarket.app'),
          'phone_number': phone,
          'apartment': 'NA',
          'floor': 'NA',
          'street': 'NA',
          'building': 'NA',
          'shipping_method': 'NA',
          'postal_code': 'NA',
          'city': 'Cairo',
          'country': 'EG',
          'state': 'NA',
        },
      });
      final paymentToken = keyJson['token']?.toString();
      if (paymentToken == null || paymentToken.isEmpty) {
        throw PaymentFailure(
          'Paymob payment key missing: ${_bodyText(keyJson)}',
        );
      }

      if (method == PaymobMethod.card) {
        // Always open the Accept iframe WebView so checkout never fails
        // silently when direct CARD/Moto pay is unavailable.
        final paymentUrl = Uri.parse(
          '$base/api/acceptance/iframes/${_credentials.iframeId}'
          '?payment_token=${Uri.encodeQueryComponent(paymentToken)}',
        );
        return PaymobCheckout(
          transactionId: merchantOrderId,
          paymentUrl: paymentUrl,
          tier: tier,
          orderId: orderId,
          authToken: authToken,
          paymobOrderId: '$paymobOrderId',
        );
      }

      final payJson = await _postJson('$base/api/acceptance/payments/pay', {
        'source': {'identifier': phone, 'subtype': 'WALLET'},
        'payment_token': paymentToken,
      });
      final redirect = payJson['redirect_url']?.toString() ??
          payJson['iframe_redirection_url']?.toString() ??
          payJson['redirection_url']?.toString();
      final parsed = redirect == null ? null : Uri.tryParse(redirect);
      if (parsed == null || !parsed.hasScheme) {
        throw PaymentFailure(
          'Paymob wallet pay had no redirect: ${_bodyText(payJson)}',
        );
      }
      return PaymobCheckout(
        transactionId: merchantOrderId,
        paymentUrl: parsed,
        tier: tier,
        orderId: orderId,
        authToken: authToken,
        paymobOrderId: '$paymobOrderId',
      );
    } on PaymentFailure {
      rethrow;
    } catch (error, stack) {
      debugPrint('Paymob checkout failed: $error');
      debugPrintStack(stackTrace: stack);
      throw PaymentFailure('$error');
    }
  }

  /// Asks Paymob whether [merchantOrderId] was paid (client-side inquiry).
  Future<PaymentStatus> fetchPaymentStatus(String transactionId) async {
    try {
      _requireApiKey();
      final base = _credentials.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final authJson = await _postJson('$base/api/auth/tokens', {
        'api_key': _credentials.apiKey,
      });
      final authToken = authJson['token']?.toString();
      if (authToken == null || authToken.isEmpty) {
        return PaymentStatus.pending;
      }

      final inquiry = await _postJson(
        '$base/api/ecommerce/orders/transaction_inquiry',
        {
          'auth_token': authToken,
          'merchant_order_id': transactionId,
        },
      );

      // Paymob shapes vary: top-level success, or nested transactions.
      if (inquiry['success'] == true ||
          inquiry['success'] == 'true' ||
          inquiry['paid'] == true) {
        return PaymentStatus.success;
      }
      final txs = inquiry['transactions'];
      if (txs is List) {
        for (final tx in txs) {
          if (tx is Map &&
              (tx['success'] == true || tx['success'] == 'true')) {
            return PaymentStatus.success;
          }
        }
        if (txs.isNotEmpty) {
          final last = txs.last;
          if (last is Map &&
              (last['pending'] == true || last['pending'] == 'true')) {
            return PaymentStatus.pending;
          }
          if (last is Map &&
              (last['success'] == false || last['success'] == 'false')) {
            return PaymentStatus.failed;
          }
        }
      }
      return PaymentStatus.pending;
    } catch (e, st) {
      debugPrint('Paymob inquiry failed for $transactionId: $e\n$st');
      // Fall back to local payment_transactions if present (legacy webhook).
      try {
        final row = await _client
            .from('payment_transactions')
            .select('status')
            .eq('id', transactionId)
            .maybeSingle();
        if (row != null) {
          return PaymentStatus.fromValue(row['status']);
        }
      } catch (_) {}
      return PaymentStatus.pending;
    }
  }

  /// Marks a grocery order paid by Visa after a successful Paymob payment.
  Future<void> markOrderPaidVisa(String orderId) async {
    try {
      await _client.rpc('mark_order_paid_visa', params: {
        'p_order_id': orderId,
      });
      return;
    } catch (e, st) {
      debugPrint('mark_order_paid_visa RPC failed, trying update: $e\n$st');
    }
    try {
      await _client.from('orders').update({
        'payment_status': 'paid',
        'payment_method': 'visa',
        'status': 'preparing',
      }).eq('id', orderId);
    } catch (e, st) {
      debugPrint('Direct order paid update failed: $e\n$st');
      throw PaymentFailure('Could not mark order paid: $e');
    }
  }

  Future<Subscription> fetchSubscription(String userId) async {
    final row = await _client
        .from('profiles')
        .select('subscription_plan, subscription_expiry')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? Subscription.free : Subscription.fromJson(row);
  }

  static const _receiptsBucket = 'payment_receipts';

  /// Uploads an InstaPay transfer screenshot for a subscription upgrade.
  Future<String> uploadSubscriptionReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final path =
        '$userId/sub_${DateTime.now().millisecondsSinceEpoch}_$safeName';
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
      throw PaymentFailure(e.message);
    } catch (e) {
      throw PaymentFailure('Could not upload receipt: $e');
    }
  }

  /// Marks the signed-in user's subscription as pending admin verification.
  Future<void> submitInstaPaySubscription({
    required PaidTier tier,
    required String receiptUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const PaymentFailure('Please sign in first.');
    final receipt = receiptUrl.trim();
    if (receipt.isEmpty) {
      throw const PaymentFailure('A payment receipt is required.');
    }
    // Direct write to `profiles` (the table the admin pending list reads);
    // no RPC needed. subscription_plan/expiry are untouched, so customers
    // still can't self-activate (the protect trigger enforces that too).
    final values = {
      'subscription_status': 'pending_verification',
      'subscription_receipt_url': receipt,
      'pending_subscription_tier': tier.value,
    };
    try {
      final updated = await _client
          .from('profiles')
          .update(values)
          .eq('id', userId)
          .select('id');
      // Zero rows: the profile row doesn't exist yet.
      if (updated.isEmpty) {
        await _client.from('profiles').insert({'id': userId, ...values});
      }
    } on PostgrestException catch (e) {
      throw PaymentFailure(e.message);
    } catch (e) {
      throw PaymentFailure('Could not submit subscription: $e');
    }
  }

  Future<List<PendingSubscriptionRequest>> listPendingSubscriptions() async {
    try {
      final rows = await _client.rpc('list_pending_subscriptions');
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map<String, dynamic>)
            PendingSubscriptionRequest.fromJson(row)
          else if (row is Map)
            PendingSubscriptionRequest.fromJson(
              Map<String, dynamic>.from(row),
            ),
      ];
    } on PostgrestException catch (e) {
      throw PaymentFailure(e.message);
    } catch (e) {
      throw PaymentFailure('Could not load pending subscriptions: $e');
    }
  }

  Future<void> approveSubscriptionRequest(String userId) async {
    try {
      await _client.rpc('approve_subscription_request', params: {
        'p_user_id': userId,
      });
    } on PostgrestException catch (e) {
      throw PaymentFailure(e.message);
    } catch (e) {
      throw PaymentFailure('Could not approve subscription: $e');
    }
  }

  void _requirePaymobConfig(PaymobMethod method) {
    _requireApiKey();
    if (_credentials.integrationId.trim().isEmpty) {
      throw const PaymentFailure('Paymob integration id is missing');
    }
    if (method == PaymobMethod.card && _credentials.iframeId.trim().isEmpty) {
      throw const PaymentFailure('Paymob iframe id is missing');
    }
  }

  void _requireApiKey() {
    if (_credentials.apiKey.trim().isEmpty) {
      throw const PaymentFailure('Paymob API key is missing in PaymobConfig');
    }
  }

  /// Paymob rejects blank / "NA" phones — always send a real E.164 value.
  static const _fallbackPhone = '+201066208383';

  static String _requireField(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.toUpperCase() == 'NA') return fallback;
    return trimmed;
  }

  static String _requirePhone(String? value) {
    var phone = (value ?? '').trim();
    if (phone.isEmpty || phone.toUpperCase() == 'NA') return _fallbackPhone;
    if (phone.startsWith('01') && phone.length >= 10) {
      phone = '+20${phone.substring(1)}';
    } else if (phone.startsWith('201') && !phone.startsWith('+')) {
      phone = '+$phone';
    } else if (RegExp(r'^\d{10,11}$').hasMatch(phone)) {
      phone = '+20$phone';
    }
    if (!phone.startsWith('+')) phone = '+$phone';
    return phone.length >= 10 ? phone : _fallbackPhone;
  }

  Future<_BillingProfile> _billingProfile() async {
    final user = _client.auth.currentUser;
    String first = 'Safeer';
    String last = 'Customer';
    var phone = user?.phone ?? '';
    var email = user?.email ?? '';
    try {
      final id = user?.id;
      if (id != null) {
        final row = await _client
            .from('profiles')
            .select('full_name, phone')
            .eq('id', id)
            .maybeSingle();
        final full = row?['full_name']?.toString().trim() ?? '';
        if (full.isNotEmpty) {
          final parts = full.split(RegExp(r'\s+'));
          first = parts.first;
          last = parts.length > 1 ? parts.sublist(1).join(' ') : 'Customer';
        }
        final p = row?['phone']?.toString().trim();
        if (p != null && p.isNotEmpty) phone = p;
      }
    } catch (_) {}
    return _BillingProfile(
      firstName: first,
      lastName: last,
      email: email,
      phone: phone,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await _http.post(
      Uri.parse(url),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final raw = response.body;
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      json = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      throw PaymentFailure(
        'Paymob HTTP ${response.statusCode} non-JSON: $raw',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PaymentFailure(
        'Paymob HTTP ${response.statusCode}: ${_bodyText(json)}',
      );
    }
    return json;
  }
}

class _BillingProfile {
  const _BillingProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
}

String _bodyText(Object? body) => switch (body) {
      null => '<empty body>',
      final String text when text.isEmpty => '<empty body>',
      final String text => text,
      final Map<dynamic, dynamic> map => jsonEncode(map),
      final List<dynamic> list => jsonEncode(list),
      _ => '$body',
    };

class PaymentFailure implements Exception {
  const PaymentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
