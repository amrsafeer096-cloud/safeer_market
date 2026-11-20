import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/addresses/data/repositories/supabase_addresses_repository.dart';
import 'package:safeer_market/features/addresses/domain/entities/address.dart';
import 'package:safeer_market/features/addresses/domain/repositories/addresses_repository.dart';
import 'package:safeer_market/features/addresses/presentation/providers/addresses_providers.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/cart/domain/entities/cart_item.dart';
import 'package:safeer_market/features/cart/presentation/providers/cart_providers.dart';
import 'package:safeer_market/features/cart/presentation/screens/cart_screen.dart';
import 'package:safeer_market/features/checkout/domain/delivery_pricing.dart';
import 'package:safeer_market/features/checkout/domain/payment_method.dart';
import 'package:safeer_market/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:safeer_market/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/rewards/data/repositories/supabase_loyalty_repository.dart';
import 'package:safeer_market/features/subscriptions/domain/subscription.dart';
import 'package:safeer_market/features/subscriptions/presentation/providers/subscription_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _base = 'https://example.supabase.co';

/// Kilometres per degree of latitude for R = 6371 km.
const _kmPerDegree = 111.19492664455873;

/// 1.45 km from the store: the 2 km / 30 EGP bracket.
final _home = Address(
  id: 'addr-1',
  title: 'المنزل',
  area: 'مدينة نصر',
  street: 'شارع 9',
  building: '12',
  latitude: StoreLocation.latitude + 1.45 / _kmPerDegree,
  longitude: StoreLocation.longitude,
);

final _pro = Subscription(
  plan: SubscriptionPlan.pro,
  expiry: DateTime.now().add(const Duration(days: 30)),
);

class _FakeCheckoutRepository implements CheckoutRepository {
  double? deliveryFee;

  @override
  Future<String> placeOrder({
    required String userId,
    required List<CartItem> items,
    required String addressDetails,
    required String deliveryArea,
    required double deliveryFee,
    required PaymentMethod paymentMethod,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String paymentStatus = 'unpaid',
    String? paymentMethodOverride,
    String? receiptUrl,
  }) async {
    this.deliveryFee = deliveryFee;
    return 'order-1';
  }

  @override
  Future<String> uploadPaymentReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    return 'https://example.com/receipts/$fileName';
  }
}

ProviderContainer _checkoutContainer(Subscription subscription) {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider
        .overrideWithValue(FakeAuthRepository(user: testUser)),
    subscriptionProvider.overrideWith((ref) async => subscription),
    addressesProvider.overrideWith((ref) async => [_home]),
  ]);
  addTearDown(container.dispose);
  container.read(selectedAddressIdProvider.notifier).state = _home.id;
  return container;
}

void main() {
  test("a profile stored as 'vip' is on the Pro plan", () {
    expect(SubscriptionPlan.fromValue('vip'), SubscriptionPlan.pro);
    expect(SubscriptionPlan.fromValue(' PRO '), SubscriptionPlan.pro);
    expect(SubscriptionPlan.fromValue('prime'), SubscriptionPlan.prime);
    expect(SubscriptionPlan.fromValue(null), SubscriptionPlan.free);
  });

  group('cart upsell banner', () {
    Future<void> pumpBanner(
      WidgetTester tester,
      Future<Subscription> Function() plan,
    ) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [subscriptionProvider.overrideWith((ref) => plan())],
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
          home: const Scaffold(body: PremiumUpsellBanner()),
        ),
      ));
      await tester.pump();
    }

    const title = 'وفر رسوم التوصيل! 💡';

    testWidgets('shows for free users', (tester) async {
      await pumpBanner(tester, () async => Subscription.free);
      expect(find.text(title), findsOneWidget);
    });

    testWidgets('is hidden for Pro, VIP and Prime subscribers', (
      tester,
    ) async {
      for (final stored in ['pro', 'vip', 'prime']) {
        await pumpBanner(
          tester,
          () async => Subscription.fromJson({
            'subscription_plan': stored,
            'subscription_expiry':
                DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          }),
        );
        expect(find.text(title), findsNothing, reason: stored);
      }
    });

    testWidgets('a lapsed plan shows it again', (tester) async {
      await pumpBanner(
        tester,
        () async => Subscription(
          plan: SubscriptionPlan.pro,
          expiry: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      expect(find.text(title), findsOneWidget);
    });
  });

  group('delivery fee', () {
    test('subscribers pay nothing; the address still has to be in range', () {
      final free = DeliveryPricing.quote(
        latitude: _home.latitude,
        longitude: _home.longitude,
        freeDelivery: true,
      );
      expect(free, isA<DeliveryAvailable>().having((q) => q.fee, 'fee', 0));
      expect(
        DeliveryPricing.quote(
          latitude: StoreLocation.latitude + 20 / _kmPerDegree,
          longitude: StoreLocation.longitude,
          freeDelivery: true,
        ),
        isA<DeliveryOutOfRange>(),
      );
    });

    test('checkout shows 0 for a Pro user and the bracket fee otherwise',
        () async {
      for (final (subscription, fee) in [
        (_pro, 0.0),
        (Subscription.free, 30.0)
      ]) {
        final container = _checkoutContainer(subscription);
        await container.read(subscriptionProvider.future);
        await container.read(addressesProvider.future);
        container.read(cartProvider.notifier).add(
              const Product(id: 'p1', name: 'لبن', price: 50),
            );

        expect(
          container.read(deliveryQuoteProvider),
          isA<DeliveryAvailable>().having((q) => q.fee, 'fee', fee),
          reason: '${subscription.plan}',
        );
        expect(container.read(checkoutTotalProvider), 50 + fee);
      }
    });

    test('the order a Pro user places is charged no delivery fee', () async {
      final repository = _FakeCheckoutRepository();
      final container = ProviderContainer(overrides: [
        authRepositoryProvider
            .overrideWithValue(FakeAuthRepository(user: testUser)),
        subscriptionProvider.overrideWith((ref) async => _pro),
        checkoutRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).add(
            const Product(id: 'p1', name: 'لبن', price: 50),
          );

      final orderId = await container
          .read(checkoutControllerProvider.notifier)
          .placeOrder(_home, paymentMethod: PaymentMethod.cashOnDelivery);

      expect(orderId, 'order-1');
      expect(repository.deliveryFee, 0);
    });
  });

  test('loyalty points read null and text safely', () {
    expect(SupabaseLoyaltyRepository.pointsFrom(null), 0);
    expect(SupabaseLoyaltyRepository.pointsFrom(''), 0);
    expect(SupabaseLoyaltyRepository.pointsFrom('12'), 12);
    expect(SupabaseLoyaltyRepository.pointsFrom(7.0), 7);
    expect(SupabaseLoyaltyRepository.pointsFrom(null, fallback: 30), 30);
  });

  group('addresses repository', () {
    Future<
        ({
          SupabaseAddressesRepository repository,
          List<http.Request> requests,
        })> repositoryAnswering(
      http.Response Function(http.Request request, int call) answer,
    ) async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        _base,
        'anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return answer(request, requests.length);
        }),
      );
      await client.auth.setInitialSession(jsonEncode({
        'access_token': 'token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'refresh_token': 'refresh',
        'user': {
          'id': testUser.id,
          'aud': 'authenticated',
          'app_metadata': <String, Object>{},
          'user_metadata': <String, Object>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }));
      return (
        repository: SupabaseAddressesRepository(client),
        requests: requests,
      );
    }

    http.Response json(Object body, http.Request request, [int status = 200]) =>
        http.Response(jsonEncode(body), status,
            headers: {'content-type': 'application/json'}, request: request);

    const draft = AddressDraft(
      title: 'المنزل',
      area: 'مدينة نصر',
      street: 'شارع 9',
      building: '12',
      latitude: 30.05,
      longitude: 31.33,
    );
    final row = {
      'id': 'a1',
      'title': 'المنزل',
      'region': 'مدينة نصر',
      'street': 'شارع 9',
      'building': '12',
      'floor_apt': null,
      'notes': null,
      'latitude': '30.05',
      'longitude': 31.33,
    };

    test('a user without a profiles row gets one, then the address saves',
        () async {
      final (:repository, :requests) = await repositoryAnswering(
        (request, call) => switch (call) {
          1 => json({
              'code': '23503',
              'message': 'insert or update on table "addresses" violates '
                  'foreign key constraint "addresses_user_id_fkey"',
              'details': 'Key (user_id) is not present in table "profiles".',
            }, request, 409),
          2 => json([], request, 201),
          _ => json(row, request, 201),
        },
      );

      final address = await repository.addAddress(testUser.id, draft);

      expect(address.id, 'a1');
      expect(address.latitude, 30.05, reason: 'numeric may come as text');
      expect([
        for (final r in requests) r.url.path
      ], [
        '/rest/v1/addresses',
        '/rest/v1/profiles',
        '/rest/v1/addresses',
      ]);
      expect(jsonDecode(requests[1].body), {'id': testUser.id});
      expect((jsonDecode(requests.last.body) as Map).keys.toSet(), {
        'user_id',
        'title',
        'region',
        'street',
        'building',
        'floor_apt',
        'notes',
        'latitude',
        'longitude',
      });
    });

    test('a refused insert shows the exact Supabase error', () async {
      final (:repository, requests: _) = await repositoryAnswering(
        (request, call) => json({
          'code': '42501',
          'message': 'new row violates row-level security policy',
          'hint': 'check the insert policy',
        }, request, 403),
      );

      await expectLater(
        repository.addAddress(testUser.id, draft),
        throwsA(isA<AddressFailure>().having(
          (failure) => failure.message,
          'message',
          allOf(
            contains('new row violates row-level security policy'),
            contains('code 42501'),
            contains('hint: check the insert policy'),
          ),
        )),
      );
    });

    test('a pin update that changes no row says why', () async {
      final (:repository, requests: _) = await repositoryAnswering(
        (request, call) => json([], request),
      );

      await expectLater(
        repository.updateLocation('a1', latitude: 30.1, longitude: 31.2),
        throwsA(isA<AddressFailure>().having(
          (failure) => failure.message,
          'message',
          contains('0 rows updated for address a1'),
        )),
      );
    });
  });
}
