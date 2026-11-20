abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/welcome';
  static const home = '/home';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const payment = '/checkout/payment';
  static const auth = '/auth';
  static const orders = '/orders';
  static const favorites = '/favorites';
  static const settings = '/settings';
  static const addresses = '/addresses';
  static const mapPicker = '/addresses/map';
  static const addAddress = '/addresses/new';
  static const editProfile = '/profile/edit';
  static const wallet = '/wallet';
  static const rewards = '/rewards';
  static const wheelGame = '/rewards/wheel';
  static const puzzle = '/rewards/puzzle';
  static const scratchCard = '/rewards/scratch';
  static const luckyChest = '/rewards/chest';

  /// Cashiers and admins only: scan a customer's code to redeem points.
  static const cashierScan = '/cashier/scan';
  static const magazines = '/magazines';

  /// The signed-in customer's live chat with customer service.
  static const supportChat = '/support/chat';

  static const notifications = '/notifications';
  static const categoryPattern = '/category/:id';
  static const productPattern = '/product/:id';

  static String product(String id) => '/product/$id';

  static const orderTrackingPattern = '/orders/:id/track';

  static String orderTracking(
    String id, {
    double? latitude,
    double? longitude,
  }) =>
      Uri(
        path: '/orders/$id/track',
        queryParameters: latitude == null || longitude == null
            ? null
            : {'lat': latitude.toString(), 'lng': longitude.toString()},
      ).toString();

  static const warehouse = '/warehouse';
  static const goodsReceipt = '/warehouse/receipt';

  static const driver = '/driver';
  static const driverMap = '/driver/map';

  static String driverMapFor({
    required double latitude,
    required double longitude,
  }) =>
      Uri(
        path: driverMap,
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
        },
      ).toString();

  static const adminOrders = '/admin/orders';
  static const adminOrderPattern = '/admin/orders/:id';

  static String adminOrder(String id) => '/admin/orders/$id';

  /// [id] is a `MainCategory.id`.
  static String category(String id) => '/category/${Uri.encodeComponent(id)}';
}
