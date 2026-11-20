import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/support_chat.dart';
import '../../domain/repositories/support_repository.dart';

/// Tables, policies and triggers are in 20261114210000_support_chat.sql and
/// 20261115010000_support_chat_media_receipts.sql.
class SupabaseSupportRepository implements SupportRepository {
  SupabaseSupportRepository(this._client);

  static const _chatColumns = 'id, user_id, customer_name, customer_phone, '
      'status, last_message, unread_admin_count, unread_customer_count, '
      'updated_at';

  static const _messageColumns = 'id, chat_id, sender_role, message, '
      'created_at, status, is_read, attachment_type, attachment_url, '
      'order_id, voice_duration';

  /// Open chats on the dashboard; older ones drop off the list.
  static const openChatsLimit = 200;

  static const _mediaBucket = 'support_media';

  final SupabaseClient _client;

  @override
  Future<SupportChat> openChat({
    required String userId,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final existing = await _openChatOf(userId);
      if (existing != null) return existing;
      final row = await _client
          .from('support_chats')
          .insert({
            'user_id': userId,
            'customer_name': _text(customerName),
            'customer_phone': _text(customerPhone),
            'status': 'open',
          })
          .select(_chatColumns)
          .single();
      return _toChat(row);
    } on PostgrestException catch (error) {
      // Opened at the same moment on another device: use that chat.
      if (error.code == '23505') {
        final chat = await _openChatOf(userId);
        if (chat != null) return chat;
      }
      throw SupportFailure(_message(error));
    }
  }

  Future<SupportChat?> _openChatOf(String userId) async {
    final row = await _client
        .from('support_chats')
        .select(_chatColumns)
        .eq('user_id', userId)
        .eq('status', 'open')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : _toChat(row);
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String chatId) {
    // Explicit select + realtime reload so new columns (status, attachments)
    // always arrive, including on the first snapshot.
    final controller = StreamController<List<SupportMessage>>();
    Future<void> load() async {
      try {
        final rows = await _client
            .from('support_messages')
            .select(_messageColumns)
            .eq('chat_id', chatId)
            .order('created_at', ascending: true);
        if (!controller.isClosed) {
          controller.add([for (final row in rows) _toMessage(row)]);
        }
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    }

    load();
    final channel = _client
        .channel('support-messages-$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (_) => load(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };
    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required SupportSenderRole senderRole,
    SupportAttachmentType? attachmentType,
    String? attachmentUrl,
    String? orderId,
    int? voiceDuration,
  }) async {
    final text = message.trim();
    if (text.isEmpty && attachmentType == null) {
      throw SupportFailure(L10n.current.supportRequestFailed('empty'));
    }
    try {
      await _client.from('support_messages').insert({
        'chat_id': chatId,
        'sender_role': senderRole.value,
        'message': text.isEmpty ? attachmentType!.previewLabel : text,
        'status': SupportMessageStatus.sent.value,
        'is_read': false,
        if (attachmentType != null) 'attachment_type': attachmentType.value,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (orderId != null) 'order_id': orderId,
        if (voiceDuration != null) 'voice_duration': voiceDuration,
      });
    } on PostgrestException catch (error) {
      throw SupportFailure(_message(error));
    }
  }

  @override
  Future<String> uploadMedia({
    required String userId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    try {
      await _client.storage.from(_mediaBucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );
      return _client.storage.from(_mediaBucket).getPublicUrl(path);
    } on StorageException catch (error) {
      throw SupportFailure(
          L10n.current.supportRequestFailed(error.message));
    } catch (error) {
      throw SupportFailure(L10n.current.supportRequestFailed('$error'));
    }
  }

  @override
  Stream<List<SupportChat>> watchOpenChats() {
    // Manual select + realtime: the plain `.stream()` filter was dropping
    // `last_message` updates for some chats on the dashboard list.
    final controller = StreamController<List<SupportChat>>();
    Future<void> load() async {
      try {
        final rows = await _client
            .from('support_chats')
            .select(_chatColumns)
            .eq('status', 'open')
            .order('updated_at', ascending: false)
            .limit(openChatsLimit);
        if (!controller.isClosed) {
          controller.add([for (final row in rows) _toChat(row)]);
        }
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    }

    load();
    final channel = _client
        .channel('admin-support-chats')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_chats',
          callback: (_) => load(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          callback: (_) => load(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };
    return controller.stream;
  }

  @override
  Stream<int> watchMyUnreadCount(String userId) {
    final controller = StreamController<int>();
    Future<void> load() async {
      try {
        Map<String, dynamic>? row;
        try {
          row = await _client
              .from('support_chats')
              .select('unread_customer_count, unread_user_count')
              .eq('user_id', userId)
              .eq('status', 'open')
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();
        } on PostgrestException {
          // Pre-migration DBs without unread_user_count.
          row = await _client
              .from('support_chats')
              .select('unread_customer_count')
              .eq('user_id', userId)
              .eq('status', 'open')
              .order('updated_at', ascending: false)
              .limit(1)
              .maybeSingle();
        }
        if (controller.isClosed) return;
        if (row == null) {
          controller.add(0);
          return;
        }
        // Prefer unread_customer_count; fall back to unread_user_count alias.
        final count = _int(row['unread_customer_count']);
        controller.add(count > 0 ? count : _int(row['unread_user_count']));
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      }
    }

    load();
    final channel = _client
        .channel('customer-support-unread-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => load(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };
    return controller.stream;
  }

  @override
  Future<void> markDelivered(
    String chatId,
    SupportSenderRole viewerRole,
  ) async {
    try {
      // Direct table update (admin dashboard: any still-sent rows → delivered).
      var query = _client
          .from('support_messages')
          .update({'status': 'delivered'})
          .eq('chat_id', chatId)
          .eq('status', 'sent');
      // Customer side only advances the other party's ticks.
      if (viewerRole == SupportSenderRole.customer) {
        query = query.neq('sender_role', viewerRole.value);
      }
      await query;
    } on PostgrestException catch (error) {
      // Older databases: fall back to the security-definer RPC.
      if (error.code == 'PGRST202' ||
          error.code == '42501' ||
          error.code == '42P01') {
        try {
          await _client.rpc<void>(
            'mark_support_messages_delivered',
            params: {
              'p_chat_id': chatId,
              'p_viewer_role': viewerRole.value,
            },
          );
        } on PostgrestException catch (rpcError) {
          if (rpcError.code == 'PGRST202') return;
          debugPrint(
              'Support delivered: ${rpcError.code} ${rpcError.message}');
        }
        return;
      }
      debugPrint('Support delivered: ${error.code} ${error.message}');
    }
  }

  @override
  Future<void> markChatRead(
    String chatId,
    SupportSenderRole viewerRole,
  ) async {
    try {
      final otherRole = viewerRole == SupportSenderRole.admin
          ? SupportSenderRole.customer.value
          : SupportSenderRole.admin.value;
      // Match the requested admin open-chat write path (and customer mirror).
      await _client
          .from('support_messages')
          .update({'status': 'read', 'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_role', viewerRole.value)
          .neq('status', 'read');
      if (viewerRole == SupportSenderRole.admin) {
        await _client
            .from('support_chats')
            .update({'unread_admin_count': 0})
            .eq('id', chatId);
      } else {
        try {
          await _client.from('support_chats').update({
            'unread_customer_count': 0,
            'unread_user_count': 0,
          }).eq('id', chatId);
        } on PostgrestException {
          await _client
              .from('support_chats')
              .update({'unread_customer_count': 0})
              .eq('id', chatId);
        }
      }
      assert(otherRole.isNotEmpty);
    } on PostgrestException catch (error) {
      // Older databases / missing UPDATE grants: security-definer RPC.
      try {
        await _client.rpc<void>(
          'mark_support_messages_read',
          params: {
            'p_chat_id': chatId,
            'p_viewer_role': viewerRole.value,
          },
        );
      } on PostgrestException catch (rpcError) {
        if (rpcError.code == 'PGRST202') {
          try {
            if (viewerRole == SupportSenderRole.admin) {
              await _client
                  .from('support_chats')
                  .update({'unread_admin_count': 0})
                  .eq('id', chatId)
                  .gt('unread_admin_count', 0);
            } else {
              await _client
                  .from('support_chats')
                  .update({'unread_customer_count': 0})
                  .eq('id', chatId)
                  .gt('unread_customer_count', 0);
            }
          } catch (_) {}
          return;
        }
        throw SupportFailure(_message(rpcError));
      }
      if (error.code != '42501' && error.code != '42P01') {
        debugPrint('Support read (direct): ${error.code} ${error.message}');
      }
    }
  }

  @override
  Future<List<SupportOrderRef>> fetchCustomerOrders(String userId) async {
    try {
      final rows = await _client
          .from('orders')
          .select('id, created_at, status, total_amount')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(12);
      return [
        for (final row in rows)
          SupportOrderRef(
            id: row['id'].toString(),
            createdAt: _time(row['created_at']),
            status: '${row['status'] ?? ''}',
            totalAmount: switch (row['total_amount']) {
              final num amount => amount.toDouble(),
              final String amount => double.tryParse(amount) ?? 0,
              _ => 0,
            },
          ),
      ];
    } on PostgrestException catch (error) {
      throw SupportFailure(_message(error));
    }
  }

  String _message(PostgrestException error) {
    debugPrint('Support chat: ${error.code} ${error.message}');
    final l10n = L10n.current;
    if (error.code == 'PGRST205' || error.code == '42P01') {
      return l10n.supportSetupMissing;
    }
    if (error.code == '42501') return l10n.supportNotAllowed;
    return l10n.supportRequestFailed('${error.message} (${error.code})');
  }

  static SupportChat _toChat(Map<String, dynamic> row) => SupportChat(
        id: row['id'].toString(),
        userId: row['user_id']?.toString() ?? '',
        customerName: _text(row['customer_name']),
        customerPhone: _text(row['customer_phone']),
        lastMessage: _text(row['last_message']),
        unreadAdminCount: _int(row['unread_admin_count']),
        unreadCustomerCount: _int(row['unread_customer_count']),
        isOpen: (row['status'] ?? 'open') == 'open',
        updatedAt: _time(row['updated_at']),
      );

  static SupportMessage _toMessage(Map<String, dynamic> row) {
    final isRead = _bool(row['is_read']);
    var status = SupportMessageStatus.fromValue(row['status']);
    // DB may set is_read without bumping status — treat as read for ticks.
    if (isRead && status != SupportMessageStatus.read) {
      status = SupportMessageStatus.read;
    }
    return SupportMessage(
      id: row['id'].toString(),
      chatId: row['chat_id'].toString(),
      senderRole: SupportSenderRole.fromValue(row['sender_role']),
      message: row['message']?.toString() ?? '',
      createdAt: _time(row['created_at']),
      status: status,
      isRead: isRead || status == SupportMessageStatus.read,
      attachmentType: SupportAttachmentType.fromValue(row['attachment_type']),
      attachmentUrl: _text(row['attachment_url']),
      orderId: row['order_id']?.toString(),
      voiceDuration: switch (row['voice_duration']) {
        final num seconds => seconds.toInt(),
        final String seconds => int.tryParse(seconds),
        _ => null,
      },
    );
  }

  static bool _bool(Object? value) => switch (value) {
        true || 1 || 'true' || 'TRUE' || 't' || '1' => true,
        _ => false,
      };

  static int _int(Object? value) => switch (value) {
        final num count => count.toInt(),
        final String count => int.tryParse(count) ?? 0,
        _ => 0,
      };

  static DateTime _time(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
