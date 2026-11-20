import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';

/// Whether the quick actions may loop their animations. Even when true they
/// stand still if the platform asks for reduced motion.
final quickActionsMotionProvider = Provider<bool>((ref) => true);

/// The home screen's row of shortcut tiles: raised, softly glowing icon
/// buttons, each tinted to its theme, with the title underneath.
/// «أحدث المنتجات» carries a pulsing NEW pill and «العب واكسب» a gently
/// floating icon with a gold sparkle.
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onNewProducts,
    required this.onOffers,
    required this.onPlayAndWin,
    required this.onCategories,
    required this.onMagazines,
  });

  final VoidCallback onNewProducts;
  final VoidCallback onOffers;
  final VoidCallback onPlayAndWin;
  final VoidCallback onCategories;
  final VoidCallback onMagazines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      _QuickActionTile(
        title: l10n.quickActionLatestProducts,
        onTap: onNewProducts,
        tint: context.palette.accent,
        badge: const _NewBadge(),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      _QuickActionTile(
        title: l10n.quickActionOffers,
        onTap: onOffers,
        tint: AppColors.secondary,
        child: const Icon(Icons.local_offer_outlined),
      ),
      _QuickActionTile(
        title: l10n.quickActionPlayAndWin,
        onTap: onPlayAndWin,
        tint: const Color(0xFF7B1FA2),
        cornerBadge: const _SparkleBadge(),
        child: const _FloatingIcon(Icons.extension_outlined),
      ),
      _QuickActionTile(
        title: l10n.magazines,
        onTap: onMagazines,
        tint: const Color(0xFF00897B),
        child: const Icon(Icons.menu_book_outlined),
      ),
      _QuickActionTile(
        title: l10n.categories,
        onTap: onCategories,
        tint: const Color(0xFFEF6C00),
        child: const Icon(Icons.grid_view_rounded),
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final tile in tiles) Expanded(child: tile)],
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.title,
    required this.onTap,
    required this.tint,
    required this.child,
    this.badge,
    this.cornerBadge,
  });

  static const boxSize = 64.0;
  static const _radius = 20.0;

  final String title;
  final VoidCallback onTap;

  /// Theme colour of the icon, its gradient and its glow.
  final Color tint;

  /// The tile's icon, centred in the box.
  final Widget child;

  /// Floats over the middle of the box's top edge.
  final Widget? badge;

  /// Sits on the box's top-end corner.
  final Widget? cornerBadge;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tint = widget.tint;
    final palette = context.palette;
    final radius = BorderRadius.circular(_QuickActionTile._radius);
    return Semantics(
      button: true,
      label: widget.title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Transform, not AnimatedScale: only the NEW pill may own a
                  // ScaleTransition.
                  Transform.scale(
                    scale: _pressed ? 0.94 : 1,
                    child: Container(
                      width: _QuickActionTile.boxSize,
                      height: _QuickActionTile.boxSize,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.card,
                            tint.withValues(alpha: 0.12),
                          ],
                        ),
                        border: Border.all(
                          color: tint.withValues(alpha: 0.18),
                        ),
                        boxShadow: palette.isDark
                            ? null
                            : [
                                // Coloured glow under the tile plus a soft lift.
                                BoxShadow(
                                  color: tint.withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  blurRadius: 6,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(size: 29, color: tint),
                        child: Center(child: widget.child),
                      ),
                    ),
                  ),
                  if (widget.badge case final badge?)
                    Positioned(
                      top: -8,
                      left: 0,
                      right: 0,
                      child: Center(child: badge),
                    ),
                  if (widget.cornerBadge case final cornerBadge?)
                    PositionedDirectional(
                      top: -4,
                      end: -4,
                      child: cornerBadge,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: palette.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red NEW pill that pulses 1.0 → 1.06 every 1.5 s.
class _NewBadge extends ConsumerStatefulWidget {
  const _NewBadge();

  @override
  ConsumerState<_NewBadge> createState() => _NewBadgeState();
}

class _NewBadgeState extends ConsumerState<_NewBadge>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final _scale = Tween(begin: 1.0, end: 1.06)
      .chain(CurveTween(curve: Curves.easeInOut))
      .animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loopUnlessReducedMotion(context, ref, _pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          ),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: palette.card, width: 1.5),
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0.4,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// An icon that drifts 2 px up and down.
class _FloatingIcon extends ConsumerStatefulWidget {
  const _FloatingIcon(this.icon);

  final IconData icon;

  @override
  ConsumerState<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends ConsumerState<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final _offset = Tween(begin: 2.0, end: -2.0)
      .chain(CurveTween(curve: Curves.easeInOut))
      .animate(_float);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loopUnlessReducedMotion(context, ref, _float);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, icon) => Transform.translate(
        offset: Offset(0, _float.isAnimating ? _offset.value : 0),
        child: icon,
      ),
      child: Icon(widget.icon),
    );
  }
}

class _SparkleBadge extends StatelessWidget {
  const _SparkleBadge();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: palette.card, width: 1.5),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
      ),
      child: const Icon(Icons.auto_awesome, size: 11, color: Colors.white),
    );
  }
}

/// Starts [controller] looping back and forth, or parks it at rest when
/// motion is off ([quickActionsMotionProvider] false or reduced motion).
void loopUnlessReducedMotion(
  BuildContext context,
  WidgetRef ref,
  AnimationController controller,
) {
  if (!ref.read(quickActionsMotionProvider) ||
      MediaQuery.disableAnimationsOf(context)) {
    controller.value = 0;
  } else if (!controller.isAnimating) {
    controller.repeat(reverse: true);
  }
}
