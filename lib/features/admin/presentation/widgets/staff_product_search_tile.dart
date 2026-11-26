import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../domain/product_search_filter.dart';

/// Funnel `PopupMenuButton` for the three product-search modes.
class ProductSearchFilterButton extends StatelessWidget {
  const ProductSearchFilterButton({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ProductSearchFilterMode mode;
  final ValueChanged<ProductSearchFilterMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final active = !mode.isDefault;
    return PopupMenuButton<ProductSearchFilterMode>(
      key: const Key('product-search-filter'),
      tooltip: 'فلتر البحث',
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in ProductSearchFilterMode.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == mode,
            child: Text(option.label),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Badge(
          isLabelVisible: active,
          smallSize: 8,
          backgroundColor: Colors.orange.shade700,
          child: Icon(
            active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            color: active ? Colors.orange.shade800 : null,
          ),
        ),
      ),
    );
  }
}

/// Red offer chip: «خصم 15% • 85.00 ج.م بدل 100.00 ج.م».
class ProductOfferBadge extends StatelessWidget {
  const ProductOfferBadge({super.key, required this.product});

  final Product product;

  static const _bg = Color(0xFFFEE2E2);
  static const _border = Color(0xFFFCA5A5); // red.shade300-ish
  static const _fg = Color(0xFFB91C1C);

  @override
  Widget build(BuildContext context) {
    if (!product.hasActiveOffer) return const SizedBox.shrink();
    final pct = product.discountPercentage;
    final detail = pct > 0
        ? 'خصم $pct% • ${AppCurrency.of(product.effectivePrice)} بدل ${AppCurrency.of(product.price)}'
        : 'بدل ${AppCurrency.of(product.price)}';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(
        detail,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}

class ProductBarcodeCopyRow extends StatelessWidget {
  const ProductBarcodeCopyRow({
    super.key,
    required this.productId,
    required this.barcode,
    this.keyPrefix = 'staff-product',
  });

  final String productId;
  final String barcode;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: 'نسخ الباركود',
      child: InkWell(
        key: Key('$keyPrefix-barcode-$productId'),
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(ClipboardData(text: barcode.trim()));
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              duration: Duration(seconds: 2),
              content: Text('تم نسخ الباركود'),
            ));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.copy_rounded, size: 13, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

Color staffStockColor(int stock, AppPalette palette) {
  if (stock <= 0) return Colors.red.shade700;
  if (stock <= 5) return Colors.orange.shade800;
  return const Color(0xFF334155);
}

/// Shared staff product row (phone orders + edit-order search).
class StaffProductSearchTile extends StatelessWidget {
  const StaffProductSearchTile({
    super.key,
    required this.product,
    required this.quantityLabel,
    required this.onAdd,
    required this.onRemove,
    this.onOpen,
    this.openOnDoubleTap = false,
    this.inCart = false,
    this.showZeroStockInRed = false,
    this.keyPrefix = 'staff-product',
  });

  final Product product;
  final String quantityLabel;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onOpen;

  /// When true (تلقي الطلبات), open details on double-tap instead of tap.
  final bool openOnDoubleTap;
  final bool inCart;

  /// When filter is «كل الأصناف», force red styling for `stock <= 0`.
  final bool showZeroStockInRed;

  /// Widget key namespace: `phone-order` for تلقي الطلبات tests/UI.
  final String keyPrefix;

  static const _narrowWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final stockQty = product.stockQuantity;
    final stockColor = (showZeroStockInRed || stockQty <= 0)
        ? staffStockColor(stockQty, palette)
        : staffStockColor(stockQty, palette);

    final image = SizedBox.square(
      dimension: 62,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: ProductImage(
            imageUrl: product.hasValidImageUrl ? product.imageUrl : null,
            iconSize: 26,
            fit: BoxFit.contain,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.35,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppCurrency.of(product.effectivePrice)} / ${product.displayUnit}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        ProductOfferBadge(product: product),
        if (product.barcode case final barcode?
            when barcode.trim().isNotEmpty)
          ProductBarcodeCopyRow(
            productId: product.id,
            barcode: barcode,
            keyPrefix: keyPrefix,
          ),
      ],
    );

    final stock = Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
      child: Text(
        'المخزون: $stockQty',
        key: Key('$keyPrefix-stock-${product.id}'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: stockColor,
        ),
      ),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('$keyPrefix-dec-${product.id}'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: inCart ? onRemove : null,
          icon: Icon(
            Icons.remove_circle_outline,
            color: inCart ? palette.accent : palette.muted,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 30),
          child: Text(
            quantityLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: inCart ? palette.accent : palette.muted,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          key: Key('$keyPrefix-add-${product.id}'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_rounded, color: palette.accent),
        ),
      ],
    );

    // phone-order uses «product» in the row key for existing widget tests.
    final rowKey = keyPrefix == 'phone-order'
        ? 'phone-order-product-${product.id}'
        : '$keyPrefix-row-${product.id}';

    return Material(
      color: palette.card,
      child: InkWell(
        key: Key(rowKey),
        onTap: openOnDoubleTap ? null : onOpen,
        onDoubleTap: openOnDoubleTap ? onOpen : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 4, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _narrowWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        image,
                        const SizedBox(width: 10),
                        Expanded(child: info),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [stock, controls],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  image,
                  const SizedBox(width: 10),
                  Expanded(child: info),
                  stock,
                  controls,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
