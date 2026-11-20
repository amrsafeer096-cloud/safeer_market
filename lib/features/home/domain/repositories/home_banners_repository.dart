import 'dart:typed_data';

import '../entities/home_banner.dart';

abstract class HomeBannersRepository {
  /// Active banners in display order. Never throws: a missing table or a
  /// network error reads as no banners, so the deck falls back to promos.
  Future<List<HomeBanner>> fetchActiveBanners();

  /// Uploads the image, then inserts the row at the end of the deck.
  Future<HomeBanner> createBanner({
    required String title,
    required String brandQuery,
    required Uint8List imageBytes,
    required String imageFileName,
  });

  Future<void> deleteBanner(String id);
}
