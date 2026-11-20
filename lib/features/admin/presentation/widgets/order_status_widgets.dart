import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/order_prep_timer.dart';

/// Whether [LiveClock]s tick. Tests turn it off so no timer is left pending.
final adminClockTicksProvider = Provider<bool>((ref) => true);

/// Rebuilds [builder] every second with the current time while [active];
/// otherwise builds once with the time of the build.
class LiveClock extends ConsumerStatefulWidget {
  const LiveClock({super.key, required this.active, required this.builder});

  final bool active;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  ConsumerState<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends ConsumerState<LiveClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LiveClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final shouldTick = widget.active && ref.read(adminClockTicksProvider);
    if (shouldTick && _timer == null) {
      _now = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    } else if (!shouldTick && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _timer == null ? DateTime.now() : _now);
}

// ---------------------------------------------------------------- filters

/// One status filter tab.
class OrderFilterDef {
  const OrderFilterDef({
    required this.id,
    required this.label,
    required this.filter,
    required this.color,
  });

  /// Suffix of the tab's `filter-<id>` key.
  final String id;
  final String label;

  /// Value of the status filter: null (all), [delayedOrderFilter] or a status.
  final String? filter;
  final Color color;
}

const _neutralTab = Color(0xFF607D8B);

/// The order status tabs, in display order. Labels are given by the caller
/// (localized).
List<OrderFilterDef> orderFilterDefs({
  required String all,
  required String fresh,
  required String delayed,
  required String preparing,
  required String forDriver,
  required String delivery,
  required String completed,
  required String cancelled,
}) =>
    [
      OrderFilterDef(
          id: 'all', label: all, filter: null, color: _neutralTab),
      OrderFilterDef(
          id: 'pending',
          label: fresh,
          filter: 'pending',
          color: const Color(0xFF1E88E5)),
      OrderFilterDef(
          id: 'delayed',
          label: delayed,
          filter: delayedOrderFilter,
          color: const Color(0xFFE57373)),
      OrderFilterDef(
          id: 'preparing',
          label: preparing,
          filter: 'preparing',
          color: const Color(0xFFFB8C00)),
      OrderFilterDef(
          id: 'ready',
          label: forDriver,
          filter: 'readyForDelivery',
          color: const Color(0xFF8E24AA)),
      OrderFilterDef(
          id: 'delivery',
          label: delivery,
          filter: 'outForDelivery',
          color: const Color(0xFFFBC02D)),
      OrderFilterDef(
          id: 'delivered',
          label: completed,
          filter: 'delivered',
          color: const Color(0xFF43A047)),
      OrderFilterDef(
          id: 'cancelled',
          label: cancelled,
          filter: 'cancelled',
          color: _neutralTab),
    ];

/// Orders per tab of [defs] (the tab whose filter is null counts them all).
Map<String?, int> countOrdersByFilter(
  Iterable<Map<String, dynamic>> orders,
  Iterable<OrderFilterDef> defs, {
  DateTime? now,
}) {
  final list = orders.toList();
  return {
    for (final def in defs)
      def.filter: list
          .where((order) => orderMatchesFilter(order, def.filter, now: now))
          .length,
  };
}

Color _darker(Color color, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

Color _onColor(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF212121);

/// The colour-coded status tabs with the number of orders in each.
class OrderFilterTabs extends StatelessWidget {
  const OrderFilterTabs({
    super.key,
    required this.defs,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final List<OrderFilterDef> defs;
  final Map<String?, int> counts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final def in defs)
          _FilterTab(
            key: Key('filter-${def.id}'),
            def: def,
            count: counts[def.filter] ?? 0,
            isSelected: def.filter == selected,
            onTap: () => onSelected(def.filter),
          ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    super.key,
    required this.def,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final OrderFilterDef def;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = def.color;
    final foreground = isSelected ? _onColor(color) : _darker(color, 0.12);
    final badgeColor = isSelected ? _darker(color, 0.28) : _darker(color);

    return Material(
      color: isSelected ? color : color.withValues(alpha: 0.14),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: isSelected ? 1 : 0.55)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 12, end: 5, top: 5, bottom: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                def.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                key: Key('filter-count-${def.id}'),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- countdown

/// How urgent a prep countdown is, by the share of the 20 minutes left:
/// over half, 20–50 %, and under 20 % (or already late).
enum PrepTone { relaxed, warning, critical }

PrepTone prepToneOf(PrepCountdown countdown) {
  if (countdown.isOverdue) return PrepTone.critical;
  final left = countdown.remainingSeconds / PrepCountdown.total.inSeconds;
  if (left > 0.5) return PrepTone.relaxed;
  if (left >= 0.2) return PrepTone.warning;
  return PrepTone.critical;
}

/// The soft pastel behind an order card (never bright, so text stays legible).
Color prepFillColor(PrepTone tone, {bool dark = false}) {
  if (dark) {
    return switch (tone) {
      PrepTone.relaxed => Colors.green.withValues(alpha: 0.18),
      PrepTone.warning => Colors.amber.withValues(alpha: 0.18),
      PrepTone.critical => Colors.red.withValues(alpha: 0.2),
    };
  }
  return switch (tone) {
    PrepTone.relaxed => const Color(0xFFE8F5E9),
    PrepTone.warning => const Color(0xFFFFF8E1),
    PrepTone.critical => const Color(0xFFFFEBEE),
  };
}

/// Dark green / amber / red for the countdown digits.
Color prepTextColor(PrepTone tone, {bool dark = false}) {
  if (dark) {
    return switch (tone) {
      PrepTone.relaxed => const Color(0xFF81C784),
      PrepTone.warning => const Color(0xFFFFD54F),
      PrepTone.critical => const Color(0xFFEF9A9A),
    };
  }
  return switch (tone) {
    PrepTone.relaxed => const Color(0xFF1B5E20),
    PrepTone.warning => const Color(0xFF8A5A00),
    PrepTone.critical => const Color(0xFFB71C1C),
  };
}

/// The full-height pastel fill behind an order card's content. It starts
/// full, shrinks toward the start edge as the time runs out, and stays
/// full (in red) once the order is late.
class PrepCardFill extends StatelessWidget {
  const PrepCardFill({super.key, required this.countdown});

  final PrepCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AnimatedFractionallySizedBox(
        key: const Key('prep-card-fill'),
        duration: const Duration(milliseconds: 900),
        curve: Curves.linear,
        widthFactor: countdown.fraction.clamp(0.0, 1.0),
        heightFactor: 1,
        child: ColoredBox(
          color: prepFillColor(prepToneOf(countdown), dark: dark),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// `MM:SS` left (`-MM:SS` overtime) as plain bold numbers with a small
/// clock, coloured by urgency.
class PrepCountdownLabel extends StatelessWidget {
  const PrepCountdownLabel({super.key, required this.countdown});

  final PrepCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = prepTextColor(prepToneOf(countdown), dark: dark);
    return Row(
      key: const Key('prep-countdown'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          countdown.isOverdue ? Icons.alarm_on_rounded : Icons.timer_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 3),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            countdown.label,
            key: const Key('prep-countdown-label'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
