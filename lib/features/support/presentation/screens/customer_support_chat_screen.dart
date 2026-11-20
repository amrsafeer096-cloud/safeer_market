import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/support_chat.dart';
import '../providers/support_providers.dart';
import '../widgets/support_chat_widgets.dart';

/// «محادثة فورية مع خدمة العملاء»: the customer's live chat with the store,
/// answered from «الشكاوى والمحادثات» on the admin dashboard.
class CustomerSupportChatScreen extends ConsumerWidget {
  const CustomerSupportChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final chatAsync = ref.watch(customerSupportChatProvider);

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(Icons.support_agent_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.supportChatTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.supportChatSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: chatAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ChatError(
            message: error.toString(),
            onRetry: () => ref.invalidate(customerSupportChatProvider),
          ),
          data: (chat) => Column(
            children: [
              Expanded(child: _CustomerMessages(chatId: chat.id)),
              SupportComposer(
                hint: l10n.supportMessageHint,
                chatId: chat.id,
                senderRole: SupportSenderRole.customer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerMessages extends ConsumerStatefulWidget {
  const _CustomerMessages({required this.chatId});

  final String chatId;

  @override
  ConsumerState<_CustomerMessages> createState() => _CustomerMessagesState();
}

class _CustomerMessagesState extends ConsumerState<_CustomerMessages> {
  final _receipts = SupportReceiptTracker();
  var _handling = false;
  var _didInitialMark = false;

  Future<void> _onMessages(List<SupportMessage> messages) async {
    if (_handling) return;
    _handling = true;
    try {
      await _receipts.onMessages(
        repository: ref.read(supportRepositoryProvider),
        chatId: widget.chatId,
        viewerRole: SupportSenderRole.customer,
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
    // Subsequent stream updates only — never call RPCs inside the builder.
    ref.listen<AsyncValue<List<SupportMessage>>>(
      supportMessagesProvider(widget.chatId),
      (previous, next) => next.whenData(_onMessages),
    );
    return ref.watch(supportMessagesProvider(widget.chatId)).when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ChatError(
            message: l10n.supportLoadFailed('$error'),
            onRetry: () =>
                ref.invalidate(supportMessagesProvider(widget.chatId)),
          ),
          data: (messages) {
            // One-shot schedule when the chat opens; ID sets prevent re-RPC.
            if (!_didInitialMark) {
              _didInitialMark = true;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _onMessages(messages));
            }
            return SupportMessageList(
              messages: messages,
              viewer: SupportSenderRole.customer,
              emptyText: l10n.supportChatWelcome,
            );
          },
        );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: palette.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: palette.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
