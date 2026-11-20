/// Egyptian mobile numbers as typed in the app (`01xxxxxxxxx`) and as Supabase
/// Auth stores them (E.164, `+201xxxxxxxxx`; `user.phone` drops the `+`).
abstract final class EgyptianPhone {
  static final pattern = RegExp(r'^01[0125]\d{8}$');

  static bool isValid(String local) => pattern.hasMatch(local);

  /// `01012345678` → `+201012345678`.
  static String toE164(String local) => '+20${local.substring(1)}';

  /// `+201012345678` / `201012345678` → `01012345678`; other numbers are
  /// returned unchanged.
  static String toLocal(String international) {
    final digits = international.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('201')) {
      return '0${digits.substring(2)}';
    }
    return international;
  }
}
