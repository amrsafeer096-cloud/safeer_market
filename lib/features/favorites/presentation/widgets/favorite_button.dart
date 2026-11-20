import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/entities/product.dart';
import '../providers/favorites_providers.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoriteIdsProvider.select(
        (ids) => ids.valueOrNull?.contains(product.id) ?? false,
      ),
    );

    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Tooltip(
      message: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
      child: Material(
        color: palette.card.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: palette.isDark ? 0 : 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _toggle(context, ref),
          child: SizedBox.square(
            dimension: 34,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isFavorite),
                size: 20,
                color: isFavorite ? AppColors.secondary : palette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (!ref.read(isSignedInProvider)) {
      messenger.hideCurrentSnackBar();
      final signedIn = await context.push<bool>(AppRoutes.auth);
      if (!(signedIn ?? false)) return;
      // Wait for the new user's favorites so the toggle doesn't undo one.
      await ref.read(favoriteIdsProvider.future);
    }

    try {
      await ref.read(favoriteIdsProvider.notifier).toggle(product.id);
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(l10n.favoritesUpdateFailed),
          ),
        );
    }
  }
}
