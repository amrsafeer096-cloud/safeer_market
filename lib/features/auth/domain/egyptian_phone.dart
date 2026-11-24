/// Egyptian mobile numbers as typed in the app (`01xxxxxxxxx`) and as Supabase
/// Auth stores them (E.164, `+201xxxxxxxxx`; `user.phone` drops the `+`).
abstract final class EgyptianPhone {
  static final pattern = RegExp(r'^01[0125]\d{8}$');

  /// Arabic-Indic (`٠-٩`) and Eastern Arabic-Indic (`۰-۹`) → Western `0-9`.
  static const _indicToWestern = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  static bool isValid(String local) => pattern.hasMatch(normalize(local));

  /// Western digits only: map Indic numerals, strip spaces/dashes/bidi marks.
  static String normalize(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      final mapped = _indicToWestern[ch];
      if (mapped != null) {
        buffer.write(mapped);
        continue;
      }
      // Keep ASCII digits only (drops spaces, dashes, LRM/RLM, etc.).
      if (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) {
        buffer.write(ch);
      }
    }
    final digits = buffer.toString();
    if (digits.length == 12 && digits.startsWith('201')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 13 && digits.startsWith('2001')) {
      return digits.substring(2);
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
    final digits = normalize(international);
    if (digits.length == 11 && digits.startsWith('01')) {
      return digits;
    }
    if (digits.length == 12 && digits.startsWith('201')) {
      return '0${digits.substring(2)}';
    }
    return international;
  }
}
