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

/// True until the user finishes or skips onboarding; the router sends a
/// first launch there.
final isFirstLaunchProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return !(prefs?.getBool(SettingsKeys.onboardingDone) ?? false);
});

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

/// Completes first-launch onboarding as soon as any auth session appears
/// (Google OAuth deep link, native Google, email, phone). Prevents the
/// Language/Theme ↔ Auth redirect loop for new Google users.
final completeOnboardingOnAuthProvider = Provider<void>((ref) {
  ref.listen(currentUserProvider, (previous, next) {
    if (previous != null || next == null) return;
    if (!ref.read(isFirstLaunchProvider)) return;
    ref.read(isFirstLaunchProvider.notifier).state = false;
  });
});
