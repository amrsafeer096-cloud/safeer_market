import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_currency.dart';
import '../../domain/loyalty_redemption.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../providers/rewards_providers.dart';
import 'cashier_redemption_screen.dart';

/// «مسح كود العميل»: the cashier scans a customer's QR code, sees what the
/// balance is worth, and redeems it. Stays open for the next customer.
class CashierScanScreen extends ConsumerStatefulWidget {
  const CashierScanScreen({super.key});

  @override
  ConsumerState<CashierScanScreen> createState() => _CashierScanScreenState();
}

class _CashierScanScreenState extends ConsumerState<CashierScanScreen> {
  /// Set while a scanned code is being handled, so the camera's repeated
  /// reads of the same code are ignored.
  bool _busy = false;

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: success ? AppColors.success : AppColors.secondary,
        content: Text(message),
      ));
  }

  Future<void> _onScan(String raw) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final userId = CustomerLoyaltyCode.decode(raw);
    if (userId == null) {
      _showMessage(l10n.scanInvalidCode);
      return;
    }

    setState(() => _busy = true);
    try {
      final customer =
          await ref.read(loyaltyRedemptionRepositoryProvider).fetchCustomer(
                userId,
              );
      if (!mounted) return;
      final quote = RedemptionQuote.forPoints(customer.points);
      if (!quote.canRedeem) {
        _showMessage(l10n.redeemInsufficientPoints);
        return;
      }
      final redemption = await Navigator.of(context).push<LoyaltyRedemption>(
        MaterialPageRoute(
          builder: (_) =>
              CashierRedemptionScreen(customer: customer, quote: quote),
        ),
      );
      if (redemption != null && mounted) {
        _showMessage(
          l10n.cashierRedeemDone(
            '${redemption.pointsRedeemed}',
            AppCurrency.of(redemption.discountEgp),
          ),
          success: true,
        );
      }
    } on LoyaltyFailure catch (failure) {
      if (mounted) _showMessage(failure.message);
    } catch (error) {
      if (mounted) _showMessage(l10n.redeemFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scanner = ref.watch(customerCodeScannerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l10n.scanCustomerCode)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          scanner(_onScan),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 24,
            end: 24,
            bottom: 40,
            child: IgnorePointer(
              child: Text(
                l10n.scanCustomerHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_busy)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
