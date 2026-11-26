import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_currency.dart';
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

    Future<List<Map<String, dynamic>>> query(String columns) async {
      final rows = await client
          .from('orders')
          .select(columns)
          .eq('taker_name', name)
          .gte('created_at', start.toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(rows as List);
    }

    // Prefer updated_at for the live timer; fall back if the column is absent.
    const withUpdated =
        'id, status, created_at, updated_at, prep_completed_at, '
        'customer_name, customer_phone, taker_name, driver_name, preparer_name, '
        'delivery_fee, total_amount, address_details, payment_method, '
        'fujitsu_order_id, delivery_area';
    const withoutUpdated =
        'id, status, created_at, prep_completed_at, '
        'customer_name, customer_phone, taker_name, driver_name, preparer_name, '
        'delivery_fee, total_amount, address_details, payment_method, '
        'fujitsu_order_id, delivery_area';
    try {
      return await query(withUpdated);
    } catch (error) {
      final message = '$error'.toLowerCase();
      if (message.contains('updated_at')) {
        debugPrint(
            'طلبات اليوم: updated_at missing, falling back to created_at');
        return await query(withoutUpdated);
      }
      rethrow;
    }
  }

  final controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  var closed = false;

  Future<void> push() async {
    try {
      final rows = await fetch();
      if (!closed && !controller.isClosed) controller.add(rows);
    } catch (error, stack) {
      debugPrint('طلبات اليوم fetch failed: $error');
      developer.log(
        'طلبات اليوم fetch failed',
        name: 'PhoneOrderTodayPanel',
        error: error,
        stackTrace: stack,
      );
      if (!closed && !controller.isClosed) {
        controller.addError(error, stack);
      }
    }
  }

  unawaited(push());
  final poll = Timer.periodic(const Duration(seconds: 5), (_) => push());

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
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'تعذّر التحميل\n$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
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
    final name = (order['customer_name'] ?? 'عميل').toString().trim();
    final phone = (order['customer_phone'] ?? '').toString().trim();
    final label = todayStatusLabel(status);
    final color = todayStatusColor(status);
    final id = '${order['id']}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('phone-order-today-$id'),
        onTap: () => showTodayOrderInspection(context, orderId: id),
        child: Padding(
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
        ),
      ),
    );
  }
}

String todayStatusLabel(String status) => switch (status) {
      'pending' => 'انتظار',
      'preparing' => 'تحضير',
      'ready_for_delivery' => 'جاهز',
      'out_for_delivery' => 'توصيل',
      'delivered' => 'تم',
      'cancelled' => 'ملغي',
      _ => status,
    };

Color todayStatusColor(String status) => switch (status) {
      'pending' => Colors.blueGrey,
      'preparing' => Colors.orange,
      'ready_for_delivery' => Colors.purple,
      'out_for_delivery' => Colors.blue,
      'delivered' => Colors.green,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };

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

Future<void> showTodayOrderInspection(
  BuildContext context, {
  required String orderId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _TodayOrderInspectionDialog(orderId: orderId),
  );
}

class _TodayOrderInspectionDialog extends ConsumerStatefulWidget {
  const _TodayOrderInspectionDialog({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_TodayOrderInspectionDialog> createState() =>
      _TodayOrderInspectionDialogState();
}

class _TodayOrderInspectionDialogState
    extends ConsumerState<_TodayOrderInspectionDialog> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = const [];
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final order = await client
          .from('orders')
          .select(
            'id, status, created_at, updated_at, prep_completed_at, '
            'customer_name, customer_phone, taker_name, preparer_name, '
            'driver_name, delivery_fee, total_amount, address_details, '
            'payment_method, fujitsu_order_id, delivery_area',
          )
          .eq('id', widget.orderId)
          .maybeSingle();
      final items = await client
          .from('order_items')
          .select(
            'id, quantity, price_at_time, weight_in_grams, '
            'products(name, barcode)',
          )
          .eq('order_id', widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order == null ? null : Map<String, dynamic>.from(order);
        _items = [
          for (final row in items as List)
            Map<String, dynamic>.from(row as Map),
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _paymentLabel(String? raw) => switch ((raw ?? '').toLowerCase()) {
        'cash' || 'cash_on_delivery' => 'نقدي',
        'visa_on_delivery' => 'فيزا عند الاستلام',
        'card' || 'visa' => 'ائتمان',
        'instapay' => 'إنستا باي',
        _ => (raw?.trim().isNotEmpty ?? false) ? raw!.trim() : '—',
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dateFmt = DateFormat('dd/MM/yyyy hh:mm a');
    final order = _order;
    final status = OrderStatus.normalize('${order?['status'] ?? ''}');
    final prepDone = order?['prep_completed_at'] != null;
    final preparedCount = prepDone ? _items.length : 0;
    final pendingCount = prepDone ? 0 : _items.length;

    return AlertDialog(
      key: const Key('phone-order-today-inspection'),
      title: const Text(
        'تفاصيل طلب اليوم',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 480,
        height: 460,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('$_error', textAlign: TextAlign.center))
                : order == null
                    ? const Center(child: Text('الطلب غير موجود'))
                    : ListView(
                        children: [
                          _kv('العميل', '${order['customer_name'] ?? '—'}'),
                          _kv('تليفون', '${order['customer_phone'] ?? '—'}'),
                          _kv(
                            'العنوان',
                            '${order['address_details'] ?? '—'}',
                          ),
                          _kv(
                            'المنطقة',
                            '${order['delivery_area'] ?? '—'}',
                          ),
                          _kv(
                            'الحالة',
                            todayStatusLabel(status),
                          ),
                          _kv(
                            'وقت الطلب',
                            dateFmt.format(
                              DateTime.tryParse('${order['created_at']}')
                                      ?.toLocal() ??
                                  DateTime.now(),
                            ),
                          ),
                          _kv('المتلقي', '${order['taker_name'] ?? '—'}'),
                          _kv('المحضر', '${order['preparer_name'] ?? '—'}'),
                          _kv('السائق', '${order['driver_name'] ?? '—'}'),
                          _kv(
                            'الدفع',
                            _paymentLabel(order['payment_method']?.toString()),
                          ),
                          if (order['fujitsu_order_id'] != null)
                            _kv(
                              'رقم فوجيتسو',
                              '${order['fujitsu_order_id']}',
                            ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: palette.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'تقدم التجهيز',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: palette.accent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  prepDone
                                      ? 'اكتمل تجهيز كل الأصناف ($_items.length)'
                                      : status == 'pending'
                                          ? 'في الانتظار — لم يبدأ التجهيز'
                                          : 'قيد التجهيز: جاهز $preparedCount • متبقي $pendingCount',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                if (prepDone)
                                  Text(
                                    'اكتمل: ${dateFmt.format(DateTime.tryParse('${order['prep_completed_at']}')?.toLocal() ?? DateTime.now())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 20),
                          Text(
                            'الأصناف (${_items.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final item in _items)
                            _ItemRow(
                              item: item,
                              prepared: prepDone,
                              pending: !prepDone,
                            ),
                          const Divider(height: 20),
                          _kv(
                            'التوصيل',
                            AppCurrency.of(
                              (order['delivery_fee'] as num?)?.toDouble() ?? 0,
                            ),
                          ),
                          _kv(
                            'الإجمالي',
                            AppCurrency.of(
                              (order['total_amount'] as num?)?.toDouble() ?? 0,
                            ),
                          ),
                        ],
                      ),
      ),
      actions: [
        FilledButton.icon(
          key: const Key('phone-order-today-back'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('رجوع للطلب الحالي'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                k,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.prepared,
    required this.pending,
  });

  final Map<String, dynamic> item;
  final bool prepared;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final product = item['products'];
    final p = product is Map
        ? Map<String, dynamic>.from(product)
        : <String, dynamic>{};
    final name = '${p['name'] ?? 'منتج'}';
    final barcode = '${p['barcode'] ?? ''}'.trim();
    final grams = item['weight_in_grams'];
    final qty = item['quantity'] ?? 1;
    final qtyLabel = (grams is num && grams > 0)
        ? '${grams.round()} جم'
        : '× $qty';
    final price = (item['price_at_time'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            prepared
                ? Icons.check_circle_rounded
                : pending
                    ? Icons.hourglass_top_rounded
                    : Icons.circle_outlined,
            size: 18,
            color: prepared
                ? Colors.green
                : pending
                    ? Colors.orange
                    : palette.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (barcode.isNotEmpty)
                  Text(barcode,
                      style: TextStyle(fontSize: 11, color: palette.muted)),
              ],
            ),
          ),
          Text(
            qtyLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Text(
            AppCurrency.of(price),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}
