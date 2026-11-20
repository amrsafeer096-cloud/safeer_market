import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_palette.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        palette: AppPalette.light,
        appBar: AppColors.primary,
        onAppBar: AppColors.onPrimary,
        snackBar: AppColors.onSurface,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        palette: AppPalette.dark,
        appBar: AppPalette.dark.surface,
        onAppBar: AppPalette.dark.onSurface,
        snackBar: const Color(0xFF2C3036),
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required Color appBar,
    required Color onAppBar,
    required Color snackBar,
  }) {
    final background = palette.background;
    final surface = palette.surface;
    final card = palette.card;
    final onSurface = palette.onSurface;

    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: palette.accent,
      onPrimary: isDark ? AppColors.primaryDark : AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: surface,
      onSurface: onSurface,
      // Light keeps Material's derived tones, as designed.
      onSurfaceVariant: isDark ? palette.muted : null,
      surfaceContainerLowest: isDark ? card : null,
      surfaceContainerLow: isDark ? card : null,
      surfaceContainer: isDark ? card : null,
      surfaceContainerHigh: isDark ? card : null,
      outlineVariant: isDark ? palette.border : null,
    );

    final textTheme = GoogleFonts.cairoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [palette],
      scaffoldBackgroundColor: background,
      canvasColor: isDark ? card : null,
      cardColor: card,
      iconTheme: IconThemeData(color: onSurface),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      dividerColor: colorScheme.primary.withValues(alpha: 0.08),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      // Light keeps Material's default dialog and sheet tint.
      dialogTheme: isDark ? DialogThemeData(backgroundColor: card) : null,
      bottomSheetTheme:
          isDark ? BottomSheetThemeData(backgroundColor: card) : null,
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: onAppBar,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: onAppBar,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.cairo(color: palette.muted),
        hintStyle: GoogleFonts.cairo(
          color: palette.muted.withValues(alpha: 0.6),
        ),
        errorStyle: GoogleFonts.cairo(color: AppColors.secondary),
        prefixIconColor: colorScheme.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondary),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: card,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: palette.muted,
        showUnselectedLabels: true,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        textStyle: GoogleFonts.cairo(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBar,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
