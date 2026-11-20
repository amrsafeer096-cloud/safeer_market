/// A customer InstaPay upgrade awaiting admin verification.
class PendingSubscriptionRequest {
  const PendingSubscriptionRequest({
    required this.userId,
    this.fullName,
    this.phone,
    this.pendingTier,
    this.receiptUrl,
    this.status = 'pending_verification',
  });

  factory PendingSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return PendingSubscriptionRequest(
      userId: '${json['id'] ?? ''}',
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      pendingTier: json['pending_subscription_tier']?.toString(),
      receiptUrl: json['subscription_receipt_url']?.toString(),
      status: json['subscription_status']?.toString() ?? 'pending_verification',
    );
  }

  final String userId;
  final String? fullName;
  final String? phone;
  final String? pendingTier;
  final String? receiptUrl;
  final String status;

  bool get isVip => pendingTier == 'vip';
}
