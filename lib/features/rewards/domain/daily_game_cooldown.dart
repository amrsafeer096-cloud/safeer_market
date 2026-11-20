/// Games that may be played at most once per rolling 24-hour window.
enum DailyGameId {
  wheel('last_played_wheel'),
  puzzle('last_played_puzzle'),
  scratch('last_played_scratch'),
  chest('last_played_chest');

  const DailyGameId(this.prefsKeyPrefix);

  final String prefsKeyPrefix;

  /// Per-user SharedPreferences key (avoids cross-account lockout).
  String prefsKeyFor(String userId) => '${prefsKeyPrefix}_$userId';
}

/// SharedPreferences helpers for rolling 24-hour game locks.
abstract final class DailyGameCooldown {
  static const lockDuration = Duration(hours: 24);

  static DateTime? parsePlayedAt(String? lastPlayedIso) {
    if (lastPlayedIso == null || lastPlayedIso.isEmpty) return null;
    return DateTime.tryParse(lastPlayedIso)?.toLocal();
  }

  /// Unlock instant = last play + 24 hours.
  static DateTime? unlockAt(String? lastPlayedIso) {
    final last = parsePlayedAt(lastPlayedIso);
    if (last == null) return null;
    return last.add(lockDuration);
  }

  /// True while [now] is still inside the 24-hour lock window.
  static bool isLocked(String? lastPlayedIso, DateTime now) {
    final unlock = unlockAt(lastPlayedIso);
    if (unlock == null) return false;
    return now.isBefore(unlock);
  }

  static Duration remaining(String? lastPlayedIso, DateTime now) {
    final unlock = unlockAt(lastPlayedIso);
    if (unlock == null) return Duration.zero;
    final left = unlock.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// `HH:MM:SS` for the remaining lock time (capped at 24h display).
  static String formatCountdown(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
