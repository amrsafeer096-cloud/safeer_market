import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../providers/orders_providers.dart';

/// Delivery + product quality rating after the order is delivered.
Future<bool> showRateOrderDialog(
  BuildContext context, {
  required String orderId,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _RateOrderDialog(orderId: orderId),
  );
  return saved == true;
}

class _RateOrderDialog extends ConsumerStatefulWidget {
  const _RateOrderDialog({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends ConsumerState<_RateOrderDialog> {
  int _delivery = 5;
  int _product = 5;
  final _comment = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _arabic =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(ordersRepositoryProvider).submitRating(
            orderId: widget.orderId,
            deliveryRating: _delivery,
            productRating: _product,
            comment: _comment.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = _arabic ? 'قيّم طلبك' : 'Rate your order';
    final deliveryLabel =
        _arabic ? 'خدمة التوصيل' : 'Delivery service';
    final productLabel =
        _arabic ? 'جودة المنتجات' : 'Product quality';
    final commentLabel =
        _arabic ? 'تعليق (اختياري)' : 'Comment (optional)';
    final submitLabel = _arabic ? 'إرسال التقييم' : 'Submit rating';
    final laterLabel = _arabic ? 'لاحقاً' : 'Later';

    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _arabic
                  ? 'نتمنى لك تجربة سعيدة! قيّم خدمة التوصيل وجودة المنتجات.'
                  : 'We hope you enjoyed it! Rate delivery and product quality.',
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            _StarRow(
              label: deliveryLabel,
              value: _delivery,
              onChanged: (v) => setState(() => _delivery = v),
            ),
            const SizedBox(height: 12),
            _StarRow(
              label: productLabel,
              value: _product,
              onChanged: (v) => setState(() => _product = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: commentLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(laterLabel),
        ),
        FilledButton(
          key: const Key('submit-order-rating'),
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                key: Key('star-$label-$i'),
                onPressed: () => onChanged(i),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 32,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
