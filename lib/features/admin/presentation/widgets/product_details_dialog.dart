import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/web/web_image_clipboard.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/phone_order.dart';
import 'admin_product_image_upload.dart';
import 'draggable_product_image.dart';
import 'staff_product_search_tile.dart';

/// «تفاصيل المنتج» for the order taker: a large image (copy / share it to
/// send to a customer), barcode and stock, and either bulk quantity or
/// single-step weight entry (quick-pick chips + focused kg/g input).
///
/// [onAddQuantity] gets the exact amount typed (1…[PhoneOrderState.maxQuantity])
/// plus an optional item note; weight-based products use [onConfirmWeight].
Future<void> showProductDetailsDialog(
  BuildContext context, {
  required Product product,
  required void Function(int quantity, String? notes) onAddQuantity,
  required void Function(int grams, String? notes) onConfirmWeight,
  String? initialNotes,
  int? initialGrams,
  int? initialQuantity,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ProductDetailsDialog(
      product: product,
      onAddQuantity: onAddQuantity,
      onConfirmWeight: onConfirmWeight,
      initialNotes: initialNotes,
      initialGrams: initialGrams,
      initialQuantity: initialQuantity,
    ),
  );
}

enum _WeightUnit { kilo, gram }

class ProductDetailsDialog extends ConsumerStatefulWidget {
  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onAddQuantity,
    required this.onConfirmWeight,
    this.initialNotes,
    this.initialGrams,
    this.initialQuantity,
  });

  final Product product;
  final void Function(int quantity, String? notes) onAddQuantity;
  final void Function(int grams, String? notes) onConfirmWeight;
  final String? initialNotes;
  final int? initialGrams;
  final int? initialQuantity;

  @override
  ConsumerState<ProductDetailsDialog> createState() =>
      _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends ConsumerState<ProductDetailsDialog> {
  late final _quantity = TextEditingController(
    text: '${(widget.initialQuantity ?? 1).clamp(1, PhoneOrderState.maxQuantity)}',
  );
  final _quantityFocus = FocusNode();
  final _weight = TextEditingController();
  final _weightFocus = FocusNode();
  late final _notes = TextEditingController(text: widget.initialNotes ?? '');
  var _busy = false;
  String? _error;
  var _unit = _WeightUnit.kilo;
  int? _selectedQuickPick;
  String? _uploadedImageUrl;

  Product get _product => widget.product;
  String? get _imageUrl {
    final url = (_uploadedImageUrl ?? _product.imageUrl)?.trim();
    return Product.isValidImageUrl(url) ? url : null;
  }

  String? get _trimmedNotes {
    final t = _notes.text.trim();
    return t.isEmpty ? null : t;
  }

  int? get _effectiveGrams => WeightOptions.parseCustomGrams(
        _weight.text,
        inKilos: _unit == _WeightUnit.kilo,
        maxGramsLimit: WeightOptions.adminMaxGrams,
      );

  bool get _canSubmitWeight {
    final g = _effectiveGrams;
    return g != null && g > 0;
  }

  static String _formatKg(int grams) => WeightOptions.kgOf(grams)
      .toStringAsFixed(WeightOptions.maxKgDecimals)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');

  void _fillWeight(int grams, {required bool selectChip}) {
    _selectedQuickPick =
        selectChip && WeightOptions.adminQuickPicksInGrams.contains(grams)
            ? grams
            : null;
    _unit = _WeightUnit.kilo;
    _weight.text = _formatKg(grams);
    _weight.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _weight.text.length,
    );
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGrams;
    if (_product.isWeightBased && initial != null && initial > 0) {
      _fillWeight(initial, selectChip: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_product.isWeightBased) {
        _weightFocus.requestFocus();
        if (_weight.text.isNotEmpty) {
          _weight.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _weight.text.length,
          );
        }
        return;
      }
      _quantity.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantity.text.length,
      );
      _quantityFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    _quantityFocus.dispose();
    _weight.dispose();
    _weightFocus.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(message),
      ));
  }

  Future<({Uint8List bytes, String mime, String name})> _download() async {
    final uri = Uri.parse(_imageUrl!);
    final response = await http.get(uri);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        response.bodyBytes.isEmpty) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final path = uri.path.toLowerCase();
    final header = response.headers['content-type']?.split(';').first.trim();
    final mime = switch (null) {
      _ when header != null && header.startsWith('image/') => header,
      _ when path.endsWith('.png') => 'image/png',
      _ when path.endsWith('.webp') => 'image/webp',
      _ when path.endsWith('.gif') => 'image/gif',
      _ => 'image/jpeg',
    };
    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => 'jpg',
    };
    return (bytes: response.bodyBytes, mime: mime, name: 'product.$ext');
  }

  /// Web: `ClipboardItem({image/png})` for Ctrl+V into WhatsApp.
  /// Other platforms: Pasteboard. Falls back to the image URL on CORS errors.
  Future<void> _copyImage() async {
    final url = _imageUrl;
    if (url == null || _busy) return;
    setState(() => _busy = true);
    var copiedImage = false;
    try {
      final image = await _download();
      if (kIsWeb) {
        copiedImage = await copyImageBlobToWebClipboard(
          image.bytes,
          mimeType: image.mime,
        );
      }
      if (!copiedImage) {
        await Pasteboard.writeImage(image.bytes);
        copiedImage = true;
      }
    } catch (_) {
      copiedImage = false;
    }
    if (!copiedImage) {
      await Clipboard.setData(ClipboardData(text: url));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(copiedImage ? 'تم نسخ الصورة' : 'تم نسخ رابط الصورة');
  }

  /// Shares the picture as a file (WhatsApp, save…), or its link if the
  /// file can't be fetched.
  Future<void> _shareImage() async {
    final url = _imageUrl;
    if (url == null || _busy) return;
    setState(() => _busy = true);
    try {
      try {
        final image = await _download();
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(image.bytes, mimeType: image.mime, name: image.name),
          ],
          fileNameOverrides: [image.name],
          text: _product.name,
        ));
      } catch (_) {
        await SharePlus.instance.share(
          ShareParams(text: '${_product.name}\n$url'),
        );
      }
    } catch (_) {
      if (mounted) _toast('تعذّرت مشاركة الصورة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyBarcode(String barcode) async {
    await Clipboard.setData(ClipboardData(text: barcode.trim()));
    if (mounted) _toast('تم نسخ الباركود');
  }

  Future<void> _copyName() async {
    await Clipboard.setData(ClipboardData(text: _product.name));
    if (mounted) _toast('تم نسخ اسم الصنف');
  }

  void _uploadImage() {
    showAdminProductImagePicker(
      context,
      product: _product,
      onUploaded: (url) => setState(() => _uploadedImageUrl = url),
    );
  }

  void _addBulk() {
    final quantity = int.tryParse(_quantity.text.trim());
    if (quantity == null ||
        quantity < 1 ||
        quantity > PhoneOrderState.maxQuantity) {
      setState(() => _error = 'أدخل كمية من 1 إلى ${PhoneOrderState.maxQuantity}');
      _quantityFocus.requestFocus();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    widget.onAddQuantity(quantity, _trimmedNotes);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('تمت إضافة $quantity × ${_product.name} للتأكيد'),
      ));
  }

  void _addWeight() {
    final grams = _effectiveGrams;
    if (grams == null || grams <= 0) {
      setState(() => _error =
          'أدخل وزناً من 0.001 إلى ${WeightOptions.adminMaxKg.toStringAsFixed(0)} كيلو');
      _weightFocus.requestFocus();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final label = WeightOptions.compactLabel(grams);
    widget.onConfirmWeight(grams, _trimmedNotes);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('تمت إضافة $label × ${_product.name} للتأكيد'),
      ));
  }

  void _onQuickPick(int grams) {
    setState(() {
      _error = null;
      _fillWeight(grams, selectChip: true);
    });
    _weightFocus.requestFocus();
  }

  void _onWeightChanged(String _) {
    final grams = _effectiveGrams;
    setState(() {
      _error = null;
      _selectedQuickPick =
          grams != null && WeightOptions.adminQuickPicksInGrams.contains(grams)
              ? grams
              : null;
    });
  }

  Widget _weightEntry(AppPalette palette) {
    final effective = _effectiveGrams;
    final price = effective == null
        ? 0.0
        : WeightOptions.priceFor(_product.effectivePrice, effective);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اختر الوزن أو اكتبه',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final grams in WeightOptions.adminQuickPicksInGrams)
              ChoiceChip(
                key: Key('product-dialog-weight-chip-$grams'),
                label: Text(WeightOptions.adminQuickPickLabel(grams)),
                selected: _selectedQuickPick == grams,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: palette.card,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _selectedQuickPick == grams
                      ? AppColors.onPrimary
                      : palette.onSurface,
                ),
                side: BorderSide(
                  color: palette.accent.withValues(alpha: 0.15),
                ),
                shape: const StadiumBorder(),
                onSelected: (_) => _onQuickPick(grams),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('product-dialog-weight-input'),
                controller: _weight,
                focusNode: _weightFocus,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  _WeightInputFormatter(inKilos: _unit == _WeightUnit.kilo),
                ],
                onChanged: _onWeightChanged,
                onSubmitted: (_) {
                  if (_canSubmitWeight) _addWeight();
                },
                decoration: InputDecoration(
                  hintText:
                      _unit == _WeightUnit.kilo ? 'مثال: 0.125' : 'مثال: 125',
                  errorText: _error,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<_WeightUnit>(
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: _WeightUnit.kilo,
                  label: Text('كيلو',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                ButtonSegment(
                  value: _WeightUnit.gram,
                  label: Text('جرام',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
              selected: {_unit},
              onSelectionChanged: (next) {
                final unit = next.first;
                final current = WeightOptions.parseCustomGrams(
                  _weight.text,
                  inKilos: _unit == _WeightUnit.kilo,
                  maxGramsLimit: WeightOptions.adminMaxGrams,
                );
                setState(() {
                  _unit = unit;
                  if (current != null) {
                    _weight.text = unit == _WeightUnit.kilo
                        ? _formatKg(current)
                        : '$current';
                    _weight.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _weight.text.length,
                    );
                  }
                });
                _weightFocus.requestFocus();
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'السعر',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
            Text(
              AppCurrency.of(price),
              key: const Key('product-dialog-weight-price'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _canSubmitWeight ? AppColors.secondary : palette.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            key: const Key('product-dialog-add-weight'),
            onPressed: _canSubmitWeight ? _addWeight : null,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: const Text('إضافة للسلة'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final barcode = _product.barcode?.trim() ?? '';
    final hasImage = _imageUrl != null;
    final lowStock = _product.stockQuantity <= 5;

    Widget infoBox({
      required Key key,
      required String label,
      required String value,
      VoidCallback? onTap,
      Color? valueColor,
      TextDirection? direction,
    }) {
      return Material(
        color: palette.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: direction,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.copy, size: 16, color: palette.accent),
              ],
            ),
          ),
        ),
      );
    }

    final bulk = _product.isWeightBased
        ? _weightEntry(palette)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إضافة كمية بالجملة',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('product-dialog-quantity'),
                      controller: _quantity,
                      focusNode: _quantityFocus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _addBulk(),
                      decoration: InputDecoration(
                        hintText: 'مثال: 5',
                        errorText: _error,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      key: const Key('product-dialog-add'),
                      onPressed: _addBulk,
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          size: 18),
                      label: const Text('إضافة للسلة'),
                    ),
                  ),
                ],
              ),
            ],
          );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        key: const Key('product-details-dialog'),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _product.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.35),
                    ),
                  ),
                  IconButton(
                    key: const Key('product-dialog-copy-name'),
                    tooltip:
                        AppLocalizations.of(context)!.adminCopyProductName,
                    visualDensity: VisualDensity.compact,
                    onPressed: _copyName,
                    icon: Icon(Icons.copy, size: 16, color: palette.accent),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${AppCurrency.of(_product.effectivePrice)} / '
                '${_product.displayUnit}',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
              if (_product.effectivePieces > 1) ...[
                const SizedBox(height: 4),
                Text(
                  'القطع: ${_product.effectivePieces}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.accent,
                  ),
                ),
              ],
              if (_product.hasActiveOffer) ...[
                const SizedBox(height: 6),
                Center(child: ProductOfferBadge(product: _product)),
              ],
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DraggableProductImage(
                        imageUrl: _imageUrl,
                        iconSize: 56,
                        fit: BoxFit.contain,
                        padding: const EdgeInsets.all(8),
                      ),
                      if (!_busy)
                        PositionedDirectional(
                          bottom: 8,
                          start: 8,
                          child: AdminProductCameraButton(
                            key: const Key('product-dialog-camera'),
                            onPressed: _uploadImage,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('product-dialog-copy-image'),
                      onPressed: hasImage && !_busy ? _copyImage : null,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('نسخ الصورة / الرابط'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('product-dialog-share-image'),
                      onPressed: hasImage && !_busy ? _shareImage : null,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: infoBox(
                      key: const Key('product-dialog-barcode'),
                      label: 'الباركود',
                      value: barcode.isEmpty ? '—' : barcode,
                      direction: TextDirection.ltr,
                      onTap: barcode.isEmpty ? null : () => _copyBarcode(barcode),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: infoBox(
                      key: const Key('product-dialog-stock'),
                      label: 'المخزون',
                      value: '${_product.stockQuantity}',
                      valueColor: lowStock ? Colors.orange.shade800 : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('product-dialog-item-notes'),
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
              bulk,
              const SizedBox(height: 10),
              TextButton(
                key: const Key('product-dialog-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق / إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Digits + one decimal point; normalizes Arabic separators/digits as typed.
class _WeightInputFormatter extends TextInputFormatter {
  _WeightInputFormatter({required this.inKilos});

  final bool inKilos;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = WeightOptions.normalizeDecimalInput(newValue.text);
    if (normalized.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    if (normalized == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    final parts = normalized.split('.');
    if (parts.length > 2) return oldValue;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(normalized)) return oldValue;

    if (parts.length == 2) {
      final maxDec = inKilos ? WeightOptions.maxKgDecimals : 0;
      if (parts[1].length > maxDec) {
        if (maxDec == 0) {
          return TextEditingValue(
            text: parts[0],
            selection: TextSelection.collapsed(offset: parts[0].length),
          );
        }
        final clipped = '${parts[0]}.${parts[1].substring(0, maxDec)}';
        return TextEditingValue(
          text: clipped,
          selection: TextSelection.collapsed(offset: clipped.length),
        );
      }
    }

    if (normalized == newValue.text) return newValue;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
