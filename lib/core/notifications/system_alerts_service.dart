import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import 'browser_notifications.dart';
import 'push_channels.dart';
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
        if (_isFlutterTest) return;
        // Background / closed-tab pushes are shown by
        // web/firebase-messaging-sw.js; this covers the open tab.
        if (await _ref.read(pushNotificationServiceProvider).initialize()) {
          _foregroundSub =
              FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        }
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
        return;
      }
      // A local notification shown by the background handler launched us.
      final launch = await _local.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true && payload != null) {
        _openPayload(payload);
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
        _openPayload(payload);
      },
    );
    // FCM displays background / terminated pushes on these channels, so they
    // must exist before the first push arrives.
    await PushChannels.createAll(_local);
    // Android 13+: POST_NOTIFICATIONS is declared in the manifest; ask at
    // runtime so terminated-state FCM banners are allowed.
    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  void _openPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {
      _navigateFromData({SystemAlertPayload.route: payload});
    }
  }

  /// In-app realtime → OS/browser banner (deduped by [id]). A [type] of
  /// `new_order` uses the order chime channel.
  Future<void> present({
    required String id,
    required String title,
    required String body,
    String route = AppRoutes.notifications,
    String? type,
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

      final payload = jsonEncode({
        SystemAlertPayload.route: route,
        if (type != null && type.isNotEmpty) 'type': type,
      });
      await _local.show(
        id.hashCode & 0x7fffffff,
        'سفير ماركت',
        displayBody.isEmpty ? displayTitle : '$displayTitle\n$displayBody',
        PushChannels.detailsFor(type),
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
    // notification_id matches the bell's realtime row, so the same
    // notification isn't shown twice.
    final notificationId = message.data['notification_id']?.toString();
    unawaited(present(
      id: notificationId ??
          message.messageId ??
          '${DateTime.now().millisecondsSinceEpoch}-$title',
      title: title,
      body: body,
      route: routeFromData(message.data),
      type: message.data['type']?.toString(),
    ));
  }

  void _onMessageOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static String routeFromData(Map<String, dynamic> data) {
    final orderId = data['order_id']?.toString().trim();
    final action = data['action']?.toString();
    final stage = data['stage']?.toString();
    if (action == 'rate_order' && orderId != null && orderId.isNotEmpty) {
      return AppRoutes.orderRating(orderId);
    }
    if (orderId != null &&
        orderId.isNotEmpty &&
        (stage == 'out_for_delivery' || stage == 'arriving_soon')) {
      return AppRoutes.orderTracking(
        orderId,
        driverPhone: data['driver_phone']?.toString(),
      );
    }

    // Customer deep-links follow [type]; staff `new_order` keeps the
    // role-specific `route` from send-push (admin / taker / driver).
    final type = (data['type']?.toString() ?? '').toLowerCase().trim();
    switch (type) {
      case 'order':
        return AppRoutes.orders;
      case 'magazine':
        return AppRoutes.magazines;
      case 'offers':
      case 'promo':
        return AppRoutes.offers;
      case 'loyalty':
        return AppRoutes.rewards;
      case 'chat':
      case 'support':
      case 'support_chat':
        return AppRoutes.supportChat;
    }

    final explicit = data[SystemAlertPayload.route]?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (type == 'new_order') return AppRoutes.driver;
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
