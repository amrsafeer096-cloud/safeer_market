import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/maps_config.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_orders_repository.dart';
import '../../data/services/delivery_route_service_factory.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/services/delivery_route_service.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return SupabaseOrdersRepository(ref.watch(supabaseClientProvider));
});

final deliveryRouteServiceProvider = Provider<DeliveryRouteService>(
  (ref) => createDeliveryRouteService(MapsConfig.apiKey),
);

final myOrdersProvider =
    FutureProvider.autoDispose<List<CustomerOrder>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(ordersRepositoryProvider).fetchOrders(user.id);
});

/// The products in an order, loaded when its card is expanded.
final customerOrderItemsProvider = FutureProvider.autoDispose
    .family<List<CustomerOrderItem>, String>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).fetchOrderItems(orderId);
});

/// Test hook. Production leaves this null so [MyOrdersScreen] subscribes to
/// `Supabase.instance.client.from('orders').stream(primaryKey: ['id'])`.
final customerOrdersStreamOverrideProvider =
    Provider<Stream<List<CustomerOrder>>?>((ref) => null);

/// Test hook. Production leaves this null so [OrderTrackingScreen] subscribes
/// to the tracked order's row with `.stream(primaryKey: ['id']).eq('id', id)`.
final trackedOrderStreamOverrideProvider =
    Provider.family<Stream<CustomerOrder?>?, String>((ref, orderId) => null);
