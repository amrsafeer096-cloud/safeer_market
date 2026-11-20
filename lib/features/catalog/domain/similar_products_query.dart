import '../../home/domain/entities/product.dart';

/// What «منتجات مشابهة» matches on, as a record so provider families and
/// caches compare it by value rather than by [Product] instance.
typedef SimilarProductsQuery = ({
  String productId,
  String name,
  String? categoryId,
  String? category,
  String? subCategory,
});

extension SimilarProductsQueryOf on Product {
  SimilarProductsQuery get similarProductsQuery => (
        productId: id,
        name: name,
        categoryId: categoryId,
        category: category,
        subCategory: subCategory,
      );
}

/// The leading word of a product name, e.g. «جبنة» of «جبنة رومي وزن», used
/// to find products of the same brand or kind. Null when too short to mean
/// anything.
String? leadingWord(String name) {
  final word = name.trim().split(RegExp(r'\s+')).first.replaceAll(
      RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');
  return word.length < 2 ? null : word;
}

/// How many leading words [name] shares with [other].
int sharedLeadingWords(String name, String other) {
  final a = name.trim().split(RegExp(r'\s+'));
  final b = other.trim().split(RegExp(r'\s+'));
  var shared = 0;
  while (shared < a.length && shared < b.length && a[shared] == b[shared]) {
    shared++;
  }
  return shared;
}
