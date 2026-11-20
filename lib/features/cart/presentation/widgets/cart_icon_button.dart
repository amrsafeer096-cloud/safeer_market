import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/cart_providers.dart';

class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);

    return IconButton(
      tooltip: AppLocalizations.of(context)!.cart,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        context.push(AppRoutes.cart);
      },
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: AppColors.secondary,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
