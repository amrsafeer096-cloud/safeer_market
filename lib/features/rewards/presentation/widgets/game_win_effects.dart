import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/audio/app_sound_service.dart';

/// Shared haptics, confetti, and SFX for loyalty games.
abstract final class GameWinEffects {
  static const confettiColors = <Color>[
    Color(0xFFFFD54F),
    Color(0xFFFF6D00),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
  ];

  static ConfettiController createController({
    Duration duration = const Duration(seconds: 3),
  }) =>
      ConfettiController(duration: duration);

  static Widget overlay({
    required ConfettiController controller,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        emissionFrequency: 0.05,
        numberOfParticles: 28,
        maxBlastForce: 28,
        minBlastForce: 10,
        gravity: 0.22,
        colors: confettiColors,
      ),
    );
  }

  static void lightTick() => HapticFeedback.selectionClick();

  static void lightImpact() => HapticFeedback.lightImpact();

  static void mediumImpact() => HapticFeedback.mediumImpact();

  static void heavyWin() => HapticFeedback.heavyImpact();

  static void vibrate() => HapticFeedback.vibrate();

  /// Wheel peg / chest-shake click.
  static void playWheelTick() => AppSoundService.instance.playWheelTick();

  /// Throttled (~120 ms) scratch sound while dragging a finger.
  static void playScratchTick() => AppSoundService.instance.playScratchTick();

  /// Tile slide in the puzzle.
  static void playPop() => AppSoundService.instance.playCartPop();

  static void playCoinCollect() => AppSoundService.instance.playCoinCollect();

  static void playWinFanfare() => AppSoundService.instance.playWinFanfare();

  /// Haptic + confetti + fanfare.
  static Future<void> celebrate({
    required ConfettiController confetti,
  }) async {
    heavyWin();
    confetti.play();
    playWinFanfare();
  }
}
