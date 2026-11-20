import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_palette.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.size,
    this.fallbackColor,
  });

  static const assetPath = 'assets/images/logo.png';

  final double size;

  /// Colour of the fallback icon; the palette's accent when null.
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticLabel: AppLocalizations.of(context)?.appTitle,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.storefront_rounded,
          size: size * 0.75,
          color: fallbackColor ?? context.palette.accent,
        ),
      ),
    );
  }
}
