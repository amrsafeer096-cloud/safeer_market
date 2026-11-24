import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/phone_order.dart';

/// Short labels for the final confirmation sheet.
String paymentConfirmLabel(PhoneOrderPayment method) => switch (method) {
      PhoneOrderPayment.cash => 'كاش عند الاستلام',
      PhoneOrderPayment.visaOnDelivery => 'فيزا',
      PhoneOrderPayment.instaPay => 'إنستا باي',
    };

/// Confirm / change payment method before «إتمام وتسجيل الطلب».
Future<PhoneOrderPayment?> showPaymentConfirmDialog(
  BuildContext context, {
  required PhoneOrderPayment current,
}) {
  return showDialog<PhoneOrderPayment>(
    context: context,
    builder: (ctx) => _PaymentConfirmDialog(current: current),
  );
}

class _PaymentConfirmDialog extends StatefulWidget {
  const _PaymentConfirmDialog({required this.current});

  final PhoneOrderPayment current;

  @override
  State<_PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<_PaymentConfirmDialog> {
  late PhoneOrderPayment _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      key: const Key('payment-confirm-dialog'),
      backgroundColor: palette.card,
      title: const Text(
        'تأكيد طريقة الدفع',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final method in PhoneOrderPayment.values)
            RadioListTile<PhoneOrderPayment>(
              key: Key('payment-confirm-${method.value}'),
              value: method,
              groupValue: _selected,
              onChanged: (v) {
                if (v != null) setState(() => _selected = v);
              },
              title: Text(
                paymentConfirmLabel(method),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('payment-confirm-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('payment-confirm-submit'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text(
            'تأكيد وتسجيل',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
