import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_providers.dart';

/// App languages shown in Settings. Native names stay in their own script so
/// users can find a language even when the UI is in another locale.
class AppLanguage {
  const AppLanguage({
    required this.locale,
    required this.nativeName,
  });

  final Locale locale;
  final String nativeName;

  static const values = <AppLanguage>[
    AppLanguage(locale: Locale('ar'), nativeName: 'العربية'),
    AppLanguage(locale: Locale('en'), nativeName: 'English'),
    AppLanguage(locale: Locale('uz'), nativeName: 'Oʻzbekcha'),
    AppLanguage(locale: Locale('ms'), nativeName: 'Bahasa Melayu'),
    AppLanguage(locale: Locale('zh'), nativeName: '中文'),
    AppLanguage(locale: Locale('ky'), nativeName: 'Кыргызча'),
  ];

  static AppLanguage forLocale(Locale locale) {
    return values.firstWhere(
      (language) => language.locale.languageCode == locale.languageCode,
      orElse: () => values.first,
    );
  }
}

const defaultAppLocale = Locale('ar');

/// The app language, saved across restarts.
final localeProvider = StateProvider<Locale>((ref) {
  final saved =
      ref.watch(sharedPreferencesProvider)?.getString(SettingsKeys.locale);
  return AppLanguage.values.map((language) => language.locale).firstWhere(
        (locale) => locale.languageCode == saved,
        orElse: () => defaultAppLocale,
      );
});
