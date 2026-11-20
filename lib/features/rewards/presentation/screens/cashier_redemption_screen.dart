import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/loyalty_redemption.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../providers/rewards_providers.dart';

/// What the cashier shows the POS and confirms: the customer, the points
/// that will go, and a SAFEER-NNN barcode for the discount. Pops with the
/// [LoyaltyRedemption] once confirmed.
class CashierRedemptionScreen extends ConsumerStatefulWidget {
  const CashierRedemptionScreen({
    super.key,
    required this.customer,
    required this.quote,
  });

  final LoyaltyCustomer customer;
  final RedemptionQuote quote;

  @override
  ConsumerState<CashierRedemptionScreen> createState() =>
      _CashierRedemptionScreenState();
}

class _CashierRedemptionScreenState
    extends ConsumerState<CashierRedemptionScreen> {
  bool _confirming = false;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final redemption =
          await ref.read(loyaltyRedemptionRepositoryProvider).redeem(
                userId: widget.customer.userId,
                discountEgp: widget.quote.discountEgp,
              );
      if (mounted) Navigator.of(context).pop(redemption);
    } catch (error) {
      if (!mounted) return;
      setState(() => _confirming = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(
            error is LoyaltyFailure
                ? error.message
                : l10n.redeemFailed('$error'),
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final customer = widget.customer;
    final quote = widget.quote;

    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(title: Text(l10n.cashierRedeemTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.cashierCustomer,
                        style: TextStyle(color: palette.muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      customer.fullName ?? customer.phone ?? customer.userId,
                      key: const Key('cashier-customer'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    if (customer.fullName != null || customer.phone != null)
                      Text(
                        customer.userId,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: palette.muted, fontSize: 11),
                      ),
                    const Divider(height: 24),
                    _Row(
                      label: l10n.cashierCurrentBalance,
                      value: l10n.rewardsPointsCount(quote.points),
                    ),
                    _Row(
                      label: l10n.cashierPointsToDeduct,
                      value: l10n.rewardsPointsCount(quote.pointsToDeduct),
                      valueKey: const Key('cashier-points-to-deduct'),
                      strong: true,
                    ),
                    _Row(
                      label: l10n.cashierDiscount,
                      value: AppCurrency.of(quote.discountEgp),
                      strong: true,
                    ),
                    _Row(
                      label: l10n.cashierRemainingPoints,
                      value: l10n.rewardsPointsCount(quote.remainingPoints),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pure white with a wide quiet zone in every theme: POS laser
            // scanners read it straight off the screen.
            Container(
              key: const Key('cashier-barcode'),
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: quote.barcodeData,
                height: 150,
                color: Colors.black,
                backgroundColor: Colors.white,
                drawText: true,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.cashierBarcodeHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton(
                key: const Key('confirm-points-deduction'),
                onPressed: _confirming ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _confirming
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.confirmPointsDeduction,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueKey,
    this.strong = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontSize: strong ? 17 : 15,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
