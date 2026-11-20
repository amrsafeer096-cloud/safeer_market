/// Card details read by the camera, normalized for the payment form.
/// Optional fields the scanner couldn't read are null so they don't
/// overwrite what the user typed.
class ScannedCard {
  const ScannedCard({required this.number, this.expiry, this.holderName});

  /// Digits only.
  final String number;

  /// `MM/YY`.
  final String? expiry;

  /// Upper-case, as printed on the card.
  final String? holderName;

  /// Null when the scan produced no usable card number.
  static ScannedCard? fromRaw({
    required String number,
    String? expiry,
    String? holderName,
  }) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) return null;

    final name = (holderName ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    return ScannedCard(
      number: digits,
      expiry: _normalizeExpiry(expiry),
      holderName: name.isEmpty ? null : name.toUpperCase(),
    );
  }

  /// Accepts `M/YY`, `MM/YY`, `MM/YYYY` and `-` separators.
  static String? _normalizeExpiry(String? raw) {
    final match =
        RegExp(r'(\d{1,2})\s*[/\-]\s*(\d{2}|\d{4})\b').firstMatch(raw ?? '');
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return null;
    final year = match.group(2)!;
    final yy = year.substring(year.length - 2);
    return '${month.toString().padLeft(2, '0')}/$yy';
  }
}
