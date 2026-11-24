/// Egyptian mobile numbers as typed in the app (`01xxxxxxxxx`) and as Supabase
/// Auth stores them (E.164, `+201xxxxxxxxx`; `user.phone` drops the `+`).
abstract final class EgyptianPhone {
  static final pattern = RegExp(r'^01[0125]\d{8}$');

  static bool isValid(String local) => pattern.hasMatch(normalize(local));

  /// Digits-only local form when the value is (or can be) an Egyptian mobile.
  static String normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('201')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 13 && digits.startsWith('2001')) {
      return digits.substring(2);
    }
    if (digits.length == 11 && digits.startsWith('01')) {
      return digits;
    }
    return digits;
  }

  /// `01012345678` → `+201012345678`.
  static String toE164(String local) {
    final normalized = normalize(local);
    return '+20${normalized.substring(1)}';
  }

  /// `+201012345678` / `201012345678` → `01012345678`; other numbers are
  /// returned unchanged.
  static String toLocal(String international) {
    final digits = international.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('201')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 11 && digits.startsWith('01')) {
      return digits;
    }
    return international;
  }
}
