import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../home/domain/entities/product.dart';
import '../../data/order_edit_service.dart';
import '../../domain/order_editability.dart';

/// Opens live order editing. Sets `is_being_edited` while open.
Future<bool> showEditOrderSheet(
  BuildContext context, {
  required String orderId,
  required String startedBy,
  double deliveryFee = 0,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => EditOrderSheet(
      orderId: orderId,
      startedBy: startedBy,
      deliveryFee: deliveryFee,
    ),
  );
  return result == true;
}

class EditOrderSheet extends ConsumerStatefulWidget {
  const EditOrderSheet({
    super.key,
    required this.orderId,
    required this.startedBy,
    this.deliveryFee = 0,
  });

  final String orderId;
  final String startedBy;
  final double deliveryFee;

  @override
  ConsumerState<EditOrderSheet> createState() => _EditOrderSheetState();
}

class _EditOrderSheetState extends ConsumerState<EditOrderSheet> {
  final _search = TextEditingController();
  final _lines = <OrderEditLine>[];
  var _loading = true;
  var _saving = false;
  var _lockHeld = false;
  Object? _error;
  List<Product> _hits = const [];
  Timer? _debounce;

  OrderEditService get _service => ref.read(orderEditServiceProvider);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    if (_lockHeld && !_saving) {
      unawaited(_service.cancelEdit(widget.orderId));
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.beginEdit(
        orderId: widget.orderId,
        startedBy: widget.startedBy,
      );
      _lockHeld = true;
      final items = await _service.fetchEditableItems(widget.orderId);
      if (!mounted) return;
      setState(() {
        _lines
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  double get _itemsTotal =>
      _lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  double get _grandTotal => _itemsTotal + widget.deliveryFee;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      try {
        final hits = await _service.searchCatalog(value);
        if (!mounted) return;
        setState(() => _hits = hits);
      } catch (_) {
        if (!mounted) return;
        setState(() => _hits = const []);
      }
    });
  }

  void _addProduct(Product product) {
    final existing = _lines.indexWhere((l) => l.productId == product.id);
    setState(() {
      if (existing >= 0) {
        _lines[existing].quantity += 1;
      } else {
        _lines.add(
          OrderEditLine(
            productId: product.id,
            productName: product.name,
            barcode: product.barcode,
            unitPrice: product.effectivePrice,
            quantity: 1,
          ),
        );
      }
      _hits = const [];
      _search.clear();
    });
  }

  Future<void> _closeWithoutSave() async {
    if (_saving) return;
    try {
      if (_lockHeld) {
        await _service.cancelEdit(widget.orderId);
        _lockHeld = false;
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _confirm() async {
    if (_saving) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('يجب أن يحتوي الطلب على صنف واحد على الأقل'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.applyEdit(orderId: widget.orderId, lines: _lines);
      _lockHeld = false;
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('تعذّر حفظ التعديلات: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _closeWithoutSave();
      },
      child: SizedBox(
        height: height,
        child: Material(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تعديل الطلب',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : _closeWithoutSave,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _body(palette)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الأصناف: ${AppCurrency.of(_itemsTotal)}  •  '
                        'التوصيل: ${AppCurrency.of(widget.deliveryFee)}  •  '
                        'الإجمالي: ${AppCurrency.of(_grandTotal)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const Key('confirm-order-edits'),
                        onPressed: (_saving || _loading) ? null : _confirm,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('تأكيد التعديلات'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppPalette palette) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعذّر فتح التعديل:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _bootstrap,
                child: const Text('إعادة المحاولة'),
              ),
              const SizedBox(height: 8),
              Text(
                'شغّل في Supabase:\n'
                '20261124020000_order_live_editing_and_fujitsu_item_sync.sql',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          key: const Key('edit-order-search'),
          controller: _search,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'بحث لإضافة منتج',
            hintText: 'اسم أو باركود',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        if (_hits.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final product in _hits)
            ListTile(
              dense: true,
              title: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(AppCurrency.of(product.effectivePrice)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_rounded,
                    color: AppColors.success),
                onPressed: () => _addProduct(product),
              ),
            ),
          const Divider(height: 24),
        ],
        const Text(
          'أصناف الطلب',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (_lines.isEmpty)
          Text(
            'لا توجد أصناف — أضف منتجاً من البحث',
            style: TextStyle(color: palette.muted),
          ),
        for (var i = 0; i < _lines.length; i++)
          _EditLineTile(
            line: _lines[i],
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _lines.removeAt(i)),
          ),
      ],
    );
  }
}

class _EditLineTile extends StatelessWidget {
  const _EditLineTile({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final OrderEditLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                ),
              ],
            ),
            Text(
              '${AppCurrency.of(line.unitPrice)} × ${line.quantity} = ${AppCurrency.of(line.lineTotal)}',
              style: TextStyle(color: palette.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () {
                    if (line.quantity <= 1) {
                      onRemove();
                      return;
                    }
                    line.quantity -= 1;
                    onChanged();
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${line.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    line.quantity += 1;
                    onChanged();
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
