import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product.dart';

/// Price with its unit (e.g. «45.95 ج.م / قطعة»). On offer, the offer price
/// is shown in green with the regular price struck through above it.
class ProductPrice extends StatelessWidget {
  const ProductPrice({
    super.key,
    required this.product,
    this.fontSize = 15,
    this.showUnit = true,
  });

  final Product product;
  final double fontSize;
  final bool showUnit;

  static const offerColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final oldPrice = product.oldPrice;
    final onOffer = oldPrice != null;
    final palette = context.palette;
    final unitStyle = TextStyle(
      fontSize: fontSize * 0.75,
      fontWeight: FontWeight.w600,
      color: palette.muted,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onOffer)
          Text(
            AppCurrency.of(oldPrice),
            key: const Key('product-original-price'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize * 0.75,
              fontWeight: FontWeight.w600,
              color: palette.muted,
              decoration: TextDecoration.lineThrough,
              decorationColor: palette.muted,
            ),
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: AppCurrency.of(product.effectivePrice),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: onOffer ? offerColor : AppColors.secondary,
                ),
              ),
              if (showUnit)
                TextSpan(text: ' / ${product.displayUnit}', style: unitStyle),
            ],
          ),
          key: const Key('product-price'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Corner badge for products on offer, e.g. «خصم 15%».
class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasActiveOffer) return const SizedBox.shrink();
    final percent = product.discountPercentage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ProductPrice.offerColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        percent > 0
            ? AppLocalizations.of(context)!.offerDiscountPercent('$percent')
            : AppLocalizations.of(context)!.offerBadge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
