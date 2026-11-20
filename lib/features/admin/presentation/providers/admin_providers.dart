import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../data/repositories/supabase_admin_orders_repository.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/admin_orders_repository.dart';

final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>((ref) {
  return SupabaseAdminOrdersRepository(ref.watch(supabaseClientProvider));
});

final adminOrdersProvider = FutureProvider.autoDispose<List<AdminOrder>>((ref) {
  return ref.watch(adminOrdersRepositoryProvider).fetchAllOrders();
});

final adminOrderProvider =
    FutureProvider.autoDispose.family<AdminOrder?, String>((ref, orderId) {
  return ref.watch(adminOrdersRepositoryProvider).fetchOrder(orderId);
});

final adminOrderItemsProvider = FutureProvider.autoDispose
    .family<List<AdminOrderItem>, String>((ref, orderId) {
  return ref.watch(adminOrdersRepositoryProvider).fetchOrderItems(orderId);
});

/// Null on the list screen's "all" filter.
final adminStatusFilterProvider =
    StateProvider.autoDispose<OrderStatus?>((ref) => null);

Future<void> updateAdminOrderStatus(
  WidgetRef ref,
  String orderId,
  OrderStatus status,
) async {
  await ref.read(adminOrdersRepositoryProvider).updateStatus(orderId, status);
  ref
    ..invalidate(adminOrderProvider(orderId))
    ..invalidate(adminOrdersProvider)
    ..invalidate(myOrdersProvider);
}
