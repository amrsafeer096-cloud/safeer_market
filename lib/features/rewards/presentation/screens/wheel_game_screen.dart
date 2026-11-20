import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/daily_game_cooldown.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../providers/daily_game_providers.dart';
import '../providers/rewards_providers.dart';
import '../wheel_prizes.dart';
import '../widgets/game_win_effects.dart';
import '../widgets/points_banner.dart';

class WheelGameScreen extends ConsumerStatefulWidget {
  const WheelGameScreen({super.key});

  @override
  ConsumerState<WheelGameScreen> createState() => _WheelGameScreenState();
}

class _WheelGameScreenState extends ConsumerState<WheelGameScreen> {
  final _selected = StreamController<int>();
  late final ConfettiController _confetti;
  Timer? _spinHaptics;
  var _spinning = false;
  var _resultHandled = false;
  var _landedIndex = -1;

  @override
  void initState() {
    super.initState();
    _confetti = GameWinEffects.createController();
  }

  @override
  void dispose() {
    _spinHaptics?.cancel();
    _selected.close();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);
    final playedToday = ref.watch(gamePlayedTodayProvider(DailyGameId.wheel));
    final countdown =
        ref.watch(gameUnlockCountdownProvider(DailyGameId.wheel));
    final pointsAsync = ref.watch(loyaltyPointsProvider);
    final points = pointsAsync.valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.luckyWheel)),
        body: Stack(
          children: [
            Column(
              children: [
                LoyaltyPointsBanner(
                  signedIn: signedIn,
                  points: points,
                  loading:
                      signedIn && points == null && pointsAsync.isLoading,
                  error: pointsAsync.hasError,
                  onRetry: () =>
                      ref.read(loyaltyPointsProvider.notifier).refresh(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        Text(
                          l10n.wheelSpinCollectLoyaltyPoints,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  FortuneWheel(
                                    selected: _selected.stream,
                                    animateFirst: false,
                                    physics: NoPanPhysics(),
                                    duration: const Duration(seconds: 5),
                                    curve: Curves.easeOutCirc,
                                    rotationCount: 10,
                                    onAnimationEnd: _onSpinFinished,
                                    indicators: const <FortuneIndicator>[
                                      FortuneIndicator(
                                        alignment: Alignment.topCenter,
                                        child: TriangleIndicator(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                    items: [
                                      for (final prize in wheelPrizes)
                                        FortuneItem(
                                          style: FortuneItemStyle(
                                            color: prize.color,
                                            borderColor: Colors.white,
                                            borderWidth: 3,
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 36,
                                            ),
                                            child: Text(prize.labelOf(l10n)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: palette.card,
                                      border: Border.all(
                                        color: AppColors.secondary,
                                        width: 4,
                                      ),
                                      boxShadow: palette.isDark
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 12,
                                              ),
                                            ],
                                    ),
                                    child: const Icon(
                                      Icons.stars_rounded,
                                      color: AppColors.secondary,
                                      size: 34,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _spinning || playedToday
                                ? null
                                : signedIn
                                    ? _spin
                                    : () => context.push(AppRoutes.auth),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              disabledBackgroundColor: AppColors.secondary
                                  .withValues(alpha: 0.4),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(
                              !signedIn
                                  ? l10n.wheelSignInToPlay
                                  : playedToday
                                      ? l10n.gameLockedUntilTomorrow(
                                          countdown)
                                      : _spinning
                                          ? l10n.wheelSpinning
                                          : l10n.wheelSpin,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            IgnorePointer(
                child: GameWinEffects.overlay(controller: _confetti)),
          ],
        ),
      ),
    );
  }

  void _spin() {
    if (_spinning || _selected.isClosed) return;
    final index = ref.read(wheelRollProvider)(wheelPrizes.length);
    setState(() {
      _spinning = true;
      _resultHandled = false;
      _landedIndex = index;
    });
    GameWinEffects.vibrate();
    _startPegTicks(index);
    _selected.add(index);
  }

  static const _spinDuration = Duration(seconds: 5);
  static const _spinRotations = 10;

  /// One click per segment the pointer crosses, following the wheel's own
  /// ease-out curve: fast clicks at first, slowing to a stop with the wheel.
  void _startPegTicks(int landedIndex) {
    _spinHaptics?.cancel();
    final totalPegs = _spinRotations * wheelPrizes.length + landedIndex;
    final clock = Stopwatch()..start();
    var crossed = 0;
    var lastTick = -1000;
    _spinHaptics = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = clock.elapsedMilliseconds;
      final t = (elapsed / _spinDuration.inMilliseconds).clamp(0.0, 1.0);
      final pegs = (Curves.easeOutCirc.transform(t) * totalPegs).floor();
      if (pegs > crossed) {
        crossed = pegs;
        // Never faster than the sound's 75 ms gate, or clicks blur to a buzz.
        if (elapsed - lastTick >= 75) {
          lastTick = elapsed;
          GameWinEffects.lightImpact();
          GameWinEffects.playWheelTick();
        }
      }
      if (t >= 1) timer.cancel();
    });
  }

  void _onSpinFinished() {
    if (_resultHandled) return;
    _resultHandled = true;
    _spinHaptics?.cancel();
    unawaited(_awardLandedPrize());
  }

  Future<void> _awardLandedPrize() async {
    if (!mounted || _landedIndex < 0) return;
    final prize = wheelPrizes[_landedIndex];

    if (!prize.isWin) {
      await markDailyGamePlayed(ref, DailyGameId.wheel);
      if (!mounted) return;
      setState(() => _spinning = false);
      GameWinEffects.lightImpact();
      await _showResultDialog(prize: prize);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _spinning = false);
      return;
    }

    // Fanfare the moment the wheel stops on a prize, not after the network.
    unawaited(GameWinEffects.celebrate(confetti: _confetti));
    try {
      await ref
          .read(loyaltyPointsProvider.notifier)
          .awardPoints(prize.points);
      await markDailyGamePlayed(ref, DailyGameId.wheel);
      if (!mounted) return;
      setState(() => _spinning = false);
      await _showResultDialog(prize: prize);
    } on LoyaltyFailure catch (error) {
      if (!mounted) return;
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showResultDialog({required WheelPrize prize}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _PrizeDialog(prize: prize),
    );
  }
}

class _PrizeDialog extends StatelessWidget {
  const _PrizeDialog({required this.prize});

  final WheelPrize prize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final won = prize.isWin;
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: won
                      ? const [Color(0xFFFFB300), Color(0xFFFF6D00)]
                      : const [AppColors.muted, AppColors.onSurface],
                ),
              ),
              child: Icon(
                won ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              won ? l10n.wheelCongrats : l10n.wheelTryAgainTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              won
                  ? l10n.wheelWonPrize(prize.labelOf(l10n))
                  : l10n.wheelNoPointsThisTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: won ? AppColors.success : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(won ? l10n.awesome : l10n.ok),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
