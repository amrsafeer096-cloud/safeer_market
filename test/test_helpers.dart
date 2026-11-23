import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, PlatformViewCreatedCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    show
        GoogleMapsFlutterPlatform,
        MapConfiguration,
        MapObjects,
        MapWidgetConfiguration;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safeer_market/app.dart';
import 'package:safeer_market/core/providers/settings_providers.dart';
import 'package:safeer_market/core/notifications/new_order_notifier.dart';
import 'package:safeer_market/core/notifications/push_notification_service.dart';
import 'package:safeer_market/features/driver/domain/entities/driver_order.dart';
import 'package:safeer_market/features/driver/domain/repositories/driver_orders_repository.dart';
import 'package:safeer_market/features/driver/domain/services/driver_location_service.dart';
import 'package:safeer_market/features/driver/presentation/providers/driver_providers.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/addresses/domain/services/location_service.dart';
import 'package:safeer_market/features/addresses/domain/entities/address.dart';
import 'package:safeer_market/features/addresses/domain/repositories/addresses_repository.dart';
import 'package:safeer_market/features/addresses/presentation/providers/addresses_providers.dart';
import 'package:safeer_market/features/addresses/presentation/widgets/center_pin_map.dart';
import 'package:safeer_market/features/warehouse/domain/entities/warehouse_order.dart';
import 'package:safeer_market/features/warehouse/domain/repositories/warehouse_orders_repository.dart';
import 'package:safeer_market/features/warehouse/presentation/providers/warehouse_providers.dart';
import 'package:safeer_market/features/admin/domain/entities/admin_order.dart';
import 'package:safeer_market/features/admin/domain/entities/order_status.dart';
import 'package:safeer_market/features/admin/domain/repositories/admin_orders_repository.dart';
import 'package:safeer_market/features/admin/domain/staff_session.dart';
import 'package:safeer_market/features/admin/presentation/providers/admin_providers.dart';
import 'package:safeer_market/features/admin/presentation/providers/staff_session_providers.dart';
import 'package:safeer_market/features/auth/domain/egyptian_phone.dart';
import 'package:safeer_market/features/auth/domain/entities/app_user.dart';
import 'package:safeer_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:safeer_market/features/auth/presentation/providers/auth_providers.dart';
import 'package:safeer_market/features/catalog/domain/category_filter.dart';
import 'package:safeer_market/features/catalog/domain/entities/category_page.dart';
import 'package:safeer_market/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:safeer_market/features/catalog/domain/similar_products_query.dart';
import 'package:safeer_market/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:safeer_market/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:safeer_market/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/providers/product_visibility_provider.dart';
import 'package:safeer_market/features/home/domain/entities/home_banner.dart';
import 'package:safeer_market/features/home/presentation/providers/home_banners_providers.dart';
import 'package:safeer_market/features/home/presentation/providers/products_providers.dart';
import 'package:safeer_market/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:safeer_market/features/notifications/domain/entities/app_notification.dart';
import 'package:safeer_market/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:safeer_market/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:safeer_market/features/orders/domain/entities/customer_order.dart';
import 'package:safeer_market/features/orders/domain/repositories/orders_repository.dart';
import 'package:safeer_market/features/orders/domain/services/delivery_route_service.dart';
import 'package:safeer_market/features/orders/presentation/providers/orders_providers.dart';
import 'package:safeer_market/features/profile/domain/entities/user_profile.dart';
import 'package:safeer_market/features/profile/domain/repositories/profile_repository.dart';
import 'package:safeer_market/features/profile/presentation/providers/profile_providers.dart';
import 'package:safeer_market/features/rewards/domain/repositories/loyalty_repository.dart';
import 'package:safeer_market/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:safeer_market/features/splash/presentation/screens/splash_screen.dart';
import 'package:safeer_market/features/subscriptions/data/paymob_service.dart';
import 'package:safeer_market/features/subscriptions/domain/pending_subscription.dart';
import 'package:safeer_market/features/subscriptions/domain/subscription.dart';
import 'package:safeer_market/features/subscriptions/presentation/providers/subscription_providers.dart';
import 'package:safeer_market/features/support/domain/entities/support_chat.dart';
import 'package:safeer_market/features/support/domain/repositories/support_repository.dart';
import 'package:safeer_market/features/support/presentation/providers/support_providers.dart';
import 'package:safeer_market/features/wallet/domain/entities/saved_card.dart';
import 'package:safeer_market/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:safeer_market/features/wallet/presentation/providers/wallet_providers.dart';

/// Raw `products.category` values under «ألبان وبيض» and «حلويات وتسالي».
const testDairy = 'جبن تترباك و مثلثات و كوب';
const testSweets = 'شيكولاتة';

const testUser = AppUser(id: 'user-1', email: 'amr@example.com');

/// Default staff session for widget tests that open [UnifiedDashboardScreen].
const testAdminStaffSession = StaffSession(
  id: 'staff-admin-1',
  name: 'مدير الاختبار',
  role: 'admin',
  username: 'admin',
  phone: '01000000000',
);

/// Skips the staff login gate with an admin (or custom) session.
Override overrideStaffSession([StaffSession session = testAdminStaffSession]) =>
    staffSessionProvider.overrideWith(
      (ref) => StaffSessionController(ref, initial: session),
    );

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AppUser? user,
    this.signUpResult = SignUpResult.signedIn,
    this.failure,
    this.googleUser,
  }) : _user = user;

  /// The SMS code [verifyPhoneOtp] accepts.
  static const validOtp = '123456';

  final SignUpResult signUpResult;
  final AuthFailure? failure;

  /// Who "Continue with Google" signs in; null acts as a dismissed picker.
  final AppUser? googleUser;

  /// E.164 numbers a code was texted to, in order.
  final codesSentTo = <String>[];
  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  Map<String, String>? lastSignUp;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  void _setUser(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (failure != null) throw failure!;
    _setUser(AppUser(id: 'user-1', email: email));
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    lastSignUp = {'fullName': fullName, 'email': email, 'phone': phone};
    if (signUpResult == SignUpResult.signedIn) {
      _setUser(AppUser(id: 'user-1', email: email));
    }
    return signUpResult;
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (failure != null) throw failure!;
    final user = googleUser;
    if (user == null) return false;
    _setUser(user);
    return true;
  }

  @override
  Future<void> signInWithPhone(String phone) async {
    if (failure != null) throw failure!;
    codesSentTo.add(phone);
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String token) async {
    if (token != validOtp) {
      throw const AuthFailure('الرمز غير صحيح أو انتهت صلاحيته');
    }
    _setUser(AppUser(id: 'phone-user', phone: EgyptianPhone.toLocal(phone)));
  }

  @override
  Future<void> signOut() async => _setUser(null);

  @override
  Future<void> deleteAccount() async => _setUser(null);
}

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    this.catalogProducts = const [],
    this.products = const [],
  });

  /// Products only reachable through the catalog (not on the home feed),
  /// like most of a 30k-item POS catalog.
  final List<Product> catalogProducts;
  final List<Product> products;
  final searches = <String>[];

  /// (categories, offset) of each category page request.
  final categoryRequests = <(List<String>, int)>[];

  Iterable<Product> get _all => {
        for (final product in [...products, ...catalogProducts])
          product.id: product,
      }.values;

  @override
  Future<CategoryPage> fetchCategoryProducts({
    required List<String> categories,
    required int offset,
    required int limit,
  }) async {
    categoryRequests.add((categories, offset));
    final matches = CategoryFilter.apply(_all, categories: categories)
      ..sort((a, b) => a.name.compareTo(b.name));
    return CategoryPage(
      products: matches.skip(offset).take(limit).toList(),
      total: matches.length,
    );
  }

  /// Returns every product so tests exercise the app's own matching in
  /// productSearchProvider rather than this fake's.
  @override
  Future<List<Product>> searchProducts(String query) async {
    searches.add(query);
    return _all.toList();
  }

  @override
  Future<Product?> fetchProductById(String id) async =>
      _all.where((p) => p.id == id).firstOrNull;

  /// Same order as the Supabase repository: sub-category, category, then
  /// the leading word of the name.
  @override
  Future<List<Product>> fetchSimilarProducts({
    required SimilarProductsQuery query,
    required int limit,
  }) async {
    final others = _all.where((p) => p.id != query.productId && p.inStock);
    final word = leadingWord(query.name);
    final similar = <String, Product>{
      if (query.categoryId != null && query.subCategory != null)
        for (final p in others)
          if (p.categoryId == query.categoryId &&
              p.subCategory == query.subCategory)
            p.id: p,
      for (final p in others)
        if (query.categoryId != null
            ? p.categoryId == query.categoryId
            : query.category != null && p.category == query.category)
          p.id: p,
      if (word != null)
        for (final p in others)
          if (p.name.startsWith(word)) p.id: p,
    };
    return similar.values.take(limit).toList();
  }
}

class FakeAdminOrdersRepository implements AdminOrdersRepository {
  FakeAdminOrdersRepository({
    List<AdminOrder> orders = const [],
    this.items = const {},
    this.customers = const {},
    this.failUpdates = false,
  }) : orders = [...orders];

  final List<AdminOrder> orders;
  final Map<String, List<AdminOrderItem>> items;
  final Map<String, OrderCustomer> customers;
  final bool failUpdates;
  final updates = <(String, OrderStatus)>[];
  final customerLookups = <Set<String>>[];

  @override
  Future<Map<String, OrderCustomer>> fetchCustomers(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.toSet();
    customerLookups.add(ids);
    return {
      for (final id in ids)
        if (customers[id] case final customer?) id: customer,
    };
  }

  @override
  Future<List<AdminOrder>> fetchAllOrders() async => [...orders];

  @override
  Future<AdminOrder?> fetchOrder(String orderId) async =>
      orders.where((o) => o.id == orderId).firstOrNull;

  @override
  Future<List<AdminOrderItem>> fetchOrderItems(String orderId) async =>
      items[orderId] ?? const [];

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    if (failUpdates) {
      throw const AdminFailure('لا تملك صلاحية تعديل هذا الطلب');
    }
    updates.add((orderId, status));
    final index = orders.indexWhere((o) => o.id == orderId);
    orders[index] = orders[index].copyWith(status: status.value);
  }
}

class FakeAddressesRepository implements AddressesRepository {
  FakeAddressesRepository([List<Address> addresses = const []])
      : addresses = [...addresses];

  final List<Address> addresses;
  var _nextId = 1;

  @override
  Future<List<Address>> fetchAddresses(String userId) async => [...addresses];

  @override
  Future<Address> addAddress(String userId, AddressDraft draft) async {
    final address = Address(
      id: 'new-${_nextId++}',
      title: draft.title,
      area: draft.area,
      street: draft.street,
      building: draft.building,
      floorApt: draft.floorApt,
      landmark: draft.landmark,
      latitude: draft.latitude,
      longitude: draft.longitude,
    );
    addresses.insert(0, address);
    return address;
  }

  @override
  Future<void> deleteAddress(String addressId) async =>
      addresses.removeWhere((a) => a.id == addressId);

  @override
  Future<void> updateLocation(
    String addressId, {
    required double latitude,
    required double longitude,
  }) async {
    final index = addresses.indexWhere((a) => a.id == addressId);
    addresses[index] = addresses[index].withLocation(
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository([this.balance = 0, List<SavedCard>? cards])
      : savedCards = List<SavedCard>.of(cards ?? const []);

  final double balance;
  final List<SavedCard> savedCards;
  String? requestedFor;

  @override
  Future<double> fetchBalance(String userId) async {
    requestedFor = userId;
    return balance;
  }

  @override
  Future<List<SavedCard>> fetchSavedCards(String userId) async {
    requestedFor = userId;
    return List<SavedCard>.of(savedCards);
  }

  @override
  Future<void> saveSavedCards(String userId, List<SavedCard> cards) async {
    requestedFor = userId;
    savedCards
      ..clear()
      ..addAll(cards);
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile, this.role = UserRole.customer]);

  UserProfile? profile;
  UserRole role;

  @override
  Future<UserProfile?> fetchProfile(String userId) async => profile;

  @override
  Future<UserRole> fetchRole(String userId) async => role;

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    profile = UserProfile(id: userId, fullName: fullName, phone: phone);
  }

  final signInSyncs =
      <({String userId, String? fullName, String? phone, String? avatarUrl})>[];

  @override
  Future<void> completeFromSignIn({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    signInSyncs.add(
      (userId: userId, fullName: fullName, phone: phone, avatarUrl: avatarUrl),
    );
    final current = profile;
    profile = UserProfile(
      id: userId,
      fullName: current?.fullName ?? fullName,
      phone: current?.phone ?? phone,
      avatarUrl: current?.avatarUrl ?? avatarUrl,
    );
  }

  final savedTokens = <({String userId, String token})>[];

  @override
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    savedTokens.add((userId: userId, token: token));
  }
}

class FakeLoyaltyRepository implements LoyaltyRepository {
  FakeLoyaltyRepository({this.points = 0, this.failure});

  int points;
  final LoyaltyFailure? failure;
  final added = <({String userId, int amount})>[];

  @override
  Future<int> fetchPoints(String userId) async {
    if (failure != null) throw failure!;
    return points;
  }

  @override
  Stream<int> watchPoints(String userId) async* {
    if (failure != null) throw failure!;
    yield points;
  }

  @override
  Future<int> addPoints({required String userId, required int amount}) async {
    if (failure != null) throw failure!;
    added.add((userId: userId, amount: amount));
    points += amount;
    return points;
  }
}

class FakePushNotificationService implements PushNotificationService {
  FakePushNotificationService({this.token});

  String? token;
  final refreshes = StreamController<String>.broadcast();

  @override
  bool get isSupported => token != null;

  @override
  Future<bool> initialize() async => isSupported;

  @override
  Future<String?> getToken() async => token;

  var deletedTokens = 0;

  @override
  Future<void> deleteToken() async {
    if (token != null) deletedTokens++;
  }

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  final messages = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get foregroundMessages => messages.stream;

  /// Latest subscription state per topic.
  final topics = <String, bool>{};

  @override
  Future<void> setTopicSubscription(
    String topic, {
    required bool subscribed,
  }) async {
    topics[topic] = subscribed;
  }
}

class FakeNewOrderNotifier implements NewOrderNotifier {
  final notifiedOrders = <String>[];

  @override
  Future<void> notifyDrivers(String orderId) async {
    notifiedOrders.add(orderId);
  }
}

class FakeDriverOrdersRepository implements DriverOrdersRepository {
  FakeDriverOrdersRepository({
    List<DriverOrder> available = const [],
    this.acceptFailure,
    this.locationFailure,
  }) : available = [...available];

  final List<DriverOrder> available;
  final mine = <DriverOrder>[];
  final DriverFailure? acceptFailure;
  final DriverFailure? locationFailure;
  final delivered = <String>[];
  final locationUpdates = <(String, double, double)>[];

  @override
  Future<List<DriverOrder>> fetchAvailableOrders() async => [...available];

  @override
  Future<List<DriverOrder>> fetchMyDeliveries() async => [...mine];

  @override
  Future<void> acceptOrder(String orderId) async {
    if (acceptFailure case final failure?) {
      available.removeWhere((order) => order.id == orderId);
      throw failure;
    }
    final order = available.firstWhere((order) => order.id == orderId);
    available.remove(order);
    mine.add(
      DriverOrder(
        id: order.id,
        createdAt: order.createdAt,
        status: 'out_for_delivery',
        totalAmount: order.totalAmount,
        deliveryFee: order.deliveryFee,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        addressDetails: order.addressDetails,
        latitude: order.latitude,
        longitude: order.longitude,
      ),
    );
  }

  @override
  Future<void> markDelivered(String orderId) async {
    mine.removeWhere((order) => order.id == orderId);
    delivered.add(orderId);
  }

  @override
  Future<void> updateDriverLocation(
    String orderId, {
    required double latitude,
    required double longitude,
  }) async {
    locationUpdates.add((orderId, latitude, longitude));
    if (locationFailure case final failure?) throw failure;
  }
}

class FakeDeliveryRouteService implements DeliveryRouteService {
  FakeDeliveryRouteService([this.points = const []]);

  final List<RoutePoint> points;
  final requests = <(RoutePoint, RoutePoint)>[];

  @override
  Future<List<RoutePoint>> route(
    RoutePoint origin,
    RoutePoint destination,
  ) async {
    requests.add((origin, destination));
    return points;
  }
}

class FakeDriverLocationService implements DriverLocationService {
  FakeDriverLocationService({this.failure});

  DriverLocationFailure? failure;
  final _positions = StreamController<DriverPosition>.broadcast();
  int permissionRequests = 0;

  /// Whether the GPS stream currently has a listener.
  bool get isStreaming => _positions.hasListener;

  void move(double latitude, double longitude) =>
      _positions.add((latitude: latitude, longitude: longitude));

  @override
  Future<void> ensurePermission() async {
    permissionRequests++;
    if (failure case final failure?) throw failure;
  }

  @override
  Stream<DriverPosition> positions() => _positions.stream;
}

class FakeOrdersRepository implements OrdersRepository {
  FakeOrdersRepository([
    List<CustomerOrder> orders = const [],
    this.items = const {},
  ]) : orders = [...orders];

  final List<CustomerOrder> orders;

  /// Products per order id.
  final Map<String, List<CustomerOrderItem>> items;

  /// Set before a cancel that should fail in a test.
  Exception? cancelFailure;
  String? requestedFor;
  final itemRequests = <String>[];
  final cancellations = <(String, OrderCancellationReason)>[];
  final _changes = StreamController<void>.broadcast();

  /// Live list for [customerOrdersStreamOverrideProvider].
  Stream<List<CustomerOrder>> get changes async* {
    yield [...orders];
    yield* _changes.stream.map((_) => [...orders]);
  }

  @override
  Future<List<CustomerOrder>> fetchOrders(String userId) async {
    requestedFor = userId;
    return [...orders];
  }

  @override
  Future<List<CustomerOrderItem>> fetchOrderItems(String orderId) async {
    itemRequests.add(orderId);
    return items[orderId] ?? const [];
  }

  @override
  Future<void> cancelOrder(
    String orderId,
    OrderCancellationReason reason,
  ) async {
    if (cancelFailure case final failure?) throw failure;
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0 || !orders[index].canCancel) {
      throw const OrdersFailure('orderCancelTooLate');
    }
    cancellations.add((orderId, reason));
    orders[index] = orders[index].copyWith(
      status: 'cancelled',
      cancellationReason: reason.value,
    );
    _changes.add(null);
  }

  final ratings = <({String orderId, int delivery, int product, String? comment})>[];

  @override
  Future<void> submitRating({
    required String orderId,
    required int deliveryRating,
    required int productRating,
    String? comment,
  }) async {
    ratings.add((
      orderId: orderId,
      delivery: deliveryRating,
      product: productRating,
      comment: comment,
    ));
  }
}

class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({
    this.catalog = const [],
    Set<String>? ids,
    this.fail = false,
  }) : ids = ids ?? {};

  final List<Product> catalog;
  final Set<String> ids;
  final bool fail;

  @override
  Future<Set<String>> fetchFavoriteIds(String userId) async => {...ids};

  @override
  Future<List<Product>> fetchFavoriteProducts(String userId) async =>
      catalog.where((product) => ids.contains(product.id)).toList();

  @override
  Future<void> addFavorite({
    required String userId,
    required String productId,
  }) async {
    if (fail) throw Exception('insert rejected');
    ids.add(productId);
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) async {
    if (fail) throw Exception('delete rejected');
    ids.remove(productId);
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService({
    this.position = const LatLng(30.0560, 31.3460),
    this.positionFailure,
    this.placemark = (area: 'مدينة نصر', street: 'شارع عباس العقاد'),
  });

  final LatLng position;
  final LocationFailure? positionFailure;

  /// Null makes reverse geocoding fail.
  final ({String area, String street})? placemark;

  final geocodedPoints = <LatLng>[];
  final openedSettings = <LocationFailureReason>[];

  @override
  Future<LatLng> currentPosition() async {
    if (positionFailure case final failure?) throw failure;
    return position;
  }

  @override
  Future<PickedLocation> reverseGeocode(LatLng point) async {
    geocodedPoints.add(point);
    final mark = placemark;
    if (mark == null) {
      throw const LocationFailure(
        LocationFailureReason.unavailable,
        'no address',
      );
    }
    return PickedLocation(point: point, area: mark.area, street: mark.street);
  }

  @override
  Future<bool> openSettingsFor(LocationFailure failure) async {
    openedSettings.add(failure.reason);
    return true;
  }
}

/// Stands in for the native Google map under the fixed center pin.
class FakeCenterPinMap extends StatefulWidget {
  const FakeCenterPinMap({super.key, required this.config});

  final CenterPinMapConfig config;

  @override
  State<FakeCenterPinMap> createState() => FakeCenterPinMapState();
}

class FakeCenterPinMapState extends State<FakeCenterPinMap>
    implements CenterPinMapController {
  late LatLng center = widget.config.initialCenter;

  /// Camera moves requested by the app (e.g. "my location").
  final moves = <LatLng>[];

  @override
  void initState() {
    super.initState();
    widget.config.onCreated(this);
  }

  @override
  Future<void> moveTo(LatLng point, {double zoom = 17}) async {
    moves.add(point);
    drag(point);
  }

  /// What a user dragging the map under the pin would do.
  void drag(LatLng to) {
    setState(() => center = to);
    widget.config.onCenterChanged(to);
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: Key('fake-center-pin-map'));
}

FakeCenterPinMapState centerPinMap(WidgetTester tester) =>
    tester.state<FakeCenterPinMapState>(find.byType(FakeCenterPinMap));

Future<void> dragMapTo(WidgetTester tester, LatLng point) async {
  centerPinMap(tester).drag(point);
  await tester.pump();
}

/// Renders every `GoogleMap` as a placeholder and records what it was given.
/// It never reports the platform view as created, so no controller (and no
/// method-channel traffic) is ever involved.
class FakeGoogleMapsPlatform extends GoogleMapsFlutterPlatform {
  MapWidgetConfiguration? lastWidgetConfiguration;
  MapObjects lastMapObjects = const MapObjects();

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    lastWidgetConfiguration = widgetConfiguration;
    lastMapObjects = mapObjects;
    return const SizedBox.expand(key: Key('fake-google-map'));
  }
}

/// Installs a [FakeGoogleMapsPlatform] for the current test.
FakeGoogleMapsPlatform useFakeGoogleMaps() {
  final previous = GoogleMapsFlutterPlatform.instance;
  final fake = FakeGoogleMapsPlatform();
  GoogleMapsFlutterPlatform.instance = fake;
  addTearDown(() => GoogleMapsFlutterPlatform.instance = previous);
  return fake;
}

class FakeWarehouseOrdersRepository implements WarehouseOrdersRepository {
  FakeWarehouseOrdersRepository({
    List<WarehouseOrder> orders = const [],
    this.failure,
  }) : orders = [...orders];

  final List<WarehouseOrder> orders;
  final WarehouseFailure? failure;
  final transitions = <(String, String)>[];
  final _changes = StreamController<void>.broadcast();

  /// Simulates a realtime event, e.g. a customer placing an order.
  void emitChange() => _changes.add(null);

  @override
  Future<List<WarehouseOrder>> fetchQueue() async =>
      orders.where((order) => order.isPending || order.isPreparing).toList();

  @override
  Future<void> startPreparing(String orderId) => _advance(orderId, 'preparing');

  @override
  Future<void> markReady(String orderId) =>
      _advance(orderId, 'ready_for_delivery');

  Future<void> _advance(String orderId, String status) async {
    if (failure case final failure?) throw failure;
    transitions.add((orderId, status));
    final index = orders.indexWhere((order) => order.id == orderId);
    final order = orders[index];
    orders[index] = WarehouseOrder(
      id: order.id,
      createdAt: order.createdAt,
      status: status,
      totalAmount: order.totalAmount,
      items: order.items,
      customerName: order.customerName,
      addressDetails: order.addressDetails,
    );
  }

  @override
  Stream<void> changes() => _changes.stream;
}

/// The profile's plan as [subscription], which a test may change the way
/// the payment webhook would; counts each read of it.
class FakePaymobService implements PaymobService {
  FakePaymobService({this.subscription = Subscription.free});

  Subscription subscription;
  var subscriptionReads = 0;

  /// An active Safeer Pro (VIP) plan.
  static Subscription get pro => Subscription(
        plan: SubscriptionPlan.pro,
        expiry: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<Subscription> fetchSubscription(String userId) async {
    subscriptionReads++;
    return subscription;
  }

  @override
  Future<PaymobCheckout> createCheckout({
    required PaidTier tier,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) =>
      throw UnimplementedError();

  @override
  Future<PaymobCheckout> createOrderCheckout({
    required String orderId,
    PaymobMethod method = PaymobMethod.card,
    String? walletPhone,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> markOrderPaidVisa(String orderId) async {}

  @override
  Future<String> uploadSubscriptionReceipt({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> submitInstaPaySubscription({
    required PaidTier tier,
    required String receiptUrl,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PendingSubscriptionRequest>> listPendingSubscriptions() async =>
      const [];

  @override
  Future<void> approveSubscriptionRequest(String userId) async {}

  @override
  Future<PaymentStatus> fetchPaymentStatus(String transactionId) async =>
      PaymentStatus.pending;
}

/// Support chats in memory; changes reach every live stream, like Supabase
/// Realtime, and messages update their chat the way the database trigger
/// does.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    List<SupportChat> chats = const [],
    Map<String, List<SupportMessage>> messages = const {},
  })  : chats = [...chats],
        messages = {
          for (final entry in messages.entries) entry.key: [...entry.value],
        };

  final List<SupportChat> chats;
  final Map<String, List<SupportMessage>> messages;
  final opened = <({String userId, String? name, String? phone})>[];
  final sent = <(String, String, SupportSenderRole)>[];
  final markedRead = <String>[];
  final markedDelivered = <String>[];
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  List<SupportChat> get _openChats =>
      chats.where((chat) => chat.isOpen).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<SupportMessage> _messagesOf(String chatId) =>
      List.unmodifiable(messages[chatId] ?? const <SupportMessage>[]);

  void _replace(
    String chatId, {
    String? lastMessage,
    int? unreadAdminCount,
    int? unreadCustomerCount,
    DateTime? updatedAt,
  }) {
    final index = chats.indexWhere((chat) => chat.id == chatId);
    final chat = chats[index];
    chats[index] = SupportChat(
      id: chat.id,
      userId: chat.userId,
      customerName: chat.customerName,
      customerPhone: chat.customerPhone,
      lastMessage: lastMessage ?? chat.lastMessage,
      unreadAdminCount: unreadAdminCount ?? chat.unreadAdminCount,
      unreadCustomerCount: unreadCustomerCount ?? chat.unreadCustomerCount,
      isOpen: chat.isOpen,
      updatedAt: updatedAt ?? chat.updatedAt,
    );
  }

  @override
  Future<SupportChat> openChat({
    required String userId,
    String? customerName,
    String? customerPhone,
  }) async {
    opened.add((userId: userId, name: customerName, phone: customerPhone));
    final existing = chats
        .where((chat) => chat.userId == userId && chat.isOpen)
        .firstOrNull;
    if (existing != null) return existing;
    final chat = SupportChat(
      id: 'chat-${_nextId++}',
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      updatedAt: DateTime.now(),
    );
    chats.add(chat);
    _changes.add(null);
    return chat;
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String chatId) async* {
    yield _messagesOf(chatId);
    yield* _changes.stream.map((_) => _messagesOf(chatId));
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required SupportSenderRole senderRole,
    SupportAttachmentType? attachmentType,
    String? attachmentUrl,
    String? orderId,
    int? voiceDuration,
  }) async {
    sent.add((chatId, message, senderRole));
    final now = DateTime.now();
    (messages[chatId] ??= []).add(SupportMessage(
      id: 'message-${_nextId++}',
      chatId: chatId,
      senderRole: senderRole,
      message: message,
      createdAt: now,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      orderId: orderId,
      voiceDuration: voiceDuration,
    ));
    final chat = chats.firstWhere((c) => c.id == chatId);
    final preview = attachmentType?.previewLabel ?? message;
    _replace(
      chatId,
      lastMessage: preview,
      updatedAt: now,
      unreadAdminCount: senderRole == SupportSenderRole.customer
          ? chat.unreadAdminCount + 1
          : chat.unreadAdminCount,
      unreadCustomerCount: senderRole == SupportSenderRole.admin
          ? chat.unreadCustomerCount + 1
          : chat.unreadCustomerCount,
    );
    _changes.add(null);
  }

  @override
  Future<String> uploadMedia({
    required String userId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async =>
      'https://example.test/support_media/$userId/$fileName';

  @override
  Stream<List<SupportChat>> watchOpenChats() async* {
    yield _openChats;
    yield* _changes.stream.map((_) => _openChats);
  }

  @override
  Stream<int> watchMyUnreadCount(String userId) async* {
    int unreadOf() {
      final chat = chats
          .where((c) => c.userId == userId && c.isOpen)
          .firstOrNull;
      return chat?.unreadCustomerCount ?? 0;
    }

    yield unreadOf();
    yield* _changes.stream.map((_) => unreadOf());
  }

  @override
  Future<void> markDelivered(
    String chatId,
    SupportSenderRole viewerRole,
  ) async {
    markedDelivered.add(chatId);
    final list = messages[chatId];
    if (list == null) return;
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i].senderRole == viewerRole) continue;
      if (list[i].status == SupportMessageStatus.sent) {
        changed = true;
        list[i] = SupportMessage(
          id: list[i].id,
          chatId: list[i].chatId,
          senderRole: list[i].senderRole,
          message: list[i].message,
          createdAt: list[i].createdAt,
          status: SupportMessageStatus.delivered,
          isRead: list[i].isRead,
          attachmentType: list[i].attachmentType,
          attachmentUrl: list[i].attachmentUrl,
          orderId: list[i].orderId,
          voiceDuration: list[i].voiceDuration,
        );
      }
    }
    if (changed) _changes.add(null);
  }

  @override
  Future<void> markChatRead(
    String chatId,
    SupportSenderRole viewerRole,
  ) async {
    markedRead.add(chatId);
    final list = messages[chatId];
    var changed = false;
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].senderRole == viewerRole) continue;
        if (list[i].status == SupportMessageStatus.read && list[i].isRead) {
          continue;
        }
        changed = true;
        list[i] = SupportMessage(
          id: list[i].id,
          chatId: list[i].chatId,
          senderRole: list[i].senderRole,
          message: list[i].message,
          createdAt: list[i].createdAt,
          status: SupportMessageStatus.read,
          isRead: true,
          attachmentType: list[i].attachmentType,
          attachmentUrl: list[i].attachmentUrl,
          orderId: list[i].orderId,
          voiceDuration: list[i].voiceDuration,
        );
      }
    }
    final chat = chats.firstWhere((c) => c.id == chatId);
    if (viewerRole == SupportSenderRole.admin && chat.unreadAdminCount != 0) {
      changed = true;
      _replace(chatId, unreadAdminCount: 0);
    } else if (viewerRole == SupportSenderRole.customer &&
        chat.unreadCustomerCount != 0) {
      changed = true;
      _replace(chatId, unreadCustomerCount: 0);
    }
    if (changed) _changes.add(null);
  }

  @override
  Future<List<SupportOrderRef>> fetchCustomerOrders(String userId) async =>
      const [];
}

/// `app_notifications` in memory; sends and deletes reach every live stream.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository([List<AppNotification> notifications = const []])
      : notifications = [...notifications];

  final List<AppNotification> notifications;
  final broadcasts = <({
    String title,
    String body,
    AppNotificationType type,
    String? imageUrl,
  })>[];
  final deleted = <String>[];
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  List<AppNotification> get _newestFirst => [...notifications]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// What an admin sending from another device looks like here.
  void push(AppNotification notification) {
    notifications.add(notification);
    _changes.add(null);
  }

  @override
  Stream<List<AppNotification>> watchNotifications() async* {
    yield _newestFirst;
    yield* _changes.stream.map((_) => _newestFirst);
  }

  @override
  Future<void> broadcast({
    required String title,
    required String body,
    required AppNotificationType type,
    String? imageUrl,
    String? targetUserId,
  }) async {
    final image = imageUrl?.trim();
    broadcasts.add((
      title: title.trim(),
      body: body.trim(),
      type: type,
      imageUrl: image == null || image.isEmpty ? null : image,
    ));
    push(AppNotification(
      id: 'sent-${_nextId++}',
      title: title.trim(),
      body: body.trim(),
      type: type,
      imageUrl: image == null || image.isEmpty ? null : image,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<void> deleteNotification(String id) async {
    deleted.add(id);
    notifications.removeWhere((notification) => notification.id == id);
    _changes.add(null);
  }
}

Future<void> pumpApp(
  WidgetTester tester, {
  List<Product> products = const [],
  List<Product> catalogProducts = const [],
  List<Product> offerProducts = const [],
  List<Product> newProducts = const [],
  // Company ad banners on the home deck; none means the built-in promos.
  List<HomeBanner> homeBanners = const [],
  // Off by default: the looping quick actions would keep pumpAndSettle from
  // ever settling.
  bool animateQuickActions = false,
  AuthRepository? authRepository,
  CatalogRepository? catalogRepository,
  ProfileRepository? profileRepository,
  OrdersRepository? ordersRepository,
  FavoritesRepository? favoritesRepository,
  WalletRepository? walletRepository,
  AdminOrdersRepository? adminOrdersRepository,
  AddressesRepository? addressesRepository,
  LocationService? locationService,
  PushNotificationService? pushNotificationService,
  LoyaltyRepository? loyaltyRepository,
  NewOrderNotifier? newOrderNotifier,
  DriverOrdersRepository? driverOrdersRepository,
  DriverLocationService? driverLocationService,
  DeliveryRouteService? deliveryRouteService,
  WarehouseOrdersRepository? warehouseOrdersRepository,
  // The signed-in user's plan; free unless given.
  PaymobService? paymobService,
  SupportRepository? supportRepository,
  NotificationsRepository? notificationsRepository,
  // Fixtures have no photos (network images never settle in widget tests),
  // so lists show photo-less products unless a test opts into customer rules.
  bool showProductsWithoutImage = true,
  // Most tests start past onboarding, as a returning user would.
  bool firstLaunch = false,
  Map<String, Object> preferences = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({
    if (!firstLaunch) SettingsKeys.onboardingDone: true,
    ...preferences,
  });
  final sharedPreferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(450, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // flutter_beep has no native side in tests.
  const beepChannel = MethodChannel('flutter_beep');
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(beepChannel, (_) async => true);
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(beepChannel, null));

  final orders = ordersRepository ?? FakeOrdersRepository();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productsProvider.overrideWith((ref) async => products),
        featuredProductsProvider.overrideWith((ref) async => products),
        offerProductsProvider.overrideWith((ref) async => offerProducts),
        allOfferProductsProvider.overrideWith((ref) async => offerProducts),
        newProductsProvider.overrideWith((ref) async => newProducts),
        allNewProductsProvider.overrideWith((ref) async => newProducts),
        homeBannersProvider.overrideWith((ref) async => homeBanners),
        quickActionsMotionProvider.overrideWithValue(animateQuickActions),
        catalogRepositoryProvider.overrideWithValue(
          catalogRepository ??
              FakeCatalogRepository(
                catalogProducts: catalogProducts,
                products: products,
              ),
        ),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profileRepository ?? FakeProfileRepository(),
        ),
        ordersRepositoryProvider.overrideWithValue(orders),
        customerOrdersStreamOverrideProvider.overrideWith((ref) {
          final userId = ref.watch(currentUserProvider)?.id;
          if (orders is! FakeOrdersRepository || userId == null) {
            return Stream<List<CustomerOrder>>.value(const []);
          }
          orders.requestedFor = userId;
          return orders.changes;
        }),
        favoritesRepositoryProvider.overrideWithValue(
          favoritesRepository ?? FakeFavoritesRepository(),
        ),
        walletRepositoryProvider.overrideWithValue(
          walletRepository ?? FakeWalletRepository(),
        ),
        adminOrdersRepositoryProvider.overrideWithValue(
          adminOrdersRepository ?? FakeAdminOrdersRepository(),
        ),
        addressesRepositoryProvider.overrideWithValue(
          addressesRepository ?? FakeAddressesRepository(),
        ),
        locationServiceProvider.overrideWithValue(
          locationService ?? FakeLocationService(),
        ),
        pushNotificationServiceProvider.overrideWithValue(
          pushNotificationService ?? FakePushNotificationService(),
        ),
        newOrderNotifierProvider.overrideWithValue(
          newOrderNotifier ?? FakeNewOrderNotifier(),
        ),
        driverOrdersRepositoryProvider.overrideWithValue(
          driverOrdersRepository ?? FakeDriverOrdersRepository(),
        ),
        driverLocationServiceProvider.overrideWithValue(
          driverLocationService ?? FakeDriverLocationService(),
        ),
        deliveryRouteServiceProvider.overrideWithValue(
          deliveryRouteService ?? FakeDeliveryRouteService(),
        ),
        trackedOrderStreamOverrideProvider.overrideWith(
          (ref, orderId) => Stream<CustomerOrder?>.value(null),
        ),
        loyaltyRepositoryProvider.overrideWithValue(
          loyaltyRepository ?? FakeLoyaltyRepository(),
        ),
        warehouseOrdersRepositoryProvider.overrideWithValue(
          warehouseOrdersRepository ?? FakeWarehouseOrdersRepository(),
        ),
        paymobServiceProvider.overrideWithValue(
          paymobService ?? FakePaymobService(),
        ),
        supportRepositoryProvider.overrideWithValue(
          supportRepository ?? FakeSupportRepository(),
        ),
        notificationsRepositoryProvider.overrideWithValue(
          notificationsRepository ?? FakeNotificationsRepository(),
        ),
        centerPinMapBuilderProvider.overrideWithValue(
          (config) => FakeCenterPinMap(config: config),
        ),
        showProductsWithoutImageProvider
            .overrideWithValue(showProductsWithoutImage),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ...overrides,
      ],
      child: const SafeerMarketApp(),
    ),
  );
}

Future<void> skipSplash(WidgetTester tester) async {
  await tester.pump(SplashScreen.duration);
  await tester.pumpAndSettle();
}
