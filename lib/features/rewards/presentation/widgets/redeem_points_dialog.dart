import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/loyalty_redemption.dart';
import '../providers/rewards_providers.dart';

/// «تبديل النقاط»: shows the customer's QR code until a cashier redeems
/// it, then says so.
Future<void> showRedeemPointsDialog(BuildContext context, WidgetRef ref) async {
  final userId = ref.read(currentUserProvider)?.id;
  if (userId == null) return;
  final messenger = ScaffoldMessenger.of(context);
  final success = AppLocalizations.of(context)!.redeemSuccess;

  final redeemed = await showDialog<bool>(
    context: context,
    builder: (_) => RedeemPointsDialog(userId: userId),
  );
  if (redeemed != true) return;
  await ref.read(loyaltyPointsProvider.notifier).refresh();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.success,
      content: Text(success),
    ));
}

/// Closes itself with `true` once the balance drops below what it was when
/// the code was shown: on the redemption's Realtime event, or on the next
/// periodic re-read if that event doesn't arrive.
class RedeemPointsDialog extends ConsumerStatefulWidget {
  const RedeemPointsDialog({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<RedeemPointsDialog> createState() => _RedeemPointsDialogState();
}

class _RedeemPointsDialogState extends ConsumerState<RedeemPointsDialog> {
  StreamSubscription<void>? _redemptions;
  Timer? _poll;
  int? _shownPoints;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _shownPoints = ref.read(loyaltyPointsProvider).valueOrNull;
    _redemptions = ref
        .read(loyaltyRedemptionRepositoryProvider)
        .watchRedemptions(widget.userId)
        .listen((_) => _close());
    _poll = Timer.periodic(
      ref.read(redemptionPollIntervalProvider),
      (_) => _checkBalance(),
    );
    unawaited(_checkBalance());
  }

  Future<void> _checkBalance() async {
    try {
      final points =
          await ref.read(loyaltyRepositoryProvider).fetchPoints(widget.userId);
      if (!mounted || _closed) return;
      final shown = _shownPoints;
      if (shown != null && points < shown) {
        _close();
      } else {
        setState(() => _shownPoints = points);
      }
    } catch (error) {
      debugPrint('Re-reading loyalty points failed: $error');
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(_redemptions?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = _shownPoints;
    return AlertDialog(
      title: Text(l10n.redeemQrTitle, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always white with a quiet zone, so the cashier's camera reads
          // it in dark mode too.
          Container(
            key: const Key('redeem-qr'),
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            // A fixed box: QrImageView lays out with a LayoutBuilder, which
            // can't answer the dialog's intrinsic-size query.
            child: SizedBox.square(
              dimension: 220,
              child: QrImageView(
                data: CustomerLoyaltyCode.encode(widget.userId),
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (points != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.rewardsPointsCount(points),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.redeemQrSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
