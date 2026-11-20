import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/main_categories.dart';
import '../category_labels.dart';
import 'main_category_image.dart';

/// Side menu of the main categories; picking one opens its products.
class CategoriesDrawer extends StatelessWidget {
  const CategoriesDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DrawerHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: MainCategories.all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final category = MainCategories.all[index];
                return _DrawerCategoryTile(
                  category: category,
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.push(AppRoutes.category(category.id));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadiusDirectional.only(
          bottomEnd: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: AppColors.onPrimary,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.categories,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.categoriesDrawerTagline,
            style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _DrawerCategoryTile extends StatelessWidget {
  const _DrawerCategoryTile({required this.category, required this.onTap});

  final MainCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: mainCategoryDecoration(
                  category,
                  borderRadius: BorderRadius.circular(14),
                  backdrop: palette.imageBackdrop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizedCategoryName(
                    AppLocalizations.of(context)!,
                    category.name,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
