import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class MobileFrame extends StatelessWidget {
  const MobileFrame({
    super.key,
    required this.child,
    this.color,
  });

  // رجعنا المتغير ده عشان النوافذ المنبثقة (Bottom Sheets) تقرأه ومتمطش على الشاشة الكبيرة
  static const double maxWidth = 500.0;

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? context.palette.card,
      width: double.infinity,
      height: double.infinity,
      child: child,
    );
  }
}
