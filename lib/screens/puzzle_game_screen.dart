import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_palette.dart';
import '../core/widgets/mobile_frame.dart';
import '../l10n/app_localizations.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/rewards/domain/daily_game_cooldown.dart';
import '../features/rewards/domain/repositories/loyalty_repository.dart';
import '../features/rewards/domain/sliding_puzzle.dart';
import '../features/rewards/presentation/providers/daily_game_providers.dart';
import '../features/rewards/presentation/providers/rewards_providers.dart';
import '../features/rewards/presentation/widgets/game_win_effects.dart';
import '../features/rewards/presentation/widgets/points_banner.dart';

const _logoAsset = 'assets/images/logo.png';

class PuzzleGameScreen extends ConsumerStatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  ConsumerState<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends ConsumerState<PuzzleGameScreen> {
  late SlidingPuzzle _puzzle;
  late final ConfettiController _confetti;
  int remainingMoves = puzzleMaxMoves;
  var _rewarded = false;

  /// Out of moves unsolved: the board is locked for the rest of the day.
  var _lost = false;
  Future<void>? _claim;

  @override
  void initState() {
    super.initState();
    _puzzle = ref.read(puzzleBoardProvider)();
    _confetti = GameWinEffects.createController();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous == null && next != null && _puzzle.isSolved && !_rewarded) {
        unawaited(_claimReward());
      }
    });
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final signedIn = ref.watch(isSignedInProvider);
    final pointsAsync = ref.watch(loyaltyPointsProvider);

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.puzzleGame)),
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
                const _GoalHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        l10n.puzzleMoves('$remainingMoves'),
                        key: const Key('puzzle-remaining-moves'),
                        style: remainingMoves <= puzzleLowMovesWarning
                            ? const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              )
                            : const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        l10n.puzzlePrize('$puzzleRewardPoints'),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: palette.isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.22),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _PuzzleBoard(
                              puzzle: _puzzle,
                              onTap: _onTileTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: _puzzle.isSolved && !_rewarded
                        ? FilledButton(
                            onPressed: _claim != null ? null : _claimReward,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              l10n.puzzleSavePoints('$puzzleRewardPoints'),
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _claim != null || _lost ? null : _shuffle,
                            icon: const Icon(Icons.shuffle_rounded),
                            label: Text(l10n.puzzleShuffle),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.accent,
                              side: BorderSide(
                                color: palette.accent,
                                width: 1.5,
                              ),
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
                          ),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              child: GameWinEffects.overlay(controller: _confetti),
            ),
          ],
        ),
      ),
    );
  }

  void _shuffle() {
    setState(() {
      _puzzle = ref.read(puzzleBoardProvider)();
      remainingMoves = puzzleMaxMoves;
      _rewarded = false;
    });
  }

  void _onTileTap(int index) {
    if (_rewarded || _lost || _claim != null) return;
    if (ref.read(gamePlayedTodayProvider(DailyGameId.puzzle))) return;
    final next = _puzzle.slide(index);
    if (identical(next, _puzzle)) return;
    // Out of moves and unsolved after this one: lock the board in the same
    // frame, so no further tap can slip through while the dialog opens.
    final outOfMoves = remainingMoves - 1 <= 0 && !next.isSolved;
    setState(() {
      _puzzle = next;
      remainingMoves--;
      if (outOfMoves) _lost = true;
    });
    GameWinEffects.lightImpact();
    GameWinEffects.playPop();
    if (next.isSolved) {
      unawaited(_claimReward());
    } else if (outOfMoves) {
      unawaited(_handleLoss());
    }
  }

  /// Lost: same daily lock as a win (timestamp + user id in
  /// SharedPreferences), then the loss dialog, then back out.
  Future<void> _handleLoss() async {
    GameWinEffects.mediumImpact();
    await markDailyGamePlayed(ref, DailyGameId.puzzle);
    if (!mounted) return;
    await _showLossDialog();
    if (!mounted) return;
    // Kicked out until tomorrow — unless an admin (no cooldown) is testing.
    if (!ref.read(gameCooldownBypassedProvider) && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _showLossDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final palette = dialogContext.palette;
        return Dialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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
                    color: Colors.red.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.sentiment_dissatisfied_rounded,
                    color: Colors.red,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.puzzleOutOfMoves,
                  key: const Key('puzzle-out-of-moves'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.ok),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _claimReward() {
    if (_rewarded) return Future.value();
    return _claim ??= _award().whenComplete(() => _claim = null);
  }

  Future<void> _award() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (!mounted) return;
      await GameWinEffects.celebrate(confetti: _confetti);
      if (!mounted) return;
      await _showGuestDialog();
      return;
    }

    // The puzzle is solved — fanfare now, not after the network round trip.
    unawaited(GameWinEffects.celebrate(confetti: _confetti));
    try {
      await ref
          .read(loyaltyPointsProvider.notifier)
          .awardPoints(puzzleRewardPoints);
      await markDailyGamePlayed(ref, DailyGameId.puzzle);
      if (!mounted) return;
      setState(() => _rewarded = true);
      if (!mounted) return;
      await _showWinDialog();
    } on LoyaltyFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showWinDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final palette = dialogContext.palette;
        return Dialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFB300), AppColors.secondary],
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.puzzleCongrats,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.puzzleEarnedPoints('$puzzleRewardPoints'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.puzzlePointsAddedToBalance,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.awesome),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGuestDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        final palette = dialogContext.palette;
        return Dialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.secondary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.puzzleGuestEarnedPoints('$puzzleRewardPoints'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.puzzleSignInToAddPoints,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      context.push(AppRoutes.auth);
                    },
                    child: Text(l10n.signIn),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _logoAsset,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: palette.imageBackdrop,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.image_outlined, color: palette.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.puzzleGoalTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.puzzleGoalDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({required this.puzzle, required this.onTap});

  final SlidingPuzzle puzzle;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final tile = (constraints.maxWidth - gap * (SlidingPuzzle.size - 1)) /
            SlidingPuzzle.size;
        final stride = tile + gap;

        return Stack(
          children: [
            for (var index = 0; index < SlidingPuzzle.tileCount; index++)
              Positioned(
                left: (index % SlidingPuzzle.size) * stride,
                top: (index ~/ SlidingPuzzle.size) * stride,
                width: tile,
                height: tile,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            for (var index = 0; index < SlidingPuzzle.tileCount; index++)
              if (puzzle.tiles[index] != SlidingPuzzle.blankId)
                AnimatedPositioned(
                  key: ValueKey('piece-${puzzle.tiles[index]}'),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  left: (index % SlidingPuzzle.size) * stride,
                  top: (index ~/ SlidingPuzzle.size) * stride,
                  width: tile,
                  height: tile,
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: _PuzzlePiece(pieceId: puzzle.tiles[index]),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _PuzzlePiece extends StatelessWidget {
  const _PuzzlePiece({required this.pieceId});

  final int pieceId;

  @override
  Widget build(BuildContext context) {
    final row = pieceId ~/ SlidingPuzzle.size;
    final column = pieceId % SlidingPuzzle.size;
    // Tile column/row 0..2 become alignment -1, 0, 1. The logo is drawn at
    // 3× the tile so ClipRect keeps only this piece's ninth.
    final alignment = Alignment(
      (column - 1).toDouble(),
      (row - 1).toDouble(),
    );
    final palette = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ClipRect(
          child: Align(
            alignment: alignment,
            child: FractionallySizedBox(
              alignment: alignment,
              widthFactor: 3,
              heightFactor: 3,
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: palette.imageBackdrop,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: palette.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
