import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/daily_game_cooldown.dart';
import '../providers/daily_game_providers.dart';
import '../providers/rewards_providers.dart';
import '../widgets/points_banner.dart';
import '../widgets/redeem_points_dialog.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final canRedeemForCustomers =
        ref.watch(userRoleProvider).valueOrNull?.canRedeemLoyalty ?? false;
    final pointsAsync = ref.watch(loyaltyPointsProvider);
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final bypassCooldown = ref.watch(gameCooldownBypassedProvider);

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.loyaltyPoints)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            LoyaltyPointsBanner(
              signedIn: signedIn,
              points: pointsAsync.valueOrNull,
              loading: signedIn &&
                  pointsAsync.valueOrNull == null &&
                  pointsAsync.isLoading,
              error: pointsAsync.hasError,
              onRetry: () =>
                  ref.read(loyaltyPointsProvider.notifier).refresh(),
            ),
            if (signedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const Key('redeem-points'),
                    onPressed: () => showRedeemPointsDialog(context, ref),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: Text(
                      l10n.redeemPoints,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            if (canRedeemForCustomers)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    key: const Key('scan-customer-code'),
                    onPressed: () => context.push(AppRoutes.cashierScan),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      l10n.scanCustomerCode,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l10n.rewardsGamesTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.rewardsGamesSubtitle,
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ),
            _GameCard(
              title: l10n.luckyWheel,
              subtitle: l10n.rewardsWheelCardSubtitle,
              icon: Icons.casino_rounded,
              colors: const [Color(0xFFFFB300), Color(0xFFFF6D00)],
              locked: !bypassCooldown &&
                  ref.watch(gamePlayedTodayProvider(DailyGameId.wheel)),
              countdown:
                  ref.watch(gameUnlockCountdownProvider(DailyGameId.wheel)),
              onTap: () => context.push(AppRoutes.wheelGame),
            ),
            _GameCard(
              title: l10n.puzzleGame,
              subtitle: l10n.rewardsPuzzleCardSubtitle,
              icon: Icons.extension_rounded,
              colors: const [AppColors.primary, Color(0xFF1A6BB5)],
              locked: !bypassCooldown &&
                  ref.watch(gamePlayedTodayProvider(DailyGameId.puzzle)),
              countdown:
                  ref.watch(gameUnlockCountdownProvider(DailyGameId.puzzle)),
              onTap: () => context.push(AppRoutes.puzzle),
            ),
            _GameCard(
              title: l10n.scratchCardTitle,
              subtitle: l10n.scratchCardSubtitle,
              icon: Icons.confirmation_number_rounded,
              colors: const [Color(0xFF78909C), Color(0xFF455A64)],
              locked: !bypassCooldown &&
                  ref.watch(gamePlayedTodayProvider(DailyGameId.scratch)),
              countdown:
                  ref.watch(gameUnlockCountdownProvider(DailyGameId.scratch)),
              onTap: () => context.push(AppRoutes.scratchCard),
            ),
            _GameCard(
              title: l10n.luckyChestTitle,
              subtitle: l10n.luckyChestSubtitle,
              icon: Icons.inventory_2_rounded,
              colors: const [Color(0xFFFFB300), Color(0xFFE65100)],
              locked: !bypassCooldown &&
                  ref.watch(gamePlayedTodayProvider(DailyGameId.chest)),
              countdown:
                  ref.watch(gameUnlockCountdownProvider(DailyGameId.chest)),
              onTap: () => context.push(AppRoutes.luckyChest),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.locked = false,
    this.countdown = '',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool locked;
  final String countdown;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: palette.card,
        elevation: 0,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: locked
              ? () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.gameLockedUntilTomorrow(countdown)),
                      ),
                    );
                }
              : onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.imageBackdrop),
            ),
            child: Opacity(
              opacity: locked ? 0.55 : 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: colors,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        locked ? Icons.lock_clock_rounded : icon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locked
                                ? l10n.gameLockedUntilTomorrow(countdown)
                                : subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: locked
                                  ? AppColors.secondary
                                  : palette.muted,
                              fontWeight:
                                  locked ? FontWeight.w800 : FontWeight.w500,
                              fontFeatures: locked
                                  ? const [FontFeature.tabularFigures()]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      locked
                          ? Icons.timer_outlined
                          : Icons.chevron_left_rounded,
                      color: palette.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
