import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer_order.dart';

/// Human-readable label for a stored [OrderCancellationReason] value, or
/// the raw text when an older row still holds the Arabic sentence.
String cancellationReasonLabel(AppLocalizations l10n, String? reason) {
  final known = OrderCancellationReason.fromValue(reason);
  if (known != null) return known.label(l10n);
  final text = reason?.trim();
  return text == null || text.isEmpty ? l10n.notSpecified : text;
}

extension OrderCancellationReasonLabel on OrderCancellationReason {
  String label(AppLocalizations l10n) => switch (this) {
        OrderCancellationReason.deliveryDelay => l10n.cancelReasonDeliveryDelay,
        OrderCancellationReason.orderedByMistake =>
          l10n.cancelReasonOrderedByMistake,
        OrderCancellationReason.changedMind => l10n.cancelReasonChangedMind,
        OrderCancellationReason.other => l10n.cancelReasonOther,
      };
}

/// Asks why the customer is cancelling; resolves to the reason, or null
/// when they dismiss.
Future<OrderCancellationReason?> showCancelOrderDialog(
  BuildContext context,
) {
  return showDialog<OrderCancellationReason>(
    context: context,
    builder: (dialogContext) => const _CancelOrderDialog(),
  );
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog();

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  OrderCancellationReason? _reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        l10n.cancelOrderConfirmTitle,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cancelOrderReasonPrompt,
              style: TextStyle(fontSize: 14, color: palette.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            RadioGroup<OrderCancellationReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in OrderCancellationReason.values)
                    RadioListTile<OrderCancellationReason>(
                      key: Key('cancel-reason-${reason.value}'),
                      value: reason,
                      title: Text(
                        reason.label(l10n),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      activeColor: AppColors.secondary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-order-dismiss'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelOrderDismiss),
        ),
        FilledButton(
          key: const Key('cancel-order-confirm'),
          onPressed:
              _reason == null ? null : () => Navigator.of(context).pop(_reason),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: Text(l10n.cancelOrderConfirm),
        ),
      ],
    );
  }
}
