import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/order_status.dart';

DateFormat get adminDateFormat =>
    DateFormat('d MMM yyyy • h:mm a', L10n.localeName)..useNativeDigits = false;

String paymentMethodLabel(String? method) {
  final l10n = L10n.current;
  return switch (method) {
    'cash_on_delivery' => l10n.cashOnDelivery,
    'card' => l10n.bankCard,
    'visa' => l10n.adminPaidByVisa,
    'instapay' => l10n.paymentMethodInstaPayLabel,
    'wallet' => l10n.wallet,
    null || '' => l10n.notSpecified,
    final other => other,
  };
}

extension OrderStatusStyle on OrderStatus {
  String get label {
    final l10n = L10n.current;
    return switch (this) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.preparing => l10n.orderStatusPreparing,
      OrderStatus.readyForDelivery => l10n.orderStatusReadyForDelivery,
      OrderStatus.outForDelivery => l10n.orderStatusOutForDelivery,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
    };
  }

  Color get color => switch (this) {
        OrderStatus.pending => const Color(0xFFEF6C00),
        OrderStatus.preparing => AppColors.primary,
        OrderStatus.readyForDelivery => const Color(0xFF6A1B9A),
        OrderStatus.outForDelivery => const Color(0xFF1565C0),
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.secondary,
      };

  /// [color], with lighter tints of the deep tones on dark surfaces.
  Color colorOn(AppPalette palette) {
    if (!palette.isDark) return color;
    return switch (this) {
      OrderStatus.preparing => palette.accent,
      OrderStatus.readyForDelivery => const Color(0xFFCE93D8),
      OrderStatus.outForDelivery => const Color(0xFF64B5F6),
      _ => color,
    };
  }

  IconData get icon => switch (this) {
        OrderStatus.pending => Icons.schedule_rounded,
        OrderStatus.preparing => Icons.inventory_2_outlined,
        OrderStatus.readyForDelivery => Icons.shopping_bag_outlined,
        OrderStatus.outForDelivery => Icons.delivery_dining_rounded,
        OrderStatus.delivered => Icons.check_circle_outline_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  /// Raw `orders.status`; unknown values render in a neutral chip.
  final String status;

  @override
  Widget build(BuildContext context) {
    final known = OrderStatus.fromValue(status);
    final palette = context.palette;
    final color = known?.colorOn(palette) ?? palette.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(known?.icon ?? Icons.info_outline, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            known?.label ?? status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
