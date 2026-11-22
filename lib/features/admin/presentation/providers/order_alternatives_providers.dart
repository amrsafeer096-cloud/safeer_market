import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../data/order_alternatives_service.dart';
import '../../domain/order_item_alternative.dart';

final orderAlternativesServiceProvider = Provider<OrderAlternativesService>(
  (ref) => OrderAlternativesService(ref.watch(supabaseClientProvider)),
);

final orderAlternativesProvider = FutureProvider.autoDispose
    .family<List<OrderItemAlternative>, String>((ref, orderId) {
  return ref.watch(orderAlternativesServiceProvider).listForOrder(orderId);
});

final pendingOrderAlternativesProvider = FutureProvider.autoDispose
    .family<List<OrderItemAlternative>, String>((ref, orderId) async {
  final all = await ref.watch(orderAlternativesProvider(orderId).future);
  return [for (final a in all) if (a.isPending) a];
});

/// Order ids with at least one pending «إرسال بدائل» set (for list badges).
final pendingAlternativeOrderIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(orderAlternativesServiceProvider).pendingOrderIds();
});
