/// Who wrote a support message: the customer or staff on the dashboard.
enum SupportSenderRole {
  customer('customer'),
  admin('admin');

  const SupportSenderRole(this.value);

  /// The value stored in `support_messages.sender_role`.
  final String value;

  static SupportSenderRole fromValue(Object? value) =>
      value == admin.value ? admin : customer;
}

/// WhatsApp-style delivery state for a support message.
enum SupportMessageStatus {
  sent('sent'),
  delivered('delivered'),
  read('read');

  const SupportMessageStatus(this.value);

  final String value;

  static SupportMessageStatus fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'delivered' => delivered,
      'read' => read,
      _ => sent,
    };
  }
}

/// Optional payload attached to a support message.
enum SupportAttachmentType {
  image('image'),
  order('order'),
  voice('voice');

  const SupportAttachmentType(this.value);

  final String value;

  static SupportAttachmentType? fromValue(Object? value) => switch (value) {
        'image' => image,
        'order' => order,
        'voice' => voice,
        _ => null,
      };

  /// Short Arabic preview used when `last_message` is missing.
  String get previewLabel => switch (this) {
        image => '📷 صورة',
        voice => '🎤 رسالة صوتية',
        order => '🧾 بخصوص طلب',
      };
}

/// A customer's conversation with customer service (`support_chats`).
class SupportChat {
  const SupportChat({
    required this.id,
    required this.userId,
    required this.updatedAt,
    this.customerName,
    this.customerPhone,
    this.lastMessage,
    this.unreadAdminCount = 0,
    this.unreadCustomerCount = 0,
    this.isOpen = true,
  });

  final String id;
  final String userId;
  final String? customerName;
  final String? customerPhone;
  final String? lastMessage;

  /// Customer messages no staff member has opened yet.
  final int unreadAdminCount;

  /// Admin replies the customer has not opened yet.
  final int unreadCustomerCount;
  final bool isOpen;
  final DateTime updatedAt;

  /// One-line preview for the admin chat list.
  String previewText(String emptyFallback) {
    final text = lastMessage?.trim();
    if (text != null && text.isNotEmpty) return text;
    return emptyFallback;
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.chatId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
    this.status = SupportMessageStatus.sent,
    this.isRead = false,
    this.attachmentType,
    this.attachmentUrl,
    this.orderId,
    this.voiceDuration,
  });

  final String id;
  final String chatId;
  final SupportSenderRole senderRole;
  final String message;
  final DateTime createdAt;
  final SupportMessageStatus status;
  final bool isRead;
  final SupportAttachmentType? attachmentType;
  final String? attachmentUrl;
  final String? orderId;

  /// Voice note length in whole seconds.
  final int? voiceDuration;

  bool get hasImage =>
      attachmentType == SupportAttachmentType.image &&
      (attachmentUrl?.isNotEmpty ?? false);

  bool get hasVoice =>
      attachmentType == SupportAttachmentType.voice &&
      (attachmentUrl?.isNotEmpty ?? false);

  bool get hasOrder =>
      attachmentType == SupportAttachmentType.order &&
      (orderId?.isNotEmpty ?? false);

  /// True when the other party has opened this message.
  bool get isSeen => isRead || status == SupportMessageStatus.read;
}

class SupportFailure implements Exception {
  const SupportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
