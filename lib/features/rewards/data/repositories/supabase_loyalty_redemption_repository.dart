import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/loyalty_redemption.dart';
import '../../domain/repositories/loyalty_redemption_repository.dart';
import '../../domain/repositories/loyalty_repository.dart';
import 'supabase_loyalty_repository.dart';

/// Both cashier steps go through security-definer functions
/// (`loyalty_customer`, `redeem_loyalty_points`) that check the caller is a
/// cashier or admin and deduct atomically.
class SupabaseLoyaltyRedemptionRepository
    implements LoyaltyRedemptionRepository {
  const SupabaseLoyaltyRedemptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LoyaltyCustomer> fetchCustomer(String userId) async {
    final Object? data;
    try {
      data = await _client.rpc<Object?>(
        'loyalty_customer',
        params: {'p_user_id': userId},
      );
    } on PostgrestException catch (error) {
      debugPrint('loyalty_customer($userId) failed: '
          '${error.code} ${error.message}');
      throw LoyaltyFailure(_message(error));
    }
    final row = data is Map ? data : const {};
    return LoyaltyCustomer(
      userId: userId,
      points: SupabaseLoyaltyRepository.pointsFrom(row['loyalty_points']),
      fullName: _text(row['full_name']),
      phone: _text(row['phone']),
    );
  }

  @override
  Future<LoyaltyRedemption> redeem({
    required String userId,
    required int discountEgp,
  }) async {
    final Object? data;
    try {
      data = await _client.rpc<Object?>(
        'redeem_loyalty_points',
        params: {'p_user_id': userId, 'p_discount_egp': discountEgp},
      );
    } on PostgrestException catch (error) {
      debugPrint('redeem_loyalty_points($userId, $discountEgp) failed: '
          '${error.code} ${error.message}');
      throw LoyaltyFailure(_message(error));
    }
    final row = data is Map ? data : const {};
    return LoyaltyRedemption(
      pointsRedeemed: SupabaseLoyaltyRepository.pointsFrom(
        row['points_redeemed'],
        fallback: discountEgp * RedemptionQuote.pointsPerEgp,
      ),
      discountEgp: SupabaseLoyaltyRepository.pointsFrom(
        row['discount_amount'],
        fallback: discountEgp,
      ),
      remainingPoints:
          SupabaseLoyaltyRepository.pointsFrom(row['remaining_points']),
    );
  }

  @override
  Stream<void> watchRedemptions(String userId) {
    late final RealtimeChannel channel;
    final controller = StreamController<void>(
      onCancel: () => _client.removeChannel(channel),
    );
    channel = _client
        .channel('loyalty-redemptions-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'loyalty_redemptions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();
    return controller.stream;
  }

  static String _message(PostgrestException error) {
    final l10n = L10n.current;
    final message = error.message;
    if (message.contains('insufficient_points')) {
      return l10n.redeemInsufficientPoints;
    }
    if (message.contains('not_allowed')) return l10n.redeemNotAllowed;
    if (message.contains('customer_not_found')) {
      return l10n.redeemCustomerNotFound;
    }
    return l10n.redeemFailed('$message (${error.code})');
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
