import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_banner.dart';
import '../providers/home_banners_providers.dart';
import '../providers/product_visibility_provider.dart';
import '../screens/product_list_screen.dart';
import 'banner_form_dialog.dart';

/// Home ad deck: the front card with two more peeking out below it (which
/// also tell the user there is more). Swipes either way, loops forever, and
/// advances on its own every [interval] unless a finger is on it.
///
/// Shows the company/brand banners admins uploaded ([homeBannersProvider]);
/// tapping one opens that company's products. Until any exist, it shows the
/// built-in store promos. Admins get a «+» to upload a banner.
class PromoCarousel extends ConsumerStatefulWidget {
  const PromoCarousel({
    super.key,
    this.interval = const Duration(seconds: 4),
  });

  final Duration interval;

  static const cardHeight = 168.0;
  static const radius = 22.0;
  static const transition = Duration(milliseconds: 550);

  @override
  ConsumerState<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<PromoCarousel>
    with SingleTickerProviderStateMixin {
  static List<_DeckItem> _promos(AppLocalizations l10n) => [
        _DeckItem.promo(
          title: l10n.promoEndlessOffersTitle,
          subtitle: l10n.promoEndlessOffersSubtitle,
          icon: Icons.local_offer_rounded,
          colors: const [AppColors.primary, Color(0xFF1565C0)],
        ),
        _DeckItem.promo(
          title: l10n.promoSavingsStoreTitle,
          subtitle: l10n.promoSavingsStoreSubtitle,
          icon: Icons.savings_rounded,
          colors: const [Color(0xFFB71C1C), AppColors.secondary],
        ),
        _DeckItem.promo(
          title: l10n.promoOpeningDiscountsTitle,
          subtitle: l10n.promoOpeningDiscountsSubtitle,
          icon: Icons.celebration_rounded,
          colors: const [AppColors.primary, AppColors.secondary],
        ),
        _DeckItem.promo(
          title: l10n.promoFreeDeliveryTitle,
          subtitle: l10n.promoFreeDeliverySubtitle,
          icon: Icons.delivery_dining_rounded,
          colors: const [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
      ];

  static const _horizontalPadding = 16.0;

  /// How each card sits at depth 0 (front), 1, 2 (peeking) and 3 (hidden,
  /// fading in behind the deck as the front card leaves).
  static const _scales = [1.0, 0.93, 0.86, 0.80];
  static const _drops = [0.0, 10.0, 20.0, 28.0];
  static const _opacities = [1.0, 0.9, 0.75, 0.0];

  /// Room below the front card for the peeking cards and its shadow.
  static const _deckBottom = 20.0 + 14.0;

  /// Swipe progress: 0 at rest, towards 1 while the front card leaves for the
  /// next banner, towards -1 while the previous banner slides back in.
  late final AnimationController _swipe = AnimationController(
    vsync: this,
    lowerBound: -1,
    upperBound: 1,
    value: 0,
    duration: PromoCarousel.transition,
  );

  /// Index of the banner at the front.
  int _front = 0;
  Timer? _timer;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _swipe.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted && !_touching && !_swipe.isAnimating) _settle(1);
    });
  }

  void _pauseAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  /// Animates to [target] (-1 previous, 0 back to rest, 1 next); past a full
  /// swipe, that banner becomes the front one.
  Future<void> _settle(double target) async {
    await _swipe.animateTo(target, curve: Curves.easeOutQuart);
    if (!mounted || target == 0) return;
    setState(() => _front += target.toInt());
    _swipe.value = 0;
  }

  void _onDragUpdate(DragUpdateDetails details, double width, bool rtl) {
    // Dragging against the reading direction brings the next banner.
    final moved = details.primaryDelta! / width;
    _swipe.value += rtl ? moved : -moved;
  }

  void _onDragEnd(DragEndDetails details, double width, bool rtl) {
    final velocity = details.primaryVelocity! / width * (rtl ? 1 : -1);
    final progress = _swipe.value;
    final target = velocity.abs() > 1
        ? velocity.sign
        : progress.abs() > 0.3
            ? progress.sign
            : 0.0;
    _settle(target);
  }

  void _open(_DeckItem item) {
    final banner = item.banner;
    if (banner == null || !banner.opensProducts) return;
    ProductListScreen.open(
      context,
      title: banner.title.isEmpty ? banner.brandQuery : banner.title,
      products: brandProductsProvider(banner.brandQuery.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploaded = ref.watch(homeBannersProvider).valueOrNull ?? const [];
    final items = uploaded.isEmpty
        ? _promos(l10n)
        : [for (final banner in uploaded) _DeckItem.banner(banner)];
    final isAdmin = ref.watch(showProductsWithoutImageProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 2 * _horizontalPadding;
        return Listener(
          onPointerDown: (_) {
            _touching = true;
            _pauseAutoPlay();
          },
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _swipe.stop(),
            onHorizontalDragUpdate: (details) =>
                _onDragUpdate(details, width, rtl),
            onHorizontalDragEnd: (details) => _onDragEnd(details, width, rtl),
            child: SizedBox(
              height: PromoCarousel.cardHeight + _deckBottom,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _swipe,
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.none,
                      children: _cards(items, width, rtl),
                    ),
                  ),
                  if (isAdmin)
                    PositionedDirectional(
                      top: 10,
                      start: _horizontalPadding + 10,
                      child: _AdminAddBannerButton(
                        tooltip: l10n.bannerAdd,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => BannerFormDialog(
                            existing: uploaded,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _release() {
    _touching = false;
    _startAutoPlay();
  }

  List<Widget> _cards(List<_DeckItem> items, double width, bool rtl) {
    final progress = _swipe.value;
    if (items.isEmpty) return const [];
    // At most one card per banner on screen at a time.
    final behind = math.min(2, items.length - 2).clamp(0, 2);
    final cards = <({double depth, Widget card})>[];
    for (var k = -1; k <= behind + 1; k++) {
      final depth = k - progress;
      if (depth <= -1 || depth >= behind + 1) continue;
      final index = (_front + k) % items.length;
      final item = items[index];
      cards.add((
        depth: depth,
        card: _positioned(
          depth: depth,
          width: width,
          rtl: rtl,
          child: _DeckCard(
            key: ValueKey(item.key),
            item: item,
            onTap:
                item.banner?.opensProducts ?? false ? () => _open(item) : null,
          ),
        ),
      ));
    }
    // Deepest first; the card leaving (or coming back) ends up on top.
    cards.sort((a, b) => b.depth.compareTo(a.depth));
    return [for (final c in cards) c.card];
  }

  Widget _positioned({
    required double depth,
    required double width,
    required bool rtl,
    required Widget child,
  }) {
    final double scale, drop, opacity, slide;
    if (depth < 0) {
      // Off to the side: sliding out after a swipe, or back in.
      scale = 1;
      drop = 0;
      opacity = 1 + depth;
      slide = depth * width * (rtl ? -1 : 1);
    } else {
      scale = _lerpAt(_scales, depth);
      drop = _lerpAt(_drops, depth);
      opacity = _lerpAt(_opacities, depth);
      slide = 0;
    }

    final isFront = depth.abs() < 0.5;
    return Positioned(
      left: _horizontalPadding,
      right: _horizontalPadding,
      top: 0,
      height: PromoCarousel.cardHeight,
      child: IgnorePointer(
        ignoring: !isFront,
        child: ExcludeSemantics(
          excluding: !isFront,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.translationValues(slide, drop, 0)
                ..rotateZ(slide / width * 0.12)
                ..scaleByDouble(scale, scale, 1, 1),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Linear interpolation through [values] given at depths 0, 1, 2, …
  static double _lerpAt(List<double> values, double depth) {
    final lower = depth.floor().clamp(0, values.length - 1);
    final upper = math.min(lower + 1, values.length - 1);
    final t = (depth - lower).clamp(0.0, 1.0);
    return values[lower] + (values[upper] - values[lower]) * t;
  }
}

/// One card of the deck: either an uploaded company [banner] or a built-in
/// promo drawn from [title], [subtitle], [icon] and [colors].
class _DeckItem {
  const _DeckItem.promo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  }) : banner = null;

  _DeckItem.banner(HomeBanner this.banner)
      : title = banner.title,
        subtitle = null,
        icon = null,
        colors = const [AppColors.primaryDark, AppColors.primary];

  final HomeBanner? banner;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color> colors;

  Object get key => banner?.id ?? title;
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({super.key, required this.item, required this.onTap});

  final _DeckItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final banner = item.banner;
    final radius = BorderRadius.circular(PromoCarousel.radius);
    return Semantics(
      button: onTap != null,
      label: item.title,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: context.palette.isDark
                ? null
                : [
                    // Ambient, then a tighter tinted drop: reads as real depth.
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: item.colors.first.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (banner != null)
                  _BannerImage(banner: banner)
                else
                  _PromoArt(item: item),
                // Sleek bottom gradient so text and the badge stay crisp over
                // any photo.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1],
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
                // Glassmorphic rim.
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                if (banner != null)
                  _BannerCaption(item: item)
                else
                  _PromoCaption(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: banner.imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 800,
      maxWidthDiskCache: 1200,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholderFadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
      ),
      errorWidget: (_, __, ___) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: Center(
          child:
              Icon(Icons.storefront_rounded, size: 56, color: Colors.white54),
        ),
      ),
    );
  }
}

/// Title and the «تسوق منتجات الشركة ←» badge over a company banner.
class _BannerCaption extends StatelessWidget {
  const _BannerCaption({required this.item});

  final _DeckItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final opens = item.banner?.opensProducts ?? false;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (item.title.isNotEmpty)
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          if (opens) ...[
            const SizedBox(height: 8),
            _CtaBadge(
              label: l10n.bannerShopBrandProducts,
              color: context.palette.accent,
              trailingArrow: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// The built-in promo look: gradient, bubbles and a big icon.
class _PromoArt extends StatelessWidget {
  const _PromoArt({required this.item});

  final _DeckItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: item.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const PositionedDirectional(
            end: -30,
            top: -40,
            child: _Bubble(size: 150, opacity: 0.1),
          ),
          const PositionedDirectional(
            end: 70,
            bottom: -60,
            child: _Bubble(size: 120, opacity: 0.07),
          ),
          PositionedDirectional(
            end: 20,
            top: 0,
            bottom: 0,
            child: Icon(
              item.icon,
              size: 72,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCaption extends StatelessWidget {
  const _PromoCaption({required this.item});

  final _DeckItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 110, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.title,
            maxLines: 2,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 12),
          _CtaBadge(
            label: AppLocalizations.of(context)!.shopNow,
            color: item.colors.first,
          ),
        ],
      ),
    );
  }
}

class _CtaBadge extends StatelessWidget {
  const _CtaBadge({
    required this.label,
    required this.color,
    this.trailingArrow = false,
  });

  final String label;
  final Color color;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The deep banner hues are unreadable on the dark pill; lift them.
    final ink =
        palette.isDark ? Color.lerp(color, palette.onSurface, 0.6)! : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(99),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1.2,
            ),
          ),
          if (trailingArrow) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_back_rounded, size: 16, color: ink),
          ],
        ],
      ),
    );
  }
}

class _AdminAddBannerButton extends StatelessWidget {
  const _AdminAddBannerButton({
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: palette.card.withValues(alpha: 0.92),
        foregroundColor: palette.accent,
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        elevation: palette.isDark ? 0 : 4,
        shadowColor: Colors.black45,
      ),
      icon: const Icon(Icons.add_photo_alternate_outlined),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
