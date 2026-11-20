import '../../domain/entities/home_banner.dart';

/// Maps a `home_banners` row to and from [HomeBanner].
class HomeBannerModel {
  const HomeBannerModel._();

  static HomeBanner fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id'].toString(),
      title: (json['title'] as String?)?.trim() ?? '',
      imageUrl: (json['image_url'] as String?)?.trim() ?? '',
      brandQuery: (json['brand_query'] as String?)?.trim() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  /// The columns of a new row; the database fills `id` and `created_at`.
  static Map<String, dynamic> toInsertJson({
    required String title,
    required String imageUrl,
    required String brandQuery,
    required int sortOrder,
  }) {
    return {
      'title': title.trim(),
      'image_url': imageUrl,
      'brand_query': brandQuery.trim(),
      'sort_order': sortOrder,
      'is_active': true,
    };
  }
}
