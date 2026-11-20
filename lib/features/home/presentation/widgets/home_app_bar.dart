import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/store_location.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/barcode_scan_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../addresses/presentation/providers/addresses_providers.dart';
import '../../../addresses/presentation/widgets/address_picker_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../providers/home_providers.dart';
import 'home_quick_actions.dart' show loopUnlessReducedMotion;
import 'loyalty_points_badge.dart';

/// Text colours for the header.
class _Ink {
  _Ink.of(BuildContext context)
      : strong = context.palette.onSurface,
        soft = context.palette.isDark
            ? context.palette.muted
            : const Color(0xFF8A919C),
        line = context.palette.isDark
            ? context.palette.border
            : const Color(0xFFE3E6EB);

  final Color strong;
  final Color soft;
  final Color line;
}

/// The home header: a soft premium gradient surface with the menu, logo,
/// delivery-address pill, notifications and account, a floating search bar
/// and the animated delivery-time badge.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.onNotificationsTap,
    required this.onSearchTap,
    required this.onScanTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onSearchTap;
  final VoidCallback onScanTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final ink = _Ink.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.isDark ? palette.surface : const Color(0xFFF3F7FC),
            palette.card,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l10n.categories,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(
                    Icons.menu_rounded,
                    color: ink.strong,
                    size: 26,
                  ),
                ),
                const AppLogo(size: 34),
                const SizedBox(width: 10),
                const Expanded(child: _DeliveryAddressHeader()),
                _NotificationsAction(onTap: onNotificationsTap),
                const _AccountAction(),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _SearchBar(onTap: onSearchTap, onScan: onScanTap),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10, 10, 10, 0),
              child: _DeliveryAndLoyaltyRow(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Looks like a search field; opens the search tab, where typing happens.
/// Floats on a soft shadow with the barcode scanner on an accent chip.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.onScan});

  final VoidCallback onTap;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final ink = _Ink.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: ink.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: palette.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.homeSearchHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: ink.soft,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Material(
                    color: palette.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                    child: IconButton(
                      tooltip: l10n.scanBarcode,
                      onPressed: onScan,
                      icon: BarcodeScanIcon(
                        size: 22,
                        color: palette.accent,
                      ),
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

class _DeliveryAddressHeader extends ConsumerWidget {
  const _DeliveryAddressHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final selected = ref.watch(selectedAddressProvider);
    final fee = switch (ref.watch(deliveryQuoteProvider)) {
      DeliveryAvailable(:final fee) => ' · ${AppCurrency.of(fee)}',
      _ => '',
    };
    final l10n = AppLocalizations.of(context)!;
    final ink = _Ink.of(context);

    return Material(
      color: context.palette.card.withValues(alpha: 0.7),
      shape: StadiumBorder(side: BorderSide(color: ink.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => signedIn
            ? showAddressPickerSheet(context)
            : context.push(AppRoutes.auth),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 8, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeDeliveringTo(StoreLocation.city),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: ink.soft,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      selected == null
                          ? l10n.homeChooseYourAddress
                          : '${selected.title}$fee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ink.strong,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: ink.strong,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bell, with a red dot while there are notifications the user hasn't
/// opened «الإشعارات» to see.
class _NotificationsAction extends ConsumerWidget {
  const _NotificationsAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(hasUnreadNotificationsProvider);
    return IconButton(
      key: const Key('home-notifications'),
      tooltip: AppLocalizations.of(context)!.homeNotificationsTooltip,
      onPressed: onTap,
      icon: Badge(
        key: const Key('home-notifications-dot'),
        isLabelVisible: unread,
        smallSize: 8,
        backgroundColor: AppColors.secondary,
        child: Icon(
          unread
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          color: _Ink.of(context).strong,
          size: 26,
        ),
      ),
    );
  }
}

class _AccountAction extends ConsumerWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final ink = _Ink.of(context);
    if (ref.watch(isSignedInProvider)) {
      return IconButton(
        tooltip: l10n.homeMyAccountTooltip,
        onPressed: () =>
            ref.read(homeTabIndexProvider.notifier).state = moreTabIndex,
        icon: CircleAvatar(
          radius: 16,
          backgroundColor:
              palette.isDark ? palette.surface : const Color(0xFFE8EEF6),
          child: Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: ink.strong,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: TextButton(
        onPressed: () async {
          final signedIn = await context.push<bool>(AppRoutes.auth);
          if ((signedIn ?? false) && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.homeSignedInSuccessfully)),
              );
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 34),
          shape: StadiumBorder(side: BorderSide(color: ink.line)),
        ),
        child: Text(
          l10n.signIn,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Loyalty on the physical left, delivery ETA on the physical right.
class _DeliveryAndLoyaltyRow extends StatelessWidget {
  const _DeliveryAndLoyaltyRow();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: LoyaltyPointsBadge(),
            ),
          ),
          SizedBox(width: 8),
          Flexible(child: _DeliveryBadge()),
        ],
      ),
    );
  }
}

/// Green «⚡ توصيل خلال 30 - 45 دقيقة» pill whose bolt gently pulses (still
/// when motion is off).
class _DeliveryBadge extends ConsumerStatefulWidget {
  const _DeliveryBadge();

  @override
  ConsumerState<_DeliveryBadge> createState() => _DeliveryBadgeState();
}

class _DeliveryBadgeState extends ConsumerState<_DeliveryBadge>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _glow = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loopUnlessReducedMotion(context, ref, _pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) => Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success
                    .withValues(alpha: 0.10 + 0.18 * _glow.value),
                blurRadius: 8 + 6 * _glow.value,
              ),
            ],
          ),
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: AppColors.success),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.homeDeliveryEta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
