import 'package:flutter/material.dart';

/// Marks [child] as the widget that flies into the cart.
///
/// `flyToCart` measures the box behind [flightKey] and flies a fixed-size
/// copy of the photo at [imageUrl] (or a placeholder icon when null), so the
/// live [child] is never rebuilt or re-laid out by the flight.
class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.flightKey,
    required this.child,
    this.imageUrl,
  });

  final GlobalKey flightKey;
  final Widget child;

  /// The product photo the flight shows; should be what [child] displays.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    // Fills whatever box it is given so [child] is centred both ways.
    return Container(
      key: flightKey,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: child,
    );
  }
}
