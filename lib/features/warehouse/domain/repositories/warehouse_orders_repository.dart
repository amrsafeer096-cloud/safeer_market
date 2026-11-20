import '../entities/warehouse_order.dart';

abstract interface class WarehouseOrdersRepository {
  /// Orders that are `pending` or `preparing`, oldest first.
  Future<List<WarehouseOrder>> fetchQueue();

  /// `pending` → `preparing`.
  Future<void> startPreparing(String orderId);

  /// `preparing` → `ready_for_delivery`, which hands the order to drivers.
  Future<void> markReady(String orderId);

  /// Emits whenever any order row changes, so the queue can refresh.
  Stream<void> changes();
}

class WarehouseFailure implements Exception {
  const WarehouseFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
