import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/daily_game_cooldown.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../providers/daily_game_providers.dart';
import '../providers/rewards_providers.dart';
import '../widgets/flying_coins_overlay.dart';
import '../widgets/game_win_effects.dart';
import '../widgets/points_banner.dart';

class LuckyChestScreen extends ConsumerStatefulWidget {
  const LuckyChestScreen({super.key});

  @override
  ConsumerState<LuckyChestScreen> createState() => _LuckyChestScreenState();
}

class _LuckyChestScreenState extends ConsumerState<LuckyChestScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _glow;
  late final AnimationController _prizePop;
  late final AnimationController _float;
  late final AnimationController _pulse;
  late final AnimationController _balancePulse;
  late final ConfettiController _confetti;
  final _bannerKey = GlobalKey();
  final _chestKey = GlobalKey();
  Timer? _hapticTicks;
  var _opened = false;
  var _busy = false;
  int? _prize;
  int? _bannerPoints;
  Offset? _coinStart;
  Offset? _coinEnd;
  var _showFlyingCoins = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _prizePop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _balancePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _confetti = GameWinEffects.createController();
  }

  @override
  void dispose() {
    _hapticTicks?.cancel();
    _shake.dispose();
    _glow.dispose();
    _prizePop.dispose();
    _float.dispose();
    _pulse.dispose();
    _balancePulse.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Animation<double> get _balancePulseAnim => TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 55,
        ),
      ]).animate(_balancePulse);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final played = ref.watch(gamePlayedTodayProvider(DailyGameId.chest));
    final pointsAsync = ref.watch(loyaltyPointsProvider);
    final countdown =
        ref.watch(gameUnlockCountdownProvider(DailyGameId.chest));
    final bannerPoints = _bannerPoints ?? pointsAsync.valueOrNull;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.luckyChestTitle)),
        body: Stack(
          children: [
            Column(
              children: [
                KeyedSubtree(
                  key: _bannerKey,
                  child: LoyaltyPointsBanner(
                    signedIn: signedIn,
                    points: bannerPoints,
                    loading: signedIn &&
                        bannerPoints == null &&
                        pointsAsync.isLoading,
                    error: pointsAsync.hasError && bannerPoints == null,
                    onRetry: () =>
                        ref.read(loyaltyPointsProvider.notifier).refresh(),
                    pulseListenable: _balancePulseAnim,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: played
                        ? Center(
                            child: Text(
                              l10n.gameLockedUntilTomorrow(countdown),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: palette.muted,
                              ),
                            ),
                          )
                        : !signedIn
                            ? Center(
                                child: FilledButton(
                                  onPressed: () =>
                                      context.push(AppRoutes.auth),
                                  child: Text(l10n.wheelSignInToPlay),
                                ),
                              )
                            : Column(
                                children: [
                                  Text(
                                    l10n.luckyChestHint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: palette.muted,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    key: _chestKey,
                                    width: 280,
                                    height: 280,
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([
                                        _shake,
                                        _glow,
                                        _prizePop,
                                        _float,
                                        _pulse,
                                      ]),
                                      builder: (context, _) {
                                        final floatY = Curves.easeInOut
                                                .transform(_float.value) *
                                            -16;
                                        final shakeX = _opened
                                            ? 0.0
                                            : math.sin(_shake.value *
                                                    math.pi *
                                                    10) *
                                                14 *
                                                (1 - _shake.value);
                                        final shakeY = _opened
                                            ? 0.0
                                            : math.cos(_shake.value *
                                                    math.pi *
                                                    8) *
                                                8 *
                                                (1 - _shake.value);
                                        final pulse = 0.55 +
                                            0.45 *
                                                Curves.easeInOut.transform(
                                                    _pulse.value);
                                        final openBoost = _opened
                                            ? (0.35 + 0.65 * _glow.value)
                                            : 0.0;
                                        final glowStrength =
                                            math.max(pulse, openBoost);
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 200 + 70 * glowStrength,
                                              height: 200 + 70 * glowStrength,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    const Color(0xFFFFF59D)
                                                        .withValues(
                                                            alpha: 0.55 *
                                                                glowStrength),
                                                    const Color(0xFFFFB300)
                                                        .withValues(
                                                            alpha: 0.28 *
                                                                glowStrength),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                            0xFFFFB300)
                                                        .withValues(
                                                            alpha: 0.45 *
                                                                glowStrength),
                                                    blurRadius: 28 +
                                                        36 * glowStrength,
                                                    spreadRadius:
                                                        4 + 10 * glowStrength,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Transform.translate(
                                              offset: Offset(
                                                shakeX,
                                                floatY + shakeY,
                                              ),
                                              child: GestureDetector(
                                                onTap: _busy || _opened
                                                    ? null
                                                    : _openChest,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFFFD54F)
                                                            .withValues(
                                                                alpha: 0.35 *
                                                                    glowStrength),
                                                        blurRadius: 24 *
                                                            glowStrength,
                                                        spreadRadius: 2 *
                                                            glowStrength,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CustomPaint(
                                                    size: const Size(
                                                        220, 200),
                                                    painter:
                                                        _TreasureChestPainter(
                                                      opened: _opened,
                                                      glow: glowStrength,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_prize != null)
                                              Transform.scale(
                                                scale: _prizePopScale,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 18,
                                                    vertical: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFFFB300)
                                                            .withValues(
                                                                alpha: 0.45),
                                                        blurRadius: 18,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    '+$_prize ${l10n.loyaltyPoints}',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color:
                                                          Color(0xFFE65100),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _opened
                                        ? l10n.luckyChestOpened
                                        : l10n.luckyChestTapToOpen,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: palette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                  ),
                ),
              ],
            ),
            if (_showFlyingCoins &&
                _coinStart != null &&
                _coinEnd != null)
              FlyingCoinsOverlay(
                start: _coinStart!,
                end: _coinEnd!,
                count: 6 + math.Random().nextInt(3),
                onCoinArrive: (_) {
                  // Haptic first and independent of the audio call.
                  GameWinEffects.lightImpact();
                  GameWinEffects.playCoinCollect();
                  _balancePulse.forward(from: 0);
                },
                onComplete: () {
                  if (mounted) setState(() => _showFlyingCoins = false);
                },
              ),
            IgnorePointer(child: GameWinEffects.overlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }

  double get _prizePopScale {
    final t = Curves.easeOutBack.transform(_prizePop.value);
    if (t < 0.7) return t / 0.7 * 1.5;
    return 1.5 - ((t - 0.7) / 0.3) * 0.5;
  }

  Offset? _centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return null;
    final global = box.localToGlobal(box.size.center(Offset.zero));
    return overlayBox.globalToLocal(global);
  }

  Future<void> _openChest() async {
    if (_busy || _opened) return;
    setState(() => _busy = true);
    final prize = 1 + math.Random().nextInt(10);
    final before =
        ref.read(loyaltyPointsProvider).valueOrNull ?? 0;

    _hapticTicks?.cancel();
    // Strong pulse every 100 ms while the chest shakes; the vibration never
    // waits on the audio call.
    _hapticTicks = Timer.periodic(const Duration(milliseconds: 100), (_) {
      GameWinEffects.mediumImpact();
      GameWinEffects.playWheelTick();
    });
    GameWinEffects.mediumImpact();
    await _shake.forward(from: 0);
    _hapticTicks?.cancel();

    if (!mounted) return;
    setState(() {
      _opened = true;
      _prize = prize;
      _bannerPoints = before;
    });
    unawaited(_glow.forward(from: 0));
    unawaited(_prizePop.forward(from: 0));
    // Bursts open: HapticFeedback.heavyImpact() fires first and immediately
    // inside celebrate(), then confetti and win_fanfare — nothing awaits audio.
    unawaited(GameWinEffects.celebrate(confetti: _confetti));

    // Measure after open layout settles.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    final start = _centerOf(_chestKey) ?? const Offset(200, 420);
    final end = _centerOf(_bannerKey) ?? const Offset(200, 80);

    setState(() {
      _coinStart = start;
      _coinEnd = end;
      _showFlyingCoins = true;
      _bannerPoints = before + prize;
    });

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _busy = false);
      return;
    }

    try {
      await ref.read(loyaltyPointsProvider.notifier).awardPoints(prize);
      await markDailyGamePlayed(ref, DailyGameId.chest);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(ctx)!.wheelCongrats),
          content:
              Text(AppLocalizations.of(ctx)!.luckyChestWonPoints('$prize')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.awesome),
            ),
          ],
        ),
      );
    } on LoyaltyFailure catch (error) {
      if (!mounted) return;
      setState(() => _bannerPoints = before);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _TreasureChestPainter extends CustomPainter {
  _TreasureChestPainter({required this.opened, required this.glow});

  final bool opened;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.76, h * 0.48),
      const Radius.circular(18),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB74D), Color(0xFFF57C00), Color(0xFFE65100)],
      ).createShader(body.outerRect);
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFE082),
    );

    final band = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.58, w * 0.76, h * 0.08),
        const Radius.circular(6),
      ),
      band,
    );

    if (opened) {
      final lidPath = Path()
        ..moveTo(w * 0.12, h * 0.42)
        ..quadraticBezierTo(w * 0.5, h * 0.05, w * 0.88, h * 0.42)
        ..lineTo(w * 0.82, h * 0.42)
        ..quadraticBezierTo(w * 0.5, h * 0.16, w * 0.18, h * 0.42)
        ..close();
      canvas.drawPath(
        lidPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFCC80), Color(0xFFEF6C00)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      // Soft glow from the open chest — flying coins are overlaid separately.
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.36),
        18 + glow * 10,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.35 + glow * 0.25),
      );
    } else {
      final lid = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.8, h * 0.26),
        const Radius.circular(20),
      );
      canvas.drawRRect(
        lid,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE0B2), Color(0xFFFFA726), Color(0xFFEF6C00)],
          ).createShader(lid.outerRect),
      );
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.42),
        14,
        Paint()..color = const Color(0xFFFFD54F),
      );
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.42),
        7,
        Paint()..color = const Color(0xFF5D4037),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreasureChestPainter oldDelegate) =>
      oldDelegate.opened != opened || oldDelegate.glow != glow;
}
