import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/settings_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/daily_game_cooldown.dart';

/// Ticks every second so countdown labels stay live.
final dailyClockTickProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!controller.isClosed) controller.add(DateTime.now());
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Admins never hit the 24-hour game cooldown.
final gameCooldownBypassedProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider).valueOrNull == UserRole.admin;
});

String? _prefsValueFor(SharedPreferences? prefs, DailyGameId game, String? userId) {
  if (prefs == null || userId == null || userId.isEmpty) return null;
  return prefs.getString(game.prefsKeyFor(userId));
}

/// Whether [game] is still locked for the signed-in user (24h rolling).
/// Always `false` for admins and guests.
final gamePlayedTodayProvider =
    Provider.autoDispose.family<bool, DailyGameId>((ref, game) {
  if (ref.watch(gameCooldownBypassedProvider)) return false;
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return false;
  final prefs = ref.watch(sharedPreferencesProvider);
  final now =
      ref.watch(dailyClockTickProvider).valueOrNull ?? DateTime.now();
  ref.watch(gameCooldownRevisionProvider);
  return DailyGameCooldown.isLocked(
    _prefsValueFor(prefs, game, userId),
    now,
  );
});

/// Per-game `HH:MM:SS` until unlock. Empty when unlocked or admin.
final gameUnlockCountdownProvider =
    Provider.autoDispose.family<String, DailyGameId>((ref, game) {
  if (ref.watch(gameCooldownBypassedProvider)) return '';
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return '';
  final prefs = ref.watch(sharedPreferencesProvider);
  final now =
      ref.watch(dailyClockTickProvider).valueOrNull ?? DateTime.now();
  ref.watch(gameCooldownRevisionProvider);
  final remaining = DailyGameCooldown.remaining(
    _prefsValueFor(prefs, game, userId),
    now,
  );
  if (remaining == Duration.zero) return '';
  return DailyGameCooldown.formatCountdown(remaining);
});

/// Bumped after marking a game played so dependents rebuild.
final gameCooldownRevisionProvider = StateProvider<int>((ref) => 0);

Future<void> markDailyGamePlayed(WidgetRef ref, DailyGameId game) async {
  // Admins bypass cooldown — don't write a lock timestamp.
  if (ref.read(gameCooldownBypassedProvider)) return;
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null || userId.isEmpty) return;
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs?.setString(
    game.prefsKeyFor(userId),
    DateTime.now().toIso8601String(),
  );
  ref.read(gameCooldownRevisionProvider.notifier).state++;
}

/// Test helper: clear locks for [userId], or all known game key prefixes.
Future<void> clearDailyGameLocks(
  SharedPreferences prefs, {
  String? userId,
}) async {
  if (userId != null) {
    for (final game in DailyGameId.values) {
      await prefs.remove(game.prefsKeyFor(userId));
    }
    return;
  }
  for (final game in DailyGameId.values) {
    await prefs.remove(game.prefsKeyPrefix);
  }
}
