import '../../../checkout/domain/delivery_pricing.dart';

class DriverOrder {
  const DriverOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    this.customerName,
    this.customerPhone,
    this.addressDetails,
    this.latitude,
    this.longitude,
  });

  final String id;
  final DateTime createdAt;

  /// Raw `orders.status`.
  final String status;

  /// Grand total the driver collects, delivery fee included.
  final double totalAmount;
  final double deliveryFee;
  final String? customerName;
  final String? customerPhone;
  final String? addressDetails;
  final double? latitude;
  final double? longitude;

  String get shortId => id.length > 6 ? id.substring(0, 6) : id;

  /// Distance from the store; null for orders placed before pins were saved.
  double? get distanceKm => latitude == null || longitude == null
      ? null
      : DeliveryPricing.distanceFromStoreKm(latitude!, longitude!);
}
