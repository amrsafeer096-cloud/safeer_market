import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/sign_in_prompt.dart';
import '../../../checkout/domain/instapay_details.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/subscription.dart';
import '../providers/subscription_providers.dart';
import 'subscription_instapay_screen.dart';
import 'subscription_success_screen.dart';

/// Payment choices on the subscription paywall (no mobile wallet).
enum _SubscriptionPayChoice { card, instaPay }

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  /// How long a return from Paymob waits for the webhook to settle the
  /// payment before telling the customer it will activate later.
  static const confirmTimeout = Duration(seconds: 30);
  static const confirmPollInterval = Duration(seconds: 2);

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with WidgetsBindingObserver {
  /// The plan whose order is being created.
  PaidTier? _startingTier;

  /// The payment open in the browser, until its outcome is known.
  PaymobCheckout? _checkout;

  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back in the app without the deep link — e.g. the customer closed the
  /// browser tab. One quick look; a pending payment stays open for the link.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final checkout = _checkout;
    if (state != AppLifecycleState.resumed || checkout == null) return;
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted && !_verifying && identical(_checkout, checkout)) {
        _confirm(checkout.transactionId, poll: false);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// The raw failure, left up long enough to read or screenshot.
  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('payment-error'),
        content: Text('$error', textDirection: TextDirection.ltr),
        duration: const Duration(seconds: 15),
        showCloseIcon: true,
      ));
  }

  Future<void> _subscribe(PaidTier tier) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureSignedIn(
          context,
          ref,
          message: l10n.paywallSignInToSubscribe,
        ) ||
        !mounted) {
      return;
    }

    final choice = await _choosePaymentMethod();
    if (choice == null || !mounted) return;

    if (choice == _SubscriptionPayChoice.instaPay) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SubscriptionInstaPayScreen(tier: tier),
        ),
      );
      return;
    }

    setState(() => _startingTier = tier);
    try {
      final checkout = await ref.read(paymobServiceProvider).createCheckout(
            tier: tier,
            method: PaymobMethod.card,
          );
      _checkout = checkout;
      final paymentUrl = checkout.paymentUrl;
      if (paymentUrl == null) {
        if (mounted) _showMessage(l10n.paymentFailedMessage);
        return;
      }
      final opened = await ref.read(paymentPageProvider).open(paymentUrl);
      if (!opened && mounted) {
        _checkout = null;
        _showMessage(l10n.paymentPageOpenFailed);
      }
    } catch (error, stack) {
      debugPrint('Starting the payment failed: $error');
      debugPrintStack(stackTrace: stack);
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _startingTier = null);
    }
  }

  Future<_SubscriptionPayChoice?> _choosePaymentMethod() {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<_SubscriptionPayChoice>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.paymentChooseMethod,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const Key('payment-method-card'),
              leading: const Icon(Icons.credit_card_rounded),
              title: Text(l10n.paymentMethodCard),
              onTap: () =>
                  Navigator.pop(context, _SubscriptionPayChoice.card),
            ),
            ListTile(
              key: const Key('payment-method-instapay'),
              leading: Image.asset(
                InstaPayDetails.logoAsset,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              title: Text(l10n.paymentMethodInstaPayLabel),
              subtitle: Text(l10n.paymentMethodInstaPaySubtitle),
              onTap: () =>
                  Navigator.pop(context, _SubscriptionPayChoice.instaPay),
            ),
          ],
        ),
      ),
    );
  }

  void _onReturnLink(Uri link) {
    final transactionId =
        link.queryParameters['transaction_id'] ?? _checkout?.transactionId;
    if (transactionId == null) return;
    unawaited(ref.read(paymentPageProvider).close());
    _confirm(transactionId, poll: true);
  }

  /// Reads the payment's outcome, waiting up to [PaywallScreen.confirmTimeout]
  /// for the webhook when [poll] is set.
  Future<void> _confirm(String transactionId, {required bool poll}) async {
    if (_verifying) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _verifying = true);
    final service = ref.read(paymobServiceProvider);
    final deadline = DateTime.now().add(PaywallScreen.confirmTimeout);
    var status = PaymentStatus.pending;
    try {
      while (true) {
        status = await service.fetchPaymentStatus(transactionId);
        if (status != PaymentStatus.pending ||
            !poll ||
            !DateTime.now().isBefore(deadline)) {
          break;
        }
        await Future<void>.delayed(PaywallScreen.confirmPollInterval);
        if (!mounted) return;
      }
    } catch (error) {
      debugPrint('Checking payment $transactionId failed: $error');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
    if (!mounted) return;

    switch (status) {
      case PaymentStatus.success:
        _checkout = null;
        ref
          ..invalidate(subscriptionProvider)
          ..invalidate(userProfileProvider);
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const SubscriptionSuccessScreen(),
          ),
        );
      case PaymentStatus.failed:
        _checkout = null;
        _showMessage(l10n.paymentFailedMessage);
      case PaymentStatus.pending:
        if (poll) _showMessage(l10n.paymentStillProcessing);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(paymentReturnLinksProvider, (_, next) {
      if (next.valueOrNull case final link?) _onReturnLink(link);
    });
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: palette.card,
          appBar: AppBar(
            backgroundColor: palette.card,
            elevation: 0,
            iconTheme: IconThemeData(color: palette.onSurface),
            title: Text(
              l10n.paywallUpgradeAccount,
              style: TextStyle(
                  color: palette.onSurface, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paywallDiscoverSafeer,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.paywallChoosePlan,
                  style: TextStyle(fontSize: 14, color: palette.muted),
                ),
                const SizedBox(height: 24),

                // باقة سفير برو (الذهبية)
                _buildPlanCard(
                  context: context,
                  tier: PaidTier.vip,
                  title: l10n.paywallProTitle,
                  price: '180 ${l10n.currencySymbol}',
                  duration: l10n.paywallPerMonth,
                  color: const Color(0xFF1C1C1E), // أسود فخم
                  textColor: const Color(0xFFFFD700), // ذهبي
                  features: [
                    l10n.paywallProUnlimitedFreeDelivery,
                    l10n.paywallProExpressDelivery,
                    l10n.paywallProWholesalePrices,
                    l10n.paywallProNoMinimumOrder,
                    l10n.paywallProUnlimitedGiveaways,
                  ],
                  isBestSeller: true,
                ),
                const SizedBox(height: 16),

                // باقة سفير برايم (الفضية/الزرقاء)
                _buildPlanCard(
                  context: context,
                  tier: PaidTier.prime,
                  title: l10n.paywallPrimeTitle,
                  price: '90 ${l10n.currencySymbol}',
                  duration: l10n.paywallPerMonth,
                  color: palette.isDark
                      ? palette.surface
                      : const Color(0xFFF4F6F9),
                  textColor:
                      palette.isDark ? palette.accent : const Color(0xFF003366),
                  buttonColor: const Color(0xFF003366),
                  features: [
                    l10n.paywallPrimeFreeDeliveryFiveOrders,
                    l10n.paywallPrimeOffersPriority,
                    l10n.paywallPrimeWeeklyPlayAndWin,
                  ],
                ),
                const SizedBox(height: 16),

                // الباقة المجانية
                _buildPlanCard(
                  context: context,
                  title: l10n.paywallFreeTitle,
                  price: l10n.paywallFreePrice,
                  duration: '',
                  color: palette.card,
                  textColor: palette.onSurface,
                  borderColor:
                      palette.isDark ? palette.border : Colors.grey.shade300,
                  features: [
                    l10n.paywallFreeStandardDelivery,
                    l10n.paywallFreePublicAccess,
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_verifying)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.paymentVerifying),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// [tier] null is the free plan, which has no subscribe button.
  Widget _buildPlanCard({
    required BuildContext context,
    PaidTier? tier,
    required String title,
    required String price,
    required String duration,
    required Color color,
    required Color textColor,
    required List<String> features,
    Color? borderColor,
    Color? buttonColor,
    bool isBestSeller = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final foreground = isBestSeller ? Colors.black : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: isBestSeller && !palette.isDark
            ? [
                BoxShadow(
                    color: textColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
            : [],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBestSeller)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: textColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.paywallBestSeller,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: price,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: duration,
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: isBestSeller ? textColor : Colors.green,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                            color:
                                isBestSeller ? Colors.white : palette.onSurface,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          if (tier != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: Key('subscribe-${tier.value}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor ?? textColor,
                  foregroundColor: foreground,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _startingTier != null || _verifying
                    ? null
                    : () => _subscribe(tier),
                child: _startingTier == tier
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: buttonColor ?? textColor,
                        ),
                      )
                    : Text(l10n.paywallSubscribeNow,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
