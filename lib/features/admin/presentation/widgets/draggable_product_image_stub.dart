import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/product_image.dart';

/// Non-web fallback: standard Flutter product image (not natively draggable).
class DraggableProductImage extends StatelessWidget {
  const DraggableProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.iconSize = 56,
    this.padding = const EdgeInsets.all(8),
  });

  final String? imageUrl;
  final BoxFit fit;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ProductImage(
      imageUrl: imageUrl,
      fit: fit,
      iconSize: iconSize,
      padding: padding,
    );
  }
}
