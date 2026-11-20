import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';

/// One slice of the rewards wheel. [points] of 0 is a miss.
class WheelPrize {
  const WheelPrize({
    required this.points,
    required this.color,
  });

  final int points;
  final Color color;

  bool get isWin => points > 0;

  String labelOf(AppLocalizations l10n) =>
      isWin ? l10n.rewardsPointsCount(points) : l10n.wheelPrizeTryAgain;

  String get label => labelOf(L10n.current);
}

const wheelPrizes = <WheelPrize>[
  WheelPrize(points: 10, color: AppColors.primary),
  WheelPrize(points: 20, color: Color(0xFFFF6D00)),
  WheelPrize(points: 50, color: AppColors.success),
  WheelPrize(points: 100, color: AppColors.secondary),
  WheelPrize(points: 0, color: AppColors.muted),
];
