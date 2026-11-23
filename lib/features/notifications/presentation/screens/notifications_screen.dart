import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_card.dart';

/// «الإشعارات»: offers, magazines and news from Safeer Market, newest
/// first. Opening it clears the bell's red dot.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) markNotificationsRead(ref);
    });
  }

  void _open(AppNotification notification) {
    switch (notification.type) {
      case AppNotificationType.magazine:
        context.push(AppRoutes.magazines);
      case AppNotificationType.promo:
        context.push(AppRoutes.offers);
      case AppNotificationType.supportChat:
        context.push(AppRoutes.supportChat);
      case AppNotificationType.loyalty:
        context.push(AppRoutes.rewards);
      case AppNotificationType.order:
        context.push(AppRoutes.orders);
      case AppNotificationType.general:
        break;
    }
  }

  static bool _opens(AppNotificationType type) =>
      type == AppNotificationType.magazine ||
      type == AppNotificationType.promo ||
      type == AppNotificationType.supportChat ||
      type == AppNotificationType.loyalty ||
      type == AppNotificationType.order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    // Arriving while the list is open: already seen.
    ref.listen(customerNotificationsProvider, (_, next) {
      if (next.hasValue) markNotificationsRead(ref);
    });
    final notificationsAsync = ref.watch(customerNotificationsProvider);

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.page,
        appBar: AppBar(
          title: Text(
            l10n.notificationsTitle,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: RefreshIndicator(
          color: palette.accent,
          onRefresh: () => ref.refresh(appNotificationsProvider.future),
          child: notificationsAsync.when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _Scrollable(
              child: _Message(
                icon: Icons.wifi_off_rounded,
                title: l10n.notificationsLoadFailed('$error'),
                action: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(appNotificationsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ),
            data: (notifications) => notifications.isEmpty
                ? const _Scrollable(child: _EmptyNotifications())
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: _opens(notification.type)
                            ? () => _open(notification)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// Lets pull-to-refresh work on the empty and error states.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return _Message(
      key: const Key('notifications-empty'),
      illustration: Container(
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              palette.accent.withValues(alpha: 0.22),
              AppColors.secondary.withValues(alpha: 0.08),
              palette.page.withValues(alpha: 0),
            ],
            stops: const [0, 0.65, 1],
          ),
        ),
        child: Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.accent, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 46,
              color: Colors.white,
            ),
          ),
        ),
      ),
      title: l10n.noNewNotifications,
      subtitle: l10n.notificationsEmptySubtitle,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.title,
    this.icon,
    this.illustration,
    this.subtitle,
    this.action,
  });

  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ?? Icon(icon, size: 64, color: palette.muted),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: palette.onSurface,
            ),
          ),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.7, color: palette.muted),
            ),
          ],
          if (action case final action?) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
}
