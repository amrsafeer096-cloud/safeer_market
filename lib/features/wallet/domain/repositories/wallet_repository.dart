import '../entities/saved_card.dart';

abstract interface class WalletRepository {
  /// The user's balance from `profiles.wallet_balance`; 0 when unset.
  Future<double> fetchBalance(String userId);

  /// Masked saved cards from `profiles.saved_cards` (no CVV / full PAN).
  Future<List<SavedCard>> fetchSavedCards(String userId);

  /// Persist the full saved-card list for [userId] (replaces previous list).
  Future<void> saveSavedCards(String userId, List<SavedCard> cards);
}
