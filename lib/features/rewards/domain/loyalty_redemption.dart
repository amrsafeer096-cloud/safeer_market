import 'dart:convert';

/// What a balance is worth at the till: every [pointsPerEgp] points take
/// 1 EGP off. Only whole pounds are redeemed; the rest stays on the account.
class RedemptionQuote {
  const RedemptionQuote._({
    required this.points,
    required this.discountEgp,
    required this.pointsToDeduct,
    required this.remainingPoints,
  });

  factory RedemptionQuote.forPoints(int points) {
    final balance = points < 0 ? 0 : points;
    final discountEgp = balance ~/ pointsPerEgp;
    return RedemptionQuote._(
      points: balance,
      discountEgp: discountEgp,
      pointsToDeduct: discountEgp * pointsPerEgp,
      remainingPoints: balance % pointsPerEgp,
    );
  }

  static const pointsPerEgp = 50;

  final int points;
  final int discountEgp;
  final int pointsToDeduct;
  final int remainingPoints;

  bool get canRedeem => discountEgp >= 1;

  /// What the POS reads off the cashier's screen, e.g. SAFEER-003.
  String get barcodeData => 'SAFEER-${discountEgp.toString().padLeft(3, '0')}';
}

/// The customer's QR payload: {"user_id": ...}.
abstract final class CustomerLoyaltyCode {
  static String encode(String userId) => jsonEncode({'user_id': userId});

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// The user id in a scanned code, or null when it isn't one of ours.
  static String? decode(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw.trim());
      final userId = data is Map ? data['user_id'] : null;
      return userId is String && _uuid.hasMatch(userId.trim())
          ? userId.trim()
          : null;
    } on FormatException {
      return null;
    }
  }
}

/// A scanned customer, as the cashier sees them.
class LoyaltyCustomer {
  const LoyaltyCustomer({
    required this.userId,
    required this.points,
    this.fullName,
    this.phone,
  });

  final String userId;
  final int points;
  final String? fullName;
  final String? phone;
}

/// A confirmed redemption.
class LoyaltyRedemption {
  const LoyaltyRedemption({
    required this.pointsRedeemed,
    required this.discountEgp,
    required this.remainingPoints,
  });

  final int pointsRedeemed;
  final int discountEgp;
  final int remainingPoints;
}
