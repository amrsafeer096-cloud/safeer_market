import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/domain/entities/user_role.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../network/page_visibility.dart';
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

/// Keeps the signed-in user's device token registered in `user_fcm_tokens`
/// (with their role and platform) and `profiles.fcm_token`: on app start with
/// a saved session, on every sign-in, whenever FCM rotates the token, and
/// again when a sleeping tab / app wakes up. Watch it once at the app root.
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

  Future<void> sync({int attempts = 3}) async {
    for (var i = 0; i < attempts && !disposed; i++) {
      final token = await push.getToken();
      if (token != null) {
        await save(token);
        return;
      }
      // Web often needs a moment after notification permission is granted.
      await Future<void>.delayed(Duration(milliseconds: 400 * (i + 1)));
    }
  }

  unawaited(sync());
  final subscription = push.onTokenRefresh.listen(save);
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(sync()));
  final visibility = listenPageBecameVisible(() => unawaited(sync()));

  ref.onDispose(() {
    disposed = true;
    subscription.cancel();
    lifecycle.dispose();
    visibility?.cancel();
  });
});

/// Deletes the device token on sign-out, so a signed-out phone or browser
/// stops receiving the previous user's orders and updates; send-push prunes
/// the dead token from `user_fcm_tokens`. Watch it once at the app root.
final fcmSignOutCleanupProvider = Provider<void>((ref) {
  ref.listen(
    currentUserProvider.select((user) => user?.id),
    (previous, next) {
      if (previous != null && next == null) {
        unawaited(ref.read(pushNotificationServiceProvider).deleteToken());
      }
    },
  );
});
