import '../../../core/l10n/l10n.dart';

enum PaymentMethod {
  cashOnDelivery('cash_on_delivery'),
  card('card'),
  instaPay('instapay');

  const PaymentMethod(this.value);

  /// Stored in `orders.payment_method`.
  final String value;

  String get label => labelOf(L10n.current);

  String labelOf(AppLocalizations l10n) => switch (this) {
        PaymentMethod.cashOnDelivery => l10n.paymentMethodCashLabel,
        PaymentMethod.card => l10n.paymentMethodCardLabel,
        PaymentMethod.instaPay => l10n.paymentMethodInstaPayLabel,
      };

  String? subtitleOf(AppLocalizations l10n) => switch (this) {
        PaymentMethod.instaPay => l10n.paymentMethodInstaPaySubtitle,
        _ => null,
      };
}
