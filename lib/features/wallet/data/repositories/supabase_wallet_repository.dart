import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/saved_card.dart';
import '../../domain/repositories/wallet_repository.dart';

class SupabaseWalletRepository implements WalletRepository {
  const SupabaseWalletRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<double> fetchBalance(String userId) async {
    final row = await _client
        .from('profiles')
        .select('wallet_balance')
        .eq('id', userId)
        .maybeSingle();

    return switch (row?['wallet_balance']) {
      final num value => value.toDouble(),
      final String value => double.tryParse(value) ?? 0,
      _ => 0,
    };
  }

  @override
  Future<List<SavedCard>> fetchSavedCards(String userId) async {
    final row = await _client
        .from('profiles')
        .select('saved_cards')
        .eq('id', userId)
        .maybeSingle();

    return _parseCards(row?['saved_cards']);
  }

  @override
  Future<void> saveSavedCards(String userId, List<SavedCard> cards) async {
    await _client.from('profiles').update({
      'saved_cards': cards.map((c) => c.toJson()).toList(),
    }).eq('id', userId);
  }

  static List<SavedCard> _parseCards(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          SavedCard.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
