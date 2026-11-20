import 'dart:math';

/// A 3×3 sliding puzzle. Tile ids `0..7` are image slices; [blankId] is the hole.
class SlidingPuzzle {
  const SlidingPuzzle(this.tiles);

  static const size = 3;
  static const tileCount = size * size;
  static const blankId = tileCount - 1;

  final List<int> tiles;

  bool get isSolved {
    for (var index = 0; index < tileCount; index++) {
      if (tiles[index] != index) return false;
    }
    return true;
  }

  int get blankIndex => tiles.indexOf(blankId);

  bool canSlide(int index) {
    if (index < 0 || index >= tileCount || tiles[index] == blankId) {
      return false;
    }
    final blank = blankIndex;
    final row = index ~/ size;
    final column = index % size;
    final blankRow = blank ~/ size;
    final blankColumn = blank % size;
    final sameRow = row == blankRow && (column - blankColumn).abs() == 1;
    final sameColumn = column == blankColumn && (row - blankRow).abs() == 1;
    return sameRow || sameColumn;
  }

  /// Returns [this] when [index] cannot slide into the hole.
  SlidingPuzzle slide(int index) {
    if (!canSlide(index)) return this;
    final next = List<int>.of(tiles);
    final blank = blankIndex;
    next[blank] = next[index];
    next[index] = blankId;
    return SlidingPuzzle(next);
  }

  static SlidingPuzzle solved() {
    return SlidingPuzzle(List<int>.generate(tileCount, (index) => index));
  }

  /// Shuffles with legal slides so the result is always solvable.
  static SlidingPuzzle shuffled(Random random, {int moves = 40}) {
    var puzzle = solved();
    var reverseIndex = -1;
    for (var step = 0; step < moves; step++) {
      final neighbors = [
        for (var index = 0; index < tileCount; index++)
          if (puzzle.canSlide(index)) index,
      ];
      var options = [
        for (final index in neighbors)
          if (index != reverseIndex) index,
      ];
      if (options.isEmpty) options = neighbors;
      final pick = options[random.nextInt(options.length)];
      reverseIndex = puzzle.blankIndex;
      puzzle = puzzle.slide(pick);
    }
    if (puzzle.isSolved) {
      final nudge = [
        for (var index = 0; index < tileCount; index++)
          if (puzzle.canSlide(index)) index,
      ].first;
      puzzle = puzzle.slide(nudge);
    }
    return puzzle;
  }
}

const puzzleRewardPoints = 50;

/// Moves allowed per attempt; running out unsolved loses the day's play.
const puzzleMaxMoves = 100;

/// At or below this many moves left, the counter turns red.
const puzzleLowMovesWarning = 5;
