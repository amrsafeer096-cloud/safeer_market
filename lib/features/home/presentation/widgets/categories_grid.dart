import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/main_categories.dart';
import '../../../catalog/presentation/category_labels.dart';

/// Sizes of the categories grid on desktop web, shared with the section
/// header above it so both line up.
abstract final class CategoriesLayout {
  /// From this width the grid switches to its desktop layout.
  static const desktopBreakpoint = 900.0;

  /// The desktop grid never gets wider than this, centered.
  static const maxContentWidth = 1100.0;

  /// The home screen pads the grid by this much on each side already.
  static const pagePadding = 16.0;

  static bool isDesktop(double width) => width >= desktopBreakpoint;

  static double _contentWidth(double width) =>
      (width - 2 * pagePadding).clamp(0.0, maxContentWidth);

  /// 5 columns on a narrower desktop window, 6 on a wide one.
  static int desktopColumns(double width) =>
      _contentWidth(width) >= 1000 ? 6 : 5;

  /// Extra space on each side (beyond [pagePadding]) that centers the
  /// content in [maxContentWidth]; 0 on mobile.
  static double sideInset(double width) {
    if (!isDesktop(width)) return 0;
    return ((width - 2 * pagePadding) - maxContentWidth).clamp(0.0, 1e9) / 2;
  }
}

/// «استكشف سفير»: 3 columns on mobile/portrait so icons stay large and
/// Arabic titles fit on 1–2 lines without ellipsis. Desktop web (≥ 900 px)
/// shows a centered, compact 5–6 column grid instead.
class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key, required this.onCategoryTap});

  final ValueChanged<MainCategory> onCategoryTap;

  /// Mobile / portrait column count.
  static const columns = 3;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final desktop = CategoriesLayout.isDesktop(size.width);
    final isPortrait = size.height >= size.width;
    // Strict 3 columns on phones & portrait; a bit wider on large landscape.
    final crossAxisCount = desktop
        ? CategoriesLayout.desktopColumns(size.width)
        : (!isPortrait && size.shortestSide >= 600)
            ? 4
            : columns;

    final grid = SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: desktop ? 12 : 18,
        crossAxisSpacing: desktop ? 12 : 14,
        // Taller tiles: large image + up to 2 lines of Arabic label.
        // Desktop: near-square, compact tiles so fewer rows are needed.
        childAspectRatio: desktop ? 0.95 : (crossAxisCount == 3 ? 0.72 : 0.78),
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = MainCategories.all[index];
          return CategoryTile(
            category: category,
            compact: desktop,
            onTap: () => onCategoryTap(category),
          );
        },
        childCount: MainCategories.all.length,
      ),
    );

    final inset = CategoriesLayout.sideInset(size.width);
    if (inset == 0) return grid;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: grid,
    );
  }
}
class CategoryTile extends StatefulWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.compact = false,
  });

  final MainCategory category;
  final VoidCallback onTap;

  /// Smaller corners, gaps and label for the desktop grid.
  final bool compact;

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final name = localizedCategoryName(
      AppLocalizations.of(context)!,
      widget.category.name,
    );
    final palette = context.palette;
    return Semantics(
      button: true,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ColoredBox(
            color: Colors.transparent,
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.compact ? 12 : 14),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Image.asset(
                        widget.category.imageUrl,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.shopping_bag_outlined,
                          color: palette.muted,
                          size: widget.compact ? 30 : 40,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.compact ? 5 : 8),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      name,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: widget.compact ? 12.5 : 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: palette.isDark
                            ? palette.onSurface
                            : const Color(0xFF1A1C20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
