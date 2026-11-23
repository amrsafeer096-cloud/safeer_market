abstract class LoyaltyRepository {
  /// Current `profiles.loyalty_points` for [userId], or 0 when the row is missing.
  Future<int> fetchPoints(String userId);

  /// Live `profiles.loyalty_points` updates for [userId] (Realtime + initial).
  Stream<int> watchPoints(String userId);

  /// Adds [amount] to the user's balance and returns the new total.
  Future<int> addPoints({required String userId, required int amount});
}

class LoyaltyFailure implements Exception {
  const LoyaltyFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
