import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../subscriptions/domain/pending_subscription.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../widgets/admin_transfer_receipt_dialog.dart';

final pendingSubscriptionsProvider =
    FutureProvider.autoDispose<List<PendingSubscriptionRequest>>((ref) async {
  return ref.watch(paymobServiceProvider).listPendingSubscriptions();
});

/// Admin list of InstaPay subscription upgrades awaiting verification.
class AdminPendingSubscriptionsView extends ConsumerWidget {
  const AdminPendingSubscriptionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final async = ref.watch(pendingSubscriptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminMenuPendingSubscriptions,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: palette.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.retry,
                onPressed: () => ref.invalidate(pendingSubscriptionsProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    l10n.adminNoPendingSubscriptions,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.muted,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _PendingSubscriptionCard(request: items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PendingSubscriptionCard extends ConsumerStatefulWidget {
  const _PendingSubscriptionCard({required this.request});

  final PendingSubscriptionRequest request;

  @override
  ConsumerState<_PendingSubscriptionCard> createState() =>
      _PendingSubscriptionCardState();
}

class _PendingSubscriptionCardState
    extends ConsumerState<_PendingSubscriptionCard> {
  var _approving = false;

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _approving = true);
    try {
      await ref
          .read(paymobServiceProvider)
          .approveSubscriptionRequest(widget.request.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminSubscriptionApproved)),
      );
      ref.invalidate(pendingSubscriptionsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final request = widget.request;
    final name = (request.fullName?.trim().isNotEmpty == true)
        ? request.fullName!.trim()
        : (request.phone?.trim().isNotEmpty == true
            ? request.phone!.trim()
            : request.userId);
    final tierLabel = request.isVip
        ? l10n.paywallProTitle
        : l10n.paywallPrimeTitle;
    final receiptUrl = request.receiptUrl?.trim();

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.onSurface,
              ),
            ),
            if (request.phone != null &&
                request.phone!.trim().isNotEmpty &&
                request.fullName?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                request.phone!.trim(),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              '${l10n.adminPendingSubscriptionTier}: $tierLabel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
            if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  key: Key('pending-sub-view-receipt-${request.userId}'),
                  onPressed: () =>
                      showAdminTransferReceiptDialog(context, receiptUrl),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(l10n.adminViewTransferReceipt),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5A2D82),
                    side: BorderSide(
                      color: const Color(0xFF5A2D82).withValues(alpha: 0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: Key('pending-sub-approve-${request.userId}'),
                onPressed: _approving ? null : _approve,
                icon: _approving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(l10n.adminActivateAccount),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
