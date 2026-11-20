import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/notifications/system_alerts_service.dart';
import '../../../../core/providers/settings_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_notifications_repository.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return SupabaseNotificationsRepository(ref.watch(supabaseClientProvider));
});

/// Everything the signed-in user (or guest) may read, live. Resubscribes on
/// sign-in and sign-out, since row level security depends on who it is.
final appNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return ref.watch(notificationsRepositoryProvider).watchNotifications();
});

/// The customer's own list: broadcasts and notifications for them. Admins
/// can read everyone's, which belong on the dashboard, not in their bell.
final customerNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<AppNotification>>>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  return ref.watch(appNotificationsProvider).whenData(
        (notifications) => [
          for (final notification in notifications)
            if (notification.targetUserId == null ||
                notification.targetUserId == userId)
              notification,
        ],
      );
});

abstract final class NotificationPrefsKeys {
  static const lastReadAt = 'last_read_notifications_at';
}

/// When this device last opened «الإشعارات»; null if it never has.
final notificationsLastReadProvider = StateProvider<DateTime?>((ref) {
  final saved = ref
      .watch(sharedPreferencesProvider)
      ?.getString(NotificationPrefsKeys.lastReadAt);
  return saved == null ? null : DateTime.tryParse(saved)?.toLocal();
});

/// The bell's red dot: a notification newer than the last visit.
final hasUnreadNotificationsProvider = Provider.autoDispose<bool>((ref) {
  final latest = ref
      .watch(customerNotificationsProvider)
      .valueOrNull
      ?.firstOrNull
      ?.createdAt;
  if (latest == null) return false;
  final lastRead = ref.watch(notificationsLastReadProvider);
  return lastRead == null || latest.isAfter(lastRead);
});

/// Everything up to now has been seen. Never earlier than the newest
/// notification, so a phone clock running behind the server can't bring
/// the red dot straight back.
void markNotificationsRead(WidgetRef ref) {
  final latest = ref
      .read(customerNotificationsProvider)
      .valueOrNull
      ?.firstOrNull
      ?.createdAt;
  final now = DateTime.now();
  final readAt = latest != null && latest.isAfter(now) ? latest : now;
  final current = ref.read(notificationsLastReadProvider);
  if (current != null && !readAt.isAfter(current)) return;
  ref.read(notificationsLastReadProvider.notifier).state = readAt;
  ref
      .read(sharedPreferencesProvider)
      ?.setString(NotificationPrefsKeys.lastReadAt,
          readAt.toUtc().toIso8601String());
}

/// Raises OS/browser banners for new customer-facing notifications (support
/// replies, broadcasts, …). Seeds [seenIds] from the first snapshot so a
/// cold start does not spam the tray with history.
final customerSystemAlertsProvider = Provider.autoDispose<void>((ref) {
  ref.watch(systemAlertsBootstrapProvider);
  final service = ref.watch(systemAlertsServiceProvider);
  var primed = false;
  ref.listen<AsyncValue<List<AppNotification>>>(
    customerNotificationsProvider,
    (previous, next) {
      next.whenData((notifications) {
        if (!primed) {
          primed = true;
          for (final n in notifications.take(40)) {
            service.seenIds.add(n.id);
          }
          return;
        }
        final previousIds = {
          for (final n in previous?.valueOrNull ?? const <AppNotification>[])
            n.id,
        };
        for (final n in notifications) {
          if (previousIds.contains(n.id)) continue;
          final route = n.type == AppNotificationType.supportChat
              ? AppRoutes.supportChat
              : AppRoutes.notifications;
          unawaited(service.present(
            id: n.id,
            title: n.title,
            body: n.body,
            route: route,
          ));
        }
      });
    },
  );
});
