import '../../../catalog/domain/main_categories.dart';
import '../../../home/domain/entities/product.dart';
import '../phone_order.dart';
import '../product_search_filter.dart';

/// Phone orders taken from the admin dashboard.
abstract class PhoneOrdersRepository {
  /// App users and POS customers matching a phone number (3+ digits) or
  /// a name.
  Future<List<PhoneOrderCustomer>> searchCustomers(String query);

  /// Adds a caller who isn't registered yet, or returns the customer already
  /// saved under [phone].
  ///
  /// The optional details are stored in Supabase only (never in the POS
  /// sync columns); [latitude]/[longitude] feed the driver app's map pin.
  /// [fujitsuZoneId] is the chosen delivery zone's Fujitsu code. A new
  /// customer is stored with `synced_to_fujitsu = false`.
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
  });

  /// Full customer card + address list for the «بيانات العميل» modal.
  Future<PhoneOrderCustomerDetails> fetchCustomerDetails(
    PhoneOrderCustomer customer,
  );

  /// Updates name / phones / notes on a POS customer.
  Future<PhoneOrderCustomer> updateCustomerDetails({
    required int posCustomerId,
    String? fullName,
    String? phone,
    String? phone2,
    String? phone3,
    String? phone4,
    String? phone5,
    String? notes,
  });

  /// Adds or edits a row in `customer_addresses`.
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
  });

  /// Active delivery zones (`delivery_zones`), for [city] when given. Empty
  /// when the table has no rows (or doesn't exist yet).
  Future<List<PhoneOrderArea>> fetchAreas({String? city});

  /// Products by name or barcode, optionally within [category].
  /// [filter] defaults to positive stock only («المخزون الفعلي»).
  /// [offersOnly] ANDs the active-offer constraint (تلقي الطلبات chips).
  Future<List<Product>> searchProducts(
    String query, {
    MainCategory? category,
    ProductSearchFilterMode filter = ProductSearchFilterMode.inStock,
    bool offersOnly = false,
  });

  /// Records the order (status pending, «جديد») and returns its id.
  ///
  /// [paymentMethod] is stored on the order; an InstaPay order needs its
  /// [receipt] image, which is uploaded first and linked on the order, and
  /// the order is saved as paid.
  ///
  /// [isSupplemental] marks a same-day «طلب ملحق» (usually with fee 0).
  Future<String> placeOrder({
    required PhoneOrderCustomer customer,
    required List<PhoneOrderLine> lines,
    required double deliveryFee,
    PhoneOrderPayment paymentMethod = PhoneOrderPayment.cash,
    PaymentReceiptImage? receipt,
    bool isSupplemental = false,
  });

  /// True when this customer already has a non-cancelled order created today
  /// (Africa/Cairo calendar day).
  Future<bool> hasOrderToday(PhoneOrderCustomer customer);

  /// Past purchases for [customer], matched by user / POS id / phone.
  Future<CustomerPurchaseHistory> fetchCustomerHistory(
    PhoneOrderCustomer customer,
  );

  /// Past orders for the left «الطلبات السابقة» tab.
  Future<List<CustomerPastOrderSummary>> fetchCustomerPastOrders(
    PhoneOrderCustomer customer,
  );

  /// One past order + its lines (repeat-order modal).
  Future<CustomerPastOrderDetail> fetchCustomerPastOrderDetail(String orderId);
}

class PhoneOrderFailure implements Exception {
  const PhoneOrderFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
