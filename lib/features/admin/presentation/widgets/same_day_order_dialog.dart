import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// Result of the same-day repeat-order prompt.
enum SameDayOrderKind { fresh, supplemental }

/// «هذا العميل لديه طلب سابق اليوم… طلب جديد أم ملحق؟»
Future<SameDayOrderKind?> showSameDayOrderDialog(BuildContext context) {
  return showDialog<SameDayOrderKind>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final palette = ctx.palette;
      return AlertDialog(
        key: const Key('same-day-order-dialog'),
        backgroundColor: palette.card,
        title: const Text(
          'طلب سابق اليوم',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'هذا العميل لديه طلب سابق اليوم، هل هذا الطلب جديد أم ملحق للطلب السابق؟',
          style: TextStyle(height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            key: const Key('same-day-order-cancel'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: const Key('same-day-order-fresh'),
            onPressed: () => Navigator.pop(ctx, SameDayOrderKind.fresh),
            child: const Text(
              'طلب جديد',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            key: const Key('same-day-order-supplemental'),
            onPressed: () => Navigator.pop(ctx, SameDayOrderKind.supplemental),
            child: const Text(
              'طلب ملحق',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    },
  );
}
