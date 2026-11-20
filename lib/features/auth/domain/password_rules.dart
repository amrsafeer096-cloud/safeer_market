/// Live password strength rules for registration.
abstract final class PasswordRules {
  static final upper = RegExp(r'[A-Z]');
  static final lower = RegExp(r'[a-z]');
  static final digit = RegExp(r'[0-9]');

  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasUppercase(String value) => upper.hasMatch(value);
  static bool hasLowercase(String value) => lower.hasMatch(value);
  static bool hasDigit(String value) => digit.hasMatch(value);

  static bool isStrong(String value) =>
      hasMinLength(value) &&
      hasUppercase(value) &&
      hasLowercase(value) &&
      hasDigit(value);
}
