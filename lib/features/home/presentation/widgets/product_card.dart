import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_flight.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/product.dart';
import '../providers/product_visibility_provider.dart';
import 'app_list_item.dart';
import 'missing_image_badge.dart';
import 'product_image.dart';
import 'product_image_canvas.dart';
import 'product_price.dart';

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    this.onFlyToCart,
  });

  final Product product;
  final VoidCallback onAdd;
  final Future<void> Function(GlobalKey imageKey)? onFlyToCart;

  // We add this to fix the skeleton error:
  static const radius = 16.0;

  static const _lightShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const _darkShadow = [
    BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  final GlobalKey imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(showProductsWithoutImageProvider);
    final lacksImage = productLacksImage(ref, widget.product);
    // Lists drop these through [shownProducts]; this covers any that don't.
    if (lacksImage && !isAdmin) return const SizedBox.shrink();
    final missingImage = lacksImage && isAdmin;
    final brokenImages = ref.read(brokenImageProductsProvider.notifier);
    final palette = context.palette;

    return InkWell(
      onTap: () {
        context.push(AppRoutes.product(widget.product.id),
            extra: widget.product);
      },
      borderRadius: BorderRadius.circular(ProductCard.radius),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(ProductCard.radius),
          // Dark mode: a hairline rim so the card lifts off the page.
          border: missingImage
              ? Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.55),
                  width: 1.5,
                )
              : palette.isDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.06))
                  : null,
          // One soft shadow: cards scroll in grids, so no stacked blurs.
          boxShadow: palette.isDark
              ? ProductCard._darkShadow
              : ProductCard._lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The only Expanded child: the photo takes all the space the
            // text and buttons below don't need, centred both ways.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: ProductImageCanvas(
                  overlays: [
                    Positioned(
                      top: 6,
                      right: 6,
                      child: FavoriteButton(product: widget.product),
                    ),
                    // Opposite corner from the favorite button.
                    Positioned(
                      top: 6,
                      left: 6,
                      child: OfferBadge(product: widget.product),
                    ),
                    if (missingImage)
                      PositionedDirectional(
                        bottom: 6,
                        start: 6,
                        child: MissingImageBadge(product: widget.product),
                      ),
                  ],
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: RepaintBoundary(
                        child: AppListItem(
                          flightKey: imageKey,
                          imageUrl: widget.product.imageUrl,
                          child: ProductImage(
                            // Known-broken links aren't requested again.
                            imageUrl:
                                lacksImage ? null : widget.product.imageUrl,
                            iconSize: 40,
                            fit: BoxFit.contain,
                            placeholderBackground: false,
                            onLoadFailed: (_) =>
                                brokenImages.report(widget.product),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Same price block as search and product details: the
                  // offer price with the regular one struck through.
                  ProductPrice(product: widget.product, fontSize: 14),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                // Only this product's line: a change elsewhere in the cart
                // doesn't rebuild every card on screen.
                final productId = widget.product.id;
                final cartItem = ref.watch(
                  cartProvider.select(
                    (items) => items
                        .where((item) => item.product.id == productId)
                        .firstOrNull,
                  ),
                );
                final quantity = cartItem?.quantity ?? 0;
                final cartNotifier = ref.read(cartProvider.notifier);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          // Launch the flight before the cart changes so the
                          // card's rebuild can't disturb its first frame.
                          premiumCartAddHaptic();
                          final flight = widget.onFlyToCart?.call(imageKey);
                          widget.onAdd();
                          await flight;
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (cartItem?.isWeightBased == true) {
                            cartNotifier.setWeight(
                              widget.product,
                              cartItem!.selectedWeightInGrams! - 250,
                            );
                          } else {
                            cartNotifier.updateQuantity(
                                widget.product.id, quantity - 1);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.remove_rounded,
                              color: palette.muted, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
