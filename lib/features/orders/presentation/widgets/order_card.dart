import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/domain/entities/order_status.dart';
import '../../../cart/domain/weight_options.dart';
import '../../domain/entities/customer_order.dart';
import '../providers/orders_providers.dart';
import 'cancel_order_dialog.dart';

class OrderStatusStyle {
  const OrderStatusStyle(
    this.label,
    this.shortLabel,
    this.color,
    this.icon, {
    this.step,
  });

  /// Full sentence shown as "حالة الطلب: …".
  final String label;

  /// Fits in the status chip.
  final String shortLabel;
  final Color color;
  final IconData icon;

  /// Reached step in [OrderProgress.steps]; null when the order left the
  /// normal flow (cancelled or an unknown status).
  final int? step;

  /// [status] may be snake_case (`out_for_delivery`) or the dashboard's
  /// camelCase (`outForDelivery`).
  static OrderStatusStyle of(
    String status,
    AppLocalizations l10n, {
    AppPalette palette = AppPalette.light,
  }) {
    switch (OrderStatus.normalize(status)) {
      case 'pending':
        return OrderStatusStyle(
          l10n.orderStatusReceivedLong,
          l10n.statusNew,
          const Color(0xFFEF6C00),
          Icons.receipt_long_rounded,
          step: 0,
        );
      case 'confirmed':
      case 'preparing':
        return OrderStatusStyle(
          l10n.orderStatusPreparingInWarehouse,
          l10n.orderStatusPreparing,
          palette.accent,
          Icons.inventory_2_outlined,
          step: 1,
        );
      case 'ready_for_delivery':
        return OrderStatusStyle(
          l10n.orderStatusAwaitingDriver,
          l10n.orderStatusReadyShort,
          // Deep tones vanish on dark cards: lighter tints there.
          palette.isDark ? const Color(0xFFCE93D8) : const Color(0xFF6A1B9A),
          Icons.shopping_bag_outlined,
          step: 2,
        );
      case 'shipped':
      case 'out_for_delivery':
        return OrderStatusStyle(
          l10n.orderOnTheWayToYou,
          l10n.orderStatusOutForDelivery,
          palette.isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
          Icons.delivery_dining_rounded,
          step: 3,
        );
      case 'delivered':
      case 'completed':
        return OrderStatusStyle(
          l10n.orderStatusDelivered,
          l10n.orderStatusDelivered,
          AppColors.success,
          Icons.check_circle_outline_rounded,
          step: 4,
        );
      case 'cancelled':
      case 'canceled':
        return OrderStatusStyle(
          l10n.orderStatusCancelled,
          l10n.orderStatusCancelled,
          AppColors.secondary,
          Icons.cancel_outlined,
        );
      default:
        return OrderStatusStyle(
          l10n.adminStatusUnknown,
          l10n.adminStatusUnknown,
          palette.muted,
          Icons.info_outline,
        );
    }
  }
}

/// One order in «طلباتي». Tapping it shows the progress, the tracking
/// button while it is on the way, the address and the products; any order
/// opens, whatever its status.
class OrderCard extends ConsumerStatefulWidget {
  const OrderCard({super.key, required this.order});

  final CustomerOrder order;

  @override
  ConsumerState<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<OrderCard> {
  /// Open from the start while the driver is on the way, so tracking is
  /// one tap away.
  late bool _expanded = widget.order.isOutForDelivery;

  @override
  void didUpdateWidget(OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The driver just left: show the tracking button.
    if (widget.order.isOutForDelivery && !oldWidget.order.isOutForDelivery) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat(
      'd MMMM yyyy • h:mm a',
      Localizations.localeOf(context).languageCode,
    )..useNativeDigits = false;
    final palette = context.palette;
    final status = OrderStatusStyle.of(order.status, l10n, palette: palette);

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      elevation: palette.isDark ? 0 : 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('order-card-${order.id}'),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderNumber(order.shortId),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.orderCardStatusLine(status.label),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(style: status),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.topCenter,
                child: _expanded
                    ? _OrderDetails(order: order, status: status)
                    : const SizedBox(width: double.infinity),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Text(
                    l10n.total,
                    style: TextStyle(fontSize: 14, color: palette.muted),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppCurrency.of(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _expanded
                          ? l10n.orderCardHideDetails
                          : l10n.orderCardShowDetails,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The expanded part of an [OrderCard]: progress, tracking, address,
/// products and — while the order is still new or being prepared — cancel.
class _OrderDetails extends ConsumerStatefulWidget {
  const _OrderDetails({required this.order, required this.status});

  final CustomerOrder order;
  final OrderStatusStyle status;

  @override
  ConsumerState<_OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends ConsumerState<_OrderDetails> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    if (_cancelling) return;
    final reason = await showCancelOrderDialog(context);
    if (reason == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    setState(() => _cancelling = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .cancelOrder(widget.order.id, reason);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(l10n.orderCancelledSuccess),
      ));
    } catch (error) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text(error.toString()),
      ));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = widget.status;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final address = order.addressDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        if (order.isCancelled)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(status.icon, color: status.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.orderCardCancelledNote,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: status.color,
                      ),
                    ),
                  ),
                ]),
                if (order.cancellationReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.cancellationReasonLine(
                      cancellationReasonLabel(l10n, order.cancellationReason),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          // Unknown statuses show the steps with none reached yet.
          OrderProgress(
            key: const Key('order-progress'),
            step: (status.step ?? -1).clamp(-1, OrderProgress.stepCount - 1),
            color: status.color,
          ),
        if (order.isOutForDelivery) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              key: Key('track-order-${order.id}'),
              onPressed: () => context.push(
                AppRoutes.orderTracking(
                  order.id,
                  latitude: order.deliveryLatitude,
                  longitude: order.deliveryLongitude,
                ),
              ),
              icon: const Icon(Icons.map_rounded),
              label: Text(l10n.orderCardTrackOnMap),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        if (address != null) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: palette.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l10n.orderCardItemsTitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: palette.accent,
          ),
        ),
        const SizedBox(height: 6),
        _OrderItems(orderId: order.id),
        if (order.canCancel) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              key: Key('cancel-order-${order.id}'),
              onPressed: _cancelling ? null : _cancel,
              icon: _cancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(l10n.cancelOrder),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrderItems extends ConsumerWidget {
  const _OrderItems({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final muted = TextStyle(fontSize: 13, color: palette.muted);

    return ref.watch(customerOrderItemsProvider(orderId)).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
          error: (_, __) => Row(children: [
            Expanded(child: Text(l10n.orderCardItemsFailed, style: muted)),
            TextButton(
              onPressed: () =>
                  ref.invalidate(customerOrderItemsProvider(orderId)),
              child: Text(l10n.retry),
            ),
          ]),
          data: (items) => items.isEmpty
              ? Text(l10n.orderCardNoItems, style: muted)
              : Column(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              constraints: const BoxConstraints(minWidth: 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                switch (item.weightInGrams) {
                                  final grams? => WeightOptions.label(grams),
                                  null => '×${item.quantity}',
                                },
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppCurrency.of(item.total),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
  }
}

/// Received → preparing → ready → on the way.
class OrderProgress extends StatelessWidget {
  const OrderProgress({super.key, required this.step, required this.color});

  static const stepCount = 4;

  static List<String> steps(AppLocalizations l10n) => [
        l10n.orderStepReceived,
        l10n.orderStepPreparing,
        l10n.orderStatusReadyShort,
        l10n.orderStatusOutForDelivery,
      ];

  /// Index of the current step in [steps].
  final int step;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final steps = OrderProgress.steps(AppLocalizations.of(context)!);
    final palette = context.palette;
    final idle = palette.muted.withValues(alpha: 0.25);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i <= step ? color : idle,
                  ),
                ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? color : palette.card,
                  border: Border.all(color: i <= step ? color : idle, width: 2),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Text(
                  steps[i],
                  textAlign: switch (i) {
                    0 => TextAlign.start,
                    _ when i == steps.length - 1 => TextAlign.end,
                    _ => TextAlign.center,
                  },
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == step ? FontWeight.w900 : FontWeight.w600,
                    color: i <= step ? color : palette.muted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});

  final OrderStatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 15, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.shortLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}
