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
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/weight_options.dart';
import '../providers/cart_providers.dart';
import '../widgets/cart_item_tile.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../subscriptions/presentation/screens/paywall_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(
          title: Text(l10n.cartTitle),
          actions: [
            if (items.isNotEmpty)
              IconButton(
                tooltip: l10n.clearCart,
                onPressed: cart.clear,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
          ],
        ),
        bottomNavigationBar: items.isEmpty
            ? null
            : _CartSummary(onContinue: () => _continue(context, ref)),
        body: items.isEmpty
            ? const _EmptyCart()
            : Column(children: [
                const PremiumUpsellBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final item in items) ...[
                        Dismissible(
                          key: ValueKey(item.product.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cart.remove(item.product.id),
                          background: const _DismissBackground(),
                          child: switch (item.selectedWeightInGrams) {
                            final grams? => CartItemTile(
                                item: item,
                                onIncrement: () => cart.setWeight(
                                  item.product,
                                  WeightOptions.next(grams),
                                ),
                                onDecrement: () => cart.setWeight(
                                  item.product,
                                  WeightOptions.previous(grams),
                                ),
                              ),
                            null => CartItemTile(
                                item: item,
                                onIncrement: () => cart.updateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                                onDecrement: () => cart.updateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                              ),
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ]),
      ),
    );
  }

  /// Guests sign in first, then carry straight on to checkout.
  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!ref.read(isSignedInProvider)) {
      final signedIn = await context.push<bool>(AppRoutes.auth);
      if (!(signedIn ?? false) || !context.mounted) return;
    }
    await context.push(AppRoutes.checkout);
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    final itemsTotal = ref.watch(cartTotalProvider);
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cartSubtotalWithCount('$count'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppCurrency.of(itemsTotal),
                  key: const Key('cart-subtotal'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.cartDeliveryFeeNextStep,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.cartContinueOrder,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.only(end: 24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 54,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.cartEmpty,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cartEmptySubtitle,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => goToHomeTab(context, ref),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.shopNow),
            ),
          ],
        ),
      ),
    );
  }
}

/// «وفر رسوم التوصيل!» — only for users without an active paid plan. Hidden
/// while the plan loads, so subscribers never see it flash.
class PremiumUpsellBanner extends ConsumerWidget {
  const PremiumUpsellBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.hasValue || !subscription.requireValue.isFree()) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => PaywallScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.isDark ? palette.card : const Color(0xFFFFF8E1),
          border: Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.amber.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_outlined,
                  color: Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.cartSaveDeliveryFeesTitle,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: palette.isDark
                              ? palette.onSurface
                              : Colors.black)),
                  const SizedBox(height: 4),
                  Text(l10n.cartPrimeUpsellSubtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              palette.isDark ? palette.muted : Colors.black87)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
