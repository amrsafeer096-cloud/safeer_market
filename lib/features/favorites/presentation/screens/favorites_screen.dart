import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../providers/favorites_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(
          title: Text(l10n.favoriteProducts),
          actions: const [CartIconButton()],
        ),
        body: ref.watch(isSignedInProvider)
            ? const _FavoritesBody()
            : _FavoritesMessage(
                icon: Icons.favorite_border_rounded,
                title: l10n.favoritesSignInPrompt,
                actionLabel: l10n.signIn,
                onAction: () => context.push(AppRoutes.auth),
              ),
      ),
    );
  }
}

class _FavoritesBody extends ConsumerWidget {
  const _FavoritesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(favoriteProductsProvider);
    // Hearts toggled off here disappear immediately, without a refetch.
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: () => Future.wait([
        ref.refresh(favoriteProductsProvider.future),
        ref.refresh(favoriteIdsProvider.future),
      ]),
      child: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FavoritesMessage(
          icon: Icons.wifi_off_rounded,
          title: l10n.favoritesLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(favoriteProductsProvider),
        ),
        data: (allProducts) {
          final products = shownProducts(
            ref,
            favoriteIds == null
                ? allProducts
                : allProducts.where((p) => favoriteIds.contains(p.id)).toList(),
          );

          if (products.isEmpty) {
            return _FavoritesMessage(
              icon: Icons.favorite_border_rounded,
              title: l10n.favoritesEmptyTitle,
              subtitle: l10n.favoritesEmptySubtitle,
              actionLabel: l10n.shopNow,
              onAction: () => goToHomeTab(context, ref),
            );
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onAdd: () => addToCartWithFeedback(context, ref, product),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.muted,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
