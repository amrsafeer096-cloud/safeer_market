import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Golden coins that arc from [start] to [end] with staggered delays.
class FlyingCoinsOverlay extends StatefulWidget {
  const FlyingCoinsOverlay({
    super.key,
    required this.start,
    required this.end,
    this.count = 7,
    this.onCoinArrive,
    this.onComplete,
  });

  final Offset start;
  final Offset end;
  final int count;
  final ValueChanged<int>? onCoinArrive;
  final VoidCallback? onComplete;

  @override
  State<FlyingCoinsOverlay> createState() => _FlyingCoinsOverlayState();
}

class _FlyingCoinsOverlayState extends State<FlyingCoinsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _completed = false;
  final _arrived = <int>{};

  @override
  void initState() {
    super.initState();
    final totalMs = 900 + (widget.count - 1) * 70;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..addListener(_onTick)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete?.call();
      }
    });
    _controller.forward();
  }

  void _onTick() {
    for (var i = 0; i < widget.count; i++) {
      if (_arrived.contains(i)) continue;
      final local = _localProgress(i);
      if (local >= 0.98) {
        _arrived.add(i);
        widget.onCoinArrive?.call(i);
      }
    }
  }

  double _localProgress(int index) {
    final stagger = (index * 0.07).clamp(0.0, 0.45);
    final span = 1.0 - stagger;
    if (span <= 0) return 1;
    final raw = ((_controller.value - stagger) / span).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(raw);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              for (var i = 0; i < widget.count; i++)
                _coinAt(i),
            ],
          );
        },
      ),
    );
  }

  Widget _coinAt(int index) {
    final t = _localProgress(index);
    if (t <= 0) return const SizedBox.shrink();

    // Quadratic bezier: start → lifted mid → end.
    final mid = Offset(
      (widget.start.dx + widget.end.dx) / 2 +
          (index.isEven ? -36.0 : 36.0) * (0.4 + index * 0.05),
      math.min(widget.start.dy, widget.end.dy) - 90 - index * 6,
    );
    final pos = _quad(widget.start, mid, widget.end, t);
    final scale = 0.85 + 0.35 * math.sin(t * math.pi);
    final opacity = t < 0.08
        ? t / 0.08
        : t > 0.9
            ? (1 - t) / 0.1
            : 1.0;

    return Positioned(
      left: pos.dx - 14,
      top: pos.dy - 14,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: const _GoldenCoin(),
        ),
      ),
    );
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }
}

class _GoldenCoin extends StatelessWidget {
  const _GoldenCoin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFD54F),
            Color(0xFFFFA000),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFF8E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '★',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFBF360C),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
