import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/auth/presentation/widgets/sign_in_prompt.dart';
import 'package:safeer_market/features/subscriptions/data/paymob_service.dart';
import 'package:safeer_market/features/subscriptions/domain/pending_subscription.dart';
import 'package:safeer_market/features/subscriptions/domain/subscription.dart';
import 'package:safeer_market/features/subscriptions/presentation/providers/subscription_providers.dart';
import 'package:safeer_market/features/subscriptions/presentation/screens/paywall_screen.dart';
import 'package:safeer_market/features/subscriptions/presentation/screens/subscription_success_screen.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _base = 'https://example.supabase.co';
const _paymobBase = 'https://accept.paymob.com';
const _paymentUrl =
    'https://accept.paymob.com/api/acceptance/iframes/1?payment_token=t';

const _testCredentials = PaymobCredentials(
  apiKey: 'test-api-key',
  integrationId: '6048858',
  iframeId: '1',
  baseUrl: _paymobBase,
);

PaymobService _serviceAnswering(
  http.Response Function(http.Request request) answer, {
  List<http.Request>? requests,
}) =>
    PaymobService(
      SupabaseClient(_base, 'anon-key'),
      credentials: _testCredentials,
      httpClient: MockClient((request) async {
        requests?.add(request);
        return answer(request);
      }),
    );

/// Mocks the 3 Paymob Accept steps (auth → order → payment key).
http.Response Function(http.Request request) _paymobHappyPath({
  String paymentToken = 't',
  int orderId = 99,
}) {
  return (request) {
    final path = request.url.path;
    if (path.endsWith('/api/auth/tokens')) {
      return _json({'token': 'auth-token'}, request);
    }
    if (path.endsWith('/api/ecommerce/orders')) {
      return _json({'id': orderId}, request);
    }
    if (path.endsWith('/api/acceptance/payment_keys')) {
      return _json({'token': paymentToken}, request);
    }
    if (path.endsWith('/api/acceptance/payments/pay')) {
      return _json({'redirect_url': _paymentUrl}, request);
    }
    if (path.endsWith('/api/ecommerce/orders/transaction_inquiry')) {
      return _json({'success': true}, request);
    }
    return _json({'error': 'unexpected ${request.url}'}, request, 404);
  };
}

http.Response _json(Object body, http.Request request, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );

class _FakePaymobService implements PaymobService {
  _FakePaymobService({
    this.statuses = const [PaymentStatus.success],
    this.checkoutError,
  });

  /// Answers to successive status checks; the last one repeats.
  final List<PaymentStatus> statuses;

  /// Thrown by [createCheckout] when set.
  final Object? checkoutError;
  final checkouts = <({PaidTier tier, PaymobMethod method})>[];
  var statusChecks = 0;
  final paidOrders = <String>[];

  @override
  Future<PaymobCheckout> createCheckout({
    required PaidTier tier,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) async {
    checkouts.add((tier: tier, method: method));
    if (checkoutError case final error?) throw error;
    return PaymobCheckout(
      transactionId: 'tx-1',
      paymentUrl: Uri.parse(_paymentUrl),
      tier: tier,
    );
  }

  @override
  Future<PaymobCheckout> createOrderCheckout({
    required String orderId,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) async {
    if (checkoutError case final error?) throw error;
    return PaymobCheckout(
      transactionId: orderId,
      paymentUrl: Uri.parse(_paymentUrl),
      orderId: orderId,
    );
  }

  @override
  Future<void> markOrderPaidVisa(String orderId) async {
    paidOrders.add(orderId);
  }

  @override
  Future<PaymentStatus> fetchPaymentStatus(String transactionId) async =>
      statuses[(statusChecks++).clamp(0, statuses.length - 1)];

  @override
  Future<Subscription> fetchSubscription(String userId) async => Subscription(
        plan: SubscriptionPlan.pro,
        expiry: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<String> uploadSubscriptionReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async =>
      'https://example.com/receipt.png';

  @override
  Future<void> submitInstaPaySubscription({
    required PaidTier tier,
    required String receiptUrl,
  }) async {}

  @override
  Future<List<PendingSubscriptionRequest>> listPendingSubscriptions() async =>
      const [];

  @override
  Future<void> approveSubscriptionRequest(String userId) async {}
}

class _FakePaymentPage implements PaymentPage {
  final opened = <Uri>[];
  var closed = 0;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }

  @override
  Future<void> close() async => closed++;
}

Future<
    ({
      _FakePaymobService service,
      _FakePaymentPage page,
      StreamController<Uri> links,
    })> _pumpPaywall(
  WidgetTester tester, {
  bool signedIn = true,
  List<PaymentStatus> statuses = const [PaymentStatus.success],
  Object? checkoutError,
}) async {
  final service =
      _FakePaymobService(statuses: statuses, checkoutError: checkoutError);
  final page = _FakePaymentPage();
  final links = StreamController<Uri>.broadcast();
  addTearDown(links.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(user: signedIn ? testUser : null),
        ),
        paymobServiceProvider.overrideWithValue(service),
        paymentPageProvider.overrideWithValue(page),
        paymentReturnLinksProvider.overrideWith((ref) => links.stream),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const PaywallScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (service: service, page: page, links: links);
}

Future<void> _payByCard(WidgetTester tester, PaidTier tier) async {
  final button = find.byKey(Key('subscribe-${tier.value}'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('payment-method-card')));
  await tester.pumpAndSettle();
}

Uri _returnLink(String status) => Uri.parse(
      'io.supabase.safeermarket://$paymentReturnHost'
      '?transaction_id=tx-1&status=$status',
    );

void main() {
  group('PaymobService', () {
    test('runs auth → order → payment key and returns the iframe URL',
        () async {
      final requests = <http.Request>[];
      final service = _serviceAnswering(
        _paymobHappyPath(),
        requests: requests,
      );

      final checkout = await service.createCheckout(
        tier: PaidTier.vip,
        method: PaymobMethod.card,
      );

      expect(checkout.tier, PaidTier.vip);
      expect(checkout.paymentUrl, isNotNull);
      expect(checkout.paymentUrl!.scheme, 'https');
      expect(checkout.paymentUrl!.path, contains('/api/acceptance/iframes/1'));
      expect(checkout.paymentUrl!.queryParameters['payment_token'], 't');
      expect(checkout.transactionId, startsWith('sub_vip_'));
      expect(
        requests.map((r) => r.url.path).toList(),
        [
          '/api/auth/tokens',
          '/api/ecommerce/orders',
          '/api/acceptance/payment_keys',
        ],
      );
      expect(jsonDecode(requests.first.body)['api_key'], 'test-api-key');
    });

    test('wallet checkout hits payments/pay after the payment key', () async {
      final requests = <http.Request>[];
      final service = _serviceAnswering(
        _paymobHappyPath(),
        requests: requests,
      );

      final checkout = await service.createCheckout(
        tier: PaidTier.prime,
        method: PaymobMethod.wallet,
        walletPhone: '01012345678',
      );

      expect(checkout.paymentUrl, Uri.parse(_paymentUrl));
      expect(
        requests.map((r) => r.url.path).last,
        '/api/acceptance/payments/pay',
      );
    });

    test('a Paymob HTTP error becomes PaymentFailure', () async {
      final service = _serviceAnswering(
        (request) => _json(
          {'detail': 'Integration not found'},
          request,
          404,
        ),
      );

      await expectLater(
        service.createCheckout(tier: PaidTier.vip),
        throwsA(isA<PaymentFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Paymob HTTP 404'),
        )),
      );
    });

    test('a request that never gets an answer says so', () async {
      final service = PaymobService(
        SupabaseClient(_base, 'anon-key'),
        credentials: _testCredentials,
        httpClient: MockClient(
          (request) async => throw http.ClientException('XMLHttpRequest error.'),
        ),
      );

      await expectLater(
        service.createCheckout(tier: PaidTier.vip),
        throwsA(isA<PaymentFailure>().having(
          (failure) => failure.message,
          'message',
          contains('XMLHttpRequest error.'),
        )),
      );
    });

    test('missing API key fails before any network call', () async {
      final service = PaymobService(
        SupabaseClient(_base, 'anon-key'),
        credentials: const PaymobCredentials(
          apiKey: '',
          integrationId: '1',
          iframeId: '1',
        ),
        httpClient: MockClient((request) async {
          fail('should not call Paymob without an API key');
        }),
      );

      await expectLater(
        service.createCheckout(tier: PaidTier.vip),
        throwsA(isA<PaymentFailure>().having(
          (failure) => failure.message,
          'message',
          contains('PAYMOB_API_KEY'),
        )),
      );
    });

    test('inquires Paymob for payment status', () async {
      final service = _serviceAnswering(_paymobHappyPath());
      expect(await service.fetchPaymentStatus('tx-1'), PaymentStatus.success);
    });
  });

  test('VIP is bought as the stored pro plan', () {
    expect(PaidTier.vip.plan, SubscriptionPlan.pro);
    expect(PaidTier.prime.plan, SubscriptionPlan.prime);
    expect(PaymentStatus.fromValue('failed'), PaymentStatus.failed);
    expect(PaymentStatus.fromValue(null), PaymentStatus.pending);
  });

  group('paywall', () {
    testWidgets('a paid return opens the activation screen', (tester) async {
      final (:service, :page, :links) = await _pumpPaywall(tester);

      await _payByCard(tester, PaidTier.vip);
      expect(service.checkouts.single,
          (tier: PaidTier.vip, method: PaymobMethod.card));
      expect(page.opened.single, Uri.parse(_paymentUrl));

      links.add(_returnLink('success'));
      await tester.pumpAndSettle();

      expect(page.closed, 1, reason: 'the iOS Safari sheet is dismissed');
      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
      expect(find.text('تم تفعيل الاشتراك بنجاح 👑'), findsOneWidget);
      expect(find.textContaining('سفير برو (VIP)'), findsOneWidget);
    });

    testWidgets('waits for the webhook when the return arrives first', (
      tester,
    ) async {
      final (:service, page: _, :links) = await _pumpPaywall(
        tester,
        statuses: const [PaymentStatus.pending, PaymentStatus.success],
      );

      await _payByCard(tester, PaidTier.prime);
      links.add(_returnLink('pending'));
      await tester.pump();
      await tester.pump();
      expect(find.text('جارٍ التحقق من الدفع…'), findsOneWidget);

      await tester.pump(PaywallScreen.confirmPollInterval);
      await tester.pumpAndSettle();
      expect(service.statusChecks, 2);
      expect(find.byType(SubscriptionSuccessScreen), findsOneWidget);
    });

    testWidgets('a failed payment says so and stays on the paywall', (
      tester,
    ) async {
      final (service: _, page: _, :links) = await _pumpPaywall(
        tester,
        statuses: const [PaymentStatus.failed],
      );

      await _payByCard(tester, PaidTier.vip);
      links.add(_returnLink('failed'));
      await tester.pumpAndSettle();

      expect(find.byType(SubscriptionSuccessScreen), findsNothing);
      expect(find.text('لم تكتمل عملية الدفع. يمكنك المحاولة مرة أخرى.'),
          findsOneWidget);
    });

    testWidgets('a failed start shows the raw error, not a generic message', (
      tester,
    ) async {
      const raw = 'FunctionsHttpException HTTP 401 Unauthorized: '
          '{"error":"not_signed_in","detail":"JWT rejected: invalid JWT"}';
      final (service: _, :page, links: _) = await _pumpPaywall(
        tester,
        checkoutError: const PaymentFailure(raw),
      );

      await _payByCard(tester, PaidTier.vip);

      expect(find.text(raw), findsOneWidget);
      expect(find.text('تعذّر بدء الدفع، حاول مرة أخرى'), findsNothing);
      expect(page.opened, isEmpty);
    });

    testWidgets('guests are asked to sign in before paying', (tester) async {
      final (:service, :page, links: _) =
          await _pumpPaywall(tester, signedIn: false);

      final button = find.byKey(const Key('subscribe-vip'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(SignInPromptSheet), findsOneWidget);
      expect(find.text('سجّل دخولك للاشتراك في باقات سفير'), findsOneWidget);
      expect(service.checkouts, isEmpty);
      expect(page.opened, isEmpty);
    });
  });
}
