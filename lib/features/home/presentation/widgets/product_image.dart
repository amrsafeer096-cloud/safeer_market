import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/product.dart';

/// Product photo from `image_url`, cached on disk.
///
/// A missing, blank, or unloadable URL falls back to a grocery icon. Decoded
/// at the size it is laid out at (never more than [maxDiskWidth] wide on
/// disk), with a static tinted placeholder and a short fade so a fast scroll
/// costs no animation work.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.iconSize = 40,
    this.fit = BoxFit.cover,
    this.padding = EdgeInsets.zero,
    this.placeholderBackground = true,
    this.onLoadFailed,
  });

  final String? imageUrl;

  /// Called with the trimmed URL, after the frame, when a valid-looking link
  /// fails to load (e.g. Storage answers "Object not found").
  final ValueChanged<String>? onLoadFailed;
  final double iconSize;
  final BoxFit fit;

  /// Inset around the loaded photo only; placeholders still fill the box.
  final EdgeInsetsGeometry padding;

  /// Whether placeholders paint a neutral tint. Turn off where the image
  /// must stay transparent, e.g. when it flies into the cart.
  final bool placeholderBackground;

  /// Widest a product photo is stored on disk: enough for the 280 px
  /// details view on a 3x screen, a fraction of a raw upload.
  static const maxDiskWidth = 900;

  static const fadeIn = Duration(milliseconds: 120);

  /// Decoded width that a [ProductImage] laid out [width] logical pixels
  /// wide keeps in the image cache.
  static int memCacheWidthFor(double width, double devicePixelRatio) =>
      (width * devicePixelRatio).round().clamp(64, maxDiskWidth).toInt();

  /// The in-memory provider a [ProductImage] of [imageUrl] laid out [width]
  /// wide resolves to, or null when the URL can't be shown. Painting through
  /// this hits the same cache entry, so it draws on its first frame.
  static ImageProvider? cachedProvider(
    String? imageUrl, {
    required double width,
    required double devicePixelRatio,
  }) {
    if (!Product.isValidImageUrl(imageUrl)) return null;
    final url = imageUrl!.trim();
    return ResizeImage.resizeIfNeeded(
      memCacheWidthFor(width, devicePixelRatio),
      null,
      CachedNetworkImageProvider(url, maxWidth: maxDiskWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Product.isValidImageUrl(imageUrl)) {
      return _Placeholder(
        iconSize: iconSize,
        background: placeholderBackground,
      );
    }
    final url = imageUrl!.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        final memCacheWidth = width == null
            ? null
            : memCacheWidthFor(width, MediaQuery.devicePixelRatioOf(context));

        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: memCacheWidth,
          maxWidthDiskCache: maxDiskWidth,
          alignment: Alignment.center,
          fadeInDuration: fadeIn,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          imageBuilder: (context, imageProvider) => Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Image(
                image: imageProvider,
                fit: fit,
                alignment: Alignment.center,
                gaplessPlayback: true,
              ),
            ),
          ),
          placeholder: (context, _) => _Placeholder(
            iconSize: iconSize,
            background: placeholderBackground,
            loading: true,
          ),
          errorWidget: (context, _, __) {
            if (onLoadFailed case final report?) {
              WidgetsBinding.instance.addPostFrameCallback((_) => report(url));
            }
            return _Placeholder(
              iconSize: iconSize,
              background: placeholderBackground,
            );
          },
        );
      },
    );
  }
}

/// A flat tinted box: blank while loading, a grocery icon when there is no
/// photo. No spinner, so a grid full of loading cards paints nothing moving.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.iconSize,
    required this.background,
    this.loading = false,
  });

  final double iconSize;
  final bool background;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox.expand(
      child: ColoredBox(
        color: background ? palette.imageBackdrop : Colors.transparent,
        child: loading
            ? null
            : Center(
                child: Icon(
                  Icons.local_grocery_store_outlined,
                  size: iconSize,
                  color: palette.accent.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}
