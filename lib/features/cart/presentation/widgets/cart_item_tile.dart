import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../home/presentation/widgets/product_image_canvas.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/weight_options.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final grams = item.selectedWeightInGrams;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 76,
            child: ProductImageCanvas(
              padding: const EdgeInsets.all(4),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              child: ProductImage(
                imageUrl: product.imageUrl,
                iconSize: 30,
                fit: BoxFit.contain,
                placeholderBackground: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name.isEmpty ? l10n.product : product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                Text(
                  '${AppCurrency.of(product.effectivePrice)} / '
                  '${product.displayUnit}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  AppCurrency.of(item.total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (grams == null)
            _QuantityStepper(
              label: '${item.quantity}',
              isLast: item.quantity == 1,
              incrementTooltip: l10n.increaseQuantity,
              decrementTooltip: l10n.decreaseQuantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            )
          else
            _QuantityStepper(
              label: WeightOptions.label(grams),
              labelWidth: 64,
              isLast: WeightOptions.previous(grams) == 0,
              incrementTooltip: l10n.increaseWeight,
              decrementTooltip: l10n.decreaseWeight,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.label,
    required this.isLast,
    required this.incrementTooltip,
    required this.decrementTooltip,
    required this.onIncrement,
    required this.onDecrement,
    this.labelWidth = 30,
  });

  final String label;

  /// Decrementing from here removes the item.
  final bool isLast;
  final String incrementTooltip;
  final String decrementTooltip;
  final double labelWidth;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: incrementTooltip,
            background: AppColors.primary,
            foreground: AppColors.onPrimary,
            onPressed: onIncrement,
          ),
          SizedBox(
            width: labelWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _PopText(
                label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _StepButton(
            icon: isLast ? Icons.delete_outline_rounded : Icons.remove_rounded,
            tooltip: isLast
                ? AppLocalizations.of(context)!.removeFromCart
                : decrementTooltip,
            background: palette.card,
            foreground: AppColors.secondary,
            onPressed: onDecrement,
          ),
        ],
      ),
    );
  }
}

/// Text that does a quick scale "pop" whenever [text] changes, so a quantity
/// change is felt on the number itself. It stays still on first build.
class _PopText extends StatefulWidget {
  const _PopText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_PopText> createState() => _PopTextState();
}

class _PopTextState extends State<_PopText>
    with SingleTickerProviderStateMixin {
  static final _pop = TweenSequence<double>([
    TweenSequenceItem(
      tween:
          Tween(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.45, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(_PopText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller.drive(_pop),
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: widget.style,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 32,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}
