import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import 'locale_provider.dart';

/// Loaded once in `main()` before the app starts. Null (defaults, nothing
/// saved) where none is provided, e.g. bare provider tests.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

abstract final class SettingsKeys {
  static const themeMode = 'settings.theme_mode';
  static const locale = 'settings.locale';
  static const onboardingDone = 'settings.onboarding_done';
  static const adminOrderAlarmMuted = 'settings.admin_order_alarm_muted';
}

/// Light until the user picks otherwise: several screens still paint fixed
/// light surfaces, so following a dark system setting by default would show
/// them half-dark.
const defaultThemeMode = ThemeMode.light;

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final saved =
      ref.watch(sharedPreferencesProvider)?.getString(SettingsKeys.themeMode);
  return ThemeMode.values.asNameMap()[saved] ?? defaultThemeMode;
});

/// Whether an auth session exists right now (restored from storage or
/// delivered by an OAuth redirect). False when auth isn't available at all
/// (bare provider tests).
bool hasActiveSession(Ref ref) {
  try {
    return ref.read(currentUserProvider) != null;
  } catch (_) {
    return false;
  }
}

/// True until the user finishes or skips onboarding; the router sends a
/// first launch there. Never true for a signed-in user: after a web OAuth
/// redirect the page reloads, and the restored session already proves the
/// user is past onboarding.
final isFirstLaunchProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final done = prefs?.getBool(SettingsKeys.onboardingDone) ?? false;
  if (done) return false;
  return !hasActiveSession(ref);
});

/// Marks onboarding as finished: the in-memory flag (so the router moves on
/// now) and the saved flag (so it survives a page reload / restart), without
/// waiting for [settingsPersistenceProvider].
void completeOnboarding(Ref ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs != null && prefs.getBool(SettingsKeys.onboardingDone) != true) {
    prefs.setBool(SettingsKeys.onboardingDone, true);
  }
  if (ref.read(isFirstLaunchProvider)) {
    ref.read(isFirstLaunchProvider.notifier).state = false;
  }
}

/// Whether the Admin Dashboard new-order alarm is muted on this device.
final adminOrderAlarmMutedProvider = StateProvider<bool>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          ?.getBool(SettingsKeys.adminOrderAlarmMuted) ??
      false;
});

/// Saves the language, theme and onboarding state whenever they change.
/// Watch it once at the app root.
final settingsPersistenceProvider = Provider<void>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs == null) return;
  ref
    ..listen(
      themeModeProvider,
      (_, mode) => prefs.setString(SettingsKeys.themeMode, mode.name),
    )
    ..listen(
      localeProvider,
      (_, locale) => prefs.setString(SettingsKeys.locale, locale.languageCode),
    )
    ..listen(
      isFirstLaunchProvider,
      (_, firstLaunch) =>
          prefs.setBool(SettingsKeys.onboardingDone, !firstLaunch),
    )
    ..listen(
      adminOrderAlarmMutedProvider,
      (_, muted) =>
          prefs.setBool(SettingsKeys.adminOrderAlarmMuted, muted),
    );
});

/// Completes first-launch onboarding whenever an auth session exists: on
/// start (a session restored after the Google OAuth redirect reloaded the
/// page) and as soon as one appears (OAuth deep link, native Google, email,
/// phone). Prevents the Language/Theme ↔ Auth redirect loop for new users.
final completeOnboardingOnAuthProvider = Provider<void>((ref) {
  ref.listen(currentUserProvider, (previous, next) {
    if (next == null) return;
    // Not inside a widget build: the router listens to the flag.
    Future.microtask(() {
      try {
        completeOnboarding(ref);
      } on StateError {
        // The container was disposed first (app shutdown, tests).
      }
    });
  }, fireImmediately: true);
});
