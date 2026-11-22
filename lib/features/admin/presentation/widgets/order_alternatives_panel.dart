import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../data/order_alternatives_service.dart';
import '../../domain/order_item_alternative.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../providers/admin_providers.dart';
import '../providers/order_alternatives_providers.dart';

/// Pending alternative suggestions for an order — used by customers (app)
/// and by taker/admin (phone orders).
class OrderAlternativesPanel extends ConsumerWidget {
  const OrderAlternativesPanel({
    super.key,
    required this.orderId,
    this.forStaff = false,
    this.customerPhone,
  });

  final String orderId;

  /// When true, copy emphasises calling the customer.
  final bool forStaff;
  final String? customerPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingOrderAlternativesProvider(orderId));
    return pending.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final alt in items)
              _AlternativeCard(
                alternative: alt,
                forStaff: forStaff,
                customerPhone: customerPhone,
              ),
          ],
        );
      },
    );
  }
}

class _AlternativeCard extends ConsumerStatefulWidget {
  const _AlternativeCard({
    required this.alternative,
    required this.forStaff,
    this.customerPhone,
  });

  final OrderItemAlternative alternative;
  final bool forStaff;
  final String? customerPhone;

  @override
  ConsumerState<_AlternativeCard> createState() => _AlternativeCardState();
}

class _AlternativeCardState extends ConsumerState<_AlternativeCard> {
  String? _busyProductId;
  var _removing = false;

  Future<void> _select(AlternativeProduct product) async {
    if (_busyProductId != null || _removing) return;
    setState(() => _busyProductId = product.productId);
    try {
      await ref.read(orderAlternativesServiceProvider).selectAlternative(
            alternativeId: widget.alternative.id,
            productId: product.productId,
          );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استبدال المنتج بالبديل المختار'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on OrderAlternativesFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  Future<void> _remove() async {
    if (_busyProductId != null || _removing) return;
    setState(() => _removing = true);
    try {
      await ref
          .read(orderAlternativesServiceProvider)
          .removeOriginalItem(alternativeId: widget.alternative.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المنتج من الطلب'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on OrderAlternativesFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  void _refresh() {
    final orderId = widget.alternative.orderId;
    ref.invalidate(orderAlternativesProvider(orderId));
    ref.invalidate(pendingOrderAlternativesProvider(orderId));
    ref.invalidate(pendingAlternativeOrderIdsProvider);
    ref.invalidate(adminOrderItemsProvider(orderId));
    ref.invalidate(customerOrderItemsProvider(orderId));
    ref.invalidate(myOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final alt = widget.alternative;
    final phone = widget.customerPhone?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded,
                  color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.forStaff
                      ? 'بدائل بانتظار قرار العميل'
                      : 'منتج غير متوفر — اختر بديلاً',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            ],
          ),
          if (widget.forStaff) ...[
            const SizedBox(height: 6),
            Text(
              phone != null && phone.isNotEmpty
                  ? 'اتصل بالعميل ($phone) واختر البديل نيابة عنه'
                  : 'اتصل بالعميل واختر البديل نيابة عنه',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final product in alt.suggestedProducts)
            _SuggestionTile(
              product: product,
              busy: _busyProductId == product.productId,
              enabled: _busyProductId == null && !_removing,
              onSelect: () => _select(product),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _busyProductId != null || _removing ? null : _remove,
            icon: _removing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: const Text('حذف المنتج من الطلب'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.product,
    required this.busy,
    required this.enabled,
    required this.onSelect,
  });

  final AlternativeProduct product;
  final bool busy;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: enabled ? onSelect : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: ProductImage(imageUrl: product.imageUrl, iconSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  if (product.barcode != null && product.barcode!.isNotEmpty)
                    Text(
                      product.barcode!,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    AppCurrency.of(product.price),
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FilledButton(
                onPressed: enabled ? onSelect : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'اختيار',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
