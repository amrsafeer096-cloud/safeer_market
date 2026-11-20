import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';

abstract final class CardValidators {
  static String digitsOf(String number) => number.replaceAll(' ', '');

  static String? number(String? value) {
    final digits = digitsOf(value ?? '');
    if (digits.isEmpty) return L10n.current.cardNumberRequired;
    if (digits.length < 13 || !_passesLuhn(digits)) {
      return L10n.current.cardNumberInvalid;
    }
    return null;
  }

  static String? expiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return L10n.current.cardExpiryRequired;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return L10n.current.cardExpiryInvalidMonth;
    final now = DateTime.now();
    if (DateTime(year, month + 1).isBefore(DateTime(now.year, now.month + 1))) {
      return L10n.current.cardExpired;
    }
    return null;
  }

  static String? cvv(String? value) =>
      (value ?? '').length < 3 ? L10n.current.cardCvvInvalid : null;

  static String? holder(String? value) => (value ?? '').trim().length < 3
      ? L10n.current.cardHolderNameRequired
      : null;

  static bool _passesLuhn(String digits) {
    var sum = 0;
    for (var i = 0; i < digits.length; i++) {
      var digit = int.parse(digits[digits.length - 1 - i]);
      if (i.isOdd) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
    }
    return sum % 10 == 0;
  }
}

/// Card numbers, dates and codes read left-to-right even in an RTL form.
class CardLtrField extends StatelessWidget {
  const CardLtrField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.formatters,
    required this.validator,
    this.obscure = false,
    this.focusNode,
    this.suffixIcon,
    this.autofillHints,
    this.keyboardType = TextInputType.number,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String> validator;
  final bool obscure;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      obscureText: obscure,
      autofillHints: autofillHints,
      inputFormatters: formatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintTextDirection: TextDirection.ltr,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
