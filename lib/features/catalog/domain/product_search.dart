import '../../home/domain/entities/product.dart';

abstract final class ProductSearch {
  static String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), '');
  }

  static bool matchesBarcode(Product product, String query) {
    final barcode = product.barcode;
    final needle = normalize(query);
    return barcode != null && needle.isNotEmpty && normalize(barcode) == needle;
  }

  static bool matches(Product product, String query) {
    final needle = normalize(query);
    if (needle.isEmpty) return false;

    if (matchesBarcode(product, needle)) return true;

    final productName = normalize(product.name);

    // البحث كجملة متصلة لمنع اختفاء الصنف أثناء الكتابة السريعة
    if (productName.contains(needle)) {
      return true;
    }

    // تقسيم الكلمات للبحث المرن بأكثر من مقطع
    final searchParts =
        needle.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (searchParts.isEmpty) return false;

    // التأكد من أن كل مقطع جزئي مكتوب موجود في اسم المنتج
    for (final part in searchParts) {
      if (!productName.contains(part)) {
        return false;
      }
    }

    return true;
  }

  static List<Product> filter(Iterable<Product> products, String query) {
    final byBarcode = <String, Product>{};
    final byName = <String, Product>{};
    for (final product in products) {
      if (matchesBarcode(product, query)) {
        byBarcode[product.id] = product;
      } else if (matches(product, query)) {
        byName[product.id] = product;
      }
    }
    // إرجاع القائمة بالشكل السليم 100%
    return [...byBarcode.values, ...byName.values];
  }
}
