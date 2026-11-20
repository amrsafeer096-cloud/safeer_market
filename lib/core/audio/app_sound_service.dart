import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The app's sound effects. Each is a file in `assets/sounds/` named
/// `<baseName>.mp3` or `<baseName>.wav` (registered in pubspec.yaml).
///
/// Drop your own `.mp3` or `.wav` with the same base name into
/// `assets/sounds/` and it is picked up with no code change; `.mp3` wins
/// when both exist.
enum AppSound {
  /// Short, rapid sounds: a pre-warmed round-robin pool, rate limited.
  wheelTick('wheel_tick', burst: true, minGapMs: 75),
  scratchTick('scratch_tick', burst: true, minGapMs: 130),
  cartPop('cart_pop', burst: true, minGapMs: 60),
  coinCollect('coin_collect', burst: true, minGapMs: 90),

  /// Long celebratory sounds: one dedicated player each, so ticks can never
  /// steal or cut them.
  winFanfare('win_fanfare', burst: false, minGapMs: 0),
  orderSuccess('order_success', burst: false, minGapMs: 0);

  const AppSound(this.baseName, {required this.burst, required this.minGapMs});

  /// File name without extension.
  final String baseName;

  /// Rapid sound (pool) vs. long sound (one dedicated player).
  final bool burst;

  /// Minimum time between two plays, so the audio engine is never flooded.
  final int minGapMs;
}

/// Plays [AppSound]s on the main media volume channel.
///
/// Call [init] once at start-up (before `runApp`). Every `play*` method is
/// fire-and-forget safe: it never throws and never blocks the caller (so
/// haptics fired alongside are not delayed by audio).
class AppSoundService {
  AppSoundService._();

  static final AppSoundService instance = AppSoundService._();

  /// Players per burst sound.
  static const _poolSize = 3;

  /// Media stream on Android, with **no audio focus request**: asking for
  /// focus on every rapid game SFX makes Android duck/suppress haptics and
  /// choke overlapping sounds. iOS: ambient, mixes with other audio.
  static final AudioContext audioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Smaller than this can't be a real audio file (a 6-byte placeholder
  /// `beep.mp3` once sat in this folder), so it is skipped.
  static const _minAudioBytes = 256;

  final _assets = <AppSound, String>{};
  final _pools = <AppSound, List<AudioPlayer>>{};
  final _modes = <AppSound, PlayerMode>{};
  final _cursor = <AppSound, int>{};
  final _lastPlayed = <AppSound, int>{};
  final _clock = Stopwatch()..start();
  Future<void>? _initFuture;

  /// Applies [audioContext], resolves every asset (mp3 → wav) and warms up
  /// the players. Idempotent.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await AudioPlayer.global.setAudioContext(audioContext);
    } catch (error) {
      // Unsupported platform (e.g. web) — the default session is fine.
      debugPrint('AppSoundService: setAudioContext skipped: $error');
    }
    for (final sound in AppSound.values) {
      try {
        _assets[sound] = await _resolveSoundAsset(sound.baseName);
        await _createPlayers(sound, PlayerMode.lowLatency);
      } catch (error) {
        debugPrint('AppSoundService: warm-up ${sound.baseName} failed: $error');
      }
    }
  }

  /// `AssetSource` path (relative to `assets/`, which audioplayers prepends)
  /// for [baseName]: `sounds/<baseName>.mp3` if that bundled file is a real
  /// audio file, else `sounds/<baseName>.wav`.
  Future<String> _resolveSoundAsset(String baseName) async {
    for (final extension in const ['mp3', 'wav']) {
      final path = 'sounds/$baseName.$extension';
      try {
        final data = await rootBundle.load('assets/$path');
        if (data.lengthInBytes >= _minAudioBytes) return path;
      } catch (_) {
        // Not bundled — try the next format.
      }
    }
    return 'sounds/$baseName.wav';
  }

  Future<void> _createPlayers(AppSound sound, PlayerMode mode) async {
    // Long sounds always use the media player, with one dedicated instance.
    final effectiveMode = sound.burst ? mode : PlayerMode.mediaPlayer;
    final count = sound.burst ? _poolSize : 1;
    final old = _pools.remove(sound);
    if (old != null) {
      for (final player in old) {
        unawaited(player.dispose());
      }
    }
    final players = <AudioPlayer>[];
    for (var i = 0; i < count; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(effectiveMode);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      try {
        await player.setSource(AssetSource(_assets[sound]!));
      } catch (error) {
        debugPrint('AppSoundService: preload ${sound.baseName} failed: $error');
      }
      players.add(player);
    }
    _pools[sound] = players;
    _modes[sound] = effectiveMode;
    _cursor[sound] = 0;
  }

  Future<void> play(AppSound sound) async {
    // Rate limit first: cheap, and keeps the engine from being flooded.
    final now = _clock.elapsedMilliseconds;
    final last = _lastPlayed[sound];
    if (last != null && now - last < sound.minGapMs) return;
    _lastPlayed[sound] = now;

    try {
      await init();
      if (!_pools.containsKey(sound)) {
        _assets[sound] ??= await _resolveSoundAsset(sound.baseName);
        await _createPlayers(sound, PlayerMode.lowLatency);
      }
      await _start(sound);
    } catch (error, stack) {
      debugPrint('AppSoundService: play ${sound.baseName} failed: $error');
      if (sound.burst && _modes[sound] == PlayerMode.lowLatency) {
        // Low-latency mode can fail on some formats/devices — fall back to
        // the regular media player and try once more.
        try {
          await _createPlayers(sound, PlayerMode.mediaPlayer);
          await _start(sound);
        } catch (retryError) {
          debugPrint('AppSoundService: fallback ${sound.baseName} failed: '
              '$retryError\n$stack');
        }
      }
    }
  }

  Future<void> _start(AppSound sound) async {
    final players = _pools[sound]!;
    final index = (_cursor[sound] ?? 0) % players.length;
    _cursor[sound] = index + 1;
    final player = players[index];
    if (!sound.burst) {
      // Dedicated long-sound player: always restart cleanly.
      await player.stop();
    }
    await player.play(AssetSource(_assets[sound]!), volume: 1.0);
  }

  void playWinFanfare() => unawaited(play(AppSound.winFanfare));

  void playCoinCollect() => unawaited(play(AppSound.coinCollect));

  void playWheelTick() => unawaited(play(AppSound.wheelTick));

  void playScratchTick() => unawaited(play(AppSound.scratchTick));

  void playCartPop() => unawaited(play(AppSound.cartPop));

  void playOrderSuccess() => unawaited(play(AppSound.orderSuccess));

  Future<void> dispose() async {
    for (final players in _pools.values) {
      for (final player in players) {
        await player.dispose();
      }
    }
    _pools.clear();
    _cursor.clear();
    _modes.clear();
    _lastPlayed.clear();
    _initFuture = null;
  }
}
