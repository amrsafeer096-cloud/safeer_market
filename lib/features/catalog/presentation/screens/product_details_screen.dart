import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../cart/presentation/widgets/cart_flight.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../home/presentation/widgets/product_image_canvas.dart';
import '../../../home/presentation/widgets/product_price.dart';
import '../../../home/presentation/widgets/app_list_item.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/repositories/supabase_product_image_repository.dart';
import '../providers/catalog_providers.dart';
import '../widgets/similar_products_section.dart';
import 'product_image_viewer.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final String productId;
  final Product? initialProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = initialProduct;
    if (product != null) return _ProductDetailsView(product: product);

    final l10n = AppLocalizations.of(context)!;
    final productAsync = ref.watch(productByIdProvider(productId));
    return productAsync.when(
      data: (product) => product == null
          ? _DetailsMessage(message: l10n.productNotAvailable)
          : _ProductDetailsView(product: product),
      loading: () => const _DetailsMessage(loading: true),
      error: (error, _) => _DetailsMessage(
        message: l10n.productLoadFailed,
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
      ),
    );
  }
}

class _ProductDetailsView extends ConsumerStatefulWidget {
  const _ProductDetailsView({required this.product});
  final Product product;
  @override
  ConsumerState<_ProductDetailsView> createState() =>
      _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<_ProductDetailsView> {
  final GlobalKey<CartIconKey> _cartKey = GlobalKey<CartIconKey>();
  final GlobalKey _imageKey = GlobalKey();
  bool _isUploadingImage = false;
  String? _currentImageUrl; // متغير جديد لعرض الصورة اللحظية

  @override
  void initState() {
    super.initState();
    // تحميل رابط الصورة الحالي عند فتح الشاشة
    _currentImageUrl = widget.product.imageUrl;
  }

  Future<void> _flyToCart(GlobalKey imageKey) async {
    if (!mounted) return;
    premiumCartAddHaptic();
    await flyToCart(
      imageKey: imageKey,
      cartKey: _cartKey,
      topInset: MediaQuery.paddingOf(context).top + kToolbarHeight,
    );
  }

  // دالة التقاط ورفع الصورة
  Future<void> _pickAndUploadImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    // تم إزالة imageQuality: 70 لعرض الصور بجودة طبيعية في المعرض
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() => _isUploadingImage = true);
    final container = ProviderScope.containerOf(context, listen: false);

    try {
      final bytes = await pickedFile.readAsBytes();
      final imageUrl =
          await container.read(productImageRepositoryProvider).replaceImage(
                product: widget.product,
                bytes: bytes,
                fileExtension: pickedFile.name.split('.').last,
              );
      refreshAfterImageChange(container, widget.product.id, imageUrl);

      if (mounted) {
        setState(() => _currentImageUrl = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.productImageUpdated),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e is ProductImageFailure
                ? e.message
                : AppLocalizations.of(context)!.productImageUploadFailed('$e')),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImagePickerOptions() {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.updateProductImage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: palette.accent),
                title: Text(l10n.takePhotoWithCamera),
                onTap: () => _pickAndUploadImage(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: palette.accent),
                title: Text(l10n.chooseFromGallery),
                onTap: () => _pickAndUploadImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // التأكد من صلاحية الأدمن
    final userRoleState = ref.watch(userRoleProvider);
    final isAdmin = userRoleState.value == UserRole.admin;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.isDark ? palette.surface : const Color(0xFFF3F7FC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: screenHeight * 0.46,
              backgroundColor:
                  palette.isDark ? palette.surface : const Color(0xFFF3F7FC),
              foregroundColor: palette.onSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: _GlassCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: palette.onSurface,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: _GlassCircleButton(
                    child: AddToCartIcon(
                      key: _cartKey,
                      badgeOptions: const BadgeOptions(active: false),
                      icon: const CartIconButton(),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.isDark
                            ? palette.surface
                            : const Color(0xFFF3F7FC),
                        palette.card,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ProductImageCanvas.color,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: palette.isDark
                              ? palette.border
                              : const Color(0xFFE3E6EB),
                        ),
                        boxShadow: palette.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: ColoredBox(
                          color: ProductImageCanvas.color,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => showProductImageViewer(
                                  context,
                                  product,
                                  imageUrl: _currentImageUrl,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: AppListItem(
                                    flightKey: _imageKey,
                                    imageUrl: _currentImageUrl,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: ColoredBox(
                                        color: ProductImageCanvas.color,
                                        child: _isUploadingImage
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : ProductImage(
                                                imageUrl: _currentImageUrl,
                                                iconSize: 96,
                                                fit: BoxFit.contain,
                                                placeholderBackground: false,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isAdmin)
                                PositionedDirectional(
                                  bottom: 12,
                                  start: 12,
                                  child: _GlassCircleButton(
                                    icon: Icons.camera_alt_rounded,
                                    onPressed: _showImagePickerOptions,
                                    tooltip: AppLocalizations.of(context)!
                                        .changeProductImage,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _ProductInfo(product: product)),
            SliverToBoxAdapter(
              child: SimilarProductsSection(
                product: product,
                onFlyToCart: _flyToCart,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        bottomNavigationBar: _AddToCartBar(
          product: product,
          onAddTrigger: () => _flyToCart(_imageKey),
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    this.icon,
    this.child,
    this.onPressed,
    this.tooltip,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = Material(
      color: palette.card.withValues(alpha: 0.92),
      shape: CircleBorder(
        side: BorderSide(
          color: palette.isDark ? palette.border : const Color(0xFFE3E6EB),
        ),
      ),
      elevation: palette.isDark ? 0 : 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: icon == null
          ? child
          : IconButton(
              tooltip: tooltip,
              onPressed: onPressed,
              icon: Icon(icon, size: 20, color: palette.onSurface),
            ),
    );
    return button;
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = product.description;
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: palette.isDark ? palette.border : const Color(0xFFE3E6EB),
        ),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name.isEmpty ? l10n.product : product.name,
                  style: GoogleFonts.cairo(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    color: palette.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: palette.isDark
                    ? palette.surface
                    : const Color(0xFFF3F7FC),
                shape: const CircleBorder(),
                child: FavoriteButton(product: product),
              ),
            ],
          ),
          if (product.isWeightBased)
            Text(
              l10n.pricePerKiloChooseWeight,
              style: GoogleFonts.cairo(fontSize: 14, color: palette.muted),
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: ProductPrice(product: product, fontSize: 26),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OfferBadge(product: product),
                  if (product.hasActiveOffer) const SizedBox(height: 6),
                  _StockBadge(inStock: product.inStock),
                ],
              ),
            ],
          ),
          if (description != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Text(
              l10n.productDescription,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.7,
                color: palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.inStock});
  final bool inStock;
  @override
  Widget build(BuildContext context) {
    final color = inStock ? AppColors.success : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            inStock
                ? AppLocalizations.of(context)!.inStock
                : AppLocalizations.of(context)!.outOfStock,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToCartBar extends ConsumerWidget {
  const _AddToCartBar({required this.product, required this.onAddTrigger});

  final Product product;
  final VoidCallback onAddTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      cartProvider.select(
        (items) =>
            items.where((item) => item.product.id == product.id).firstOrNull,
      ),
    );

    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: 54,
          child: item == null
              ? _addButton(context, ref)
              : _QuantitySelector(item: item, onAddTrigger: onAddTrigger),
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton.icon(
      onPressed: product.inStock
          ? () => addToCartWithFeedback(
                context,
                ref,
                product,
                onAdding: onAddTrigger,
              )
          : null,
      icon: const Icon(Icons.add_shopping_cart_rounded),
      label: Text(product.inStock
          ? l10n.addToCartButton
          : l10n.productCurrentlyUnavailable),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuantitySelector extends ConsumerWidget {
  const _QuantitySelector({required this.item, required this.onAddTrigger});

  final CartItem item;
  final VoidCallback onAddTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.read(cartProvider.notifier);
    final product = item.product;
    final quantity = item.quantity;
    final grams = item.selectedWeightInGrams;
    final canAdd = switch (grams) {
      final grams? => WeightOptions.next(grams) != grams,
      null => product.inStock && quantity < product.stockQuantity,
    };
    final palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.productDetailsInCart,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  AppCurrency.of(item.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuantityButton(
                icon: Icons.add_rounded,
                tooltip:
                    grams == null ? l10n.increaseQuantity : l10n.increaseWeight,
                background: AppColors.secondary,
                foreground: AppColors.onSecondary,
                onPressed: !canAdd
                    ? null
                    : () {
                        onAddTrigger();
                        if (grams == null) {
                          cart.updateQuantity(product.id, quantity + 1);
                        } else {
                          cart.setWeight(product, WeightOptions.next(grams));
                        }
                      },
              ),
              SizedBox(
                width: grams == null ? 52 : 84,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    grams == null ? '$quantity' : WeightOptions.label(grams),
                    key: const Key('details-quantity'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.remove_rounded,
                tooltip:
                    grams == null ? l10n.decreaseQuantity : l10n.decreaseWeight,
                background: palette.card,
                foreground: AppColors.secondary,
                onPressed: grams == null
                    ? () => cart.updateQuantity(product.id, quantity - 1)
                    : () =>
                        cart.setWeight(product, WeightOptions.previous(grams)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? background : background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 24, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _DetailsMessage extends StatelessWidget {
  const _DetailsMessage({this.message, this.onRetry, this.loading = false});

  final String? message;
  final VoidCallback? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.productDetailsTitle)),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: palette.accent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onRetry,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
