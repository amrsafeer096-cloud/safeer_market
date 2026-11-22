import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  /// Every notification the caller may read, newest first, updated live:
  /// broadcasts and their own for customers, all of them for admins.
  Stream<List<AppNotification>> watchNotifications();

  /// Admins only: a notification for every customer (or [targetUserId]).
  Future<void> broadcast({
    required String title,
    required String body,
    required AppNotificationType type,
    String? imageUrl,
    String? targetUserId,
  });

  /// Admins only.
  Future<void> deleteNotification(String id);
}
