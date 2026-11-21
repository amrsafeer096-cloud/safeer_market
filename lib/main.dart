import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/audio/app_sound_service.dart';
import 'core/config/app_config.dart';
import 'core/notifications/push_background_handler.dart';
import 'core/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web handles background pushes in web/firebase-messaging-sw.js.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  final (_, preferences) = await (
    Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    ),
    // Read before the first frame, so the saved language, theme and
    // onboarding state apply without a flash of the defaults.
    SharedPreferences.getInstance(),
  ).wait;
  // A restored (or just redirected-back) session means onboarding is done:
  // save it before the first frame so the router never sends a signed-in
  // user back to the welcome screens after a web reload.
  if (Supabase.instance.client.auth.currentSession != null) {
    await preferences.setBool(SettingsKeys.onboardingDone, true);
  }
  // Media-channel audio context + warm-up of the bundled sound effects.
  unawaited(AppSoundService.instance.init());
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const SafeerMarketApp(),
    ),
  );
}
