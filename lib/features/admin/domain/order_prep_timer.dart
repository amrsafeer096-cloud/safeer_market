import 'entities/order_status.dart';

/// Sentinel for the status filter: new/preparing orders over [PrepCountdown.total].
const delayedOrderFilter = '__delayed__';

/// The colour band of the prep countdown bar.
enum PrepBand {
  /// 20:00 → 10:00 left.
  green,

  /// 10:00 → 05:00 left.
  yellow,

  /// 05:00 → 00:00 left.
  lightRed,

  /// Past 20 minutes: overtime.
  overdue,
}

/// The 20-minute prep clock of an order, from its `created_at`.
class PrepCountdown {
  const PrepCountdown._(this.elapsed);

  /// Time since the order was placed (never negative).
  factory PrepCountdown.since(DateTime createdAt, DateTime now) {
    final elapsed = now.difference(createdAt);
    return PrepCountdown._(elapsed.isNegative ? Duration.zero : elapsed);
  }

  static const total = Duration(minutes: 20);

  final Duration elapsed;

  /// Seconds left; negative once the order is late.
  int get remainingSeconds => total.inSeconds - elapsed.inSeconds;

  bool get isOverdue => remainingSeconds < 0;

  PrepBand get band {
    final seconds = elapsed.inSeconds;
    if (isOverdue) return PrepBand.overdue;
    if (seconds < 10 * 60) return PrepBand.green;
    if (seconds < 15 * 60) return PrepBand.yellow;
    return PrepBand.lightRed;
  }

  /// How much of the bar is filled: the time left, or all of it when late.
  double get fraction =>
      isOverdue ? 1 : remainingSeconds / total.inSeconds;

  /// `MM:SS` left, or `-MM:SS` of overtime.
  String get label {
    final seconds = remainingSeconds.abs();
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '${isOverdue ? '-' : ''}$minutes:$rest';
  }
}

DateTime? _createdAt(Map<String, dynamic> order) =>
    DateTime.tryParse('${order['created_at'] ?? ''}');

/// Whether the prep clock is running for [order]: new or preparing and the
/// prep not yet completed.
bool orderRunsPrepClock(Map<String, dynamic> order) {
  final status = OrderStatus.normalize('${order['status'] ?? ''}');
  if (status != OrderStatus.pending.value &&
      status != OrderStatus.preparing.value) {
    return false;
  }
  if (order['prep_completed_at'] != null) return false;
  return _createdAt(order) != null;
}

/// The countdown of [order], or null when its clock isn't running.
PrepCountdown? orderPrepCountdown(Map<String, dynamic> order, DateTime now) {
  if (!orderRunsPrepClock(order)) return null;
  return PrepCountdown.since(_createdAt(order)!, now);
}

/// New/preparing for more than 20 minutes: listed under «متأخر».
bool orderIsDelayed(Map<String, dynamic> order, {DateTime? now}) =>
    orderPrepCountdown(order, now ?? DateTime.now())?.isOverdue ?? false;

/// Whether [order] belongs to the status filter [filter] (null = all, the
/// [delayedOrderFilter] sentinel, or a status value in either spelling).
bool orderMatchesFilter(
  Map<String, dynamic> order,
  String? filter, {
  DateTime? now,
}) {
  if (filter == null) return true;
  if (filter == delayedOrderFilter) return orderIsDelayed(order, now: now);
  return OrderStatus.normalize('${order['status'] ?? ''}') ==
      OrderStatus.normalize(filter);
}
