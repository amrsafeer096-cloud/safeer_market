import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

abstract final class AppCurrency {
  static NumberFormat get format => NumberFormat.currency(
        locale: L10n.localeName,
        symbol: L10n.current.currencySymbol,
        decimalDigits: 2,
      );

  static String of(num value, {String? unit}) {
    final price = format.format(value);
    if (unit == null || unit.isEmpty) return price;
    return '$price / $unit';
  }
}
