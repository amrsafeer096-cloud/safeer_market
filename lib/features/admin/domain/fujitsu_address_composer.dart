/// TrustyDelivery / Fujitsu POS full-address formula used in admin customer
/// registration and add/edit address dialogs.
String composeFujitsuAddress({
  String? building,
  String? street,
  String? landmark,
  String? floor,
  String? apartment,
  String? zone,
  String? city,
  String? governorate,
}) {
  String? clean(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  String? streetPart(String? raw) {
    final t = clean(raw);
    if (t == null) return null;
    // Avoid duplicating «ش » / «ش.» if the user already typed it.
    if (t == 'ش' || RegExp(r'^ش[\s.]').hasMatch(t)) return t;
    return 'ش $t';
  }

  String? landmarkPart(String? raw) {
    final t = clean(raw);
    if (t == null) return null;
    if (t.startsWith('ع.م ') || t.startsWith('ع.م')) return t;
    return 'ع.م $t';
  }

  final parts = <String>[
    if (clean(building) case final b?) b,
    if (streetPart(street) case final s?) s,
    if (landmarkPart(landmark) case final l?) l,
    if (clean(floor) case final f?) 'الدور $f',
    if (clean(apartment) case final a?) 'شقة $a',
    if (clean(zone) case final z?) z,
    if (clean(city) case final c?) c,
    if (clean(governorate) case final g?) g,
  ];
  return parts.join(' - ');
}
