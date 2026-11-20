import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
});

/// The signed-in user's role, or null for guests. Falls back to customer when
/// it can't be read, so a network error never locks anyone out of shopping.
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return null;
  try {
    return await ref.watch(profileRepositoryProvider).fetchRole(userId);
  } catch (_) {
    return UserRole.customer;
  }
});

/// The signed-in user's profile, or null for guests.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  UserProfile? stored;
  try {
    stored = await ref.watch(profileRepositoryProvider).fetchProfile(user.id);
  } catch (_) {
    // The sign-up metadata below is enough to greet the user by name.
  }

  return UserProfile(
    id: user.id,
    fullName: stored?.fullName ?? user.fullName,
    phone: stored?.phone ?? user.phone,
    email: user.email,
    avatarUrl: stored?.avatarUrl ?? user.avatarUrl,
  );
});

/// On every sign-in (Google, phone, email, or a restored session), saves what
/// the sign-in provider knows — name, photo, verified phone — into the user's
/// `profiles` row so orders have their details. Watch it once at the app root.
final profileSyncProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  final user = ref.read(currentUserProvider);
  if (userId == null || user == null) return;

  var disposed = false;
  ref.onDispose(() => disposed = true);

  unawaited(() async {
    try {
      await ref.read(profileRepositoryProvider).completeFromSignIn(
            userId: userId,
            fullName: user.fullName,
            phone: user.phone,
            avatarUrl: user.avatarUrl,
          );
      if (!disposed) ref.invalidate(userProfileProvider);
    } catch (error) {
      debugPrint('Profile sync failed: $error');
    }
  }());
});
