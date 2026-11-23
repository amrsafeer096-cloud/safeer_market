import 'package:flutter/material.dart';

/// Responsive product grid — same formula as «التصنيفات السلعية»
/// ([CategoryScreen]): ≥2 columns on mobile, more as width grows (~180 px
/// per tile).
abstract final class ProductGridLayout {
  /// Minimum tile width used to decide column count.
  static const tileMinWidth = 180.0;

  static const mainAxisSpacing = 12.0;
  static const crossAxisSpacing = 12.0;

  /// Matches the category product grid aspect ratio.
  static const childAspectRatio = 0.65;

  static int columnsFor(double crossAxisExtent) {
    final count = (crossAxisExtent / tileMinWidth).floor();
    return count < 2 ? 2 : count;
  }

  static SliverGridDelegate gridDelegateFor(double crossAxisExtent) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columnsFor(crossAxisExtent),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
