import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(),
);

/// Firebase Cloud Messaging setup: Firebase init, permission, device token.
///
/// Every method degrades to "no push" instead of throwing, so the app keeps
/// working when Firebase isn't configured or the user declines permission.
class PushNotificationService {
  Future<bool>? _ready;
  Future<void>? _deleting;

  /// Android, iOS and the browser (web/firebase-messaging-sw.js shows
  /// notifications while the tab is in the background or closed).
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// `android`, `ios` or `web`, as stored in `user_fcm_tokens.platform`.
  static String get platformName =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

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
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications: permission denied.');
        return false;
      }
      if (!kIsWeb) {
        // iOS hides notifications while the app is open unless told otherwise.
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return true;
    } catch (error) {
      debugPrint('Push notifications disabled: $error');
      return false;
    }
  }

  /// The FCM token for this device, or null when push is unavailable.
  Future<String?> getToken() async {
    if (!await initialize()) return null;
    await _deleting;
    try {
      return await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && AppConfig.firebaseVapidKey.isNotEmpty
            ? AppConfig.firebaseVapidKey
            : null,
      );
    } catch (error) {
      // On iOS this fails until APNs has registered the device; on the web
      // when the service worker can't be registered.
      debugPrint('Push notifications: could not get token: $error');
      return null;
    }
  }

  /// Invalidates this device's token, so a signed-out device stops getting
  /// the previous user's notifications. The next [getToken] issues a new one.
  Future<void> deleteToken() {
    return _deleting = () async {
      if (!await initialize()) return;
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (error) {
        debugPrint('Push notifications: could not delete token: $error');
      }
    }();
  }

  /// Emits whenever FCM rotates this device's token.
  Stream<String> get onTokenRefresh async* {
    if (!await initialize()) return;
    yield* FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Data payloads of messages received while the app is open, so a
  /// foreground message (for example a new order) can update the UI.
  Stream<Map<String, dynamic>> get foregroundMessages async* {
    if (!await initialize()) return;
    yield* FirebaseMessaging.onMessage.map((message) => message.data);
  }

  /// FCM topics aren't available in the browser.
  Future<void> setTopicSubscription(
    String topic, {
    required bool subscribed,
  }) async {
    if (kIsWeb || !await initialize()) return;
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
