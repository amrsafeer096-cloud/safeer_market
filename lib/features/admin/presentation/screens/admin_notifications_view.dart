import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/resizable_columns.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/widgets/notification_card.dart';

/// Prefills the send form when staff picks «إعادة إرسال» → edit first.
final notificationComposeDraftProvider =
    StateProvider<AppNotification?>((ref) => null);

final notificationHistorySearchProvider = StateProvider<String>((ref) => '');
final notificationHistoryTypeProvider =
    StateProvider<AppNotificationType?>((ref) => null);
final notificationHistoryDateProvider = StateProvider<DateTime?>((ref) => null);

/// «إرسال إشعارات»: form on one side, filtered history with resend on the other.
class AdminNotificationsView extends ConsumerWidget {
  const AdminNotificationsView({super.key});

  static const splitMinWidth = 900.0;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteNotificationTitle),
        content: Text(l10n.adminDeleteNotificationConfirm(notification.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .deleteNotification(notification.id);
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(l10n.adminDeleteNotificationFailed('$error')),
        ));
    }
  }

  Future<void> _resend(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminResendNotificationTitle),
        content: Text(l10n.adminResendNotificationConfirm(notification.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: Key('resend-edit-${notification.id}'),
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: Text(l10n.adminResendFillForm),
          ),
          FilledButton.icon(
            key: Key('resend-now-${notification.id}'),
            onPressed: () => Navigator.pop(ctx, 'now'),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.adminResendNotification),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'edit') {
      ref.read(notificationComposeDraftProvider.notifier).state = notification;
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationsRepositoryProvider).broadcast(
            title: notification.title,
            body: notification.body,
            type: notification.type,
            imageUrl: notification.imageUrl ?? '',
          );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.adminNotificationSent),
        ));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(l10n.adminNotificationSendFailed('$error')),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final split = constraints.maxWidth >= splitMinWidth;
      final form = const _BroadcastForm();
      final history = _NotificationsHistory(
        onDelete: (n) => _delete(context, ref, n),
        onResend: (n) => _resend(context, ref, n),
      );
      if (!split) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            form,
            const SizedBox(height: 20),
            SizedBox(height: 520, child: history),
          ],
        );
      }
      return ResizableColumns(
        layoutId: 'admin-notifications',
        columns: [
          ResizableColumn(
            flex: 5,
            minWidth: 320,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [form],
            ),
          ),
          ResizableColumn(
            flex: 5,
            minWidth: 320,
            child: history,
          ),
        ],
      );
    });
  }
}

class _NotificationsHistory extends ConsumerWidget {
  const _NotificationsHistory({
    required this.onDelete,
    required this.onResend,
  });

  final ValueChanged<AppNotification> onDelete;
  final ValueChanged<AppNotification> onResend;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final history = ref.watch(appNotificationsProvider);
    final search = ref.watch(notificationHistorySearchProvider).trim();
    final typeFilter = ref.watch(notificationHistoryTypeProvider);
    final dateFilter = ref.watch(notificationHistoryDateProvider);

    return Material(
      color: palette.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Icon(Icons.history_rounded, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.adminNotificationsHistory,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              key: const Key('notification-history-search'),
              onChanged: (value) => ref
                  .read(notificationHistorySearchProvider.notifier)
                  .state = value,
              decoration: InputDecoration(
                hintText: l10n.adminNotificationSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  key: const Key('notification-filter-date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateFilter ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      ref
                          .read(notificationHistoryDateProvider.notifier)
                          .state = picked;
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(dateFilter == null
                      ? l10n.adminNotificationFilterByDate
                      : '${dateFilter.year}/${dateFilter.month}/${dateFilter.day}'),
                ),
              ),
              if (dateFilter != null)
                IconButton(
                  key: const Key('notification-clear-date'),
                  tooltip: l10n.adminNotificationClearDateFilter,
                  onPressed: () => ref
                      .read(notificationHistoryDateProvider.notifier)
                      .state = null,
                  icon: const Icon(Icons.clear_rounded),
                ),
              const SizedBox(width: 4),
              Text(l10n.adminNotificationFilterByType,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.muted)),
              const SizedBox(width: 6),
              for (final entry in <(AppNotificationType?, String)>[
                (null, l10n.all),
                (AppNotificationType.general, l10n.notificationTypeGeneral),
                (AppNotificationType.promo, l10n.notificationTypePromo),
                (AppNotificationType.magazine, l10n.notificationTypeMagazine),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    key: Key(
                        'notification-filter-type-${entry.$1?.value ?? 'all'}'),
                    label: Text(entry.$2),
                    selected: typeFilter == entry.$1,
                    showCheckmark: false,
                    onSelected: (_) => ref
                        .read(notificationHistoryTypeProvider.notifier)
                        .state = entry.$1,
                  ),
                ),
            ]),
          ),
          const Divider(height: 16),
          Expanded(
            child: history.when(
              skipLoadingOnRefresh: true,
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.notificationsLoadFailed('$error'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.muted)),
                ),
              ),
              data: (notifications) {
                final filtered = notifications.where((n) {
                  if (typeFilter != null && n.type != typeFilter) return false;
                  if (dateFilter != null &&
                      !_sameDay(n.createdAt.toLocal(), dateFilter)) {
                    return false;
                  }
                  if (search.isNotEmpty) {
                    final q = search.toLowerCase();
                    final hay =
                        '${n.title} ${n.body}'.toLowerCase();
                    if (!hay.contains(q)) return false;
                  }
                  return true;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(l10n.adminNoNotificationsSent,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: palette.muted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = filtered[index];
                    return NotificationCard(
                      notification: notification,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            key: Key(
                                'resend-notification-${notification.id}'),
                            onPressed: () => onResend(notification),
                            style: TextButton.styleFrom(
                              foregroundColor: palette.accent,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: Text(l10n.adminResendNotification),
                          ),
                          TextButton.icon(
                            key: Key(
                                'delete-notification-${notification.id}'),
                            onPressed: () => onDelete(notification),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastForm extends ConsumerStatefulWidget {
  const _BroadcastForm();

  @override
  ConsumerState<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends ConsumerState<_BroadcastForm> {
  static const _types = [
    AppNotificationType.general,
    AppNotificationType.promo,
    AppNotificationType.magazine,
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _imageUrl = TextEditingController();
  var _type = AppNotificationType.general;
  var _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _applyDraft(AppNotification? draft) {
    if (draft == null) return;
    _title.text = draft.title;
    _body.text = draft.body;
    _imageUrl.text = draft.imageUrl ?? '';
    setState(() => _type = draft.type == AppNotificationType.order
        ? AppNotificationType.general
        : draft.type);
    ref.read(notificationComposeDraftProvider.notifier).state = null;
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(notificationsRepositoryProvider).broadcast(
            title: _title.text,
            body: _body.text,
            type: _type,
            imageUrl: _imageUrl.text,
          );
      _formKey.currentState!.reset();
      _title.clear();
      _body.clear();
      _imageUrl.clear();
      setState(() => _type = AppNotificationType.general);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.adminNotificationSent),
        ));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(l10n.adminNotificationSendFailed('$error')),
        ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    ref.listen(notificationComposeDraftProvider, (_, next) {
      if (next != null) _applyDraft(next);
    });

    InputDecoration decoration(String label, {String? hint, IconData? icon}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: palette.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        );

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      elevation: palette.isDark ? 0 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.adminSendNotifications,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(l10n.adminNotificationFormSubtitle,
                          style:
                              TextStyle(fontSize: 13, color: palette.muted)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('notification-title-field'),
                controller: _title,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: decoration(
                  l10n.adminNotificationTitleLabel,
                  hint: l10n.adminNotificationTitleHint,
                  icon: Icons.title_rounded,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.adminNotificationTitleRequired
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('notification-body-field'),
                controller: _body,
                minLines: 2,
                maxLines: 5,
                maxLength: 500,
                decoration: decoration(
                  l10n.adminNotificationBodyLabel,
                  hint: l10n.adminNotificationBodyHint,
                  icon: Icons.notes_rounded,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.adminNotificationBodyRequired
                    : null,
              ),
              const SizedBox(height: 8),
              Text(l10n.adminNotificationTypeLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: palette.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in _types)
                    ChoiceChip(
                      key: Key('notification-type-${type.value}'),
                      selected: _type == type,
                      showCheckmark: false,
                      avatar: Icon(type.icon,
                          size: 18,
                          color: _type == type ? Colors.white : type.color),
                      label: Text(type.label(l10n)),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _type == type ? Colors.white : null,
                      ),
                      selectedColor: type.color,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('notification-image-field'),
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: decoration(
                  l10n.adminNotificationImageLabel,
                  hint: 'https://',
                  icon: Icons.image_outlined,
                ),
                validator: (value) {
                  final url = (value ?? '').trim();
                  if (url.isEmpty) return null;
                  final uri = Uri.tryParse(url);
                  final valid = uri != null &&
                      (uri.scheme == 'https' || uri.scheme == 'http') &&
                      uri.host.isNotEmpty;
                  return valid ? null : l10n.adminNotificationImageInvalid;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  key: const Key('send-notification'),
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(l10n.adminSendNotificationButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
