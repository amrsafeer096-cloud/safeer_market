import 'package:flutter/material.dart';

import 'product_image.dart';

/// Square product thumbnail: pure white pad + [BoxFit.contain] so packaging
/// is never cropped. Used on order prep cards and alternatives UI.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.iconSize = 20,
    this.padding = 4,
    this.borderRadius = 8,
  });

  final String? imageUrl;
  final double size;
  final double iconSize;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: ProductImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              iconSize: iconSize,
              placeholderBackground: false,
            ),
          ),
        ),
      ),
    );
  }
}
