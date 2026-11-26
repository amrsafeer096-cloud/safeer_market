import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/phone_order.dart';

/// One staged product waiting for Enter-confirm into the cart.
class StagedCartItem {
  StagedCartItem({
    required this.product,
    this.quantity = 1,
    this.weightInGrams,
  });

  final Product product;
  int quantity;
  int? weightInGrams;

  double get lineTotal => switch (weightInGrams) {
        final grams? => WeightOptions.priceFor(product.effectivePrice, grams),
        null => product.effectivePrice * quantity,
      };

  String get quantityLabel {
    if (weightInGrams != null) {
      return WeightOptions.phoneOrderLabel(weightInGrams!);
    }
    return '$quantity';
  }
}

/// First Enter: review staged lines. Second Enter / confirm returns the map.
Future<Map<String, StagedCartItem>?> showStagedReviewDialog(
  BuildContext context, {
  required Map<String, StagedCartItem> staged,
}) {
  return showDialog<Map<String, StagedCartItem>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _StagedReviewDialog(initial: staged),
  );
}

class _StagedReviewDialog extends StatefulWidget {
  const _StagedReviewDialog({required this.initial});

  final Map<String, StagedCartItem> initial;

  @override
  State<_StagedReviewDialog> createState() => _StagedReviewDialogState();
}

class _StagedReviewDialogState extends State<_StagedReviewDialog> {
  late final Map<String, StagedCartItem> _items = {
    for (final e in widget.initial.entries)
      e.key: StagedCartItem(
        product: e.value.product,
        quantity: e.value.quantity,
        weightInGrams: e.value.weightInGrams,
      ),
  };

  void _confirm() {
    if (_items.isEmpty) {
      Navigator.of(context).pop(<String, StagedCartItem>{});
      return;
    }
    Navigator.of(context).pop(_items);
  }

  void _inc(String id) {
    final item = _items[id];
    if (item == null) return;
    setState(() {
      if (item.weightInGrams != null) {
        item.weightInGrams = WeightOptions.next(item.weightInGrams!);
      } else if (item.quantity < PhoneOrderState.maxQuantity) {
        item.quantity += 1;
      }
    });
  }

  void _dec(String id) {
    final item = _items[id];
    if (item == null) return;
    setState(() {
      if (item.weightInGrams != null) {
        final prev = WeightOptions.previous(item.weightInGrams!);
        if (prev <= 0) {
          _items.remove(id);
        } else {
          item.weightInGrams = prev;
        }
      } else if (item.quantity <= 1) {
        _items.remove(id);
      } else {
        item.quantity -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _confirm,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _confirm,
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          key: const Key('phone-order-staged-review'),
          title: const Text(
            'مراجعة الأصناف',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 420,
            child: _items.isEmpty
                ? Text(
                    'لا توجد أصناف محددة',
                    style: TextStyle(color: palette.muted),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry in _items.entries)
                        ListTile(
                          key: Key('staged-review-${entry.key}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.value.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            AppCurrency.of(entry.value.lineTotal),
                            style: TextStyle(color: palette.accent),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('staged-dec-${entry.key}'),
                                onPressed: () => _dec(entry.key),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                entry.value.quantityLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              IconButton(
                                key: Key('staged-inc-${entry.key}'),
                                onPressed: () => _inc(entry.key),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              key: const Key('staged-review-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('رجوع'),
            ),
            FilledButton(
              key: const Key('staged-review-confirm'),
              onPressed: _confirm,
              child: const Text('تأكيد وإضافة للسلة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Double-click cart line: edit qty with keyboard +/- and cancel item.
Future<void> showCartLineEditDialog(
  BuildContext context, {
  required PhoneOrderLine line,
  required void Function(int quantity, String? notes) onSetQuantity,
  required void Function(int grams, String? notes) onSetWeightGrams,
  required VoidCallback onRemove,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CartLineEditDialog(
      line: line,
      onSetQuantity: onSetQuantity,
      onSetWeightGrams: onSetWeightGrams,
      onRemove: onRemove,
    ),
  );
}

class _CartLineEditDialog extends StatefulWidget {
  const _CartLineEditDialog({
    required this.line,
    required this.onSetQuantity,
    required this.onSetWeightGrams,
    required this.onRemove,
  });

  final PhoneOrderLine line;
  final void Function(int quantity, String? notes) onSetQuantity;
  final void Function(int grams, String? notes) onSetWeightGrams;
  final VoidCallback onRemove;

  @override
  State<_CartLineEditDialog> createState() => _CartLineEditDialogState();
}

class _CartLineEditDialogState extends State<_CartLineEditDialog> {
  late final TextEditingController _qty;
  late final TextEditingController _notes;
  late final FocusNode _focus;
  late int? _weight;

  bool get _isWeight => widget.line.weightInGrams != null;

  String? get _trimmedNotes {
    final t = _notes.text.trim();
    return t.isEmpty ? null : t;
  }

  @override
  void initState() {
    super.initState();
    _weight = widget.line.weightInGrams;
    final text = _isWeight
        ? WeightOptions.phoneOrderLabel(_weight!)
        : '${widget.line.quantity}';
    _qty = TextEditingController(text: _isWeight ? '$_weight' : text);
    _notes = TextEditingController(text: widget.line.notes ?? '');
    // Handle +/- on the FocusNode so the focused TextField cannot swallow them.
    _focus = FocusNode(onKeyEvent: _onQtyKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectAll();
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _selectAll() {
    _qty.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _qty.text.length,
    );
  }

  KeyEventResult _onQtyKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final ch = event.character;

    final isInc = ch == '+' ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.arrowUp ||
        // Shift+= on many layouts produces '+' via equal without character.
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
    if (_isWeight) {
      setState(() {
        if (delta > 0) {
          _weight = WeightOptions.next(_weight!);
        } else {
          final prev = WeightOptions.previous(_weight!);
          _weight = prev <= 0 ? _weight : prev;
        }
        _qty.text = '$_weight';
        _selectAll();
      });
      return;
    }
    final current = int.tryParse(_qty.text.trim()) ?? widget.line.quantity;
    final next = (current + delta).clamp(1, PhoneOrderState.maxQuantity);
    setState(() {
      _qty.text = '$next';
      _selectAll();
    });
  }

  void _save() {
    final notes = _trimmedNotes;
    if (_isWeight) {
      final grams = int.tryParse(_qty.text.trim()) ?? _weight ?? 0;
      if (grams <= 0) {
        widget.onRemove();
      } else {
        widget.onSetWeightGrams(grams, notes);
      }
    } else {
      final q = int.tryParse(_qty.text.trim()) ?? 0;
      if (q <= 0) {
        widget.onRemove();
      } else {
        widget.onSetQuantity(
          q.clamp(1, PhoneOrderState.maxQuantity),
          notes,
        );
      }
    }
    Navigator.of(context).pop();
  }

  void _cancelItem() {
    widget.onRemove();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('phone-order-cart-edit'),
      title: Text(
        widget.line.product.name,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('cart-edit-dec'),
                onPressed: () => _bump(-1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: TextField(
                  key: const Key('cart-edit-qty'),
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
                  decoration: InputDecoration(
                    labelText: _isWeight ? 'الوزن (جم)' : 'الكمية',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                key: const Key('cart-edit-inc'),
                onPressed: () => _bump(1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('cart-edit-item-notes'),
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظة للصنف',
              hintText: 'مثال: على ربعين، تقطيع رفيع...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('cart-edit-remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
              ),
              onPressed: _cancelItem,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'إلغاء الصنف',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
        FilledButton(
          key: const Key('cart-edit-save'),
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
