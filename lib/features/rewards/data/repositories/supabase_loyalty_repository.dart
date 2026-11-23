import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/resilient_realtime_stream.dart';
import '../../domain/repositories/loyalty_repository.dart';

/// `profiles.loyalty_points`, which may be null on older rows: null (or a
/// missing row) counts as 0 when reading and when adding to it.
class SupabaseLoyaltyRepository implements LoyaltyRepository {
  SupabaseLoyaltyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<int> fetchPoints(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('loyalty_points')
          .eq('id', userId)
          .maybeSingle();
      return pointsFrom(row?['loyalty_points']);
    } on PostgrestException catch (error) {
      debugPrint('loyalty_points read failed: ${error.code} ${error.message}');
      throw LoyaltyFailure(
        L10n.current.loyaltyPointsLoadFailed(error.message),
      );
    }
  }

  @override
  Stream<int> watchPoints(String userId) {
    return resilientRealtimeStream<int>(
      fetch: () => fetchPoints(userId),
      disconnectedPollInterval: const Duration(seconds: 15),
      create: () {
        late final RealtimeChannel channel;
        final controller = StreamController<int>(
          onCancel: () => _client.removeChannel(channel),
        );
        channel = _client
            .channel('loyalty-points-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'profiles',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: userId,
              ),
              callback: (payload) {
                final row = payload.newRecord;
                if (!controller.isClosed) {
                  controller.add(pointsFrom(row['loyalty_points']));
                }
              },
            )
            .subscribe();
        return controller.stream;
      },
    );
  }

  @override
  Future<int> addPoints({
    required String userId,
    required int amount,
  }) async {
    if (amount <= 0) return fetchPoints(userId);

    final next = await fetchPoints(userId) + amount;
    try {
      final updated = await _client
          .from('profiles')
          .update({'loyalty_points': next})
          .eq('id', userId)
          .select('loyalty_points');
      if (updated.isEmpty) {
        await _client.from('profiles').insert({
          'id': userId,
          'loyalty_points': next,
        });
        return next;
      }
      return pointsFrom(updated.first['loyalty_points'], fallback: next);
    } on PostgrestException catch (error) {
      debugPrint(
          'loyalty_points update failed: ${error.code} ${error.message}');
      throw LoyaltyFailure(
        L10n.current.loyaltyPointsUpdateFailed(error.message),
      );
    }
  }

  /// A stored balance as an int: null, blank or unreadable is [fallback].
  static int pointsFrom(Object? value, {int fallback = 0}) => switch (value) {
        final num number => number.toInt(),
        final String text => num.tryParse(text.trim())?.toInt() ?? fallback,
        _ => fallback,
      };
}
