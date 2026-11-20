import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/repositories/supabase_support_repository.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/repositories/support_repository.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupabaseSupportRepository(ref.watch(supabaseClientProvider));
});

/// The signed-in customer's open chat, created with their profile's name and
/// phone on their first visit.
final customerSupportChatProvider =
    FutureProvider.autoDispose<SupportChat>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) throw SupportFailure(L10n.current.pleaseSignInFirst);
  final profile = await ref.read(userProfileProvider.future);
  return ref.watch(supportRepositoryProvider).openChat(
        userId: userId,
        customerName: profile?.displayName,
        customerPhone: profile?.phone,
      );
});

final supportMessagesProvider = StreamProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, chatId) {
  return ref.watch(supportRepositoryProvider).watchMessages(chatId);
});

/// Dashboard: every open chat, most recently active first.
/// Kept alive at the top of the admin dashboard so badges stay live on
/// every menu (تلقي الطلبات, حالة الطلب, …).
final openSupportChatsProvider =
    StreamProvider.autoDispose<List<SupportChat>>((ref) {
  return ref.watch(supportRepositoryProvider).watchOpenChats();
});

/// Customer app: live unread count for «المزيد» / «تحدث معنا» badges.
final customerSupportUnreadProvider = StreamProvider.autoDispose<int>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return Stream.value(0);
  return ref.watch(supportRepositoryProvider).watchMyUnreadCount(userId);
});

/// Dashboard: the chat open in «الشكاوى والمحادثات».
final selectedSupportChatIdProvider = StateProvider<String?>((ref) => null);

/// Distinct chats with unread customer messages, excluding the chat the
/// admin currently has open (its badge clears as soon as they select it).
final supportUnreadTotalProvider = Provider.autoDispose<int>((ref) {
  final chats = ref.watch(openSupportChatsProvider).valueOrNull ?? const [];
  final selectedId = ref.watch(selectedSupportChatIdProvider);
  return chats
      .where(
        (chat) => chat.unreadAdminCount > 0 && chat.id != selectedId,
      )
      .length;
});

/// Session-scoped chat ids already marked delivered from the dashboard, keyed
/// by the unread count at mark time so a later increase (new messages) can
/// mark again — but identical stream re-emissions never re-call the RPC.
final Map<String, int> _adminDeliveredUnreadAt = {};

/// Marks delivered/read for message ids at most once per session.
///
/// Never call from [build] / a [StreamBuilder] builder — only from a stream
/// listener or an explicit user action (e.g. selecting a chat).
class SupportReceiptTracker {
  final Set<String> deliveredMarkedIds = {};
  final Set<String> readMarkedIds = {};

  SupportSenderRole _other(SupportSenderRole viewer) =>
      viewer == SupportSenderRole.admin
          ? SupportSenderRole.customer
          : SupportSenderRole.admin;

  /// Marks `sent` → delivered for unseen other-party message ids only.
  Future<void> markDeliveredIfNeeded({
    required SupportRepository repository,
    required String chatId,
    required SupportSenderRole viewerRole,
    required List<SupportMessage> messages,
  }) async {
    final other = _other(viewerRole);
    final toDeliver = [
      for (final message in messages)
        if (message.senderRole == other &&
            message.status == SupportMessageStatus.sent &&
            !deliveredMarkedIds.contains(message.id))
          message.id,
    ];
    if (toDeliver.isEmpty) return;
    deliveredMarkedIds.addAll(toDeliver);
    try {
      await repository.markDelivered(chatId, viewerRole);
    } catch (_) {
      deliveredMarkedIds.removeAll(toDeliver);
      rethrow;
    }
  }

  /// Marks unread other-party messages as read for ids not yet tracked.
  Future<void> markReadIfNeeded({
    required SupportRepository repository,
    required String chatId,
    required SupportSenderRole viewerRole,
    required List<SupportMessage> messages,
  }) async {
    final other = _other(viewerRole);
    final toRead = [
      for (final message in messages)
        if (message.senderRole == other &&
            message.status != SupportMessageStatus.read &&
            !readMarkedIds.contains(message.id))
          message.id,
    ];
    if (toRead.isEmpty) return;
    readMarkedIds.addAll(toRead);
    try {
      await repository.markChatRead(chatId, viewerRole);
    } catch (_) {
      readMarkedIds.removeAll(toRead);
      rethrow;
    }
  }

  Future<void> onMessages({
    required SupportRepository repository,
    required String chatId,
    required SupportSenderRole viewerRole,
    required List<SupportMessage> messages,
    bool markRead = true,
  }) async {
    await markDeliveredIfNeeded(
      repository: repository,
      chatId: chatId,
      viewerRole: viewerRole,
      messages: messages,
    );
    if (!markRead) return;
    await markReadIfNeeded(
      repository: repository,
      chatId: chatId,
      viewerRole: viewerRole,
      messages: messages,
    );
  }
}

/// While the admin dashboard is open, turn customer ✓ into ✓✓ (delivered)
/// for chats that newly gain unread customer messages.
/// Call from a [ConsumerWidget]/[ConsumerStatefulWidget] `build` via
/// [ref.listen] only — never call an RPC directly from `build`.
void watchAdminSupportDelivered(WidgetRef ref) {
  ref.listen(openSupportChatsProvider, (previous, next) {
    next.whenData((chats) {
      final repository = ref.read(supportRepositoryProvider);
      for (final chat in chats) {
        if (chat.unreadAdminCount <= 0) {
          _adminDeliveredUnreadAt.remove(chat.id);
          continue;
        }
        final markedAt = _adminDeliveredUnreadAt[chat.id];
        // Same unread count already marked → skip (breaks Realtime loops).
        if (markedAt != null && markedAt >= chat.unreadAdminCount) continue;
        _adminDeliveredUnreadAt[chat.id] = chat.unreadAdminCount;
        repository.markDelivered(chat.id, SupportSenderRole.admin);
      }
    });
  });
}
