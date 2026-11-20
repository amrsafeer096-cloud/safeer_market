import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scratcher/scratcher.dart';

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
import '../widgets/game_win_effects.dart';
import '../widgets/points_banner.dart';

/// Possible scratch prizes (0 = better luck next time).
const _scratchPrizes = [0, 5, 10, 15];

class ScratchCardScreen extends ConsumerStatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  ConsumerState<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends ConsumerState<ScratchCardScreen>
    with TickerProviderStateMixin {
  late final int _prizePoints;
  late final ConfettiController _confetti;
  late final AnimationController _prizePop;
  late final AnimationController _foilFade;
  final _scratchKey = GlobalKey<ScratcherState>();
  var _revealed = false;
  var _awarding = false;
  var _coverGone = false;
  DateTime _lastScratchHaptic = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _prizePoints = _scratchPrizes[Random().nextInt(_scratchPrizes.length)];
    _confetti = GameWinEffects.createController();
    _prizePop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _foilFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    _prizePop.dispose();
    _foilFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final played = ref.watch(gamePlayedTodayProvider(DailyGameId.scratch));
    final pointsAsync = ref.watch(loyaltyPointsProvider);
    final countdown =
        ref.watch(gameUnlockCountdownProvider(DailyGameId.scratch));

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.scratchCardTitle)),
        body: Stack(
          children: [
            Column(
              children: [
                LoyaltyPointsBanner(
                  signedIn: signedIn,
                  points: pointsAsync.valueOrNull,
                  loading: signedIn &&
                      pointsAsync.valueOrNull == null &&
                      pointsAsync.isLoading,
                  error: pointsAsync.hasError,
                  onRetry: () =>
                      ref.read(loyaltyPointsProvider.notifier).refresh(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: played
                        ? _LockedPanel(
                            message: l10n.gameLockedUntilTomorrow(countdown),
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
                                    l10n.scratchCardHint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: palette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFB300)
                                                    .withValues(alpha: 0.28),
                                                blurRadius: 22,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ColoredBox(
                                                  color: palette.card,
                                                  child: Center(
                                                    child: ScaleTransition(
                                                      scale: TweenSequence<
                                                          double>([
                                                        TweenSequenceItem(
                                                          tween: Tween(
                                                                  begin: 0.85,
                                                                  end: 1.18)
                                                              .chain(
                                                            CurveTween(
                                                              curve: Curves
                                                                  .easeOutBack,
                                                            ),
                                                          ),
                                                          weight: 65,
                                                        ),
                                                        TweenSequenceItem(
                                                          tween: Tween(
                                                                  begin: 1.18,
                                                                  end: 1.0)
                                                              .chain(
                                                            CurveTween(
                                                              curve: Curves
                                                                  .easeOut,
                                                            ),
                                                          ),
                                                          weight: 35,
                                                        ),
                                                      ]).animate(_prizePop),
                                                      child: _PrizeReveal(
                                                        points: _prizePoints,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (!_coverGone)
                                                  FadeTransition(
                                                    opacity: Tween<double>(
                                                      begin: 1,
                                                      end: 0,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: _foilFade,
                                                        curve:
                                                            Curves.easeOutCubic,
                                                      ),
                                                    ),
                                                    child: Scratcher(
                                                      key: _scratchKey,
                                                      brushSize: 46,
                                                      threshold: 50.0,
                                                      color: const Color(
                                                          0xFFB0BEC5),
                                                      image: Image.asset(
                                                        'assets/images/logo.png',
                                                        fit: BoxFit.cover,
                                                        color: const Color(
                                                            0xFF90A4AE),
                                                        colorBlendMode:
                                                            BlendMode
                                                                .softLight,
                                                      ),
                                                      onScratchUpdate:
                                                          _onScratchDrag,
                                                      onThreshold:
                                                          _onThreshold,
                                                      child: ColoredBox(
                                                        color: palette.card,
                                                        child: Center(
                                                          child: _PrizeReveal(
                                                            points:
                                                                _prizePoints,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                IgnorePointer(
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              24),
                                                      border: Border.all(
                                                        width: 3,
                                                        color: const Color(
                                                            0xFFFFD54F),
                                                      ),
                                                      gradient:
                                                          LinearGradient(
                                                        begin: Alignment
                                                            .topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          Colors.white
                                                              .withValues(
                                                                  alpha:
                                                                      0.22),
                                                          Colors.transparent,
                                                          const Color(
                                                                  0xFFFFB300)
                                                              .withValues(
                                                                  alpha:
                                                                      0.18),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
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

  void _onScratchDrag() {
    final now = DateTime.now();
    if (now.difference(_lastScratchHaptic) <
        const Duration(milliseconds: 55)) {
      return;
    }
    _lastScratchHaptic = now;
    GameWinEffects.lightImpact();
    GameWinEffects.playScratchTick();
  }

  void _onThreshold() {
    if (_revealed || _awarding) return;
    _revealed = true;
    unawaited(_finishReveal());
  }

  Future<void> _finishReveal() async {
    _scratchKey.currentState
        ?.reveal(duration: const Duration(milliseconds: 280));
    await _foilFade.forward(from: 0);
    if (!mounted) return;
    setState(() => _coverGone = true);
    unawaited(_prizePop.forward(from: 0));
    await _award();
  }

  Future<void> _award() async {
    if (_awarding) return;
    _awarding = true;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      if (_prizePoints > 0) {
        // Fanfare + coin chime as soon as the prize shows.
        unawaited(GameWinEffects.celebrate(confetti: _confetti));
        Future<void>.delayed(
          const Duration(milliseconds: 450),
          GameWinEffects.playCoinCollect,
        );
        await ref
            .read(loyaltyPointsProvider.notifier)
            .awardPoints(_prizePoints);
      } else {
        GameWinEffects.lightImpact();
      }
      await markDailyGamePlayed(ref, DailyGameId.scratch);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ResultDialog(
          won: _prizePoints > 0,
          points: _prizePoints,
        ),
      );
      if (mounted) context.pop();
    } on LoyaltyFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unexpectedError)),
      );
    } finally {
      _awarding = false;
    }
  }
}

class _PrizeReveal extends StatelessWidget {
  const _PrizeReveal({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final won = points > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          won ? Icons.stars_rounded : Icons.sentiment_dissatisfied_rounded,
          size: 64,
          color: won ? AppColors.secondary : AppColors.muted,
        ),
        const SizedBox(height: 12),
        Text(
          won ? l10n.scratchWonPoints('$points') : l10n.scratchBetterLuck,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.won, required this.points});

  final bool won;
  final int points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Dialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              won ? Icons.celebration_rounded : Icons.refresh_rounded,
              size: 64,
              color: won ? AppColors.secondary : AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              won ? l10n.wheelCongrats : l10n.scratchBetterLuck,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            if (won) ...[
              const SizedBox(height: 8),
              Text(
                l10n.scratchWonPoints('$points'),
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 15),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.awesome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_rounded, size: 56, color: palette.muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
