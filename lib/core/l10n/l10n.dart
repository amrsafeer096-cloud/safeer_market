import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

export '../../l10n/app_localizations.dart';

/// Strings for code that has no [BuildContext] (repositories, services,
/// domain helpers). Widgets should use `AppLocalizations.of(context)!` so they
/// rebuild when the language changes.
abstract final class L10n {
  static Locale _locale = defaultAppLocale;

  static AppLocalizations get current => lookupAppLocalizations(_locale);

  /// For text persisted for store staff (e.g. order address lines), which
  /// must not depend on the customer's app language.
  static AppLocalizations get store => lookupAppLocalizations(defaultAppLocale);

  /// Locale tag for `intl` formatters (`DateFormat`, `NumberFormat`).
  static String get localeName => _locale.languageCode;

  /// Kept in sync with [localeProvider] by the app root.
  static void setLocale(Locale locale) => _locale = locale;
}

/// Localized strings for providers; recomputes when the language changes.
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(localeProvider)),
);
