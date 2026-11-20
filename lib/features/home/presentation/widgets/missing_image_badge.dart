import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../providers/product_visibility_provider.dart';

/// «بدون صورة» pill on products whose photo is missing or failed to load;
/// nothing for anyone but admins.
class MissingImageBadge extends ConsumerWidget {
  const MissingImageBadge({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!flagsMissingImage(ref, product)) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hide_image_outlined,
            size: 12,
            color: AppColors.onSecondary,
          ),
          const SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)!.productNoImageBadge,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.onSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
