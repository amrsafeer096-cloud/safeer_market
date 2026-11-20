import '../l10n/l10n.dart';

/// Safeer Market's Nasr City branch. Delivery fees are priced by the
/// distance from this point to the customer's pinned address.
abstract final class StoreLocation {
  static const latitude = 30.040283;
  static const longitude = 31.338779;

  /// The only city Safeer Market delivers to.
  static String get city => L10n.current.storeCityName;
}
