import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';

/// Amber loyalty pill shown opposite the delivery ETA on Home.
class LoyaltyPointsBadge extends ConsumerWidget {
  const LoyaltyPointsBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final points = ref.watch(loyaltyPointsProvider).valueOrNull ?? 0;
    final label = points > 0
        ? l10n.loyaltyPointsRedeem(points)
        : l10n.loyaltyPointsEarnNow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.rewards),
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF4D6),
                Color(0xFFFFE0A3),
                Color(0xFFFFC857),
              ],
            ),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFE8A317).withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE8A317).withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: Color(0xFFB7791F),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.palette.isDark
                          ? const Color(0xFF5C3B00)
                          : const Color(0xFF7A4E00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
