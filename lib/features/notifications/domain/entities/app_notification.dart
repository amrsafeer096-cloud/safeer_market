/// What a notification is about; decides its icon and where tapping it goes.
enum AppNotificationType {
  general('general'),
  promo('promo'),
  magazine('magazine'),
  order('order'),
  supportChat('support_chat');

  const AppNotificationType(this.value);

  /// The value stored in `app_notifications.type`.
  final String value;

  static AppNotificationType fromValue(Object? value) => values.firstWhere(
        (type) => type.value == value,
        orElse: () => general,
      );
}

/// A row of `app_notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.imageUrl,
    this.targetUserId,
  });

  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? imageUrl;

  /// Null for a broadcast to every customer.
  final String? targetUserId;
  final DateTime createdAt;
}

class NotificationsFailure implements Exception {
  const NotificationsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
