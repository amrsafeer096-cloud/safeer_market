import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../home/domain/entities/product.dart';

/// Replaces a product's photo: uploads it to the `product_images` bucket and
/// points `products.image_url` at it.
class SupabaseProductImageRepository {
  const SupabaseProductImageRepository(this._client);

  static const bucket = 'product_images';

  final SupabaseClient _client;

  /// Returns the saved `image_url`, cache-busted so no stale or failed copy
  /// of an earlier photo with the same file name is shown.
  Future<String> replaceImage({
    required Product product,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = switch (fileExtension.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    final barcode = product.barcode?.trim();
    final fileName =
        '${barcode == null || barcode.isEmpty ? product.id : barcode}.$ext';
    final storage = _client.storage.from(bucket);

    try {
      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext',
        ),
      );
    } on StorageException catch (error) {
      debugPrint('Product image upload to $bucket/$fileName failed: '
          '${error.statusCode} ${error.message}');
      throw ProductImageFailure(
        L10n.current.productImageUploadFailed(error.message),
      );
    }

    final imageUrl = '${storage.getPublicUrl(fileName)}'
        '?t=${DateTime.now().millisecondsSinceEpoch}';

    final List<Map<String, dynamic>> updated;
    try {
      updated = await _client
          .from('products')
          .update({'image_url': imageUrl})
          .eq('id', product.id)
          .select('id, image_url');
    } on PostgrestException catch (error) {
      debugPrint('Saving image_url for product ${product.id} failed: '
          '${error.code} ${error.message}');
      throw ProductImageFailure(
        L10n.current.productImageUploadFailed(error.message),
      );
    }

    // RLS doesn't raise on UPDATE: a blocked one just matches no rows.
    if (updated.isEmpty) {
      debugPrint(
        'Product image: products.image_url was NOT updated for ${product.id} '
        '(0 rows). RLS is blocking UPDATE on public.products for this user. '
        'Run supabase/migrations/20261105050000_admin_product_images.sql in '
        'the Supabase SQL Editor and make sure profiles.role = \'admin\'.',
      );
      throw ProductImageFailure(L10n.current.productImageSaveBlocked);
    }
    return imageUrl;
  }
}

class ProductImageFailure implements Exception {
  const ProductImageFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
