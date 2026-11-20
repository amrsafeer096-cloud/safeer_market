import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// The white "display box" product photos sit in. Product photos are JPEGs
/// shot on white, so instead of letting that white clash with a dark card,
/// every photo gets a white, padded, rounded canvas in both themes — the
/// white reads as part of the design, not as a cut-out.
///
/// Everything inside renders with the light theme, so placeholders and any
/// badges or buttons placed on the canvas ([overlays]) match it in dark mode.
class ProductImageCanvas extends StatelessWidget {
  const ProductImageCanvas({
    super.key,
    required this.child,
    this.overlays = const [],
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  static const color = Colors.white;

  /// Built once: re-creating [AppTheme.light] per card would cost a frame.
  static final ThemeData _lightTheme = AppTheme.light;

  /// The photo (or its placeholder).
  final Widget child;

  /// Widgets positioned over the canvas, e.g. favorite and offer badges.
  final List<Widget> overlays;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _lightTheme,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(
          color: color,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(padding: padding, child: child),
              ...overlays,
            ],
          ),
        ),
      ),
    );
  }
}
