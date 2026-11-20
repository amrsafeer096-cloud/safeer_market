import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/resizable_columns.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../support/domain/entities/support_chat.dart';
import '../../../support/presentation/providers/support_providers.dart';
import '../../../support/presentation/widgets/support_chat_widgets.dart';
import '../widgets/admin_status_chip.dart';
import 'unified_dashboard_screen.dart';

/// Badge text for an unread count.
String unreadLabel(int count) => count > 99 ? '99+' : '$count';

/// Opens a chat and clears unread once. Message-level receipts still run in
/// [_AdminConversation] (once per message id) — never from a stream `build`.
void _selectChat(WidgetRef ref, String chatId) {
  ref.read(selectedSupportChatIdProvider.notifier).state = chatId;
  ref
      .read(supportRepositoryProvider)
      .markChatRead(chatId, SupportSenderRole.admin)
      .catchError((Object error) {
    debugPrint('Support chat: mark read on select failed: $error');
  });
}

/// «الشكاوى والمحادثات»: open customer chats beside the selected
/// conversation; on narrow screens one at a time.
class AdminSupportView extends ConsumerWidget {
  const AdminSupportView({super.key});

  static const splitMinWidth = 700.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final selectedId = ref.watch(selectedSupportChatIdProvider);

    return ref.watch(openSupportChatsProvider).when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.supportLoadFailed('$error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: palette.muted),
              ),
            ),
          ),
          data: (chats) {
            final selected =
                chats.where((chat) => chat.id == selectedId).firstOrNull;
            return LayoutBuilder(builder: (context, constraints) {
              final split = constraints.maxWidth >= splitMinWidth;
              final list = _ChatList(chats: chats, selectedId: selected?.id);
              final conversation = selected == null
                  ? Center(
                      child: Text(l10n.supportSelectChat,
                          style: TextStyle(color: palette.muted)))
                  : _AdminConversation(
                      key: ValueKey(selected.id),
                      chat: selected,
                      onBack: split
                          ? null
                          : () => ref
                              .read(selectedSupportChatIdProvider.notifier)
                              .state = null,
                    );
              if (!split) return selected == null ? list : conversation;
              return ResizableColumns(
                layoutId: 'admin-support',
                columns: [
                  ResizableColumn(flex: 2, minWidth: 240, child: list),
                  ResizableColumn(flex: 3, minWidth: 340, child: conversation),
                ],
              );
            });
          },
        );
  }
}

class _ChatList extends ConsumerWidget {
  const _ChatList({required this.chats, required this.selectedId});

  final List<SupportChat> chats;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Material(
      color: palette.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Icon(Icons.forum_rounded, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.supportCenterTitle,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              Text('${chats.length}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: palette.muted)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Text(l10n.supportNoChats,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: palette.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: chats.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) => _ChatTile(
                      chat: chats[index],
                      selected: chats[index].id == selectedId,
                      onTap: () => _selectChat(ref, chats[index].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.selected,
    required this.onTap,
  });

  final SupportChat chat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final name = chat.customerName ?? l10n.adminNoName;
    final unread = chat.unreadAdminCount > 0;
    return ListTile(
      key: Key('support-chat-${chat.id}'),
      selected: selected,
      selectedTileColor: palette.accent.withValues(alpha: 0.1),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: palette.accent.withValues(alpha: 0.12),
        child: Text(name.characters.first,
            style: TextStyle(
                fontWeight: FontWeight.w900, color: palette.accent)),
      ),
      title: Row(children: [
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: unread ? FontWeight.w900 : FontWeight.w700)),
        ),
        Text(supportTimeLabel(chat.updatedAt),
            style: TextStyle(
                fontSize: 11,
                color: unread ? AppColors.secondary : palette.muted)),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chat.customerPhone != null)
            Text(chat.customerPhone!,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, color: palette.muted)),
          Row(children: [
            Expanded(
              child: Text(
                  chat.previewText(l10n.supportNoMessagesYet),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: unread ? palette.onSurface : palette.muted,
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.normal)),
            ),
            if (unread)
              Badge(
                key: Key('support-unread-${chat.id}'),
                backgroundColor: Colors.red,
                label: Text(unreadLabel(chat.unreadAdminCount)),
              ),
          ]),
        ],
      ),
    );
  }
}

class _AdminConversation extends ConsumerStatefulWidget {
  const _AdminConversation({super.key, required this.chat, this.onBack});

  final SupportChat chat;

  /// Narrow screens: back to the chat list.
  final VoidCallback? onBack;

  @override
  ConsumerState<_AdminConversation> createState() =>
      _AdminConversationState();
}

class _AdminConversationState extends ConsumerState<_AdminConversation> {
  final _receipts = SupportReceiptTracker();
  var _handling = false;
  var _didInitialMark = false;

  Future<void> _onMessages(List<SupportMessage> messages) async {
    if (_handling) return;
    _handling = true;
    try {
      // Delivered + read only for message ids not yet tracked this session.
      await _receipts.onMessages(
        repository: ref.read(supportRepositoryProvider),
        chatId: widget.chat.id,
        viewerRole: SupportSenderRole.admin,
        messages: messages,
      );
    } catch (error) {
      debugPrint('Support chat: could not mark receipts: $error');
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final chat = widget.chat;
    final name = chat.customerName ?? l10n.adminNoName;

    // Subsequent stream updates only — never call RPCs inside the builder.
    ref.listen<AsyncValue<List<SupportMessage>>>(
      supportMessagesProvider(chat.id),
      (previous, next) => next.whenData(_onMessages),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: palette.card,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 12, 10),
            child: Row(children: [
              if (widget.onBack != null)
                BackButton(onPressed: widget.onBack)
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    SelectableText(
                      chat.customerPhone ?? l10n.adminNoPhoneNumber,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                key: const Key('support-latest-orders'),
                onPressed: () => _showLatestOrders(context, chat),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(l10n.supportLatestOrders),
              ),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ref.watch(supportMessagesProvider(chat.id)).when(
                skipLoadingOnRefresh: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                    child: Text(l10n.supportLoadFailed('$error'),
                        textAlign: TextAlign.center)),
                data: (messages) {
                  // One-shot when the chat is opened/selected; ID sets
                  // ensure each message is marked at most once.
                  if (!_didInitialMark) {
                    _didInitialMark = true;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _onMessages(messages));
                  }
                  return SupportMessageList(
                    messages: messages,
                    viewer: SupportSenderRole.admin,
                    emptyText: l10n.supportNoMessagesYet,
                    onOrderTap: (orderId) {
                      ref.read(orderPrepChecklistProvider.notifier).state = {};
                      ref.read(selectedOrderIdProvider.notifier).state =
                          orderId;
                      ref.read(adminMenuProvider.notifier).state =
                          AdminMenu.orderStatus;
                    },
                  );
                },
              ),
        ),
        SupportComposer(
          hint: l10n.supportReplyHint,
          chatId: chat.id,
          senderRole: SupportSenderRole.admin,
          customerUserId: chat.userId,
          onOrderAttached: (orderId) {
            // Keep the admin on the chat; the order card is tappable later.
          },
        ),
      ],
    );
  }
}

/// The customer's latest orders from the live orders feed; picking one
/// opens it on the orders screen.
void _showLatestOrders(BuildContext context, SupportChat chat) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
          l10n.supportLatestOrdersTitle(chat.customerName ?? l10n.adminNoName),
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 420,
        child: Consumer(builder: (context, ref, _) {
          final orders = (ref.watch(liveOrdersProvider).valueOrNull ??
                  const <Map<String, dynamic>>[])
              .where((order) => order['user_id']?.toString() == chat.userId)
              .take(5)
              .toList();
          if (orders.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.supportNoOrders, textAlign: TextAlign.center),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final order in orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('#${_shortId(order['id'])}',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text([
                    AppCurrency.of(
                        double.tryParse('${order['total_amount']}') ?? 0),
                    if (DateTime.tryParse('${order['created_at']}')
                        case final createdAt?)
                      adminDateFormat.format(createdAt.toLocal()),
                  ].join(' • ')),
                  trailing: DashboardStatusBadge(
                      status: '${order['status'] ?? ''}'),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(orderPrepChecklistProvider.notifier).state = {};
                    ref.read(selectedOrderIdProvider.notifier).state =
                        order['id']?.toString();
                    ref.read(adminMenuProvider.notifier).state =
                        AdminMenu.orderStatus;
                  },
                ),
            ],
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

String _shortId(Object? id) {
  final text = '${id ?? ''}';
  return text.length > 6 ? text.substring(0, 6) : text;
}
