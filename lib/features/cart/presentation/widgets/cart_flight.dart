import 'dart:async';
import 'dart:math' as math;

import 'package:add_to_cart_animation/add_to_cart_animation.dart'
    show CartIconKey;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/audio/app_sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../home/presentation/widgets/app_list_item.dart';
import '../../../home/presentation/widgets/product_image.dart';

/// Subtle double light tap plus a bubbly pop used when a product flies into
/// the cart.
void premiumCartAddHaptic() {
  AppSoundService.instance.playCartPop();
  HapticFeedback.lightImpact();
  Future<void>.delayed(const Duration(milliseconds: 120), () {
    HapticFeedback.lightImpact();
  });
}

/// Flies a copy of the product photo behind [imageKey] into the cart icon
/// behind [cartKey], then bumps the icon.
///
/// The source box and the target box are measured, and the overlay entry is
/// inserted, synchronously before this returns its future, so callers can
/// launch the flight and then update the cart in the same event handler
/// without the source widget's rebuild racing the first animation frame.
///
/// The flying widget is a fixed-size [Image] on the same in-memory
/// [ImageProvider] the source [ProductImage] resolved, so it paints on its
/// first frame instead of flashing a placeholder, and is scaled with a
/// transform rather than re-laid out, so it never resizes mid-flight.
///
/// The flight is skipped (the icon still bumps) when the source is not
/// mounted or has scrolled out of view. [topInset] is the height of anything
/// pinned over the content (app bar); a source whose centre sits above it is
/// treated as hidden.
Future<void> flyToCart({
  required GlobalKey imageKey,
  required GlobalKey<CartIconKey> cartKey,
  double topInset = 0,
}) async {
  final cartContext = cartKey.currentContext;
  if (cartContext == null || !cartContext.mounted) return;

  final flight = _CartFlight.capture(
    imageKey: imageKey,
    cartContext: cartContext,
    topInset: topInset,
  );
  if (flight != null) await flight.run();

  await cartKey.currentState?.runCartAnimation();
}

class _CartFlight {
  _CartFlight._({
    required this.overlay,
    required this.source,
    required this.target,
    required this.child,
  });

  static const duration = Duration(milliseconds: 750);

  /// How far above the straight line the flight path arcs.
  static const arcHeight = 48.0;

  final OverlayState overlay;
  final Rect source;
  final Rect target;
  final Widget child;

  /// Measures the boxes now; null when the source cannot fly.
  static _CartFlight? capture({
    required GlobalKey imageKey,
    required BuildContext cartContext,
    required double topInset,
  }) {
    final sourceContext = imageKey.currentContext;
    if (sourceContext == null || !sourceContext.mounted) return null;
    final sourceBox = sourceContext.findRenderObject();
    final cartBox = cartContext.findRenderObject();
    if (sourceBox is! RenderBox || cartBox is! RenderBox) return null;
    if (!_isLaidOut(sourceBox) || !_isLaidOut(cartBox)) return null;

    final overlay = Overlay.maybeOf(sourceContext, rootOverlay: true);
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null || overlayBox is! RenderBox) return null;

    final source = sourceBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
        sourceBox.size;
    final target =
        cartBox.localToGlobal(Offset.zero, ancestor: overlayBox) & cartBox.size;

    final screen = Offset.zero & overlayBox.size;
    if (!screen.contains(source.center) || source.center.dy < topInset) {
      return null;
    }

    // The key sits on the box AppListItem builds, so the item is its parent.
    final imageUrl =
        sourceContext.findAncestorWidgetOfExactType<AppListItem>()?.imageUrl;
    final provider = ProductImage.cachedProvider(
      imageUrl,
      width: source.width,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(sourceContext),
    );

    return _CartFlight._(
      overlay: overlay,
      source: source,
      target: target,
      child: SizedBox(
        width: source.width,
        height: source.height,
        child: provider == null
            ? Icon(
                Icons.local_grocery_store_outlined,
                size: math.min(source.width, source.height) * 0.6,
                color: sourceContext.palette.accent.withValues(alpha: 0.6),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: provider,
                  width: source.width,
                  height: source.height,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                ),
              ),
      ),
    );
  }

  static bool _isLaidOut(RenderBox box) =>
      box.attached && box.hasSize && !box.size.isEmpty;

  Future<void> run() async {
    final done = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CartFlightOverlay(
        flight: this,
        onDone: () {
          entry.remove();
          entry.dispose();
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    overlay.insert(entry);
    await done.future;
  }
}

class _CartFlightOverlay extends StatefulWidget {
  const _CartFlightOverlay({required this.flight, required this.onDone});

  final _CartFlight flight;
  final VoidCallback onDone;

  @override
  State<_CartFlightOverlay> createState() => _CartFlightOverlayState();
}

class _CartFlightOverlayState extends State<_CartFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _CartFlight.duration,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: _targetScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.4), weight: 30),
  ]).animate(_controller);

  double get _targetScale {
    final source = widget.flight.source;
    final target = widget.flight.target;
    final ratio = math.min(
      target.width / source.width,
      target.height / source.height,
    );
    return ratio.clamp(0.1, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.flight.source;
    final target = widget.flight.target;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.flight.child,
        builder: (context, child) {
          final t = _progress.value;
          final center = Offset.lerp(source.center, target.center, t)! -
              Offset(0, _CartFlight.arcHeight * math.sin(math.pi * t));
          return Stack(
            children: [
              Positioned(
                left: center.dx - source.width / 2,
                top: center.dy - source.height / 2,
                width: source.width,
                height: source.height,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Opacity(opacity: _opacity.value, child: child),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
