import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:safeer_market/features/catalog/data/repositories/supabase_product_image_repository.dart';
import 'package:safeer_market/features/home/domain/entities/product.dart';
import 'package:safeer_market/features/home/presentation/providers/product_visibility_provider.dart';

const _base = 'https://example.supabase.co';
const _product =
    Product(id: 'p1', name: 'زيت', price: 50, barcode: '6221234567890');

/// Supabase over a fake HTTP server: Storage accepts the upload with
/// [storageStatus]; the products UPDATE answers with [updatedRows].
({SupabaseProductImageRepository repository, List<http.Request> requests})
    _repository({
  int storageStatus = 200,
  List<Map<String, Object?>> updatedRows = const [],
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    if (request.url.path.startsWith('/storage/v1/object/')) {
      return storageStatus == 200
          ? http.Response(
              jsonEncode({'Key': 'product_images/x.jpg', 'Id': '1'}),
              200,
              request: request,
            )
          : http.Response(
              jsonEncode({
                'statusCode': '$storageStatus',
                'error': 'Unauthorized',
                'message': 'new row violates row-level security policy',
              }),
              storageStatus,
              request: request,
            );
    }
    if (request.url.path == '/rest/v1/products') {
      return http.Response(
        jsonEncode(updatedRows),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    }
    return http.Response('not found', 404, request: request);
  });
  return (
    repository: SupabaseProductImageRepository(
      SupabaseClient(_base, 'anon-key', httpClient: client),
    ),
    requests: requests,
  );
}

Future<String> _replace(SupabaseProductImageRepository repository) =>
    repository.replaceImage(
      product: _product,
      bytes: Uint8List.fromList([1, 2, 3]),
      fileExtension: 'JPEG',
    );

void main() {
  test('uploads to product_images and saves a cache-busted image_url',
      () async {
    final (:repository, :requests) = _repository(
      updatedRows: [
        {'id': 'p1', 'image_url': 'saved'},
      ],
    );

    final url = await _replace(repository);

    expect(
      url,
      startsWith(
        '$_base/storage/v1/object/public/product_images/6221234567890.jpg?t=',
      ),
    );
    final upload = requests.first;
    expect(
        upload.url.path, '/storage/v1/object/product_images/6221234567890.jpg');
    expect(upload.headers['x-upsert'], 'true');

    final update = requests.last;
    expect(update.method, 'PATCH');
    expect(update.url.queryParameters['id'], 'eq.p1');
    expect(update.url.queryParameters['select'], 'id,image_url',
        reason: 'the updated row is read back to detect RLS');
    expect(jsonDecode(update.body), {'image_url': url});
  });

  test('an UPDATE that RLS silently blocks is reported, not "successful"',
      () async {
    final (:repository, requests: _) = _repository(updatedRows: const []);

    await expectLater(
      _replace(repository),
      throwsA(
        isA<ProductImageFailure>().having(
          (failure) => failure.message,
          'message',
          contains('صلاحية تعديل المنتجات مرفوضة'),
        ),
      ),
    );
  });

  test('a refused Storage upload stops before touching the product', () async {
    final (:repository, :requests) = _repository(storageStatus: 403);

    await expectLater(
        _replace(repository), throwsA(isA<ProductImageFailure>()));
    expect(requests.where((r) => r.url.path == '/rest/v1/products'), isEmpty);
  });

  test('a new photo takes the product off the failed-image list', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final broken = container.read(brokenImageProductsProvider.notifier)
      ..report(_product);
    await Future<void>.delayed(BrokenImageProducts.flushDelay);
    expect(broken.state.keys, ['p1']);

    broken.forget('p1');
    expect(broken.state, isEmpty);
  });

  test('after a new photo, old copies of the product stay off the lists',
      () async {
    const oldLink = '$_base/storage/v1/object/public/product_images/gone.jpg';
    const newLink =
        '$_base/storage/v1/object/public/product_images/6221234567890.jpg?t=1';
    const stale = Product(id: 'p1', name: 'زيت', price: 50, imageUrl: oldLink);
    const fresh = Product(id: 'p1', name: 'زيت', price: 50, imageUrl: newLink);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final broken = container.read(brokenImageProductsProvider.notifier)
      ..report(stale);
    await Future<void>.delayed(BrokenImageProducts.flushDelay);

    container
        .read(replacedProductImagesProvider.notifier)
        .record('p1', newLink);
    broken
      ..forget('p1')
      // A card loaded before the upload retries the dead link.
      ..report(stale);
    await Future<void>.delayed(BrokenImageProducts.flushDelay);
    expect(broken.state, isEmpty);

    expect(
      productsNeedingImage(
        stored: const [stale, _product],
        failedToLoad: const [],
        replaced: container.read(replacedProductImagesProvider),
      ),
      isEmpty,
      reason: 'the list fetched before the upload no longer counts it',
    );

    // The new photo itself failing is a real failure.
    broken.report(fresh);
    await Future<void>.delayed(BrokenImageProducts.flushDelay);
    expect(broken.state.keys, ['p1']);
  });
}
