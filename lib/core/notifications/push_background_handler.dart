import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'push_channels.dart';

/// FCM entry point while the app is in the background or terminated
/// (Android / iOS). Runs in its own isolate, so it must stay top-level and
/// initialize everything it uses.
///
/// Messages with a `notification` block (everything send-push and
/// notify-drivers send) are displayed by the OS on the channel named in the
/// message, with the order chime for new orders; tapping one opens the app
/// through `onMessageOpenedApp` / `getInitialMessage`. Data-only messages are
/// shown here as local notifications.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (message.notification != null) return;

    final data = message.data;
    final title = data['title']?.toString().trim() ?? '';
    final body = data['body']?.toString().trim() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await PushChannels.createAll(plugin);
    final type = data['type']?.toString();
    await plugin.show(
      (message.messageId ?? '$title$body').hashCode & 0x7fffffff,
      title.isEmpty ? 'سفير ماركت' : title,
      body.isEmpty ? null : body,
      PushChannels.detailsFor(type),
      payload: jsonEncode(data),
    );
  } catch (error) {
    debugPrint('FCM background: ${message.messageId} skipped: $error');
  }
}
