import '../entities/driver_order.dart';

abstract interface class DriverOrdersRepository {
  /// Unassigned orders the warehouse marked `ready_for_delivery`, oldest
  /// first.
  Future<List<DriverOrder>> fetchAvailableOrders();

  /// Orders the signed-in driver accepted and hasn't delivered yet.
  Future<List<DriverOrder>> fetchMyDeliveries();

  /// Assigns the order to the signed-in driver and sends it out for delivery.
  /// Throws [DriverFailure] when another driver got there first.
  Future<void> acceptOrder(String orderId);

  Future<void> markDelivered(String orderId);

  /// Publishes the driver's position on an order that is out for delivery,
  /// for the customer's live tracking map. Throws [DriverFailure] when the
  /// row was not updated.
  Future<void> updateDriverLocation(
    String orderId, {
    required double latitude,
    required double longitude,
  });
}

class DriverFailure implements Exception {
  const DriverFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
