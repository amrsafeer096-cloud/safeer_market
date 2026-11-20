import 'package:flutter/material.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/weight_options.dart';

/// Asks how many grams of a weight-based [product] to put in the cart.
/// Resolves to null when the sheet is dismissed.
Future<int?> showWeightPickerSheet(
  BuildContext context, {
  required Product product,
  int? initialGrams,
  String? title,
  String Function(int grams)? labelFor,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => WeightPickerSheet(
      product: product,
      initialGrams: initialGrams,
      title: title,
      labelFor: labelFor,
    ),
  );
}

class WeightPickerSheet extends StatefulWidget {
  const WeightPickerSheet({
    super.key,
    required this.product,
    this.initialGrams,
    this.title,
    this.labelFor,
  });

  final Product product;

  /// The weight already in the cart, if any.
  final int? initialGrams;

  /// Defaults to [AppLocalizations.chooseWeight].
  final String? title;

  /// Chip label; defaults to [WeightOptions.label].
  final String Function(int grams)? labelFor;

  @override
  State<WeightPickerSheet> createState() => _WeightPickerSheetState();
}

class _WeightPickerSheetState extends State<WeightPickerSheet> {
  late int _grams = widget.initialGrams ?? WeightOptions.defaultGrams;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isUpdate = widget.initialGrams != null;
    final options = {...WeightOptions.presetsInGrams, _grams}.toList()..sort();
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title ?? l10n.chooseWeight,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              product.name.isEmpty ? l10n.product : product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              l10n.pricePerKilo(AppCurrency.of(product.effectivePrice)),
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grams in options)
                  ChoiceChip(
                    label: Text(
                      (widget.labelFor ?? WeightOptions.label)(grams),
                    ),
                    selected: grams == _grams,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: palette.card,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: grams == _grams
                          ? AppColors.onPrimary
                          : palette.onSurface,
                    ),
                    side: BorderSide(
                      color: palette.accent.withValues(alpha: 0.15),
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (_) => setState(() => _grams = grams),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.weightPickerPrice,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  AppCurrency.of(
                    WeightOptions.priceFor(product.effectivePrice, _grams),
                  ),
                  key: const Key('weight-sheet-price'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_grams),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(isUpdate ? l10n.updateWeight : l10n.addToCart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
