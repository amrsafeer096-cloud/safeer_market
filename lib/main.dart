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
import 'core/providers/settings_providers.dart';

/// FCM entry when the app is killed / backgrounded (mobile only).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Payload is shown by the OS tray; deep-link runs on tap via onMessageOpenedApp.
  debugPrint('FCM background: ${message.messageId} ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
  // Media-channel audio context + warm-up of the bundled sound effects.
  unawaited(AppSoundService.instance.init());
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const SafeerMarketApp(),
    ),
  );
}
