import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../cart/presentation/widgets/cart_flight.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../domain/entities/product.dart';
import '../providers/product_visibility_provider.dart';
import '../widgets/product_card.dart';

/// «عرض الكل» for a home section: every product of [products] in a grid.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<Product>>> products;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required ProviderListenable<AsyncValue<List<Product>>> products,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListScreen(title: title, products: products),
      ),
    );
  }

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _cartKey = GlobalKey<CartIconKey>();

  Future<void> _flyToCart(GlobalKey imageKey) =>
      flyToCart(imageKey: imageKey, cartKey: _cartKey);

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref
        .watch(widget.products)
        .whenData((products) => shownProducts(ref, products));
    final palette = context.palette;

    return MobileFrame(
      color: palette.page,
      child: Scaffold(
        backgroundColor: palette.page,
        appBar: AppBar(
          backgroundColor: palette.page,
          surfaceTintColor: Colors.transparent,
          foregroundColor: palette.onSurface,
          title: Text(
            widget.title,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.onSurface,
            ),
          ),
          actions: [
            AddToCartIcon(
              key: _cartKey,
              badgeOptions: const BadgeOptions(active: false),
              icon: const CartIconButton(),
            ),
          ],
        ),
        body: switch (productsAsync.valueOrNull) {
          null when productsAsync.isLoading =>
            const Center(child: CircularProgressIndicator()),
          final products? when products.isNotEmpty => GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.58,
              ),
              addAutomaticKeepAlives: false,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return RepaintBoundary(
                  child: ProductCard(
                    product: product,
                    onAdd: () => addToCartWithFeedback(context, ref, product),
                    onFlyToCart: _flyToCart,
                  ),
                );
              },
            ),
          _ => Center(
              child: Text(
                AppLocalizations.of(context)!.noProductsCurrently,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.muted,
                ),
              ),
            ),
        },
      ),
    );
  }
}
