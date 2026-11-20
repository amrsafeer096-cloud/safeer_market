import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/domain/main_categories.dart';
import '../../../catalog/presentation/category_labels.dart';

/// «استكشف سفير»: 3 columns on mobile/portrait so icons stay large and
/// Arabic titles fit on 1–2 lines without ellipsis.
class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({super.key, required this.onCategoryTap});

  final ValueChanged<MainCategory> onCategoryTap;

  /// Mobile / portrait column count.
  static const columns = 3;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPortrait = size.height >= size.width;
    // Strict 3 columns on phones & portrait; a bit wider on large landscape.
    final crossAxisCount =
        (!isPortrait && size.shortestSide >= 600) ? 4 : columns;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        // Taller tiles: large image + up to 2 lines of Arabic label.
        childAspectRatio: crossAxisCount == 3 ? 0.72 : 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = MainCategories.all[index];
          return CategoryTile(
            category: category,
            onTap: () => onCategoryTap(category),
          );
        },
        childCount: MainCategories.all.length,
      ),
    );
  }
}

class CategoryTile extends StatefulWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});

  final MainCategory category;
  final VoidCallback onTap;

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
                    borderRadius: BorderRadius.circular(14),
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
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                        fontSize: 13.5,
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
