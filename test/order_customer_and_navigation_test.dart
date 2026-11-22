import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/core/routing/app_routes.dart';
import 'package:safeer_market/core/theme/app_theme.dart';
import 'package:safeer_market/features/addresses/data/services/google_places_search_service.dart';
import 'package:safeer_market/features/addresses/domain/services/location_service.dart';
import 'package:safeer_market/features/addresses/domain/services/place_search_service.dart';
import 'package:safeer_market/features/addresses/presentation/providers/addresses_providers.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/center_pin_map.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/location_picker_scaffold.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/place_search_bar.dart';
import 'package:safeer_market/features/admin/data/repositories/supabase_admin_orders_repository.dart';
import 'package:safeer_market/features/admin/domain/entities/admin_order.dart';
import 'package:safeer_market/features/admin/domain/staff_session.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'test_helpers.dart';
import 'package:safeer_market/features/driver/domain/entities/driver_order.dart';
import 'package:safeer_market/features/driver/presentation/screens/driver_dashboard_screen.dart';
import 'package:safeer_market/features/driver/presentation/screens/order_map_screen.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/subscriptions/domain/subscription.dart';
import 'package:safeer_market/features/subscriptions/presentation/providers/subscription_providers.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

const _customerId = '6f1c2a9e-3b7d-4e21-9a55-0c8d7e6f5a41';
const _lat = 30.0561;
const _lng = 31.3301;

Widget _app(List<Override> overrides, Widget home) => ProviderScope(
      overrides: overrides,
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
        home: home,
      ),
    );

class _FakePlaces implements PlaceSearchService {
  final queries = <String>[];

  @override
  Future<List<PlaceSuggestion>> suggest(String query, {LatLng? near}) async {
    queries.add(query);
    return const [
      PlaceSuggestion(
        id: 'p1',
        title: 'شارع عباس العقاد',
        subtitle: 'مدينة نصر، القاهرة',
      ),
    ];
  }

  @override
  Future<LatLng> locate(PlaceSuggestion suggestion) async =>
      const LatLng(_lat, _lng);
}

void main() {
  group('admin order details', () {
    Future<List<Uri>> pumpWithOrder(
      WidgetTester tester,
      Map<String, dynamic> order,
    ) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final launched = <Uri>[];
      await tester.pumpWidget(_app([
        overrideStaffSession(),
        userRoleProvider.overrideWith((ref) async => UserRole.admin),
        liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier([order])),
        adminOrdersRepositoryProvider.overrideWithValue(
          FakeAdminOrdersRepository(customers: {
            _customerId: const OrderCustomer(
              fullName: 'منى حسن',
              phone: '01098765432',
            ),
          }),
        ),
        externalUrlLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ], const UnifiedDashboardScreen()));
      await tester.pumpAndSettle();
      // Admins land on «تلقي الطلبات»; the orders live under «حالة الطلب».
      await tester.tap(find.byKey(const Key('admin-tab-1')));
      await tester.pumpAndSettle();
      return launched;
    }

    final order = <String, dynamic>{
      'id': 'a1b2c3d4-0000-0000-0000-000000000000',
      'user_id': _customerId,
      'status': 'delivered',
      'total_amount': 165,
      'created_at': '2026-11-11T10:00:00Z',
      'address_details': 'المنزل: شارع مكرم عبيد، عمارة 7 - مدينة نصر',
      'delivery_latitude': _lat,
      'delivery_longitude': _lng,
    };

    testWidgets('shows the customer from profiles, not the fallbacks', (
      tester,
    ) async {
      await pumpWithOrder(tester, order);
      expect(find.text('منى حسن'), findsOneWidget, reason: 'order card');

      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(find.text('منى حسن'), findsNWidgets(2));
      expect(find.text('01098765432'), findsOneWidget);
      expect(find.text('بدون اسم'), findsNothing);
      expect(find.text('بدون رقم'), findsNothing);
    });

    testWidgets('a name stored on the order wins over the profile', (
      tester,
    ) async {
      await pumpWithOrder(tester, {
        ...order,
        'customer_name': 'منى (تليفون)',
        'customer_phone': '01111111111',
      });
      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(find.text('منى (تليفون)'), findsNWidgets(2));
      expect(find.text('01111111111'), findsOneWidget);
    });

    testWidgets('«التوجه عبر الخريطة» opens directions to the pin', (
      tester,
    ) async {
      final launched = await pumpWithOrder(tester, order);
      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(find.text(order['address_details'] as String), findsOneWidget);
      await tester.tap(find.byKey(const Key('order-navigate')));
      await tester.pump();

      expect(launched, [
        Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng'),
      ]);
    });

    testWidgets('without a GPS pin the navigate button is hidden', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final launched = <Uri>[];
      await tester.pumpWidget(_app([
        overrideStaffSession(const StaffSession(
          id: 'staff-driver-1',
          name: 'طيار الاختبار',
          role: 'driver',
          username: 'driver',
        )),
        userRoleProvider.overrideWith((ref) async => UserRole.driver),
        liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier([
              {
                ...order,
                'status': 'outForDelivery',
                'delivery_latitude': null,
                'delivery_longitude': null,
              },
            ])),
        adminOrdersRepositoryProvider
            .overrideWithValue(FakeAdminOrdersRepository()),
        externalUrlLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ], const UnifiedDashboardScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#a1b2c3'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order-navigate')), findsNothing);
      expect(find.text(order['address_details'] as String), findsOneWidget);
      expect(launched, isEmpty);
      expect(find.byType(OrderMapScreen), findsNothing);
    });

    test('profiles are read in one query for every customer', () async {
      final requests = <http.Request>[];
      final repository = SupabaseAdminOrdersRepository(SupabaseClient(
        'https://example.supabase.co',
        'anon-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {'id': 'u1', 'full_name': 'منى', 'phone': '0101'},
              {'id': 'u2', 'full_name': ' ', 'phone': null},
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      ));

      final customers = await repository.fetchCustomers(['u1', 'u2', 'u1']);

      expect(requests.single.url.path, '/rest/v1/profiles');
      expect(requests.single.url.queryParameters['id'], 'in.("u1","u2")');
      expect(customers['u1']?.fullName, 'منى');
      expect(customers['u2']?.fullName, isNull);
      expect(await repository.fetchCustomers(const []), isEmpty);
      expect(requests, hasLength(1));
    });
  });

  group('driver order card', () {
    Future<List<Uri>> openDriverDashboard(
      WidgetTester tester,
      DriverOrder order,
    ) async {
      final launched = <Uri>[];
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        profileRepository: FakeProfileRepository(
          const UserProfile(id: 'user-1', fullName: 'كريم السائق'),
          UserRole.driver,
        ),
        driverOrdersRepository: FakeDriverOrdersRepository(available: [order]),
        overrides: [
          liveOrdersProvider.overrideWith(() => FixedLiveOrdersNotifier(const <Map<String, dynamic>>[]),
          ),
          externalUrlLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
            return true;
          }),
        ],
      );
      await skipSplash(tester);
      // Drivers sign in to the unified dashboard; this is their own screen.
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go(AppRoutes.driver);
      await tester.pumpAndSettle();
      expect(find.byType(DriverDashboardScreen), findsOneWidget);
      return launched;
    }

    final withPin = DriverOrder(
      id: 'f00dcafe-1111-2222-3333-444455556666',
      createdAt: DateTime(2026, 11, 11, 18, 30),
      status: 'readyForDelivery',
      totalAmount: 165,
      deliveryFee: 35,
      customerName: 'منى حسن',
      addressDetails: 'المنزل: شارع مكرم عبيد، عمارة 7 - مدينة نصر',
      latitude: StoreLocation.latitude + 0.02,
      longitude: StoreLocation.longitude,
    );

    testWidgets('shows the full address and navigates to the pin', (
      tester,
    ) async {
      final launched = await openDriverDashboard(tester, withPin);

      expect(
        tester
            .widget<SelectableText>(
                find.byKey(Key('driver-address-${withPin.id}')))
            .data,
        withPin.addressDetails,
      );
      await tester.tap(find.byKey(Key('driver-navigate-${withPin.id}')));
      await tester.pump();

      expect(launched, [
        Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${withPin.latitude},${withPin.longitude}'),
      ]);
    });

    testWidgets('an order without a pin hides the navigate button', (
      tester,
    ) async {
      final noPin = DriverOrder(
        id: withPin.id,
        createdAt: withPin.createdAt,
        status: withPin.status,
        totalAmount: withPin.totalAmount,
        deliveryFee: withPin.deliveryFee,
        addressDetails: 'شارع مكرم عبيد، مدينة نصر',
      );
      final launched = await openDriverDashboard(tester, noPin);

      expect(find.byKey(Key('driver-navigate-${noPin.id}')), findsNothing);
      expect(find.text('شارع مكرم عبيد، مدينة نصر'), findsOneWidget);
      expect(launched, isEmpty);
    });
  });

  group('address map search', () {
    testWidgets('picking a suggestion moves the map and pin there', (
      tester,
    ) async {
      final places = _FakePlaces();
      PickedLocation? confirmed;
      await tester.pumpWidget(_app(
          [
            placeSearchServiceProvider.overrideWithValue(places),
            locationServiceProvider.overrideWithValue(FakeLocationService()),
            subscriptionProvider.overrideWith((ref) async => Subscription.free),
            centerPinMapBuilderProvider.overrideWithValue(
              (config) => FakeCenterPinMap(config: config),
            ),
          ],
          LocationPickerScaffold(
            title: 'حدد الموقع',
            onConfirm: (picked) async => confirmed = picked,
          )));
      await tester.pumpAndSettle();

      expect(find.text('ابحث عن منطقة أو شارع...'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('map-search-field')), 'عباس العقاد');
      await tester.pump(PlaceSearchBar.debounce);
      await tester.pumpAndSettle();
      expect(places.queries, ['عباس العقاد']);
      expect(find.text('مدينة نصر، القاهرة'), findsOneWidget);

      await tester.tap(find.byKey(const Key('map-search-result-0')));
      await tester.pumpAndSettle();

      expect(centerPinMap(tester).moves, [const LatLng(_lat, _lng)]);
      expect(find.byKey(const Key('map-search-result-0')), findsNothing);

      await tester.tap(find.text('تأكيد الموقع'));
      await tester.pumpAndSettle();
      expect(confirmed?.point, const LatLng(_lat, _lng));
    });
  });

  group('GooglePlacesSearchService', () {
    test('autocompletes in Egypt near the map, then reads the location',
        () async {
      final requests = <http.Request>[];
      final service = GooglePlacesSearchService(
        apiKey: 'test-key',
        languageCode: 'ar',
        client: MockClient((request) async {
          requests.add(request);
          final body = request.url.path.endsWith(':autocomplete')
              ? {
                  'suggestions': [
                    {
                      'placePrediction': {
                        'placeId': 'ChIJ123',
                        'text': {'text': 'شارع عباس العقاد، مدينة نصر'},
                        'structuredFormat': {
                          'mainText': {'text': 'شارع عباس العقاد'},
                          'secondaryText': {'text': 'مدينة نصر'},
                        },
                      },
                    },
                    {'queryPrediction': {}},
                  ],
                }
              : {
                  'location': {'latitude': _lat, 'longitude': _lng},
                };
          return http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
              request: request);
        }),
      );

      final suggestions = await service.suggest(
        ' عباس ',
        near: const LatLng(30.05, 31.33),
      );
      expect(suggestions.single.id, 'ChIJ123');
      expect(suggestions.single.title, 'شارع عباس العقاد');
      expect(suggestions.single.subtitle, 'مدينة نصر');

      final autocomplete = requests.first;
      expect(autocomplete.method, 'POST');
      expect(autocomplete.url.toString(),
          'https://places.googleapis.com/v1/places:autocomplete');
      expect(autocomplete.headers['X-Goog-Api-Key'], 'test-key');
      final sent = jsonDecode(autocomplete.body) as Map;
      expect(sent['input'], 'عباس');
      expect(sent['languageCode'], 'ar');
      expect(sent['includedRegionCodes'], ['eg']);
      expect(sent['locationBias']['circle']['center'],
          {'latitude': 30.05, 'longitude': 31.33});

      final point = await service.locate(suggestions.single);
      expect(point, const LatLng(_lat, _lng));
      final details = requests.last;
      expect(details.url.path, '/v1/places/ChIJ123');
      expect(details.headers['X-Goog-FieldMask'], 'location');
      expect(details.url.queryParameters['sessionToken'], sent['sessionToken'],
          reason: 'one billing session per search');
    });

    test("Google's error message is passed on", () async {
      final service = GooglePlacesSearchService(
        apiKey: 'bad',
        languageCode: 'ar',
        client: MockClient((request) async => http.Response(
              jsonEncode({
                'error': {'message': 'API key not valid.'},
              }),
              400,
              request: request,
            )),
      );

      await expectLater(
        service.suggest('مدينة نصر'),
        throwsA(isA<PlaceSearchFailure>()
            .having((f) => f.message, 'message', 'API key not valid.')),
      );
    });
  });
}
