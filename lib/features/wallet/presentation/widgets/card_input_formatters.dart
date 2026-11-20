import 'package:flutter/services.dart';

/// Groups digits as `1234 5678 9012 3456`.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  static const maxDigits = 19;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Formats expiry input as `MM/YY`.
class ExpiryDateFormatter extends TextInputFormatter {
  const ExpiryDateFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final deleting = newValue.text.length < oldValue.text.length;
    final text = switch (digits.length) {
      0 => '',
      1 || 2 when deleting => digits,
      1 => digits,
      2 => '$digits/',
      _ => '${digits.substring(0, 2)}/${digits.substring(2)}',
    };
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
