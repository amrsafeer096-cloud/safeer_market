import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';

/// «منذ ساعتين»; the date once it is a week old.
String notificationTimeAgo(
  AppLocalizations l10n,
  DateTime time, {
  DateTime? now,
}) {
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inMinutes < 1) return l10n.timeJustNow;
  if (elapsed.inHours < 1) return l10n.timeMinutesAgo(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.timeHoursAgo(elapsed.inHours);
  if (elapsed.inDays < 7) return l10n.timeDaysAgo(elapsed.inDays);
  return (DateFormat('d MMM yyyy', l10n.localeName)..useNativeDigits = false)
      .format(time);
}

extension AppNotificationTypeStyle on AppNotificationType {
  IconData get icon => switch (this) {
        AppNotificationType.general => Icons.campaign_rounded,
        AppNotificationType.promo => Icons.local_offer_rounded,
        AppNotificationType.magazine => Icons.menu_book_rounded,
        AppNotificationType.order => Icons.shopping_bag_rounded,
        AppNotificationType.supportChat => Icons.support_agent_rounded,
      };

  Color get color => switch (this) {
        AppNotificationType.general => AppColors.primary,
        AppNotificationType.promo => AppColors.secondary,
        AppNotificationType.magazine => const Color(0xFF6A1B9A),
        AppNotificationType.order => AppColors.success,
        AppNotificationType.supportChat => const Color(0xFF0284C7),
      };

  String label(AppLocalizations l10n) => switch (this) {
        AppNotificationType.general => l10n.notificationTypeGeneral,
        AppNotificationType.promo => l10n.notificationTypePromo,
        AppNotificationType.magazine => l10n.notificationTypeMagazine,
        AppNotificationType.order => l10n.notificationTypeOrder,
        AppNotificationType.supportChat => l10n.notificationTypeSupportChat,
      };
}

/// One notification: type icon, bold title, body, optional image and how
/// long ago it was sent. [trailing] sits beside the time (the dashboard's
/// delete button).
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.trailing,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final type = notification.type;
    final color = palette.isDark && type == AppNotificationType.general
        ? palette.accent
        : type.color;
    final imageUrl = notification.imageUrl;

    return Material(
      color: palette.card,
      elevation: palette.isDark ? 0 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('notification-${notification.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(type.icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            height: 1.4,
                          ),
                        ),
                        if (notification.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Icon(Icons.chevron_left_rounded,
                          color: palette.muted),
                    ),
                ],
              ),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          ColoredBox(color: palette.imageBackdrop),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: palette.imageBackdrop,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: palette.muted),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      type.label(l10n),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule_rounded, size: 14, color: palette.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notificationTimeAgo(l10n, notification.createdAt),
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
