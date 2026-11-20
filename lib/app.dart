import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n.dart';
import 'core/notifications/fcm_token_sync.dart';
import 'core/notifications/system_alerts_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/settings_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/providers/notifications_providers.dart';
import 'features/profile/presentation/providers/profile_providers.dart';
import 'features/subscriptions/presentation/providers/subscription_providers.dart';

class SafeerMarketApp extends ConsumerWidget {
  const SafeerMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    L10n.setLocale(locale);
    ref
      ..watch(settingsPersistenceProvider)
      ..watch(completeOnboardingOnAuthProvider)
      ..watch(fcmTokenSyncProvider)
      ..watch(driverTopicSyncProvider)
      ..watch(profileSyncProvider)
      ..watch(subscriptionAutoRefreshProvider)
      ..watch(systemAlertsBootstrapProvider)
      ..watch(customerSystemAlertsProvider)
      // Reads the plan on start and on sign-in, without rebuilding the app
      // when it changes.
      ..listen(subscriptionProvider, (_, __) {});

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
