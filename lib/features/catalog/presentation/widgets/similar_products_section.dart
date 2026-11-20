import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../domain/similar_products_query.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../providers/catalog_providers.dart';

/// The «منتجات مشابهة» header and horizontal row of [ProductCard]s for
/// [product], from [similarProductsProvider]. Collapses to nothing when
/// there is nothing to show.
class SimilarProductsSection extends ConsumerWidget {
  const SimilarProductsSection({
    super.key,
    required this.product,
    this.onFlyToCart,
  });

  static const cardWidth = 160.0;
  static const listHeight = 300.0;

  final Product product;

  /// Flies the tapped card's photo into a cart icon; null adds silently.
  final Future<void> Function(GlobalKey imageKey)? onFlyToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync =
        ref.watch(similarProductsProvider(product.similarProductsQuery));
    final products =
        shownProducts(ref, similarAsync.valueOrNull ?? const <Product>[]);

    if (products.isEmpty && !similarAsync.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: context.palette.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.similarProducts,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.palette.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: listHeight,
          child: products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final similar = products[index];
                    return SizedBox(
                      width: cardWidth,
                      child: ProductCard(
                        product: similar,
                        onAdd: () =>
                            addToCartWithFeedback(context, ref, similar),
                        onFlyToCart: onFlyToCart,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
