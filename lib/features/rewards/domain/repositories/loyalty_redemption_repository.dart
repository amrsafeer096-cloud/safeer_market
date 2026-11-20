import '../loyalty_redemption.dart';

/// Redeeming loyalty points at the till (`loyalty_redemptions`).
abstract class LoyaltyRedemptionRepository {
  /// Cashier side: the scanned customer's name and live balance.
  Future<LoyaltyCustomer> fetchCustomer(String userId);

  /// Cashier side: takes [discountEgp] × 50 points off [userId] and records
  /// the redemption under the signed-in cashier.
  Future<LoyaltyRedemption> redeem({
    required String userId,
    required int discountEgp,
  });

  /// Customer side: emits whenever a redemption is recorded for [userId].
  Stream<void> watchRedemptions(String userId);
}
