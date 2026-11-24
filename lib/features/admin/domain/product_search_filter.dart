/// Funnel modes for staff product search («تلقي الطلبات» / «تعديل الطلب»).
enum ProductSearchFilterMode {
  /// Only products with positive stock (default, current behavior).
  inStock,

  /// Every product, including zero / negative stock.
  allItems,

  /// Only products with an active `discount_price` offer.
  offers;

  String get label => switch (this) {
        inStock => 'المخزون الفعلي',
        allItems => 'كل الأصناف',
        offers => 'العروض',
      };

  bool get isDefault => this == inStock;
}
