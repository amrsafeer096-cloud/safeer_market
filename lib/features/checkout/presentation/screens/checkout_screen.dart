import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/audio/app_sound_service.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../addresses/presentation/providers/addresses_providers.dart';
import '../../../addresses/presentation/screens/add_address_screen.dart';
import '../../../addresses/presentation/widgets/address_card.dart';
import '../../../addresses/presentation/widgets/address_picker_sheet.dart';
import '../../../addresses/presentation/widgets/pin_address_on_map.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../wallet/domain/entities/saved_card.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../domain/checkout_pricing.dart';
import '../../domain/delivery_pricing.dart';
import '../../domain/instapay_details.dart';
import '../../domain/payment_method.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../providers/checkout_providers.dart';
import 'payment_screen.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = ref.watch(cartProvider.select((items) => items.isEmpty));

    ref.listen(checkoutControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final error = next.error;
        final message =
            error is CheckoutFailure ? error.message : l10n.unexpectedError;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.secondary,
              content: Text(l10n.checkoutOrderFailed(message)),
            ),
          );
      }
    });

    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(title: Text(l10n.checkoutTitle)),
        bottomNavigationBar: isEmpty
            ? null
            : _ConfirmBar(onConfirm: () => _confirm(context, ref)),
        body: isEmpty
            ? const _EmptyCheckout()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Section(
                    icon: Icons.location_on_rounded,
                    title: l10n.checkoutDeliveryAddress,
                    trailing: const _ManageAddressesButton(),
                    child: const _DeliveryAddressSection(),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    icon: Icons.payments_rounded,
                    title: l10n.checkoutPaymentMethod,
                    child: const _PaymentMethodSelector(),
                  ),
                  const SizedBox(height: 16),
                  const _EstimatedArrival(),
                  const SizedBox(height: 16),
                  _Section(
                    icon: Icons.receipt_long_rounded,
                    title: l10n.checkoutOrderSummary,
                    child: const _OrderSummary(),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    if (!ref.read(isSignedInProvider)) {
      await context.push<bool>(AppRoutes.auth);
      return;
    }

    final address = ref.read(selectedAddressProvider);
    if (address == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkoutSelectAddressFirst)),
      );
      await showAddressPickerSheet(context);
      return;
    }

    switch (ref.read(deliveryQuoteProvider)) {
      case DeliveryAvailable():
        break;
      case DeliveryOutOfRange(:final distanceKm):
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(_outOfRangeMessage(l10n, distanceKm)),
          ),
        );
        return;
      case DeliveryLocationMissing() || null:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.checkoutPinLocationForFee)),
        );
        await pinAddressOnMap(context, ref, address);
        return;
    }

    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final total = ref.read(checkoutTotalProvider);

    // Card / Visa: create the order first (pending), then open Paymob from
    // the payment screen so the webhook can mark it paid.
    if (paymentMethod == PaymentMethod.card) {
      final orderId =
          await ref.read(checkoutControllerProvider.notifier).placeOrder(
                address,
                paymentMethod: paymentMethod,
                clearCart: false,
                paymentStatus: 'pending',
                paymentMethodOverride: 'visa',
              );
      if (orderId == null) return;
      if (!context.mounted) return;

      final paid = await context.push<bool>(
        AppRoutes.payment,
        extra: PaymentRouteArgs(
          amount: total,
          savedCard: ref.read(selectedCheckoutCardProvider),
          orderId: orderId,
        ),
      );
      // Back-out or failed Paymob: order stays pending/unpaid; cart kept.
      if (paid != true || !context.mounted) return;
      ref.read(checkoutControllerProvider.notifier).clearCart();
      _showPlaced(context, ref, messenger, l10n, orderId);
      return;
    }

    // InstaPay: require a transfer screenshot, then await admin verification.
    if (paymentMethod == PaymentMethod.instaPay) {
      final receipt = ref.read(instaPayReceiptProvider);
      if (receipt == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.instaPayReceiptRequired)),
        );
        return;
      }
      final orderId =
          await ref.read(checkoutControllerProvider.notifier).placeOrder(
                address,
                paymentMethod: paymentMethod,
                paymentStatus: 'pending_verification',
                paymentMethodOverride: 'instapay',
                receipt: receipt,
              );
      if (orderId == null || !context.mounted) return;
      _showPlaced(context, ref, messenger, l10n, orderId);
      return;
    }

    final orderId =
        await ref.read(checkoutControllerProvider.notifier).placeOrder(
              address,
              paymentMethod: paymentMethod,
            );
    if (orderId == null) return;
    _showPlaced(context, ref, messenger, l10n, orderId);
  }
}

void _showPlaced(
  BuildContext context,
  WidgetRef ref,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  String orderId,
) {
  final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
  AppSoundService.instance.playOrderSuccess();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l10n.checkoutOrderPlaced(shortId)),
          ),
        ],
      ),
    ),
  );
  if (context.mounted) goToHomeTab(context, ref);
}

String _outOfRangeMessage(AppLocalizations l10n, double distanceKm) =>
    l10n.checkoutOutOfRange(
      DeliveryPricing.formatDistance(distanceKm),
      DeliveryPricing.formatDistance(DeliveryPricing.maxDistanceKm),
    );

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ManageAddressesButton extends ConsumerWidget {
  const _ManageAddressesButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSignedInProvider)) return const SizedBox.shrink();
    return TextButton(
      onPressed: () => context.push(AppRoutes.addresses),
      child: Text(AppLocalizations.of(context)!.manageAddresses),
    );
  }
}

class _DeliveryAddressSection extends ConsumerWidget {
  const _DeliveryAddressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(isSignedInProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);

    if (!signedIn) {
      return _AddressPrompt(message: l10n.checkoutSignInToChooseAddress);
    }
    if (selected != null) {
      final notice = switch (ref.watch(deliveryQuoteProvider)) {
        DeliveryLocationMissing() => (
            message: l10n.checkoutPinThisAddressForFee,
            action: l10n.checkoutPinLocation,
          ),
        DeliveryOutOfRange(:final distanceKm) => (
            message: _outOfRangeMessage(l10n, distanceKm),
            action: l10n.editLocation,
          ),
        _ => null,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddressCard(
            address: selected,
            selected: true,
            onTap: () => showAddressPickerSheet(context),
            trailing: TextButton(
              onPressed: () => showAddressPickerSheet(context),
              child: Text(l10n.checkoutChangeAddress),
            ),
          ),
          if (notice != null) ...[
            const SizedBox(height: 8),
            _AddressPrompt(
              message: notice.message,
              actionLabel: notice.action,
              onAction: () => pinAddressOnMap(context, ref, selected),
            ),
          ],
        ],
      );
    }
    if (addressesAsync.isLoading && !addressesAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (addressesAsync.valueOrNull?.isEmpty ?? true) {
      return _AddressPrompt(
        message: l10n.checkoutAddDeliveryAddress,
        actionLabel: l10n.checkoutAddAddress,
        onAction: () async {
          final address = await openAddAddress(context);
          if (address != null) {
            ref.read(selectedAddressIdProvider.notifier).state = address.id;
          }
        },
      );
    }
    return _AddressPrompt(
      message: l10n.checkoutNoAddressChosen,
      actionLabel: l10n.checkoutChooseAddress,
      onAction: () => showAddressPickerSheet(context),
    );
  }
}

class _AddressPrompt extends StatelessWidget {
  const _AddressPrompt({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_location_alt_outlined,
              color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null)
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends ConsumerWidget {
  const _PaymentMethodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(selectedPaymentMethodProvider);
    final savedCards = ref.watch(savedCardsProvider);
    final selectedCard = ref.watch(selectedCheckoutCardProvider);

    return Column(
      children: [
        for (final method in PaymentMethod.values) ...[
          _PaymentOption(
            leading: _paymentLeading(method),
            label: method.labelOf(l10n),
            subtitle: method.subtitleOf(l10n),
            selected: method == selected,
            onTap: () {
              ref.read(selectedPaymentMethodProvider.notifier).state = method;
              if (method != PaymentMethod.instaPay) {
                ref.read(instaPayReceiptProvider.notifier).state = null;
              }
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: method == PaymentMethod.card &&
                    selected == PaymentMethod.card
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _CheckoutSavedCards(
                        key: ValueKey(
                          selectedCard?.id ?? 'new-card',
                        ),
                        cards: savedCards,
                        selectedCard: selectedCard,
                        onSelect: (card) => ref
                            .read(selectedCheckoutCardProvider.notifier)
                            .state = card,
                        onAddNew: () => ref
                            .read(selectedCheckoutCardProvider.notifier)
                            .state = null,
                      ),
                    ),
                  )
                : method == PaymentMethod.instaPay &&
                        selected == PaymentMethod.instaPay
                    ? const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: _InstaPayDetailsCard(),
                      )
                    : const SizedBox.shrink(),
          ),
          if (method != PaymentMethod.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _paymentLeading(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cashOnDelivery => const Icon(Icons.payments_outlined),
      PaymentMethod.card => const Icon(Icons.credit_card_rounded),
      PaymentMethod.instaPay => const _InstaPayBadge(),
    };
  }
}

class _CheckoutSavedCards extends StatelessWidget {
  const _CheckoutSavedCards({
    super.key,
    required this.cards,
    required this.selectedCard,
    required this.onSelect,
    required this.onAddNew,
  });

  final List<SavedCard> cards;
  final SavedCard? selectedCard;
  final ValueChanged<SavedCard?> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cards.isNotEmpty) ...[
            Text(
              l10n.checkoutSavedCards,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 6),
            for (final card in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SavedCardRadio(
                  label: card.maskedLabel,
                  subtitle: '${card.holderName} · ${card.expiry}',
                  selected: selectedCard?.id == card.id,
                  onTap: () => onSelect(card),
                ),
              ),
          ],
          _SavedCardRadio(
            label: l10n.checkoutUseOrAddNewCard,
            selected: selectedCard == null,
            onTap: onAddNew,
            accent: true,
          ),
        ],
      ),
    );
  }
}

class _SavedCardRadio extends StatelessWidget {
  const _SavedCardRadio({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.accent = false,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.muted;

    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.06) : palette.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : palette.muted.withValues(alpha: 0.2),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      textDirection: accent ? null : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: accent && selected
                            ? palette.accent
                            : palette.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 11.5, color: palette.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final Widget leading;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.muted;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? palette.accent.withValues(alpha: 0.06) : palette.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? palette.accent
                    : palette.muted.withValues(alpha: 0.25),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 24),
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstaPayBadge extends StatelessWidget {
  const _InstaPayBadge();

  @override
  Widget build(BuildContext context) {
    // Transparent official logo — no box, border, or fill behind it.
    return Image.asset(
      InstaPayDetails.logoAsset,
      height: 32,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _InstaPayDetailsCard extends ConsumerWidget {
  const _InstaPayDetailsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final receipt = ref.watch(instaPayReceiptProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A2D82).withValues(alpha: 0.25),
        ),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF5A2D82).withValues(alpha: 0.06),
            const Color(0xFFF37021).withValues(alpha: 0.05),
            palette.card,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                // Silent backup copy before opening InstaPay.
                await Clipboard.setData(
                  const ClipboardData(text: InstaPayDetails.ipa),
                );
                final uri = Uri.parse(InstaPayDetails.deepLink);
                final ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.paymentPageOpenFailed)),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A2D82),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                l10n.instaPayOpenApp,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.instaPayReceiptTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.instaPayReceiptHint,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (receipt == null)
            _InstaPayReceiptPicker(
              onPick: () => _pickInstaPayReceipt(context, ref),
            )
          else
            _InstaPayReceiptPreview(
              bytes: receipt.bytes,
              onClear: () =>
                  ref.read(instaPayReceiptProvider.notifier).state = null,
              onReplace: () => _pickInstaPayReceipt(context, ref),
            ),
        ],
      ),
    );
  }
}

class _InstaPayReceiptPicker extends StatelessWidget {
  const _InstaPayReceiptPicker({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final accent = const Color(0xFF5A2D82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: accent.withValues(alpha: 0.45),
            radius: 14,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, color: accent, size: 28),
                const SizedBox(height: 8),
                Text(
                  l10n.instaPayReceiptPick,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
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

class _InstaPayReceiptPreview extends StatelessWidget {
  const _InstaPayReceiptPreview({
    required this.bytes,
    required this.onClear,
    required this.onReplace,
  });

  final Uint8List bytes;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Stack(
      children: [
        GestureDetector(
          onTap: onReplace,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: Material(
            color: palette.card.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Future<void> _pickInstaPayReceipt(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhotoWithCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
  if (source == null || !context.mounted) return;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) return;
    final name = picked.name.trim().isEmpty
        ? 'instapay_receipt.jpg'
        : picked.name.trim();
    final lower = name.toLowerCase();
    final contentType = switch (null) {
      _ when lower.endsWith('.png') => 'image/png',
      _ when lower.endsWith('.webp') => 'image/webp',
      _ when lower.endsWith('.gif') => 'image/gif',
      _ when lower.endsWith('.heic') => 'image/heic',
      _ => 'image/jpeg',
    };
    ref.read(instaPayReceiptProvider.notifier).state = InstaPayReceiptDraft(
      bytes: Uint8List.fromList(bytes),
      fileName: name,
      contentType: contentType,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cameraOpenFailed)),
    );
  }
}

class _EstimatedArrival extends ConsumerStatefulWidget {
  const _EstimatedArrival();

  @override
  ConsumerState<_EstimatedArrival> createState() => _EstimatedArrivalState();
}

class _EstimatedArrivalState extends ConsumerState<_EstimatedArrival> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // Keeps the estimate current while the customer lingers on this screen.
    _tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final arrival = CheckoutPricing.estimatedArrival(now);
    final timeFormat =
        DateFormat('h:mm a', Localizations.localeOf(context).languageCode)
          ..useNativeDigits = false;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.checkoutEstimatedArrival,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            timeFormat.format(arrival),
            key: const Key('estimated-arrival'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends ConsumerWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(cartItemCountProvider);
    final itemsTotal = ref.watch(cartTotalProvider);
    final total = ref.watch(checkoutTotalProvider);
    final (feeLabel, feeValue, feePending) =
        switch (ref.watch(deliveryQuoteProvider)) {
      DeliveryAvailable(:final distanceKm, :final fee) => (
          l10n.checkoutDeliveryFeeWithDistance(
            DeliveryPricing.formatDistance(distanceKm),
          ),
          AppCurrency.of(fee),
          false,
        ),
      DeliveryOutOfRange() => (
          l10n.deliveryFee,
          l10n.checkoutOutOfDeliveryRange,
          true,
        ),
      DeliveryLocationMissing() => (
          l10n.deliveryFee,
          l10n.checkoutPinLocation,
          true,
        ),
      null => (l10n.deliveryFee, l10n.checkoutChooseAddress, true),
    };

    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SummaryRow(label: l10n.checkoutItemCount, value: '$count'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: l10n.checkoutSubtotal,
            value: AppCurrency.of(itemsTotal),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: feeLabel,
            value: feeValue,
            highlight: feePending,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.checkoutGrandTotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                AppCurrency.of(total),
                key: const Key('checkout-total'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: context.palette.muted),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.secondary : null,
          ),
        ),
      ],
    );
  }
}

class _ConfirmBar extends ConsumerWidget {
  const _ConfirmBar({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(checkoutControllerProvider).isLoading;
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);
    final hasReceipt = ref.watch(instaPayReceiptProvider) != null;
    final instaPayBlocked =
        paymentMethod == PaymentMethod.instaPay && !hasReceipt;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: isSubmitting
                ? null
                : () {
                    if (instaPayBlocked) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!
                                  .instaPayReceiptRequired,
                            ),
                          ),
                        );
                      return;
                    }
                    onConfirm();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor:
                  AppColors.secondary.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.checkoutConfirmOrder,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: instaPayBlocked
                              ? Colors.white.withValues(alpha: 0.75)
                              : null,
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

class _EmptyCheckout extends ConsumerWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 54,
              color: context.palette.accent,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cartEmpty,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => goToHomeTab(context, ref),
              child: Text(l10n.shopNow),
            ),
          ],
        ),
      ),
    );
  }
}
