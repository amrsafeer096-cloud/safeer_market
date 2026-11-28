import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/web/web_image_clipboard.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/widgets/draggable_product_image.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../widgets/similar_products_section.dart';

/// Opens [product]'s photo on a white full-screen page, crisp at a fixed
/// size (no zoom), with «منتجات مشابهة» underneath. [imageUrl] overrides the
/// product's photo, e.g. right after an admin uploaded a new one.
Future<void> showProductImageViewer(
  BuildContext context,
  Product product, {
  String? imageUrl,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) =>
          ProductImageViewer(product: product, imageUrl: imageUrl),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class ProductImageViewer extends StatefulWidget {
  const ProductImageViewer({super.key, required this.product, this.imageUrl});

  /// Largest the photo is drawn, so it is never upscaled into pixelation.
  static const imageSize = 280.0;

  final Product product;
  final String? imageUrl;

  @override
  State<ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<ProductImageViewer> {
  var _busy = false;

  String? get _imageUrl {
    final url = (widget.imageUrl ?? widget.product.imageUrl)?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(message),
      ));
  }

  Future<({Uint8List bytes, String mime, String name})> _download(String url) async {
    final uri = Uri.parse(url);
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

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _toast(AppLocalizations.of(context)!.imageLinkCopied);
  }

  Future<void> _copyImage(String url) async {
    if (_busy) return;
    setState(() => _busy = true);
    var copiedImage = false;
    try {
      final image = await _download(url);
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

  Future<void> _shareImage(String url) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      try {
        final image = await _download(url);
        await SharePlus.instance.share(ShareParams(
          files: [
            XFile.fromData(image.bytes, mimeType: image.mime, name: image.name),
          ],
          fileNameOverrides: [image.name],
          text: widget.product.name,
        ));
      } catch (_) {
        await SharePlus.instance.share(
          ShareParams(text: '${widget.product.name}\n$url'),
        );
      }
    } catch (_) {
      if (mounted) _toast('تعذّرت مشاركة الصورة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = _imageUrl;

    return Scaffold(
      backgroundColor: context.palette.card,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  if (url != null) ...[
                    IconButton.filledTonal(
                      tooltip: 'نسخ الصورة',
                      onPressed: _busy ? null : () => _copyImage(url),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton.filledTonal(
                      tooltip: l10n.copyImageLink,
                      onPressed: _busy ? null : () => _copyLink(url),
                      icon: const Icon(Icons.link_rounded),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'مشاركة / تحميل',
                      onPressed: _busy ? null : () => _shareImage(url),
                      icon: const Icon(Icons.share_rounded),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ProductImageViewer.imageSize,
                    maxHeight: ProductImageViewer.imageSize,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: url == null
                        ? const ProductImage(
                            imageUrl: null,
                            iconSize: 96,
                            fit: BoxFit.contain,
                            placeholderBackground: false,
                          )
                        : DraggableProductImage(
                            imageUrl: url,
                            iconSize: 96,
                            fit: BoxFit.contain,
                            padding: EdgeInsets.zero,
                          ),
                  ),
                ),
              ),
            ),
            SimilarProductsSection(product: widget.product),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
