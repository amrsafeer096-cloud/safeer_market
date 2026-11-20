import '../entities/support_chat.dart';

abstract interface class SupportRepository {
  /// The customer's open chat, created on their first visit.
  Future<SupportChat> openChat({
    required String userId,
    String? customerName,
    String? customerPhone,
  });

  /// The chat's messages, oldest first, updated live.
  Stream<List<SupportMessage>> watchMessages(String chatId);

  /// Inserts a message; the database updates the chat's last message,
  /// time and unread counts.
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required SupportSenderRole senderRole,
    SupportAttachmentType? attachmentType,
    String? attachmentUrl,
    String? orderId,
    int? voiceDuration,
  });

  /// Uploads bytes to the `support_media` bucket; returns a public URL.
  Future<String> uploadMedia({
    required String userId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  });

  /// Staff only: every open chat, most recently active first, updated live.
  Stream<List<SupportChat>> watchOpenChats();

  /// The signed-in customer's open-chat unread count (`unread_customer_count`
  /// / `unread_user_count`), live for bottom-nav and «تحدث معنا» badges.
  Stream<int> watchMyUnreadCount(String userId);

  /// Marks the other party's `sent` messages as `delivered` for [viewerRole].
  Future<void> markDelivered(String chatId, SupportSenderRole viewerRole);

  /// Marks the other party's messages as `read` for [viewerRole] and clears
  /// that side's unread badge on the chat.
  Future<void> markChatRead(String chatId, SupportSenderRole viewerRole);

  /// Recent orders for [userId] (order-reference picker).
  Future<List<SupportOrderRef>> fetchCustomerOrders(String userId);
}

/// A short order summary shown in the «بخصوص طلب» picker.
class SupportOrderRef {
  const SupportOrderRef({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
  });

  final String id;
  final DateTime createdAt;
  final String status;
  final double totalAmount;

  String get shortId => id.length > 6 ? id.substring(0, 6) : id;
}
