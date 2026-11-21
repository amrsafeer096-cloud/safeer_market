import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channels shared by the app and the FCM background
/// isolate. The ids must match `channel_id` in the send-push / notify-drivers
/// Edge Functions and the default channel in AndroidManifest.xml.
abstract final class PushChannels {
  /// New orders for admins, order takers and drivers: max importance and the
  /// order chime (android/app/src/main/res/raw/order_chime.ogg). Android
  /// fixes a channel's sound when it is first created, so a new sound needs
  /// a new channel id.
  static const orders = AndroidNotificationChannel(
    'safeer_orders',
    'طلبات جديدة',
    description: 'تنبيه بصوت مميز عند وصول طلب جديد',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('order_chime'),
    enableVibration: true,
  );

  /// Order updates, offers and support replies with the default sound.
  static const alerts = AndroidNotificationChannel(
    'safeer_alerts',
    'سفير ماركت',
    description: 'تحديثات الطلبات والعروض والرسائل',
    importance: Importance.high,
  );

  /// Data `type`s that ring the order chime.
  static bool isUrgent(String? type) => type == 'new_order';

  static Future<void> createAll(FlutterLocalNotificationsPlugin plugin) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(orders);
    await android?.createNotificationChannel(alerts);
  }

  static NotificationDetails detailsFor(String? type) {
    final urgent = isUrgent(type);
    final channel = urgent ? orders : alerts;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: urgent ? Priority.max : Priority.high,
        sound: channel.sound,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: urgent ? 'order_chime.caf' : null,
      ),
    );
  }
}
