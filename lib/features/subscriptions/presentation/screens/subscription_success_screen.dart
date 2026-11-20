import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/audio/app_sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/subscription.dart';
import '../providers/subscription_providers.dart';

/// Shown once Paymob confirms a plan payment, or after an InstaPay upgrade
/// request is submitted for admin review ([pendingVerification]).
class SubscriptionSuccessScreen extends ConsumerStatefulWidget {
  const SubscriptionSuccessScreen({
    super.key,
    this.pendingVerification = false,
  });

  /// InstaPay path: receipt received, plan not active yet.
  final bool pendingVerification;

  static const gold = Color(0xFFFFD700);

  @override
  ConsumerState<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends ConsumerState<SubscriptionSuccessScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    AppSoundService.instance.playOrderSuccess();
  }

  /// Reads the new plan from `profiles` before going back, so the rest of
  /// the app (e.g. «العب واكسب») sees it straight away.
  Future<void> _continueShopping() async {
    setState(() => _leaving = true);
    try {
      await refreshSubscription(ref);
    } catch (error) {
      debugPrint('Refreshing the subscription failed: $error');
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final pending = widget.pendingVerification;
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final plan = subscription?.activePlan();
    final expiry = subscription?.expiry;
    final planName = switch (plan) {
      SubscriptionPlan.pro => l10n.paywallProTitle,
      SubscriptionPlan.prime => l10n.paywallPrimeTitle,
      _ => null,
    };

    return Scaffold(
      backgroundColor: palette.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: SubscriptionSuccessScreen.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pending
                      ? Icons.hourglass_top_rounded
                      : Icons.workspace_premium_rounded,
                  size: 72,
                  color: SubscriptionSuccessScreen.gold,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                pending
                    ? l10n.subscriptionPendingSuccessTitle
                    : l10n.subscriptionActivatedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: palette.onSurface,
                ),
              ),
              if (pending) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.subscriptionPendingSuccessBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: palette.muted),
                ),
              ] else if (planName != null && expiry != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.subscriptionActiveUntil(
                    planName,
                    DateFormat.yMMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(expiry.toLocal()),
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: palette.muted),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const Key('continue-shopping'),
                  onPressed: _leaving ? null : _continueShopping,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _leaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          l10n.subscriptionContinueShopping,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
