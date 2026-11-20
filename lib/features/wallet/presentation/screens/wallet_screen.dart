import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/saved_card.dart';
import '../providers/wallet_providers.dart';
import '../widgets/add_card_sheet.dart';

/// [WalletScreen] as a standalone route, opened from Settings.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.savedCards),
        ),
        body: const WalletScreen(),
      ),
    );
  }
}

/// Body of the المحفظة tab; hosted inside the home screen's Scaffold.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(isSignedInProvider);
    final cards = ref.watch(savedCardsProvider);
    final palette = context.palette;

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: () => ref.refresh(walletBalanceProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const _WalletHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(title: l10n.savedCards),
                const SizedBox(height: 12),
                for (final card in cards) ...[
                  _SavedCardTile(card: card),
                  const SizedBox(height: 10),
                ],
                _AddCardButton(
                  onTap: () => signedIn
                      ? showAddCardSheet(context)
                      : context.push(AppRoutes.auth),
                ),
                if (cards.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.walletAddCardHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.wallet,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          const _BalanceCard(),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(isSignedInProvider);
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: context.palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        children: [
          const PositionedDirectional(
            top: -40,
            end: -30,
            child: _Bubble(size: 140, opacity: 0.08),
          ),
          const PositionedDirectional(
            bottom: -50,
            start: -20,
            child: _Bubble(size: 120, opacity: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        l10n.walletInAppBalance,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: !signedIn
                        ? const _GuestBalance()
                        : balanceAsync.when(
                            loading: () => const SizedBox.square(
                              dimension: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            error: (error, _) => TextButton.icon(
                              onPressed: () =>
                                  ref.invalidate(walletBalanceProvider),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.walletBalanceLoadFailed),
                            ),
                            data: (balance) => FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppCurrency.of(balance ?? 0),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.walletBalanceAutoApplied,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBalance extends StatelessWidget {
  const _GuestBalance();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.push(AppRoutes.auth),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        shape: const StadiumBorder(),
      ),
      child: Text(AppLocalizations.of(context)!.walletSignInToViewBalance),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.addBankCard,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const Icon(
                Icons.credit_card_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedCardTile extends ConsumerWidget {
  const _SavedCardTile({required this.card});

  final SavedCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand.label} •••• ${card.last4}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.walletCardExpires(card.expiry),
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.walletDeleteCard,
            onPressed: () => ref.read(savedCardsProvider.notifier).remove(card),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
