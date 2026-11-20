import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/home_banner.dart';
import '../../domain/repositories/home_banners_repository.dart';
import '../models/home_banner_model.dart';

class SupabaseHomeBannersRepository implements HomeBannersRepository {
  SupabaseHomeBannersRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'home_banners';
  static const _bucket = 'banners';

  @override
  Future<List<HomeBanner>> fetchActiveBanners() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('created_at');
      return rows
          .map(HomeBannerModel.fromJson)
          .where((banner) => banner.imageUrl.isNotEmpty)
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Could not load home banners; showing promos',
        name: 'home_banners',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  @override
  Future<HomeBanner> createBanner({
    required String title,
    required String brandQuery,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    final ext = _extension(imageFileName);
    final path = 'home/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = _client.storage.from(_bucket);
    await storage.uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        },
      ),
    );

    final last = await _client
        .from(_table)
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextOrder = ((last?['sort_order'] as num?)?.toInt() ?? -1) + 1;

    final row = await _client
        .from(_table)
        .insert(
          HomeBannerModel.toInsertJson(
            title: title,
            imageUrl: storage.getPublicUrl(path),
            brandQuery: brandQuery,
            sortOrder: nextOrder,
          ),
        )
        .select()
        .single();
    return HomeBannerModel.fromJson(row);
  }

  @override
  Future<void> deleteBanner(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  static String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'jpg';
    return switch (fileName.substring(dot + 1).toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
  }
}
