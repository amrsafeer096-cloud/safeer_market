import '../entities/user_profile.dart';
import '../entities/user_role.dart';

abstract class ProfileRepository {
  /// Returns null when the user has no `profiles` row yet.
  Future<UserProfile?> fetchProfile(String userId);

  /// `profiles.role`; [UserRole.customer] when the row or column is missing.
  Future<UserRole> fetchRole(String userId);

  /// Saves the name and phone, creating the `profiles` row if missing.
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  });

  /// After sign-in: creates the `profiles` row for a new user, or fills in
  /// fields that are still empty. Never overwrites what the user saved.
  Future<void> completeFromSignIn({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Registers this device's push token in `user_fcm_tokens` (with the
  /// user's role and platform) and `profiles.fcm_token`.
  Future<void> saveFcmToken({required String userId, required String token});
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
