import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/sign_in_prompt.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/weight_options.dart';
import '../providers/cart_providers.dart';
import 'weight_picker_sheet.dart';

/// Out-of-stock products are refused with a message, and guests are asked to
/// sign in first. Weight-based products ask for a weight first; nothing is
/// added if the user dismisses that sheet.
/// [onAdding] runs right before the cart changes, so a fly-to-cart flight
/// can be launched ahead of the rebuild. Resolves to whether the product was
/// actually added.
Future<bool> addToCartWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  VoidCallback? onAdding,
}) async {
  final l10n = AppLocalizations.of(context)!;
  if (!product.inStock) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(l10n.productUnavailableNow),
        ),
      );
    return false;
  }
  // Guests browse freely but need an account for a cart.
  if (!await ensureSignedIn(context, ref, message: l10n.guestCartMessage) ||
      !context.mounted) {
    return false;
  }

  final cart = ref.read(cartProvider.notifier);
  final String message;
  if (product.isWeightBased) {
    CartItem? existing;
    for (final item in ref.read(cartProvider)) {
      if (item.product.id == product.id) {
        existing = item;
        break;
      }
    }
    final pick = await showWeightPickerSheet(
      context,
      product: product,
      initialGrams: existing?.selectedWeightInGrams,
      initialNotes: existing?.notes,
    );
    if (pick == null || !context.mounted) return false;
    onAdding?.call();
    cart.setWeight(product, pick.grams, notes: pick.notes);
    message = l10n.cartAddedWeightOfProduct(
      WeightOptions.label(pick.grams),
      product.name,
    );
  } else {
    onAdding?.call();
    cart.add(product);
    message = l10n.cartAddedProduct(product.name);
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        // A SnackBar with an action persists until swiped by default.
        persist: false,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6EE7A8)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: l10n.viewCart,
          textColor: Colors.white,
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ),
    );
  return true;
}
