import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/rewards/domain/sliding_puzzle.dart';
import 'package:safeer_market/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:safeer_market/screens/puzzle_game_screen.dart';

import 'test_helpers.dart';

void main() {
  test('legal shuffles stay solvable and unsolved', () {
    for (var seed = 0; seed < 20; seed++) {
      final puzzle = SlidingPuzzle.shuffled(Random(seed));
      expect(puzzle.tiles.toSet(), {0, 1, 2, 3, 4, 5, 6, 7, 8});
      expect(puzzle.isSolved, isFalse);
    }
  });

  test('only an adjacent tile slides into the hole', () {
    const puzzle = SlidingPuzzle([0, 1, 2, 3, 4, 5, 6, 8, 7]);
    expect(puzzle.canSlide(8), isTrue);
    expect(puzzle.canSlide(4), isTrue);
    expect(puzzle.canSlide(0), isFalse);
    expect(puzzle.slide(8).isSolved, isTrue);
    expect(identical(puzzle.slide(0), puzzle), isTrue);
  });

  testWidgets('tiles show different slices of the logo, not the whole image', (
    tester,
  ) async {
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      paymobService: FakePaymobService(subscription: FakePaymobService.pro),
      overrides: [
        puzzleBoardProvider.overrideWithValue(SlidingPuzzle.solved),
      ],
    );
    await skipSplash(tester);
    await tester.tap(find.text('العب واكسب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('لعبة البازل'));
    await tester.pumpAndSettle();

    final crops = tester
        .renderObjectList<RenderFractionallySizedOverflowBox>(
          find.byType(FractionallySizedBox),
        )
        .toList();
    expect(crops, hasLength(8));

    final offsets = <Offset>{};
    for (final crop in crops) {
      final slice = crop.child!;
      expect(slice.size.width, moreOrLessEquals(crop.size.width * 3));
      expect(slice.size.height, moreOrLessEquals(crop.size.height * 3));
      offsets.add((slice.parentData! as BoxParentData).offset);
    }
    expect(offsets, hasLength(8));
  });

  testWidgets('solving the puzzle adds 50 loyalty points', (tester) async {
    final loyalty = FakeLoyaltyRepository(points: 80);
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      paymobService: FakePaymobService(subscription: FakePaymobService.pro),
      loyaltyRepository: loyalty,
      overrides: [
        puzzleBoardProvider.overrideWithValue(
          () => const SlidingPuzzle([0, 1, 2, 3, 4, 5, 6, 8, 7]),
        ),
      ],
    );
    await skipSplash(tester);

    await tester.tap(find.text('العب واكسب'));
    await tester.pumpAndSettle();
    expect(find.text('لعبة البازل'), findsOneWidget);

    await tester.tap(find.text('لعبة البازل'));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleGameScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('piece-7')));
    await tester.pumpAndSettle();

    expect(find.text('مبرووك!'), findsOneWidget);
    expect(find.text('كسبت 50 نقطة 🎉'), findsOneWidget);
    expect(
      loyalty.added,
      [(userId: testUser.id, amount: puzzleRewardPoints)],
    );
    expect(loyalty.points, 130);

    await tester.tap(find.widgetWithText(FilledButton, 'رائع!'));
    await tester.pumpAndSettle();
  });
}
