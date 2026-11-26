import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../admin/domain/product_search_filter.dart';
import '../../../admin/presentation/widgets/staff_product_search_tile.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../cart/presentation/widgets/weight_picker_sheet.dart';
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

  OrderEditLine? _lineOf(String productId) {
    for (final line in _lines) {
      if (line.productId == productId) return line;
    }
    return null;
  }

  String _qtyLabel(Product product) {
    final line = _lineOf(product.id);
    if (line == null) return '0';
    if (line.soldByWeight) {
      final grams = line.weightInGrams ?? 0;
      return grams > 0 ? WeightOptions.compactLabel(grams) : '0';
    }
    return '${line.quantity}';
  }

  Future<void> _addProduct(Product product) async {
    if (product.isWeightBased) {
      await _pickWeight(product);
      return;
    }
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
            isWeightBased: false,
            unit: product.unit,
          ),
        );
      }
    });
  }

  Future<void> _pickWeight(Product product) async {
    final existing = _lineOf(product.id);
    final grams = await showWeightPickerSheet(
      context,
      product: product,
      initialGrams: existing?.weightInGrams,
      title: 'اختر الوزن المطلوب',
      labelFor: WeightOptions.phoneOrderLabel,
    );
    if (grams == null || !mounted) return;
    setState(() {
      if (grams <= 0) {
        _lines.removeWhere((l) => l.productId == product.id);
        return;
      }
      if (existing != null) {
        existing
          ..weightInGrams = grams
          ..quantity = 1;
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
            weightInGrams: grams,
            isWeightBased: true,
            unit: Product.weightUnit,
          ),
        );
      }
    });
  }

  void _removeOne(String productId) {
    final i = _lines.indexWhere((l) => l.productId == productId);
    if (i < 0) return;
    final line = _lines[i];
    setState(() {
      if (line.soldByWeight) {
        final grams = line.weightInGrams ?? 0;
        final prev = WeightOptions.previous(grams);
        if (prev <= 0) {
          _lines.removeAt(i);
        } else {
          line.weightInGrams = prev;
          line.quantity = 1;
        }
        return;
      }
      if (line.quantity <= 1) {
        _lines.removeAt(i);
      } else {
        line.quantity -= 1;
      }
    });
  }

  Future<void> _openLineEditor(Product product) async {
    final line = _lineOf(product.id);
    if (product.isWeightBased || (line?.soldByWeight ?? false)) {
      await _pickWeight(product);
      return;
    }
    if (line == null) {
      await _addProduct(product);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _EditOrderQtyDialog(
        productName: line.productName,
        initialQuantity: line.quantity,
        onSave: (qty) {
          setState(() {
            if (qty <= 0) {
              _lines.removeWhere((l) => l.productId == product.id);
            } else {
              line.quantity = qty;
            }
          });
        },
        onRemove: () {
          setState(() {
            _lines.removeWhere((l) => l.productId == product.id);
          });
        },
      ),
    );
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
              quantityLabel: _qtyLabel(product),
              inCart: _lineOf(product.id) != null,
              showZeroStockInRed:
                  _filter == ProductSearchFilterMode.allItems,
              openOnDoubleTap: true,
              onAdd: () => _addProduct(product),
              onRemove: () => _removeOne(product.id),
              onOpen: () => _openLineEditor(product),
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
              onAdd: () {
                if (line.soldByWeight) {
                  unawaited(_pickWeight(line.toProduct()));
                } else {
                  setState(() => line.quantity += 1);
                }
              },
              onRemove: () => _removeOne(line.productId),
              onOpen: () => unawaited(_openLineEditor(line.toProduct())),
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
    required this.onOpen,
  });

  final OrderEditLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final grams = line.weightInGrams;
    final qtyLabel = line.soldByWeight && grams != null && grams > 0
        ? WeightOptions.compactLabel(grams)
        : '${line.quantity}';
    return StaffProductSearchTile(
      product: line.toProduct(),
      quantityLabel: qtyLabel,
      inCart: true,
      openOnDoubleTap: true,
      onAdd: onAdd,
      onRemove: onRemove,
      onOpen: onOpen,
    );
  }
}

/// Quick piece-quantity editor (pre-filled, +/- keys, cancel item).
class _EditOrderQtyDialog extends StatefulWidget {
  const _EditOrderQtyDialog({
    required this.productName,
    required this.initialQuantity,
    required this.onSave,
    required this.onRemove,
  });

  final String productName;
  final int initialQuantity;
  final ValueChanged<int> onSave;
  final VoidCallback onRemove;

  @override
  State<_EditOrderQtyDialog> createState() => _EditOrderQtyDialogState();
}

class _EditOrderQtyDialogState extends State<_EditOrderQtyDialog> {
  static const _maxQty = 9999;
  late final TextEditingController _qty;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: '${widget.initialQuantity}');
    _focus = FocusNode(onKeyEvent: _onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectAll();
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _qty.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _selectAll() {
    _qty.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _qty.text.length,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final ch = event.character;
    final isInc = ch == '+' ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.arrowUp ||
        (key == LogicalKeyboardKey.equal && ch == '+');
    if (isInc) {
      _bump(1);
      return KeyEventResult.handled;
    }
    final isDec = ch == '-' ||
        key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract ||
        key == LogicalKeyboardKey.arrowDown;
    if (isDec) {
      _bump(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _bump(int delta) {
    final current = int.tryParse(_qty.text.trim()) ?? widget.initialQuantity;
    final next = (current + delta).clamp(1, _maxQty);
    setState(() {
      _qty.text = '$next';
      _selectAll();
    });
  }

  void _save() {
    final q = int.tryParse(_qty.text.trim()) ?? 0;
    widget.onSave(q);
    Navigator.of(context).pop();
  }

  void _cancelItem() {
    widget.onRemove();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('edit-order-qty-dialog'),
      title: Text(
        widget.productName,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('edit-order-qty-dec'),
                onPressed: () => _bump(-1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: TextField(
                  key: const Key('edit-order-qty-field'),
                  controller: _qty,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  onSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                key: const Key('edit-order-qty-inc'),
                onPressed: () => _bump(1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('edit-order-qty-remove'),
          onPressed: _cancelItem,
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: const Text('إلغاء الصنف'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton(
          key: const Key('edit-order-qty-save'),
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
