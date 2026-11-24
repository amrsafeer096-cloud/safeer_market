import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/web/web_image_clipboard.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/phone_order.dart';
import 'draggable_product_image.dart';

/// «تفاصيل المنتج» for the order taker: a large image (copy / share it to
/// send to a customer), barcode and stock, and a bulk «إضافة كمية بالجملة».
///
/// [onAddQuantity] gets the exact amount typed (1…[PhoneOrderState.maxQuantity]);
/// weight-based products have no bulk field and use [onPickWeight] instead.
Future<void> showProductDetailsDialog(
  BuildContext context, {
  required Product product,
  required ValueChanged<int> onAddQuantity,
  required VoidCallback onPickWeight,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ProductDetailsDialog(
      product: product,
      onAddQuantity: onAddQuantity,
      onPickWeight: onPickWeight,
    ),
  );
}

class ProductDetailsDialog extends StatefulWidget {
  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.onAddQuantity,
    required this.onPickWeight,
  });

  final Product product;
  final ValueChanged<int> onAddQuantity;
  final VoidCallback onPickWeight;

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  final _quantity = TextEditingController();
  final _quantityFocus = FocusNode();
  var _busy = false;
  String? _error;

  Product get _product => widget.product;
  String? get _imageUrl => _product.hasValidImageUrl ? _product.imageUrl : null;

  @override
  void dispose() {
    _quantity.dispose();
    _quantityFocus.dispose();
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
    widget.onAddQuantity(quantity);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('تمت إضافة $quantity × ${_product.name} للسلة'),
      ));
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
                  Icon(Icons.copy_rounded, size: 18, color: palette.accent),
              ],
            ),
          ),
        ),
      );
    }

    final bulk = _product.isWeightBased
        ? SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('product-dialog-pick-weight'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPickWeight();
              },
              icon: const Icon(Icons.scale_rounded),
              label: const Text('اختيار الوزن'),
            ),
          )
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
              Text(
                _product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16, height: 1.35),
              ),
              const SizedBox(height: 2),
              Text(
                '${AppCurrency.of(_product.effectivePrice)} / '
                '${_product.displayUnit}',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Web: native <img draggable> for Chrome → WhatsApp drag.
                  child: DraggableProductImage(
                    imageUrl: _imageUrl,
                    iconSize: 56,
                    fit: BoxFit.contain,
                    padding: const EdgeInsets.all(8),
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
