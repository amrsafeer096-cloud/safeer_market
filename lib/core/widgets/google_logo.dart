import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four-colour Google "G", drawn so no image asset is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side * 0.2;
    final ring = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      side - stroke,
      side - stroke,
    );

    double rad(double degrees) => degrees * math.pi / 180;
    void arc(Color color, double from, double to) {
      canvas.drawArc(
        ring,
        rad(from),
        rad(to - from),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Angles run clockwise from 3 o'clock; the gap at the upper right is the
    // opening of the "G".
    arc(_blue, 0, 45);
    arc(_green, 45, 160);
    arc(_yellow, 160, 215);
    arc(_red, 215, 320);

    canvas.drawRect(
      Rect.fromLTRB(side / 2, (side - stroke) / 2, side - stroke / 4,
          (side + stroke) / 2),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
