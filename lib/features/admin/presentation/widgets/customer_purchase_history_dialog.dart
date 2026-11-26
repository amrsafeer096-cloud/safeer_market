import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../cart/presentation/widgets/weight_picker_sheet.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../domain/phone_order.dart';
import '../../domain/repositories/phone_orders_repository.dart';
import '../providers/phone_order_providers.dart';

/// «مشتريات العميل المعتادة والسابقة»: a centered dialog with the caller's
/// past purchases (date filter, most ordered) and their last order with a
/// quick re-order.
Future<void> showCustomerPurchaseHistoryDialog(
  BuildContext context,
  PhoneOrderCustomer customer,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => CustomerPurchaseHistoryDialog(customer: customer),
  );
}

enum _HistorySort { frequent, recent }

enum _DatePreset { all, week, month, custom }

class CustomerPurchaseHistoryDialog extends ConsumerStatefulWidget {
  const CustomerPurchaseHistoryDialog({super.key, required this.customer});

  final PhoneOrderCustomer customer;

  @override
  ConsumerState<CustomerPurchaseHistoryDialog> createState() =>
      _CustomerPurchaseHistoryDialogState();
}

class _CustomerPurchaseHistoryDialogState
    extends ConsumerState<CustomerPurchaseHistoryDialog> {
  _HistorySort _sort = _HistorySort.frequent;
  _DatePreset _preset = _DatePreset.all;
  DateTimeRange? _range;

  void _setPreset(_DatePreset preset) {
    final now = DateTime.now();
    setState(() {
      _preset = preset;
      _range = switch (preset) {
        _DatePreset.all || _DatePreset.custom => null,
        _DatePreset.week => DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
        _DatePreset.month => DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      };
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preset = _DatePreset.custom;
      _range = picked;
    });
  }

  List<CustomerPurchaseItem> _visible(CustomerPurchaseHistory history) {
    final items = _sort == _HistorySort.frequent
        ? history.mostFrequent
        : history.mostRecent;
    final range = _range;
    if (range == null) return items;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day)
        .add(const Duration(days: 1));
    return [
      for (final item in items)
        if (!item.lastOrderedAt.isBefore(start) &&
            item.lastOrderedAt.isBefore(end))
          item,
    ];
  }

  Future<void> _addProduct(Product product, {int? initialGrams}) async {
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    if (!product.isWeightBased) {
      controller.add(product);
      return;
    }
    final state = ref.read(phoneOrderControllerProvider);
    PhoneOrderLine? existing;
    for (final line in state.lines) {
      if (line.product.id == product.id) {
        existing = line;
        break;
      }
    }
    final pick = await showWeightPickerSheet(
      context,
      product: product,
      initialGrams: initialGrams ??
          existing?.weightInGrams ??
          state.weightOf(product.id),
      initialNotes: existing?.notes,
      title: 'اختر الوزن المطلوب',
      labelFor: WeightOptions.adminQuickPickLabel,
      fastAdminEntry: true,
    );
    if (pick == null || !mounted) return;
    controller.setWeight(product, pick.grams, notes: pick.notes);
  }

  void _addLastAmount(CustomerPurchaseItem item) {
    ref.read(phoneOrderControllerProvider.notifier).addFromHistory(
          item.product,
          lastQuantity: item.lastQuantity,
          lastWeightInGrams: item.lastWeightInGrams,
        );
  }

  void _repeatLastOrder(CustomerPurchaseHistory history) {
    if (history.lastOrderLines.isEmpty) return;
    ref
        .read(phoneOrderControllerProvider.notifier)
        .replaceLines(history.lastOrderLines);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'تم تحميل آخر طلب (${history.lastOrderLines.length} منتج)',
        ),
      ));
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final async = ref.watch(
      phoneOrderCustomerHistoryProvider(widget.customer.key),
    );

    return Dialog(
      key: const Key('phone-order-history-dialog'),
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مشتريات العميل المعتادة والسابقة',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        if (widget.customer.fullName case final name?)
                          Text(
                            name,
                            style:
                                TextStyle(fontSize: 12, color: palette.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) {
                  debugPrint('Customer purchase history failed: $error');
                  final detail = switch (error) {
                    PhoneOrderFailure(:final message) => message,
                    _ => '$error',
                  };
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      detail.contains('phone_order_customer_history') ||
                              detail.contains('PGRST202')
                          ? 'تعذّر تحميل مشتريات العميل — شغّل ترحيل phone_order_customer_history على Supabase'
                          : 'تعذّر تحميل مشتريات العميل',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted),
                    ),
                  );
                },
                data: _body,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  key: const Key('phone-order-history-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(CustomerPurchaseHistory history) {
    final palette = context.palette;
    if (history.isEmpty) {
      return Padding(
        key: const Key('phone-order-customer-history-empty'),
        padding: const EdgeInsets.all(32),
        child: Text(
          'لا توجد طلبات سابقة مسجلة لهذا العميل',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
        ),
      );
    }

    final items = _visible(history);
    final inCart = ref.watch(phoneOrderControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      shrinkWrap: true,
      children: [
        if (history.lastOrderLines.isNotEmpty) ...[
          const _SectionTitle('آخر طلب', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 6),
          _LastOrderCard(
            lines: history.lastOrderLines,
            onRepeat: () => _repeatLastOrder(history),
          ),
          const SizedBox(height: 16),
        ],
        const _SectionTitle('تصفية بتاريخ الطلبات السابقة',
            icon: Icons.event_rounded),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Chip(
              key: const Key('phone-order-history-date-all'),
              label: 'الكل',
              selected: _preset == _DatePreset.all,
              onTap: () => _setPreset(_DatePreset.all),
            ),
            _Chip(
              key: const Key('phone-order-history-date-week'),
              label: 'آخر 7 أيام',
              selected: _preset == _DatePreset.week,
              onTap: () => _setPreset(_DatePreset.week),
            ),
            _Chip(
              key: const Key('phone-order-history-date-month'),
              label: 'آخر 30 يوماً',
              selected: _preset == _DatePreset.month,
              onTap: () => _setPreset(_DatePreset.month),
            ),
            ActionChip(
              key: const Key('phone-order-history-date-custom'),
              avatar: const Icon(Icons.calendar_month_rounded, size: 16),
              label: Text(
                _preset == _DatePreset.custom && _range != null
                    ? '${_dateLabel(_range!.start)} - ${_dateLabel(_range!.end)}'
                    : 'تحديد فترة',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              onPressed: _pickRange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: _SectionTitle('الأكثر طلباً', icon: Icons.star_rounded),
            ),
            _Chip(
              key: const Key('phone-order-history-frequent'),
              label: 'الأكثر طلباً',
              selected: _sort == _HistorySort.frequent,
              onTap: () => setState(() => _sort = _HistorySort.frequent),
            ),
            const SizedBox(width: 6),
            _Chip(
              key: const Key('phone-order-history-recent'),
              label: 'آخر الطلبات',
              selected: _sort == _HistorySort.recent,
              onTap: () => setState(() => _sort = _HistorySort.recent),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'لا توجد مشتريات في هذه الفترة',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _HistoryRow(
                item: item,
                inCartLabel: _inCartLabel(inCart.lineOf(item.product.id)),
                onAdd: () => _addProduct(
                  item.product,
                  initialGrams: item.lastWeightInGrams,
                ),
                onAddLast: () => _addLastAmount(item),
              ),
            ),
      ],
    );
  }

  String? _inCartLabel(PhoneOrderLine? line) => switch (line) {
        null => null,
        PhoneOrderLine(:final weightInGrams?) =>
          'في السلة: ${WeightOptions.phoneOrderLabel(weightInGrams)}',
        PhoneOrderLine(:final quantity) => 'في السلة: $quantity',
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: palette.accent.withValues(alpha: 0.18),
      onSelected: (_) => onTap(),
    );
  }
}

/// The last order's lines, with «إعادة الطلب».
class _LastOrderCard extends StatelessWidget {
  const _LastOrderCard({required this.lines, required this.onRepeat});

  final List<PhoneOrderLine> lines;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = lines.fold<double>(0, (sum, line) => sum + line.total);
    return Container(
      key: const Key('phone-order-last-order'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  Text(
                    line.isWeightBased
                        ? WeightOptions.phoneOrderLabel(line.weightInGrams!)
                        : '×${line.quantity}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: palette.accent,
                    ),
                  ),
                  SizedBox(
                    width: 84,
                    child: Text(
                      AppCurrency.of(line.total),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الإجمالي: ${AppCurrency.of(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              FilledButton.icon(
                key: const Key('phone-order-repeat-last'),
                onPressed: onRepeat,
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text(
                  'إعادة الطلب',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.item,
    required this.inCartLabel,
    required this.onAdd,
    required this.onAddLast,
  });

  final CustomerPurchaseItem item;
  final String? inCartLabel;
  final VoidCallback onAdd;
  final VoidCallback onAddLast;

  String get _lastAmountLabel {
    if (item.lastWeightInGrams case final grams?) {
      return 'آخر مرة: ${WeightOptions.label(grams)}';
    }
    return 'آخر مرة: ${item.lastQuantity}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final product = item.product;
    final outOfStock = !product.inStock;

    return Material(
      color: palette.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('phone-order-history-row-${product.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: outOfStock ? null : onAdd,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 4, 6),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 62,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: const Color(0xFFFFFFFF),
                    child: Opacity(
                      opacity: outOfStock ? 0.45 : 1,
                      child: ProductImage(
                        imageUrl:
                            product.hasValidImageUrl ? product.imageUrl : null,
                        iconSize: 26,
                        fit: BoxFit.contain,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: outOfStock
                            ? palette.muted
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppCurrency.of(product.effectivePrice)} / ${product.displayUnit}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: outOfStock
                            ? palette.muted
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        _Badge(
                          text: 'طُلِب ${item.timesOrdered} مرات',
                          color: palette.accent,
                        ),
                        _Badge(text: _lastAmountLabel, color: palette.muted),
                        if (inCartLabel != null)
                          _Badge(text: inCartLabel!, color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton(
                    key: Key('phone-order-history-add-${product.id}'),
                    onPressed: outOfStock ? null : onAdd,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 30),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('+ إضافة'),
                  ),
                  TextButton(
                    key: Key('phone-order-history-last-${product.id}'),
                    onPressed: outOfStock ? null : onAddLast,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 24),
                      foregroundColor: palette.accent,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      item.isWeightBased || item.lastWeightInGrams != null
                          ? 'آخر وزن'
                          : 'آخر كمية',
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
