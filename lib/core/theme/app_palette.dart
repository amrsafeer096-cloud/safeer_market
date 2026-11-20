import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's surface and text colors for the current brightness. Widgets
/// read these through [AppPaletteContext.palette] instead of fixed
/// [AppColors] / [Colors.white], so light mode looks exactly as designed and
/// dark mode has no white cards.
///
/// Brand fills that carry white content (primary buttons, headers, the red
/// secondary, success green) stay in [AppColors] in both modes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.page,
    required this.surface,
    required this.card,
    required this.onSurface,
    required this.muted,
    required this.imageBackdrop,
    required this.accent,
    required this.border,
    required this.shadow,
  });

  /// The values the app was designed with.
  static const light = AppPalette(
    background: AppColors.background,
    page: AppColors.card,
    surface: AppColors.surface,
    card: AppColors.card,
    onSurface: AppColors.onSurface,
    muted: AppColors.muted,
    imageBackdrop: AppColors.imageBackdrop,
    accent: AppColors.primary,
    border: Color(0x14000000),
    shadow: Color(0x14000000),
  );

  static const dark = AppPalette(
    background: Color(0xFF111316),
    page: Color(0xFF111316),
    surface: Color(0xFF1A1C20),
    card: Color(0xFF22252A),
    onSurface: Color(0xFFE6E8EC),
    muted: Color(0xFF9AA1AD),
    imageBackdrop: Color(0xFF2A2D33),
    accent: Color(0xFF7FB2E5),
    border: Color(0x1FFFFFFF),
    shadow: Color(0x33000000),
  );

  /// Behind the scaffold and grouped lists.
  final Color background;

  /// Pages laid out as white in light mode (home, product grids): darkest in
  /// dark mode, so cards on them stand out.
  final Color page;

  /// Pages, sheets and input fills (light grey in light mode).
  final Color surface;

  /// Cards, tiles, bars and anything that was white.
  final Color card;

  /// Main text and icons.
  final Color onSurface;

  /// Secondary text, hints and inactive icons.
  final Color muted;

  /// Behind product photos and image placeholders.
  final Color imageBackdrop;

  /// The brand blue as text, icons, outlines and tints on a surface; lighter
  /// in dark mode so it stays readable. Fills under white content keep
  /// [AppColors.primary].
  final Color accent;

  /// Hairline outlines.
  final Color border;

  /// Drop shadows: soft in light mode, barely there in dark mode.
  final Color shadow;

  bool get isDark => card.computeLuminance() < 0.2;

  @override
  AppPalette copyWith({
    Color? background,
    Color? page,
    Color? surface,
    Color? card,
    Color? onSurface,
    Color? muted,
    Color? imageBackdrop,
    Color? accent,
    Color? border,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      page: page ?? this.page,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      imageBackdrop: imageBackdrop ?? this.imageBackdrop,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      page: mix(page, other.page),
      surface: mix(surface, other.surface),
      card: mix(card, other.card),
      onSurface: mix(onSurface, other.onSurface),
      muted: mix(muted, other.muted),
      imageBackdrop: mix(imageBackdrop, other.imageBackdrop),
      accent: mix(accent, other.accent),
      border: mix(border, other.border),
      shadow: mix(shadow, other.shadow),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The [AppPalette] of the current theme ([AppPalette.light] outside one).
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
