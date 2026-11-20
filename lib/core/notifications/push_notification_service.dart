import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(),
);

/// Firebase Cloud Messaging setup: Firebase init, permission, device token.
///
/// Every method degrades to "no push" instead of throwing, so the app keeps
/// working when Firebase isn't configured or the user declines permission.
class PushNotificationService {
  Future<bool>? _ready;

  /// Web needs a VAPID key and a service worker, which aren't set up yet.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initializes Firebase and asks for notification permission once;
  /// resolves to whether push notifications can be used.
  Future<bool> initialize() => _ready ??= _initialize();

  Future<bool> _initialize() async {
    if (!isSupported) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final messaging = FirebaseMessaging.instance;
      // TODO: Connect Firebase to this project before notifications can ring
      // on a device. Download google-services.json from the Firebase console
      // (Project settings → Your apps → Android) and place it at
      // android/app/google-services.json, matching this app's package name.
      // Until that file is the one generated for this app, requestPermission
      // and the foreground handler below will not deliver real pushes.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications: permission denied.');
        return false;
      }
      // iOS hides notifications while the app is open unless told otherwise.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      return true;
    } catch (error) {
      debugPrint('Push notifications disabled: $error');
      return false;
    }
  }

  /// The FCM token for this device, or null when push is unavailable.
  Future<String?> getToken() async {
    if (!await initialize()) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      // On iOS this fails until APNs has registered the device.
      debugPrint('Push notifications: could not get token: $error');
      return null;
    }
  }

  /// Emits whenever FCM rotates this device's token.
  Stream<String> get onTokenRefresh async* {
    if (!await initialize()) return;
    yield* FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Data payloads of messages received while the app is open.
  ///
  /// Uses `FirebaseMessaging.onMessage` so a foreground message (for example
  /// the driver accepting an order) can update the UI without a system tray
  /// banner. Background ringing still depends on the TODO in [initialize]:
  /// google-services.json must be connected first.
  Stream<Map<String, dynamic>> get foregroundMessages async* {
    if (!await initialize()) return;
    yield* FirebaseMessaging.onMessage.map((message) => message.data);
  }

  Future<void> setTopicSubscription(
    String topic, {
    required bool subscribed,
  }) async {
    if (!await initialize()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      if (subscribed) {
        await messaging.subscribeToTopic(topic);
      } else {
        await messaging.unsubscribeFromTopic(topic);
      }
    } catch (error) {
      debugPrint('Push notifications: topic "$topic" update failed: $error');
    }
  }
}
