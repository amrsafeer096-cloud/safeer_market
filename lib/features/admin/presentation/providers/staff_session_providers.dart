import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../domain/staff_session.dart';

const _staffSessionKey = 'safeer_staff_session_v1';

/// Currently logged-in dashboard staff member, or null when the login gate
/// should be shown.
final staffSessionProvider =
    StateNotifierProvider<StaffSessionController, StaffSession?>(
  (ref) => StaffSessionController(ref),
);

class StaffSessionController extends StateNotifier<StaffSession?> {
  StaffSessionController(this._ref, {StaffSession? initial}) : super(initial) {
    // Tests pass [initial] so SharedPreferences restore does not clear it.
    if (initial == null) unawaited(_restore());
  }

  final Ref _ref;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_staffSessionKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        state = StaffSession.fromJson(map);
      }
    } catch (error) {
      debugPrint('staff session restore failed: $error');
    }
  }

  Future<void> _persist(StaffSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session == null) {
      await prefs.remove(_staffSessionKey);
    } else {
      await prefs.setString(_staffSessionKey, jsonEncode(session.toJson()));
    }
  }

  /// Verifies credentials via `staff_login` and opens the dashboard.
  Future<StaffSession> login({
    required String username,
    required String password,
  }) async {
    final client = _ref.read(supabaseClientProvider);
    try {
      final rows = await client.rpc(
        'staff_login',
        params: {
          'p_username': username.trim(),
          'p_password': password,
        },
      );
      final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
      if (list.isEmpty) {
        throw const StaffLoginFailure('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      final row = list.first;
      final session = StaffSession(
        id: '${row['id']}',
        name: '${row['name'] ?? ''}',
        role: '${row['role'] ?? ''}',
        username: '${row['username'] ?? username.trim()}',
        phone: row['phone']?.toString(),
      );
      state = session;
      await _persist(session);
      unawaited(_syncPushRole(session));
      return session;
    } on PostgrestException catch (error) {
      final text = '${error.message} ${error.details ?? ''}';
      if (text.contains('invalid_credentials')) {
        throw const StaffLoginFailure('اسم المستخدم أو كلمة المرور غير صحيحة');
      }
      throw StaffLoginFailure(error.message);
    }
  }

  Future<void> logout() async {
    state = null;
    await _persist(null);
    // Revert the device token to the signed-in profile's push role.
    unawaited(_syncPushRole(null));
  }

  Future<void> _syncPushRole(StaffSession? session) async {
    try {
      final client = _ref.read(supabaseClientProvider);
      final push = _ref.read(pushNotificationServiceProvider);
      final token = await push.getToken();
      if (token == null) return;
      final role = switch (session?.role) {
        'admin' => 'admin',
        'taker' => 'taker',
        'driver' => 'delivery',
        // Preparers still hear new-order alerts as takers when on shift.
        'preparer' => 'taker',
        _ => null,
      };
      await client.rpc('register_fcm_token', params: {
        'p_token': token,
        'p_platform': PushNotificationService.platformName,
        if (role != null) 'p_role': role,
      });
    } catch (error) {
      debugPrint('staff FCM role sync failed: $error');
    }
  }
}

class StaffLoginFailure implements Exception {
  const StaffLoginFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
