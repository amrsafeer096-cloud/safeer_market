import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
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

class ProductImageViewer extends StatelessWidget {
  const ProductImageViewer({super.key, required this.product, this.imageUrl});

  /// Largest the photo is drawn, so it is never upscaled into pixelation.
  static const imageSize = 280.0;

  final Product product;
  final String? imageUrl;

  String? get _imageUrl {
    final url = (imageUrl ?? product.imageUrl)?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.imageLinkCopied)));
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
                  if (url != null)
                    IconButton.filledTonal(
                      tooltip: l10n.copyImageLink,
                      onPressed: () => _copyLink(context, url),
                      icon: const Icon(Icons.link_rounded),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: imageSize,
                    maxHeight: imageSize,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ProductImage(
                      imageUrl: url,
                      iconSize: 96,
                      fit: BoxFit.contain,
                      placeholderBackground: false,
                    ),
                  ),
                ),
              ),
            ),
            SimilarProductsSection(product: product),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
