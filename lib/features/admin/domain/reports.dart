import 'entities/order_status.dart';
import 'order_prep_timer.dart';
import 'order_rating.dart';

/// The reports of «التقارير واليومية».
enum ReportKind {
  deliveryOrders('طلبات التوصيل'),
  deliveryItems('أصناف طلبات التوصيل'),
  receivers('إنتاجية المتلقين'),
  preparers('إنتاجية المحضرين'),
  drivers('إنتاجية الطيارين'),
  followUp('متابعة الطلبات'),
  customers('طلبات العملاء'),
  customerRatings('تقييمات العملاء');

  const ReportKind(this.label);

  final String label;

  /// The filters that make sense for this report; the others are hidden and
  /// ignored.
  Set<ReportFilter> get filters => switch (this) {
        deliveryOrders ||
        deliveryItems ||
        followUp =>
          ReportFilter.values.toSet(),
        receivers => {
            ReportFilter.date,
            ReportFilter.receiver,
            ReportFilter.status,
          },
        preparers => {
            ReportFilter.date,
            ReportFilter.preparer,
            ReportFilter.status,
          },
        drivers => {
          ReportFilter.date,
          ReportFilter.driver,
          ReportFilter.status,
        },
        customers => {
            ReportFilter.date,
            ReportFilter.receiver,
            ReportFilter.status,
          },
        customerRatings => {ReportFilter.date},
      };
}

enum ReportFilter { date, preparer, receiver, driver, status }

/// What to report on. Dates are whole days: [from] to [to], both included.
class ReportFilters {
  const ReportFilters({
    required this.from,
    required this.to,
    this.preparer,
    this.receiver = '',
    this.driver,
    this.status,
  });

  factory ReportFilters.today([DateTime? now]) {
    final today = _day(now ?? DateTime.now());
    return ReportFilters(from: today, to: today);
  }

  final DateTime from;
  final DateTime to;
  final String? preparer;

  /// Part of the name of whoever took the order.
  final String receiver;
  final String? driver;

  /// An [OrderStatus.value], or null for any.
  final String? status;

  /// Start of [from]'s day.
  DateTime get start => _day(from);

  /// Start of the day after [to] (exclusive upper bound).
  DateTime get endExclusive {
    final last = _day(to);
    return DateTime(last.year, last.month, last.day + 1);
  }

  ReportFilters copyWith({
    DateTime? from,
    DateTime? to,
    String? preparer,
    bool clearPreparer = false,
    String? receiver,
    String? driver,
    bool clearDriver = false,
    String? status,
    bool clearStatus = false,
  }) =>
      ReportFilters(
        from: from ?? this.from,
        to: to ?? this.to,
        preparer: clearPreparer ? null : preparer ?? this.preparer,
        receiver: receiver ?? this.receiver,
        driver: clearDriver ? null : driver ?? this.driver,
        status: clearStatus ? null : status ?? this.status,
      );

  /// Only the filters in [allowed]; the others are reset.
  ReportFilters limitedTo(Set<ReportFilter> allowed) => ReportFilters(
        from: from,
        to: to,
        preparer: allowed.contains(ReportFilter.preparer) ? preparer : null,
        receiver: allowed.contains(ReportFilter.receiver) ? receiver : '',
        driver: allowed.contains(ReportFilter.driver) ? driver : null,
        status: allowed.contains(ReportFilter.status) ? status : null,
      );

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// A figure in the summary strip above the table.
class ReportStat {
  const ReportStat(this.label, this.value);

  final String label;
  final String value;
}

class ReportColumn {
  const ReportColumn(this.label, {this.width = 120});

  final String label;
  final double width;
}

/// A finished report: a summary and a table, all text.
class ReportTable {
  const ReportTable({
    required this.title,
    required this.summary,
    required this.columns,
    required this.rows,
  });

  final String title;
  final List<ReportStat> summary;
  final List<ReportColumn> columns;
  final List<List<String>> rows;
}

typedef Money = String Function(num value);

String _plainMoney(num value) => value.toStringAsFixed(2);

const _statusNames = {
  'pending': 'جديد',
  'preparing': 'تحضير',
  'ready_for_delivery': 'للطيار',
  'out_for_delivery': 'توصيل',
  'delivered': 'مكتمل',
  'cancelled': 'ملغي',
};

String reportStatusName(Object? status) {
  final value = OrderStatus.normalize('${status ?? ''}');
  return _statusNames[value] ?? 'غير معروف';
}

num _num(Object? value) => switch (value) {
      final num number => number,
      final String text => num.tryParse(text) ?? 0,
      _ => 0,
    };

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _time(Object? value) =>
    DateTime.tryParse('${value ?? ''}')?.toLocal();

String _two(int value) => value.toString().padLeft(2, '0');

String _dateTime(DateTime? value) => value == null
    ? '—'
    : '${value.year}-${_two(value.month)}-${_two(value.day)} '
        '${_two(value.hour)}:${_two(value.minute)}';

String _minutes(Duration? value) {
  if (value == null) return '—';
  final minutes = value.inSeconds / 60;
  return '${minutes.toStringAsFixed(minutes < 10 ? 1 : 0)} د';
}

Duration? _average(List<Duration?> nullable) {
  final values = nullable.whereType<Duration>().toList();
  if (values.isEmpty) return null;
  final total = values.fold<int>(0, (sum, d) => sum + d.inSeconds);
  return Duration(seconds: (total / values.length).round());
}

String _shortId(Object? id) {
  final text = '$id';
  return '#${text.length > 6 ? text.substring(0, 6) : text}';
}

bool _cancelled(Map<String, dynamic> order) =>
    OrderStatus.normalize('${order['status'] ?? ''}') ==
    OrderStatus.cancelled.value;

bool _delivered(Map<String, dynamic> order) =>
    OrderStatus.normalize('${order['status'] ?? ''}') ==
    OrderStatus.delivered.value;

double _total(Map<String, dynamic> order) =>
    _num(order['total_amount']).toDouble();

/// Builds [kind] from the orders in range ([orders]) and, for
/// [ReportKind.deliveryItems], their `order_items` rows ([items]).
ReportTable buildReport(
  ReportKind kind,
  List<Map<String, dynamic>> orders, {
  List<Map<String, dynamic>> items = const [],
  DateTime? now,
  Money? money,
}) {
  final clock = now ?? DateTime.now();
  final fmt = money ?? _plainMoney;
  return switch (kind) {
    ReportKind.deliveryOrders => _deliveryOrders(orders, fmt),
    ReportKind.deliveryItems => _deliveryItems(orders, items, fmt),
    ReportKind.receivers => _receivers(orders, fmt),
    ReportKind.preparers => _preparers(orders, fmt, clock),
    ReportKind.drivers => _drivers(orders, fmt),
    ReportKind.followUp => _followUp(orders, clock),
    ReportKind.customers => _customers(orders, fmt),
    // Built via [buildCustomerRatingsReport] from order_ratings rows.
    ReportKind.customerRatings => const ReportTable(
        title: 'تقييمات العملاء',
        summary: [],
        columns: [],
        rows: [],
      ),
  };
}

/// Summary + recent ratings table for «تقييمات العملاء».
ReportTable buildCustomerRatingsReport(
  List<OrderRating> ratings, {
  bool lowOnly = false,
}) {
  final summary = OrderRatingsSummary.from(ratings);
  final rows = lowOnly ? ratings.where((r) => r.isLow).toList() : ratings;

  String stars(int n) => '$n ★';
  String avg(double v) =>
      ratings.isEmpty ? '—' : '${v.toStringAsFixed(2)} / 5';

  return ReportTable(
    title: ReportKind.customerRatings.label,
    summary: [
      ReportStat('متوسط خدمة التوصيل', avg(summary.avgDelivery)),
      ReportStat('متوسط جودة المنتجات', avg(summary.avgProduct)),
      ReportStat('عدد التقييمات', '${summary.total}'),
      if (lowOnly)
        ReportStat('تقييمات منخفضة', '${rows.length}'),
    ],
    columns: const [
      ReportColumn('رقم الطلب', width: 90),
      ReportColumn('العميل', width: 140),
      ReportColumn('الطيار', width: 120),
      ReportColumn('التوصيل', width: 80),
      ReportColumn('المنتجات', width: 80),
      ReportColumn('التعليق', width: 260),
      ReportColumn('التاريخ', width: 140),
    ],
    rows: [
      for (final r in rows)
        [
          r.shortOrderId,
          r.customerName ?? '—',
          r.driverName ?? '—',
          stars(r.deliveryRating),
          stars(r.productRating),
          r.comment ?? '—',
          _dateTime(r.createdAt),
        ],
    ],
  );
}

ReportTable _deliveryOrders(List<Map<String, dynamic>> orders, Money fmt) {
  final live = orders.where((o) => !_cancelled(o)).toList();
  final sales = live.fold<double>(0, (sum, o) => sum + _total(o));
  final fees = live.fold<double>(
      0, (sum, o) => sum + _num(o['delivery_fee']).toDouble());
  return ReportTable(
    title: ReportKind.deliveryOrders.label,
    summary: [
      ReportStat('عدد الطلبات', '${orders.length}'),
      ReportStat('إجمالي المبيعات', fmt(sales)),
      ReportStat('رسوم التوصيل', fmt(fees)),
      ReportStat('مكتمل', '${orders.where(_delivered).length}'),
      ReportStat('ملغي', '${orders.where(_cancelled).length}'),
    ],
    columns: const [
      ReportColumn('رقم الطلب', width: 90),
      ReportColumn('الوقت', width: 140),
      ReportColumn('العميل', width: 150),
      ReportColumn('الهاتف', width: 120),
      ReportColumn('العنوان', width: 220),
      ReportColumn('المتلقي', width: 110),
      ReportColumn('المحضر', width: 110),
      ReportColumn('الطيار', width: 110),
      ReportColumn('الحالة', width: 90),
      ReportColumn('رسوم التوصيل', width: 110),
      ReportColumn('الإجمالي', width: 110),
    ],
    rows: [
      for (final o in orders)
        [
          _shortId(o['id']),
          _dateTime(_time(o['created_at'])),
          _text(o['customer_name']) ?? '—',
          _text(o['customer_phone']) ?? '—',
          _text(o['address_details']) ?? '—',
          _text(o['taker_name']) ??
              (o['order_source'] == 'phone' ? '—' : 'التطبيق'),
          _text(o['preparer_name']) ?? '—',
          _text(o['driver_name']) ?? '—',
          reportStatusName(o['status']),
          fmt(_num(o['delivery_fee'])),
          fmt(_total(o)),
        ],
    ],
  );
}

ReportTable _deliveryItems(
  List<Map<String, dynamic>> orders,
  List<Map<String, dynamic>> items,
  Money fmt,
) {
  final liveIds = {
    for (final o in orders)
      if (!_cancelled(o)) '${o['id']}',
  };

  final lines = <String, _ItemTotals>{};
  for (final row in items) {
    if (!liveIds.contains('${row['order_id']}')) continue;
    final product = switch (row['products']) {
      final Map<String, dynamic> map => map,
      [final Map<String, dynamic> first, ...] => first,
      _ => null,
    };
    final name = _text(product?['name']) ?? 'منتج محذوف';
    final barcode = _text(product?['barcode']) ?? '${row['product_id'] ?? ''}';
    final key = '$barcode|$name';
    final totals = lines.putIfAbsent(key, () => _ItemTotals(name, barcode));
    final quantity = _num(row['quantity']);
    final grams = _num(row['weight_in_grams']);
    totals.orders.add('${row['order_id']}');
    if (grams > 0) {
      totals.grams += grams * (quantity == 0 ? 1 : quantity);
    } else {
      totals.quantity += quantity;
    }
    totals.value += _num(row['price_at_time']).toDouble() * quantity;
  }

  final sorted = lines.values.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final quantity = sorted.fold<num>(0, (s, l) => s + l.quantity);
  final value = sorted.fold<double>(0, (s, l) => s + l.value);

  return ReportTable(
    title: ReportKind.deliveryItems.label,
    summary: [
      ReportStat('عدد الأصناف', '${sorted.length}'),
      ReportStat('إجمالي الكميات', _trim(quantity)),
      ReportStat('إجمالي القيمة', fmt(value)),
      ReportStat('عدد الطلبات', '${liveIds.length}'),
    ],
    columns: const [
      ReportColumn('الصنف', width: 240),
      ReportColumn('الباركود', width: 140),
      ReportColumn('عدد الطلبات', width: 100),
      ReportColumn('الكمية', width: 90),
      ReportColumn('الوزن (كجم)', width: 100),
      ReportColumn('القيمة', width: 120),
    ],
    rows: [
      for (final l in sorted)
        [
          l.name,
          l.barcode.isEmpty ? '—' : l.barcode,
          '${l.orders.length}',
          l.quantity == 0 ? '—' : _trim(l.quantity),
          l.grams == 0 ? '—' : (l.grams / 1000).toStringAsFixed(2),
          fmt(l.value),
        ],
    ],
  );
}

class _ItemTotals {
  _ItemTotals(this.name, this.barcode);

  final String name;
  final String barcode;
  final orders = <String>{};
  num quantity = 0;
  num grams = 0;
  double value = 0;
}

String _trim(num value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

/// Groups [orders] by [keyOf] (null keys are skipped).
Map<String, List<Map<String, dynamic>>> _groupBy(
  List<Map<String, dynamic>> orders,
  String? Function(Map<String, dynamic> order) keyOf,
) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final order in orders) {
    final key = keyOf(order);
    if (key != null) groups.putIfAbsent(key, () => []).add(order);
  }
  return groups;
}

double _sales(Iterable<Map<String, dynamic>> orders) =>
    orders.where((o) => !_cancelled(o)).fold<double>(0, (s, o) => s + _total(o));

ReportTable _receivers(List<Map<String, dynamic>> orders, Money fmt) {
  final groups = _groupBy(orders, (o) => _text(o['taker_name']));
  final entries = groups.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  final taken = groups.values.fold<int>(0, (s, l) => s + l.length);
  return ReportTable(
    title: ReportKind.receivers.label,
    summary: [
      ReportStat('عدد المتلقين', '${groups.length}'),
      ReportStat('الطلبات المستلمة', '$taken'),
      ReportStat('إجمالي المبيعات',
          fmt(groups.values.fold<double>(0, (s, l) => s + _sales(l)))),
    ],
    columns: const [
      ReportColumn('المتلقي', width: 180),
      ReportColumn('عدد الطلبات', width: 110),
      ReportColumn('إجمالي المبيعات', width: 130),
      ReportColumn('متوسط الطلب', width: 120),
      ReportColumn('مكتمل', width: 90),
      ReportColumn('ملغي', width: 90),
    ],
    rows: [
      for (final e in entries)
        () {
          final live = e.value.where((o) => !_cancelled(o)).length;
          return [
            e.key,
            '${e.value.length}',
            fmt(_sales(e.value)),
            live == 0 ? '—' : fmt(_sales(e.value) / live),
            '${e.value.where(_delivered).length}',
            '${e.value.where(_cancelled).length}',
          ];
        }(),
    ],
  );
}

ReportTable _preparers(
  List<Map<String, dynamic>> orders,
  Money fmt,
  DateTime now,
) {
  final groups = _groupBy(orders, (o) => _text(o['preparer_name']));
  final entries = groups.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  Duration? prepTime(Map<String, dynamic> o) {
    final created = _time(o['created_at']);
    final done = _time(o['prep_completed_at']);
    if (created == null || done == null) return null;
    final d = done.difference(created);
    return d.isNegative ? Duration.zero : d;
  }

  bool late(Map<String, dynamic> o) {
    final took = prepTime(o);
    if (took != null) return took > PrepCountdown.total;
    return orderIsDelayed(o, now: now);
  }

  final all = groups.values.expand((l) => l).toList();
  return ReportTable(
    title: ReportKind.preparers.label,
    summary: [
      ReportStat('عدد المحضرين', '${groups.length}'),
      ReportStat('الطلبات المحضّرة', '${all.length}'),
      ReportStat('متوسط زمن التجهيز',
          _minutes(_average([for (final o in all) prepTime(o)]))),
      ReportStat('متأخر', '${all.where(late).length}'),
    ],
    columns: const [
      ReportColumn('المحضر', width: 180),
      ReportColumn('عدد الطلبات', width: 110),
      ReportColumn('إجمالي قيمة الطلبات', width: 150),
      ReportColumn('تم تجهيزها', width: 100),
      ReportColumn('متوسط زمن التجهيز', width: 140),
      ReportColumn('متأخر', width: 90),
    ],
    rows: [
      for (final e in entries)
        [
          e.key,
          '${e.value.length}',
          fmt(_sales(e.value)),
          '${e.value.where((o) => o['prep_completed_at'] != null).length}',
          _minutes(_average([for (final o in e.value) prepTime(o)])),
          '${e.value.where(late).length}',
        ],
    ],
  );
}

ReportTable _drivers(List<Map<String, dynamic>> orders, Money fmt) {
  final groups = _groupBy(orders, (o) => _text(o['driver_name']));
  final entries = groups.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  // `updated_at` of a delivered order is when it was closed.
  Duration? deliveryTime(Map<String, dynamic> o) {
    if (!_delivered(o)) return null;
    final created = _time(o['created_at']);
    final closed = _time(o['updated_at']);
    if (created == null || closed == null) return null;
    final d = closed.difference(created);
    return d.isNegative ? null : d;
  }

  final all = groups.values.expand((l) => l).toList();
  final delivered = all.where(_delivered).toList();
  return ReportTable(
    title: ReportKind.drivers.label,
    summary: [
      ReportStat('عدد الطيارين', '${groups.length}'),
      ReportStat('الطلبات المسندة', '${all.length}'),
      ReportStat('تم تسليمها', '${delivered.length}'),
      ReportStat('إجمالي المحصّل',
          fmt(delivered.fold<double>(0, (s, o) => s + _total(o)))),
    ],
    columns: const [
      ReportColumn('الطيار', width: 180),
      ReportColumn('الطلبات المسندة', width: 120),
      ReportColumn('تم تسليمها', width: 100),
      ReportColumn('ملغي', width: 90),
      ReportColumn('إجمالي المحصّل', width: 130),
      ReportColumn('رسوم التوصيل', width: 120),
      ReportColumn('متوسط الزمن حتى التسليم', width: 170),
    ],
    rows: [
      for (final e in entries)
        () {
          final done = e.value.where(_delivered).toList();
          return [
            e.key,
            '${e.value.length}',
            '${done.length}',
            '${e.value.where(_cancelled).length}',
            fmt(done.fold<double>(0, (s, o) => s + _total(o))),
            fmt(done.fold<double>(
                0, (s, o) => s + _num(o['delivery_fee']).toDouble())),
            _minutes(_average([for (final o in done) deliveryTime(o)])),
          ];
        }(),
    ],
  );
}

ReportTable _followUp(List<Map<String, dynamic>> orders, DateTime now) {
  int count(OrderStatus status) => orders
      .where((o) =>
          OrderStatus.normalize('${o['status'] ?? ''}') == status.value)
      .length;
  final delayed = orders.where((o) => orderIsDelayed(o, now: now)).length;

  String elapsed(Map<String, dynamic> o) {
    final created = _time(o['created_at']);
    if (created == null) return '—';
    if (_cancelled(o)) return '—';
    if (_delivered(o)) {
      final closed = _time(o['updated_at']);
      return closed == null ? '—' : _minutes(closed.difference(created));
    }
    return _minutes(now.difference(created));
  }

  return ReportTable(
    title: ReportKind.followUp.label,
    summary: [
      ReportStat('الإجمالي', '${orders.length}'),
      ReportStat('جديد', '${count(OrderStatus.pending)}'),
      ReportStat('تحضير', '${count(OrderStatus.preparing)}'),
      ReportStat('للطيار', '${count(OrderStatus.readyForDelivery)}'),
      ReportStat('توصيل', '${count(OrderStatus.outForDelivery)}'),
      ReportStat('مكتمل', '${count(OrderStatus.delivered)}'),
      ReportStat('ملغي', '${count(OrderStatus.cancelled)}'),
      ReportStat('متأخر', '$delayed'),
    ],
    columns: const [
      ReportColumn('رقم الطلب', width: 90),
      ReportColumn('الوقت', width: 140),
      ReportColumn('العميل', width: 150),
      ReportColumn('الحالة', width: 90),
      ReportColumn('المنقضي', width: 100),
      ReportColumn('التأخير', width: 90),
      ReportColumn('المحضر', width: 110),
      ReportColumn('الطيار', width: 110),
    ],
    rows: [
      for (final o in orders)
        [
          _shortId(o['id']),
          _dateTime(_time(o['created_at'])),
          _text(o['customer_name']) ?? '—',
          reportStatusName(o['status']),
          elapsed(o),
          orderIsDelayed(o, now: now) ? 'متأخر' : '—',
          _text(o['preparer_name']) ?? '—',
          _text(o['driver_name']) ?? '—',
        ],
    ],
  );
}

ReportTable _customers(List<Map<String, dynamic>> orders, Money fmt) {
  final groups = _groupBy(
    orders,
    (o) =>
        _text(o['customer_phone']) ??
        _text(o['user_id']) ??
        _text(o['customer_name']),
  );
  final entries = groups.entries.toList()
    ..sort((a, b) => _sales(b.value).compareTo(_sales(a.value)));

  String nameOf(List<Map<String, dynamic>> list) {
    for (final o in list) {
      if (_text(o['customer_name']) case final name?) return name;
    }
    return '—';
  }

  return ReportTable(
    title: ReportKind.customers.label,
    summary: [
      ReportStat('عدد العملاء', '${groups.length}'),
      ReportStat('عدد الطلبات', '${orders.length}'),
      ReportStat('إجمالي المشتريات', fmt(_sales(orders))),
    ],
    columns: const [
      ReportColumn('العميل', width: 180),
      ReportColumn('الهاتف', width: 130),
      ReportColumn('عدد الطلبات', width: 100),
      ReportColumn('إجمالي المشتريات', width: 140),
      ReportColumn('متوسط الطلب', width: 120),
      ReportColumn('ملغي', width: 80),
      ReportColumn('آخر طلب', width: 140),
    ],
    rows: [
      for (final e in entries)
        () {
          final live = e.value.where((o) => !_cancelled(o)).toList();
          final last = e.value
              .map((o) => _time(o['created_at']))
              .whereType<DateTime>()
              .fold<DateTime?>(
                  null, (a, b) => a == null || b.isAfter(a) ? b : a);
          return [
            nameOf(e.value),
            _text(e.value.first['customer_phone']) ?? '—',
            '${live.length}',
            fmt(_sales(e.value)),
            live.isEmpty ? '—' : fmt(_sales(e.value) / live.length),
            '${e.value.where(_cancelled).length}',
            _dateTime(last),
          ];
        }(),
    ],
  );
}
