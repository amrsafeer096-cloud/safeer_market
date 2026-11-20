import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../data/repositories/supabase_home_banners_repository.dart';
import '../../domain/entities/home_banner.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/home_banners_repository.dart';

final homeBannersRepositoryProvider = Provider<HomeBannersRepository>((ref) {
  return SupabaseHomeBannersRepository(ref.watch(supabaseClientProvider));
});

/// The company ads on the home deck, in order. Empty (never an error) until
/// an admin uploads one, when the deck shows the built-in promos instead.
final homeBannersProvider = FutureProvider<List<HomeBanner>>((ref) {
  return ref.watch(homeBannersRepositoryProvider).fetchActiveBanners();
});

/// In-stock products of a company/brand: those whose name contains the
/// banner's keyword. Lists still apply the customer photo filter.
final brandProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, brandQuery) async {
  final products = await ref.watch(productSearchProvider(brandQuery).future);
  return products.available;
});
