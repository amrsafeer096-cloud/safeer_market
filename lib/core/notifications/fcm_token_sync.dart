import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/domain/entities/user_role.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import 'new_order_notifier.dart';
import 'push_notification_service.dart';

/// Subscribes driver devices to the [driversTopic] and unsubscribes them when
/// a driver signs out. Customers are never touched, so guests aren't asked
/// for notification permission at launch. Watch it once at the app root.
final driverTopicSyncProvider = Provider<void>((ref) {
  ref.listen(
    userRoleProvider.select((role) => role.valueOrNull),
    (previous, next) {
      final push = ref.read(pushNotificationServiceProvider);
      if (next == UserRole.driver) {
        unawaited(push.setTopicSubscription(driversTopic, subscribed: true));
      } else if (previous == UserRole.driver) {
        unawaited(push.setTopicSubscription(driversTopic, subscribed: false));
      }
    },
    fireImmediately: true,
  );
});

/// Keeps the signed-in user's `profiles.fcm_token` current: on app start with
/// a saved session, on every sign-in, and whenever FCM rotates the token.
/// Watch it once at the app root.
final fcmTokenSyncProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return;

  final push = ref.watch(pushNotificationServiceProvider);
  final profiles = ref.watch(profileRepositoryProvider);
  var disposed = false;

  Future<void> save(String? token) async {
    if (token == null || disposed) return;
    try {
      await profiles.saveFcmToken(userId: userId, token: token);
    } catch (error) {
      debugPrint('Push notifications: could not save token: $error');
    }
  }

  unawaited(push.getToken().then(save));
  final subscription = push.onTokenRefresh.listen(save);
  ref.onDispose(() {
    disposed = true;
    subscription.cancel();
  });
});
