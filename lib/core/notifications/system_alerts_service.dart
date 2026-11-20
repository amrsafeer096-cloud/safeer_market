import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import 'browser_notifications.dart';
import 'push_notification_service.dart';

/// Payload keys used when a system tray / browser notification is tapped.
abstract final class SystemAlertPayload {
  static const route = 'route';
}

/// Shows OS/browser notifications when the app is backgrounded or the tab
/// is unfocused, and deep-links into chat / orders / the bell list.
class SystemAlertsService {
  SystemAlertsService(this._ref);

  final Ref _ref;
  final _local = FlutterLocalNotificationsPlugin();
  final seenIds = <String>{};
  var _started = false;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  static const _channelId = 'safeer_alerts';
  static const _channelName = 'سفير ماركت';

  static const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

  bool get _mobileTray =>
      !kIsWeb &&
      !_isFlutterTest &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      if (kIsWeb) {
        await requestBrowserNotificationPermission();
        return;
      }
      if (!_mobileTray) return;

      await _initLocalNotifications();
      await _ref.read(pushNotificationServiceProvider).initialize();
      _foregroundSub =
          FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _openedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _navigateFromData(initial.data);
      }
    } catch (error) {
      debugPrint('SystemAlerts: start skipped: $error');
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateFromData(data);
        } catch (_) {
          _navigateFromData({SystemAlertPayload.route: payload});
        }
      },
    );
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
      ),
    );
  }

  /// In-app realtime → OS/browser banner (deduped by [id]).
  Future<void> present({
    required String id,
    required String title,
    required String body,
    String route = AppRoutes.notifications,
  }) async {
    if (seenIds.contains(id)) return;
    seenIds.add(id);
    if (seenIds.length > 200) {
      seenIds.remove(seenIds.first);
    }

    final displayTitle = title.trim().isEmpty ? 'سفير ماركت' : title;
    final displayBody = body.trim();

    try {
      if (kIsWeb) {
        await showBrowserNotification(
          title: 'سفير ماركت',
          body: displayBody.isEmpty ? displayTitle : displayBody,
          tag: id,
          onClick: () => navigate(route),
        );
        return;
      }
      if (!_mobileTray) return;

      final payload = jsonEncode({SystemAlertPayload.route: route});
      await _local.show(
        id.hashCode & 0x7fffffff,
        'سفير ماركت',
        displayBody.isEmpty ? displayTitle : '$displayTitle\n$displayBody',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (error) {
      debugPrint('SystemAlerts: present skipped: $error');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'سفير ماركت';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    unawaited(present(
      id: message.messageId ??
          '${DateTime.now().millisecondsSinceEpoch}-$title',
      title: title,
      body: body,
      route: routeFromData(message.data),
    ));
  }

  void _onMessageOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static String routeFromData(Map<String, dynamic> data) {
    final explicit = data[SystemAlertPayload.route]?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final type = data['type']?.toString();
    if (type == 'support_chat') return AppRoutes.supportChat;
    if (type == 'order') return AppRoutes.orders;
    return AppRoutes.notifications;
  }

  void _navigateFromData(Map<String, dynamic> data) {
    navigate(routeFromData(data));
  }

  void navigate(String route) {
    final router = _ref.read(appRouterProvider);
    scheduleMicrotask(() {
      try {
        router.go(AppRoutes.home);
        router.push(route);
      } catch (error) {
        debugPrint('SystemAlerts: navigate failed: $error');
      }
    });
  }
}

final systemAlertsServiceProvider = Provider<SystemAlertsService>((ref) {
  final service = SystemAlertsService(ref);
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Boots permission + FCM/local handlers once the app tree is up.
final systemAlertsBootstrapProvider = Provider<void>((ref) {
  unawaited(ref.watch(systemAlertsServiceProvider).start());
});
