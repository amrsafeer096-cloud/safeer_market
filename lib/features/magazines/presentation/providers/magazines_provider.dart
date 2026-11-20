import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../data/repositories/supabase_magazines_repository.dart';
import '../../domain/entities/magazine.dart';
import '../../domain/repositories/magazines_repository.dart';

final magazinesRepositoryProvider = Provider<MagazinesRepository>((ref) {
  return SupabaseMagazinesRepository(ref.watch(supabaseClientProvider));
});

/// Magazines on offer today, for the customer-facing «المجلات» screen.
final magazinesProvider = FutureProvider<List<Magazine>>((ref) {
  return ref.watch(magazinesRepositoryProvider).fetchActiveMagazines();
});

/// Every magazine, for the admin dashboard.
final adminMagazinesProvider =
    FutureProvider.autoDispose<List<Magazine>>((ref) {
  return ref.watch(magazinesRepositoryProvider).fetchAllMagazines();
});
