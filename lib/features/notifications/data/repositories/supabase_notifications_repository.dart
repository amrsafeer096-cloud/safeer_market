import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Table and policies are in 20261114220000_app_notifications.sql.
class SupabaseNotificationsRepository implements NotificationsRepository {
  const SupabaseNotificationsRepository(this._client);

  static const _table = 'app_notifications';

  /// The newest notifications are enough for the list and the bell.
  static const limit = 100;

  final SupabaseClient _client;

  @override
  Stream<List<AppNotification>> watchNotifications() => _client
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(limit)
      .map((rows) => rows.map(_toNotification).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<void> broadcast({
    required String title,
    required String body,
    required AppNotificationType type,
    String? imageUrl,
  }) async {
    final image = imageUrl?.trim();
    try {
      await _client.from(_table).insert({
        'title': title.trim(),
        'body': body.trim(),
        'type': type.value,
        'image_url': image == null || image.isEmpty ? null : image,
        'target_user_id': null,
      });
    } on PostgrestException catch (error) {
      throw NotificationsFailure(_message(error));
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      // `select` returns the deleted rows; row level security filtering the
      // row out would otherwise "succeed" without deleting anything.
      final deleted = await _client.from(_table).delete().eq('id', id).select('id');
      if (deleted.isEmpty) {
        throw NotificationsFailure(L10n.current.notificationsNotAllowed);
      }
    } on PostgrestException catch (error) {
      throw NotificationsFailure(_message(error));
    }
  }

  static String _message(PostgrestException error) {
    debugPrint('Notifications: ${error.code} ${error.message}');
    final l10n = L10n.current;
    if (error.code == 'PGRST205' || error.code == '42P01') {
      return l10n.notificationsSetupMissing;
    }
    if (error.code == '42501') return l10n.notificationsNotAllowed;
    return '${error.message} (${error.code})';
  }

  static AppNotification _toNotification(Map<String, dynamic> row) {
    String? text(String key) {
      final value = row[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return AppNotification(
      id: row['id'].toString(),
      title: text('title') ?? '',
      body: text('body') ?? '',
      type: AppNotificationType.fromValue(row['type']),
      imageUrl: text('image_url'),
      targetUserId: text('target_user_id'),
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ?? DateTime.now(),
    );
  }
}
