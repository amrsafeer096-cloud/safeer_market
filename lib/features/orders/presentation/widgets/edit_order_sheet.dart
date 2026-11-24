import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../admin/domain/product_search_filter.dart';
import '../../../admin/presentation/widgets/staff_product_search_tile.dart';
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
  var _filter = ProductSearchFilterMode.inStock;
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
        final hits = await _service.searchCatalog(
          value,
          filter: _filter,
        );
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
            imageUrl: product.imageUrl,
            listPrice: product.hasActiveOffer ? product.price : null,
            stockQuantity: product.stockQuantity,
            unitPrice: product.effectivePrice,
            quantity: 1,
          ),
        );
      }
    });
  }

  void _removeOne(String productId) {
    final i = _lines.indexWhere((l) => l.productId == productId);
    if (i < 0) return;
    setState(() {
      if (_lines[i].quantity <= 1) {
        _lines.removeAt(i);
      } else {
        _lines[i].quantity -= 1;
      }
    });
  }

  int _qtyOf(String productId) {
    for (final line in _lines) {
      if (line.productId == productId) return line.quantity;
    }
    return 0;
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        TextField(
          key: const Key('edit-order-search'),
          controller: _search,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'بحث بالاسم أو الباركود',
            prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
            suffixIcon: ProductSearchFilterButton(
              mode: _filter,
              onChanged: (mode) {
                setState(() => _filter = mode);
                _onSearchChanged(_search.text);
              },
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (_hits.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'نتائج البحث',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 4),
          for (final product in _hits) ...[
            StaffProductSearchTile(
              product: product,
              quantityLabel: '${_qtyOf(product.id)}',
              inCart: _qtyOf(product.id) > 0,
              showZeroStockInRed:
                  _filter == ProductSearchFilterMode.allItems,
              onAdd: () => _addProduct(product),
              onRemove: () => _removeOne(product.id),
            ),
            const Divider(height: 1, indent: 12),
          ],
          const SizedBox(height: 12),
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
          )
        else
          for (final line in _lines)
            _OrderLineAsProductTile(
              line: line,
              onAdd: () => setState(() => line.quantity += 1),
              onRemove: () => _removeOne(line.productId),
            ),
      ],
    );
  }
}

/// Existing cart line rendered with the same staff product tile chrome.
class _OrderLineAsProductTile extends StatelessWidget {
  const _OrderLineAsProductTile({
    required this.line,
    required this.onAdd,
    required this.onRemove,
  });

  final OrderEditLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return StaffProductSearchTile(
      product: line.toProduct(),
      quantityLabel: '${line.quantity}',
      inCart: true,
      onAdd: onAdd,
      onRemove: onRemove,
    );
  }
}
