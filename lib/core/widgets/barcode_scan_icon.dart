import 'package:flutter/material.dart';

/// Alias for the linear supermarket barcode glyph.
typedef BarcodeIcon = BarcodeScanIcon;

/// 1D product-barcode glyph (vertical bars), for scan actions and barcode
/// labels that used to show a QR icon.
class BarcodeScanIcon extends StatelessWidget {
  const BarcodeScanIcon({
    super.key,
    this.size = 22,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFF1A1C20);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BarcodeBarsPainter(resolved),
      ),
    );
  }
}

class _BarcodeBarsPainter extends CustomPainter {
  _BarcodeBarsPainter(this.color);

  final Color color;

  /// Relative bar widths (narrow / wide), like a simplified EAN strip.
  static const _pattern = <double>[
    1.2, 0.9, 1.8, 0.9, 1.2, 0.9, 2.2, 0.9, 1.2, 0.9, 1.6, 0.9, 1.2, 0.9, 2.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final total = _pattern.fold<double>(0, (sum, w) => sum + w);
    final unit = size.width / total;
    final top = size.height * 0.12;
    final bottom = size.height * 0.88;
    var x = 0.0;
    var draw = true;
    for (final width in _pattern) {
      final barWidth = width * unit;
      if (draw) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x, top, x + barWidth * 0.85, bottom),
            const Radius.circular(0.6),
          ),
          paint,
        );
      }
      x += barWidth;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeBarsPainter oldDelegate) =>
      oldDelegate.color != color;
}
