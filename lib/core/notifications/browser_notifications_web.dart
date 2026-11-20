// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Requests permission for the HTML5 Notifications API (once per browser).
Future<bool> requestBrowserNotificationPermission() async {
  try {
    if (!html.Notification.supported) return false;
    final current = html.Notification.permission;
    if (current == 'granted') return true;
    if (current == 'denied') return false;
    final result = await html.Notification.requestPermission();
    return result == 'granted';
  } catch (_) {
    return false;
  }
}

/// Shows a desktop/mobile browser notification outside the Flutter canvas.
Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? tag,
  void Function()? onClick,
}) async {
  try {
    if (!html.Notification.supported) return;
    if (html.Notification.permission != 'granted') {
      final ok = await requestBrowserNotificationPermission();
      if (!ok) return;
    }
    final notification = html.Notification(
      title,
      body: body,
      tag: tag,
      icon: '/icons/Icon-192.png',
    );
    notification.onClick.listen((_) {
      onClick?.call();
      notification.close();
    });
  } catch (_) {}
}
