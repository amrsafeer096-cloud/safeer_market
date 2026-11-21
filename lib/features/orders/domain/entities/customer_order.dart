import '../../../admin/domain/entities/order_status.dart';

class OrdersFailure implements Exception {
  const OrdersFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Why the customer cancelled; the value stored in
/// `orders.cancellation_reason`.
enum OrderCancellationReason {
  deliveryDelay('delivery_delay'),
  orderedByMistake('ordered_by_mistake'),
  changedMind('changed_mind'),
  other('other');

  const OrderCancellationReason(this.value);

  final String value;

  static OrderCancellationReason? fromValue(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    for (final reason in values) {
      if (reason.value == text) return reason;
    }
    // Older rows may still hold the Arabic sentence the customer picked.
    return null;
  }
}

/// A line of the order as the customer bought it (`order_items`).
class CustomerOrderItem {
  const CustomerOrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.weightInGrams,
  });

  final String productName;
  final int quantity;

  /// Price per unit when ordered; for weight-based lines, of the weight.
  final double unitPrice;

  /// Set for weight-based products (quantity is then 1).
  final int? weightInGrams;

  double get total => unitPrice * quantity;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.status,
    this.addressDetails,
    this.cancellationReason,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.driverName,
    this.driverPhone,
  });

  factory CustomerOrder.fromRow(Map<String, dynamic> row) {
    final total = row['total_amount'];
    final created = row['created_at'];
    final address = row['address_details']?.toString().trim();
    final reason = row['cancellation_reason']?.toString().trim();
    final driverName = row['driver_name']?.toString().trim();
    final driverPhone = row['driver_phone']?.toString().trim();
    return CustomerOrder(
      id: row['id'].toString(),
      createdAt: created is DateTime
          ? created.toLocal()
          : DateTime.parse('$created').toLocal(),
      totalAmount:
          total is num ? total.toDouble() : double.tryParse('$total') ?? 0,
      status: (row['status'] ?? 'pending').toString(),
      addressDetails: address == null || address.isEmpty ? null : address,
      cancellationReason: reason == null || reason.isEmpty ? null : reason,
      deliveryLatitude: _toDouble(row['delivery_latitude']),
      deliveryLongitude: _toDouble(row['delivery_longitude']),
      driverLatitude: _toDouble(row['driver_lat']),
      driverLongitude: _toDouble(row['driver_lng']),
      driverName: driverName == null || driverName.isEmpty ? null : driverName,
      driverPhone:
          driverPhone == null || driverPhone.isEmpty ? null : driverPhone,
    );
  }

  final String id;
  final DateTime createdAt;
  final double totalAmount;
  final String status;
  final String? addressDetails;

  /// Key from [OrderCancellationReason], or free text on older rows.
  final String? cancellationReason;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  /// Last position the driver shared; null until their GPS reports in.
  final double? driverLatitude;
  final double? driverLongitude;
  final String? driverName;
  final String? driverPhone;

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  /// [status] in snake_case, however the dashboard spelled it.
  String get normalizedStatus => OrderStatus.normalize(status);

  bool get isOutForDelivery => const {
        'out_for_delivery',
        'shipped',
      }.contains(normalizedStatus);

  bool get isDelivered => const {
        'delivered',
        'completed',
      }.contains(normalizedStatus);

  bool get isCancelled => const {
        'cancelled',
        'canceled',
      }.contains(normalizedStatus);

  /// Still new or being prepared: the customer can cancel from «طلباتي».
  bool get canCancel => const {
        'pending',
        'new',
        'preparing',
      }.contains(normalizedStatus);

  CustomerOrder copyWith({
    String? status,
    String? cancellationReason,
  }) =>
      CustomerOrder(
        id: id,
        createdAt: createdAt,
        totalAmount: totalAmount,
        status: status ?? this.status,
        addressDetails: addressDetails,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        driverName: driverName,
        driverPhone: driverPhone,
      );

  static double? _toDouble(Object? value) => switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text),
        _ => null,
      };
}
