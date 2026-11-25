import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/order_status.dart';
import '../providers/staff_session_providers.dart';

/// Today's orders for the logged-in taker (by `taker_name`).
final takerTodayOrdersProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final staff = ref.watch(staffSessionProvider);
  final name = staff?.name.trim() ?? '';
  if (name.isEmpty) {
    return Stream.value(const []);
  }
  final client = ref.watch(supabaseClientProvider);

  Future<List<Map<String, dynamic>>> fetch() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final rows = await client
        .from('orders')
        .select(
          'id, status, created_at, updated_at, prep_completed_at, '
          'customer_name, phone, delivery_phone, taker_name, receiver_name',
        )
        .ilike('taker_name', name)
        .gte('created_at', start.toIso8601String())
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(80);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  final controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  var closed = false;

  Future<void> push() async {
    try {
      final rows = await fetch();
      if (!closed && !controller.isClosed) controller.add(rows);
    } catch (error, stack) {
      if (!closed && !controller.isClosed) {
        controller.addError(error, stack);
      }
    }
  }

  unawaited(push());
  final poll = Timer.periodic(const Duration(seconds: 8), (_) => push());

  final channel = client.channel('phone-order-today-$name');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (_) => push(),
      )
      .subscribe();

  ref.onDispose(() {
    closed = true;
    poll.cancel();
    unawaited(client.removeChannel(channel));
    unawaited(controller.close());
  });

  return controller.stream;
});

/// Fixed right-side «طلبات اليوم» for the logged-in taker.
class PhoneOrderTodayPanel extends ConsumerWidget {
  const PhoneOrderTodayPanel({super.key});

  static const width = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final orders = ref.watch(takerTodayOrdersProvider);

    return Material(
      color: palette.card,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                'طلبات اليوم',
                key: const Key('phone-order-today-title'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: palette.accent,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: orders.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'تعذّر التحميل',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'لا طلبات اليوم',
                        style:
                            TextStyle(color: palette.muted, fontSize: 12),
                      ),
                    );
                  }
                  return ListView.separated(
                    key: const Key('phone-order-today-list'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: palette.border),
                    itemBuilder: (context, i) =>
                        _TodayOrderCard(order: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayOrderCard extends StatelessWidget {
  const _TodayOrderCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final status = OrderStatus.normalize('${order['status'] ?? ''}');
    final name = (order['customer_name'] ??
            order['receiver_name'] ??
            'عميل')
        .toString()
        .trim();
    final phone = (order['phone'] ?? order['delivery_phone'] ?? '')
        .toString()
        .trim();
    final label = _statusLabel(status);
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'عميل' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          if (phone.isNotEmpty)
            Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: palette.muted),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              _StatusElapsedTimer(order: order),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'pending' => 'جديد',
        'preparing' => 'تحضير',
        'ready_for_delivery' => 'للطيار',
        'out_for_delivery' => 'توصيل',
        'delivered' => 'مكتمل',
        'cancelled' => 'ملغي',
        _ => status,
      };

  static Color _statusColor(String status) => switch (status) {
        'pending' => Colors.blueGrey,
        'preparing' => Colors.orange,
        'ready_for_delivery' => Colors.purple,
        'out_for_delivery' => Colors.blue,
        'delivered' => Colors.green,
        'cancelled' => Colors.red,
        _ => Colors.grey,
      };
}

/// Live MM:SS / HH:MM from last status change (`updated_at` preferred).
class _StatusElapsedTimer extends StatefulWidget {
  const _StatusElapsedTimer({required this.order});

  final Map<String, dynamic> order;

  @override
  State<_StatusElapsedTimer> createState() => _StatusElapsedTimerState();
}

class _StatusElapsedTimerState extends State<_StatusElapsedTimer> {
  Timer? _tick;
  String? _lastStatus;
  DateTime? _statusChangedAt;

  @override
  void initState() {
    super.initState();
    _lastStatus =
        OrderStatus.normalize('${widget.order['status'] ?? ''}');
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _StatusElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final status =
        OrderStatus.normalize('${widget.order['status'] ?? ''}');
    if (_lastStatus != null && _lastStatus != status) {
      _statusChangedAt = DateTime.now();
    }
    _lastStatus = status;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  DateTime _anchor() {
    // Prefer the moment we observed a status change so the timer
    // resets to 00:00 immediately in the UI.
    if (_statusChangedAt != null) return _statusChangedAt!;

    final status = OrderStatus.normalize('${widget.order['status'] ?? ''}');
    DateTime? parse(Object? raw) => DateTime.tryParse('$raw')?.toLocal();

    final updated = parse(widget.order['updated_at']);
    if (updated != null) return updated;
    if (status == OrderStatus.readyForDelivery.value) {
      final prep = parse(widget.order['prep_completed_at']);
      if (prep != null) return prep;
    }
    return parse(widget.order['created_at']) ?? DateTime.now();
  }

  String _format(Duration d) {
    final total = d.inSeconds.clamp(0, 99 * 3600);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_anchor());
    return Text(
      _format(elapsed),
      key: Key('today-timer-${widget.order['id']}'),
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w900,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
  }
}
