import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../auth/domain/egyptian_phone.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, full_name, phone, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile(
      id: row['id'].toString(),
      fullName: row['full_name'] as String?,
      phone: row['phone'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  @override
  Future<UserRole> fetchRole(String userId) async {
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return UserRole.fromValue(row?['role']);
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    try {
      final normalized = EgyptianPhone.normalize(phone);
      await _saveOwnRow(userId, {
        'full_name': fullName,
        'phone': normalized.isEmpty ? phone : normalized,
      });
      await _linkPosCustomer(userId);
    } on PostgrestException catch (error) {
      throw ProfileFailure(L10n.current.profileSaveFailed(error.message));
    }
  }

  @override
  Future<void> completeFromSignIn({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final row = await _client
        .from('profiles')
        .select('full_name, phone, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    bool isBlank(Object? value) => value is! String || value.trim().isEmpty;
    final normalizedPhone = phone == null || phone.trim().isEmpty
        ? null
        : EgyptianPhone.normalize(phone);
    final missing = <String, Object?>{
      if (!isBlank(fullName) && isBlank(row?['full_name']))
        'full_name': fullName,
      if (!isBlank(normalizedPhone) && isBlank(row?['phone']))
        'phone': normalizedPhone,
      if (!isBlank(avatarUrl) && isBlank(row?['avatar_url']))
        'avatar_url': avatarUrl,
    };

    try {
      if (row == null) {
        await _client.from('profiles').upsert({'id': userId, ...missing});
      } else if (missing.isNotEmpty) {
        await _client.from('profiles').update(missing).eq('id', userId);
      }
      await _linkPosCustomer(userId);
    } on PostgrestException catch (error) {
      throw ProfileFailure(L10n.current.profileSaveFailed(error.message));
    }
  }

  /// Merge this app account into an existing POS customer with the same phone.
  Future<void> _linkPosCustomer(String userId) async {
    try {
      await _client.rpc(
        'link_profile_to_pos_customer',
        params: {'p_user_id': userId},
      );
    } on PostgrestException catch (error) {
      // Migration may not be applied yet — profile save still succeeded.
      debugPrint('link_profile_to_pos_customer: ${error.message}');
    }
  }

  @override
  Future<void> saveFcmToken({
    required String userId,
    required String token,
  }) async {
    try {
      // user_fcm_tokens feeds the send-push Edge Function (one row per
      // device, role read from profiles). Before that migration runs, only
      // the legacy profiles.fcm_token is kept.
      await _client.rpc('register_fcm_token', params: {
        'p_token': token,
        'p_platform': PushNotificationService.platformName,
      });
    } on PostgrestException catch (error) {
      debugPrint('Push notifications: register_fcm_token failed: '
          '${error.message}');
    }
    try {
      await _saveOwnRow(userId, {'fcm_token': token});
    } on PostgrestException catch (error) {
      throw ProfileFailure(
        L10n.current.notificationTokenSaveFailed(error.message),
      );
    }
  }

  Future<void> _saveOwnRow(String userId, Map<String, Object?> values) async {
    final updated = await _client
        .from('profiles')
        .update(values)
        .eq('id', userId)
        .select('id');
    // Zero rows means the profile row is missing (or RLS hid it).
    if (updated.isEmpty) {
      await _client.from('profiles').insert({'id': userId, ...values});
    }
  }
}
