import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/main_categories.dart';

/// Widest a category cover is decoded or stored: tiles are at most ~100
/// logical px, so 2x of twice that is plenty.
const mainCategoryImageWidth = 400;

ImageProvider mainCategoryImageProvider(MainCategory category) {
  if (category.isAssetImage) {
    return ResizeImage(
      AssetImage(category.imageUrl),
      width: mainCategoryImageWidth,
    );
  }
  return ResizeImage(
    CachedNetworkImageProvider(
      category.imageUrl,
      maxWidth: mainCategoryImageWidth,
    ),
    width: mainCategoryImageWidth,
  );
}

/// Paints [category]'s cover photo over a neutral tint, which also stays
/// as the fallback while the photo loads or if it can't be fetched. Pass
/// `context.palette.imageBackdrop` as [backdrop] to follow the theme.
BoxDecoration mainCategoryDecoration(
  MainCategory category, {
  required BorderRadiusGeometry borderRadius,
  List<BoxShadow>? boxShadow,
  Color backdrop = AppColors.imageBackdrop,
  BoxFit fit = BoxFit.cover,
}) {
  return BoxDecoration(
    color: backdrop,
    borderRadius: borderRadius,
    boxShadow: boxShadow,
    image: DecorationImage(
      image: mainCategoryImageProvider(category),
      fit: fit,
      onError: (_, __) {},
    ),
  );
}
