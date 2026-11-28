/// Funnel modes for staff product search («تلقي الطلبات» / «تعديل الطلب»).
enum ProductSearchFilterMode {
  /// Only products with positive stock (default, current behavior).
  inStock,

  /// Every product, including zero / negative stock.
  allItems,

  /// Only products with an active `discount_price` offer.
  /// Kept for «تعديل الطلب» dropdown; تلقي الطلبات uses [offersOnly] instead.
  offers;

  String get label => switch (this) {
        inStock => 'المخزون الفعلي',
        allItems => 'كل الأصناف',
        offers => 'العروض',
      };

  bool get isDefault => this == inStock;

  /// Stock scope chips (excludes the legacy combined «العروض» mode).
  bool get isStockScope => this == inStock || this == allItems;
}

/// Normalize Arabic (and Latin) text for substring search: alef variants,
/// teh marbuta, alef maqsura, tatweel stripped; Latin lowercased.
String normalizeArabicSearch(String input) {
  final lower = input.trim().toLowerCase();
  if (lower.isEmpty) return lower;
  final out = StringBuffer();
  for (final unit in lower.runes) {
    final ch = String.fromCharCode(unit);
    if (ch == '\u0640') continue; // tatweel ـ
    out.write(switch (ch) {
      'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
      'ة' => 'ه',
      'ى' => 'ي',
      'ؤ' => 'و',
      'ئ' => 'ي',
      _ => ch,
    });
  }
  return out.toString();
}

/// True when [haystack] contains [needle] after [normalizeArabicSearch].
bool arabicSearchContains(String haystack, String needle) {
  final n = normalizeArabicSearch(needle);
  if (n.isEmpty) return true;
  return normalizeArabicSearch(haystack).contains(n);
}
