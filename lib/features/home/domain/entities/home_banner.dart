/// A company/brand ad on the home deck. Tapping it opens every product whose
/// name contains [brandQuery].
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.brandQuery,
    this.sortOrder = 0,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String title;
  final String imageUrl;

  /// Product-name keyword, e.g. «جهينة»; empty when the banner opens nothing.
  final String brandQuery;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;

  bool get opensProducts => brandQuery.trim().isNotEmpty;
}
