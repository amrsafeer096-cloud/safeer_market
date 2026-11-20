import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_palette.dart';
import 'product_card.dart';

/// Placeholder shaped like [ProductCard], shown while products load.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(ProductCard.radius),
        boxShadow: palette.isDark
            ? null
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Shimmer.fromColors(
        baseColor: palette.isDark ? palette.surface : Colors.grey.shade300,
        highlightColor:
            palette.isDark ? palette.imageBackdrop : Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Bone(radius: 12)),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 4, end: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(height: 14),
                    SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: _Bone(height: 14),
                    ),
                    SizedBox(height: 10),
                    SizedBox(width: 64, child: _Bone(height: 18)),
                    SizedBox(height: 10),
                    _Bone(height: 40, radius: 13),
                  ],
                ),
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({this.height, this.radius = 8});

  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
