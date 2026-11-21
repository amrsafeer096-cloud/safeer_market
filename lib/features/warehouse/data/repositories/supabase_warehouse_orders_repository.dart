import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/realtime_session.dart';
import '../../../../core/network/resilient_realtime_stream.dart';
import '../../domain/entities/warehouse_order.dart';
import '../../domain/repositories/warehouse_orders_repository.dart';

class SupabaseWarehouseOrdersRepository implements WarehouseOrdersRepository {
  const SupabaseWarehouseOrdersRepository(this._client);

  static const _columns = 'id, created_at, status, total_amount, '
      'address_details, profiles!user_id(full_name), '
      'order_items(quantity, products(name))';

  final SupabaseClient _client;

  @override
  Future<List<WarehouseOrder>> fetchQueue() async {
    final rows = await _client
        .from('orders')
        .select(_columns)
        .inFilter('status', ['pending', 'preparing']).order('created_at');
    return rows.map(_toOrder).toList();
  }

  @override
  Future<void> startPreparing(String orderId) => _advance(
        orderId,
        from: 'pending',
        to: 'preparing',
      );

  @override
  Future<void> markReady(String orderId) => _advance(
        orderId,
        from: 'preparing',
        to: 'ready_for_delivery',
      );

  Future<void> _advance(
    String orderId, {
    required String from,
    required String to,
  }) async {
    try {
      final updated = await _client
          .from('orders')
          .update({'status': to})
          .eq('id', orderId)
          .eq('status', from)
          .select('id');
      // Zero rows: RLS refused, or someone else already moved the order.
      if (updated.isEmpty) {
        throw WarehouseFailure(L10n.current.warehouseOrderAlreadyUpdated);
      }
    } on PostgrestException catch (error) {
      throw WarehouseFailure(L10n.current.orderUpdateFailed(error.message));
    }
  }

  @override
  Stream<void> changes() {
    // Tick stream: Realtime events (or the 20s HTTP poll while the socket
    // is down) notify the dashboard so it can invalidate its queue without
    // dying on channelError / WebSocketChannelException.
    var tick = 0;
    return resilientRealtimeStream<int>(
      fetch: () async => ++tick,
      create: () {
        late final RealtimeChannel channel;
        late final StreamController<int> controller;
        controller = StreamController<int>(
          onListen: () {
            channel = _client
                .channel(
                    'warehouse-orders-${DateTime.now().microsecondsSinceEpoch}')
                .onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'orders',
                  callback: (_) {
                    if (!controller.isClosed) controller.add(++tick);
                  },
                )
                .subscribe((status, [error]) {
                  if (status == RealtimeSubscribeStatus.channelError ||
                      status == RealtimeSubscribeStatus.timedOut) {
                    if (!controller.isClosed) {
                      controller.addError(
                        RealtimeSubscribeException(status, error),
                      );
                    }
                  }
                });
          },
          onCancel: () {
            unawaited(_client.removeChannel(channel));
          },
        );
        return controller.stream;
      },
      onReconnect: () => ensureRealtimeAuth(_client),
    ).map((_) {});
  }

  static WarehouseOrder _toOrder(Map<String, dynamic> row) {
    final profile = _single(row['profiles']);
    final items = switch (row['order_items']) {
      final List<dynamic> list => [
          for (final item in list.whereType<Map<String, dynamic>>())
            WarehouseOrderItem(
              productName: _text(_single(item['products'])?['name']) ??
                  L10n.current.deletedProduct,
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            ),
        ],
      _ => const <WarehouseOrderItem>[],
    };
    return WarehouseOrder(
      id: row['id'].toString(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: (row['status'] ?? 'pending').toString(),
      totalAmount: switch (row['total_amount']) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text) ?? 0,
        _ => 0,
      },
      items: items,
      customerName: _text(profile?['full_name']),
      addressDetails: _text(row['address_details']),
    );
  }

  static Map<String, dynamic>? _single(Object? value) => switch (value) {
        final Map<String, dynamic> map => map,
        [final Map<String, dynamic> first, ...] => first,
        _ => null,
      };

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
