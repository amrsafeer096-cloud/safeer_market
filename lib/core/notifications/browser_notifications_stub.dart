/// Non-web stub for HTML5 Notifications.
Future<bool> requestBrowserNotificationPermission() async => false;

Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? tag,
  void Function()? onClick,
}) async {}
