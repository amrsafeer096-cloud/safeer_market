import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/notifications/new_order_notifier.dart';
import '../../data/repositories/supabase_warehouse_orders_repository.dart';
import '../../domain/entities/warehouse_order.dart';
import '../../domain/repositories/warehouse_orders_repository.dart';

final warehouseOrdersRepositoryProvider =
    Provider<WarehouseOrdersRepository>((ref) {
  return SupabaseWarehouseOrdersRepository(ref.watch(supabaseClientProvider));
});

final warehouseQueueProvider =
    FutureProvider.autoDispose<List<WarehouseOrder>>((ref) {
  return ref.watch(warehouseOrdersRepositoryProvider).fetchQueue();
});

final warehouseActionsProvider = Provider(WarehouseActions.new);

class WarehouseActions {
  const WarehouseActions(this._ref);

  final Ref _ref;

  Future<void> startPreparing(WarehouseOrder order) async {
    try {
      await _ref
          .read(warehouseOrdersRepositoryProvider)
          .startPreparing(order.id);
    } finally {
      _ref.invalidate(warehouseQueueProvider);
    }
  }

  Future<void> markReady(WarehouseOrder order) async {
    try {
      await _ref.read(warehouseOrdersRepositoryProvider).markReady(order.id);
    } finally {
      _ref.invalidate(warehouseQueueProvider);
    }
    unawaited(_notifyDrivers(_ref.read(newOrderNotifierProvider), order.id));
  }

  /// The status is already saved, so a failed push must not fail the action.
  static Future<void> _notifyDrivers(
    NewOrderNotifier notifier,
    String orderId,
  ) async {
    try {
      await notifier.notifyDrivers(orderId);
    } catch (error) {
      debugPrint('Could not notify drivers about order $orderId: $error');
    }
  }
}
