import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_loyalty_redemption_repository.dart';
import '../../data/repositories/supabase_loyalty_repository.dart';
import '../../domain/repositories/loyalty_redemption_repository.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../widgets/customer_code_camera.dart';
import '../../domain/sliding_puzzle.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return SupabaseLoyaltyRepository(ref.watch(supabaseClientProvider));
});

final loyaltyRedemptionRepositoryProvider =
    Provider<LoyaltyRedemptionRepository>((ref) {
  return SupabaseLoyaltyRedemptionRepository(ref.watch(supabaseClientProvider));
});

/// The camera view the cashier scans customer codes with; calls `onScan`
/// with each code's raw text. Tests swap in a fake.
final customerCodeScannerProvider =
    Provider<Widget Function(ValueChanged<String> onScan)>((ref) {
  return (onScan) => CustomerCodeCamera(onScan: onScan);
});

/// How often the customer's QR dialog re-reads the balance, in case the
/// Realtime event doesn't arrive.
final redemptionPollIntervalProvider =
    Provider<Duration>((ref) => const Duration(seconds: 4));

/// Signed-in user's loyalty balance — single source of truth for Home,
/// the loyalty hub, Cashier QR, and every game header. Guests resolve to 0.
/// Keeps a Realtime subscription on `profiles.loyalty_points`.
final loyaltyPointsProvider =
    AsyncNotifierProvider<LoyaltyPointsNotifier, int>(
  LoyaltyPointsNotifier.new,
);

class LoyaltyPointsNotifier extends AsyncNotifier<int> {
  StreamSubscription<int>? _live;

  @override
  Future<int> build() async {
    ref.onDispose(() {
      unawaited(_live?.cancel());
      _live = null;
    });

    final user = ref.watch(currentUserProvider);
    if (user == null) return 0;

    final repo = ref.read(loyaltyRepositoryProvider);
    final initial = await repo.fetchPoints(user.id);

    // Live updates from DB triggers (order awards, campaigns, redemptions).
    await _live?.cancel();
    _live = repo.watchPoints(user.id).listen(
      (points) {
        state = AsyncData(points);
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('loyaltyPoints live stream error: $error\n$stack');
      },
    );

    return initial;
  }

  /// Optimistically bumps the displayed balance, then persists to Supabase.
  /// Rolls back on failure. Returns the confirmed total.
  Future<int> awardPoints(int amount) async {
    if (amount <= 0) return state.valueOrNull ?? 0;
    final user = ref.read(currentUserProvider);
    if (user == null) return state.valueOrNull ?? 0;

    final previous = state.valueOrNull ?? 0;
    state = AsyncData(previous + amount);

    try {
      final next = await ref.read(loyaltyRepositoryProvider).addPoints(
            userId: user.id,
            amount: amount,
          );
      state = AsyncData(next);
      return next;
    } catch (error, stack) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData(0);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loyaltyRepositoryProvider).fetchPoints(user.id),
    );
  }
}

/// Picks a slice index in `0 .. itemCount - 1`. Tests override this.
final wheelRollProvider = Provider<int Function(int itemCount)>((ref) {
  return (itemCount) => Fortune.randomInt(0, itemCount);
});

/// Builds the opening (or reshuffled) puzzle board. Tests override this.
final puzzleBoardProvider = Provider<SlidingPuzzle Function()>((ref) {
  return () => SlidingPuzzle.shuffled(Random());
});
