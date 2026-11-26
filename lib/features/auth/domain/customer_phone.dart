import 'egyptian_phone.dart';

/// Dial-code entry for the customer phone country selector.
class PhoneCountry {
  const PhoneCountry({
    required this.iso2,
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String iso2;
  final String name;

  /// Digits only, no `+` (e.g. `20`, `971`).
  final String dialCode;
  final String flag;

  String get dialLabel => '+$dialCode';

  String get menuLabel => '$flag  $dialLabel  $name';
}

/// Customer phones: Egypt (+20) mobiles/landlines + international numbers.
///
/// Storage:
/// - Egypt → local digits (`010…` / `02…`) for backward compatibility.
/// - Other countries → E.164 with `+` (`+97150…`).
abstract final class CustomerPhone {
  static const egypt = PhoneCountry(
    iso2: 'EG',
    name: 'مصر',
    dialCode: '20',
    flag: '🇪🇬',
  );

  static const countries = <PhoneCountry>[
    egypt,
    PhoneCountry(iso2: 'SA', name: 'السعودية', dialCode: '966', flag: '🇸🇦'),
    PhoneCountry(iso2: 'AE', name: 'الإمارات', dialCode: '971', flag: '🇦🇪'),
    PhoneCountry(iso2: 'KW', name: 'الكويت', dialCode: '965', flag: '🇰🇼'),
    PhoneCountry(iso2: 'QA', name: 'قطر', dialCode: '974', flag: '🇶🇦'),
    PhoneCountry(iso2: 'BH', name: 'البحرين', dialCode: '973', flag: '🇧🇭'),
    PhoneCountry(iso2: 'OM', name: 'عُمان', dialCode: '968', flag: '🇴🇲'),
    PhoneCountry(iso2: 'JO', name: 'الأردن', dialCode: '962', flag: '🇯🇴'),
    PhoneCountry(iso2: 'LB', name: 'لبنان', dialCode: '961', flag: '🇱🇧'),
    PhoneCountry(iso2: 'IQ', name: 'العراق', dialCode: '964', flag: '🇮🇶'),
    PhoneCountry(iso2: 'PS', name: 'فلسطين', dialCode: '970', flag: '🇵🇸'),
    PhoneCountry(iso2: 'SY', name: 'سوريا', dialCode: '963', flag: '🇸🇾'),
    PhoneCountry(iso2: 'YE', name: 'اليمن', dialCode: '967', flag: '🇾🇪'),
    PhoneCountry(iso2: 'LY', name: 'ليبيا', dialCode: '218', flag: '🇱🇾'),
    PhoneCountry(iso2: 'SD', name: 'السودان', dialCode: '249', flag: '🇸🇩'),
    PhoneCountry(iso2: 'MA', name: 'المغرب', dialCode: '212', flag: '🇲🇦'),
    PhoneCountry(iso2: 'DZ', name: 'الجزائر', dialCode: '213', flag: '🇩🇿'),
    PhoneCountry(iso2: 'TN', name: 'تونس', dialCode: '216', flag: '🇹🇳'),
    PhoneCountry(iso2: 'MY', name: 'ماليزيا', dialCode: '60', flag: '🇲🇾'),
    PhoneCountry(iso2: 'TR', name: 'تركيا', dialCode: '90', flag: '🇹🇷'),
    PhoneCountry(iso2: 'GB', name: 'المملكة المتحدة', dialCode: '44', flag: '🇬🇧'),
    PhoneCountry(iso2: 'DE', name: 'ألمانيا', dialCode: '49', flag: '🇩🇪'),
    PhoneCountry(iso2: 'FR', name: 'فرنسا', dialCode: '33', flag: '🇫🇷'),
    PhoneCountry(iso2: 'IT', name: 'إيطاليا', dialCode: '39', flag: '🇮🇹'),
    PhoneCountry(iso2: 'US', name: 'الولايات المتحدة', dialCode: '1', flag: '🇺🇸'),
    PhoneCountry(iso2: 'CA', name: 'كندا', dialCode: '1', flag: '🇨🇦'),
    PhoneCountry(iso2: 'IN', name: 'الهند', dialCode: '91', flag: '🇮🇳'),
    PhoneCountry(iso2: 'PK', name: 'باكستان', dialCode: '92', flag: '🇵🇰'),
    PhoneCountry(iso2: 'CN', name: 'الصين', dialCode: '86', flag: '🇨🇳'),
    PhoneCountry(iso2: 'AU', name: 'أستراليا', dialCode: '61', flag: '🇦🇺'),
  ];

  /// Dial codes longest-first for prefix detection (`971` before `97`).
  static final List<PhoneCountry> _byDialDesc = () {
    final list = [...countries];
    list.sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    return list;
  }();

  static PhoneCountry countryForDial(String dialCode) {
    final d = dialCode.replaceAll('+', '').trim();
    for (final c in countries) {
      if (c.dialCode == d) return c;
    }
    return egypt;
  }

  /// Digits only (Indic → Western); keeps no `+`.
  static String digitsOnly(String raw) => EgyptianPhone.normalize(raw);

  /// Parsed view of a stored or typed phone.
  static ParsedCustomerPhone parse(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) {
      return const ParsedCustomerPhone(
        country: egypt,
        national: '',
        storage: '',
      );
    }

    final hasPlus = trimmed.startsWith('+');
    final has00 = trimmed.startsWith('00');
    var digits = digitsOnly(trimmed);

    if (hasPlus || has00 || (digits.length >= 11 && !digits.startsWith('0'))) {
      // International / E.164 style.
      if (digits.startsWith('00')) digits = digits.substring(2);
      PhoneCountry? matched;
      String national = digits;
      for (final c in _byDialDesc) {
        if (digits.startsWith(c.dialCode) &&
            digits.length > c.dialCode.length) {
          matched = c;
          national = digits.substring(c.dialCode.length);
          break;
        }
      }
      matched ??= egypt;
      // Egypt E.164 → restore leading 0 for local display/storage.
      if (matched.dialCode == '20' &&
          national.isNotEmpty &&
          !national.startsWith('0')) {
        national = '0$national';
      }
      return ParsedCustomerPhone(
        country: matched,
        national: national,
        storage: toStorage(matched, national),
      );
    }

    // Local Egyptian (or bare national under Egypt default).
    final local = EgyptianPhone.normalize(trimmed);
    return ParsedCustomerPhone(
      country: egypt,
      national: local,
      storage: local,
    );
  }

  /// While typing: detect `+` / `00` / Egyptian local and return updated
  /// country + national input (prefix stripped).
  static ({PhoneCountry country, String national}) detectWhileTyping({
    required PhoneCountry current,
    required String input,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return (country: current, national: '');
    }

    if (trimmed.startsWith('+') || trimmed.startsWith('00')) {
      final parsed = parse(trimmed);
      return (country: parsed.country, national: parsed.national);
    }

    final digits = digitsOnly(trimmed);
    // Egyptian mobile / landline → force +20.
    if (EgyptianPhone.isValidCustomerPhone(digits) ||
        digits.startsWith('01') ||
        digits.startsWith('02') ||
        digits.startsWith('03')) {
      return (country: egypt, national: digits);
    }

    return (country: current, national: trimmed.replaceAll(RegExp(r'[^\d+]'), ''));
  }

  static String toStorage(PhoneCountry country, String nationalRaw) {
    var national = digitsOnly(nationalRaw);
    if (national.isEmpty) return '';
    if (country.dialCode == '20') {
      // Keep Egyptian local form.
      if (national.startsWith('20') && national.length >= 11) {
        national = '0${national.substring(2)}';
      }
      return national;
    }
    // Drop a single leading 0 on national part for E.164.
    if (national.startsWith('0')) national = national.substring(1);
    return '+${country.dialCode}$national';
  }

  /// Comparable key for dedupe / search (digits with country, no +).
  static String compareKey(String? raw) {
    final p = parse(raw);
    if (p.storage.isEmpty) return '';
    if (p.country.dialCode == '20') {
      final n = p.national.startsWith('0') ? p.national.substring(1) : p.national;
      return '20$n';
    }
    final n =
        p.national.startsWith('0') ? p.national.substring(1) : p.national;
    return '${p.country.dialCode}$n';
  }

  static bool isValid({
    required PhoneCountry country,
    required String nationalRaw,
  }) {
    final national = digitsOnly(nationalRaw);
    if (national.isEmpty) return false;
    if (country.dialCode == '20') {
      return EgyptianPhone.isValidCustomerPhone(national);
    }
    var n = national.startsWith('0') ? national.substring(1) : national;
    // ITU E.164 national part roughly 4–14; full number 7–15 after CC.
    final fullLen = country.dialCode.length + n.length;
    return n.length >= 4 && n.length <= 14 && fullLen >= 7 && fullLen <= 15;
  }

  static bool isValidOrEmpty({
    required PhoneCountry country,
    required String nationalRaw,
  }) =>
      nationalRaw.trim().isEmpty ||
      isValid(country: country, nationalRaw: nationalRaw);

  /// Valid stored value (Egypt local or +E.164).
  static bool isValidStored(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final p = parse(raw);
    return isValid(country: p.country, nationalRaw: p.national);
  }

  static bool isValidStoredOrEmpty(String? raw) =>
      raw == null || raw.trim().isEmpty || isValidStored(raw);

  /// Unique non-empty storage values; duplicates by [compareKey] dropped.
  static List<String> uniqueStorage(Iterable<String?> phones) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in phones) {
      final p = parse(raw);
      if (p.storage.isEmpty) continue;
      final key = compareKey(p.storage);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(p.storage);
    }
    return out;
  }

  static String formatPhones(
    Iterable<String?> phones, {
    String separator = ' / ',
    String empty = '—',
  }) {
    final unique = uniqueStorage(phones);
    if (unique.isEmpty) return empty;
    return unique.join(separator);
  }

  /// Pad/truncate to exactly 5 slots (nulls for empties) after dedupe.
  static List<String?> fiveSlots(Iterable<String?> phones) {
    final unique = uniqueStorage(phones);
    return [
      for (var i = 0; i < 5; i++) i < unique.length ? unique[i] : null,
    ];
  }
}

class ParsedCustomerPhone {
  const ParsedCustomerPhone({
    required this.country,
    required this.national,
    required this.storage,
  });

  final PhoneCountry country;
  final String national;
  final String storage;
}
