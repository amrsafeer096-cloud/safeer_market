import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../core/providers/settings_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_wallet_repository.dart';
import '../../data/saved_card_secrets.dart';
import '../../domain/entities/saved_card.dart';
import '../../domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return SupabaseWalletRepository(ref.watch(supabaseClientProvider));
});

final savedCardSecretsProvider = Provider<SavedCardSecrets>((ref) {
  return SavedCardSecrets();
});

/// The signed-in user's wallet balance, or null for guests.
final walletBalanceProvider = FutureProvider.autoDispose<double?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value();
  return ref.watch(walletRepositoryProvider).fetchBalance(user.id);
});

String savedCardsPrefsKey(String userId) => 'wallet.saved_cards.$userId';

/// Cards persisted per user (SharedPreferences + Supabase `profiles.saved_cards`).
/// CVV lives only in [SavedCardSecrets] (encrypted device storage).
final savedCardsProvider =
    NotifierProvider<SavedCardsNotifier, List<SavedCard>>(
  SavedCardsNotifier.new,
);

/// Which saved card is selected at checkout for Visa/card payment.
/// `null` means “use or add a new card”.
final selectedCheckoutCardProvider = StateProvider<SavedCard?>((ref) {
  ref.watch(currentUserProvider);
  return null;
});

class SavedCardsNotifier extends Notifier<List<SavedCard>> {
  @override
  List<SavedCard> build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];

    final cached = _readPrefs(user.id);
    unawaited(_hydrateFromRemote(user.id, cached));
    return cached;
  }

  SharedPreferences? get _prefs => ref.read(sharedPreferencesProvider);

  SavedCardSecrets get _secrets => ref.read(savedCardSecretsProvider);

  List<SavedCard> _readPrefs(String userId) {
    final raw = _prefs?.getString(savedCardsPrefsKey(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            SavedCard.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (e, st) {
      debugPrint('Failed to parse saved cards prefs: $e\n$st');
      return const [];
    }
  }

  Future<void> _writePrefs(String userId, List<SavedCard> cards) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      savedCardsPrefsKey(userId),
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _hydrateFromRemote(
    String userId,
    List<SavedCard> local,
  ) async {
    try {
      final remote =
          await ref.read(walletRepositoryProvider).fetchSavedCards(userId);
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.id != userId) return;

      final byId = <String, SavedCard>{
        for (final card in local) card.id: card,
        for (final card in remote) card.id: card,
      };
      final merged = byId.values.toList();
      if (!_sameCards(merged, state)) {
        state = merged;
      }
      await _writePrefs(userId, merged);
      if (!_sameCards(merged, remote)) {
        await ref.read(walletRepositoryProvider).saveSavedCards(userId, merged);
      }
    } catch (e, st) {
      debugPrint('Saved cards remote hydrate failed: $e\n$st');
    }
  }

  Future<void> add(
    SavedCard card, {
    String? cvv,
    String? pan,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final next = [...state.where((c) => c.id != card.id), card];
    state = next;
    await _persist(user.id, next);
    if (cvv != null && cvv.trim().isNotEmpty) {
      await _secrets.writeCvv(
        userId: user.id,
        cardId: card.id,
        cvv: cvv,
      );
    }
    if (pan != null && pan.trim().isNotEmpty) {
      await _secrets.writePan(
        userId: user.id,
        cardId: card.id,
        pan: pan,
      );
    }
  }

  Future<void> remove(SavedCard card) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final next = [for (final c in state) if (c.id != card.id) c];
    state = next;
    final selected = ref.read(selectedCheckoutCardProvider);
    if (selected?.id == card.id) {
      ref.read(selectedCheckoutCardProvider.notifier).state = null;
    }
    await _persist(user.id, next);
    await _secrets.deleteCvv(userId: user.id, cardId: card.id);
    await _secrets.deletePan(userId: user.id, cardId: card.id);
  }

  Future<String?> readCvv(SavedCard card) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    return _secrets.readCvv(userId: user.id, cardId: card.id);
  }

  Future<String?> readPan(SavedCard card) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    return _secrets.readPan(userId: user.id, cardId: card.id);
  }

  Future<void> _persist(String userId, List<SavedCard> cards) async {
    await _writePrefs(userId, cards);
    try {
      await ref.read(walletRepositoryProvider).saveSavedCards(userId, cards);
    } catch (e, st) {
      debugPrint('Saved cards remote save failed: $e\n$st');
    }
  }

  static bool _sameCards(List<SavedCard> a, List<SavedCard> b) {
    if (a.length != b.length) return false;
    final ids = {for (final c in a) c.id};
    return b.every((c) => ids.contains(c.id));
  }
}
