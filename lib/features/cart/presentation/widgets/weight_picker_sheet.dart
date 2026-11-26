import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/weight_options.dart';

/// Asks how many grams of a weight-based [product] to put in the cart.
/// Resolves to null when the sheet is dismissed.
Future<WeightSelection?> showWeightPickerSheet(
  BuildContext context, {
  required Product product,
  int? initialGrams,
  String? initialNotes,
  String? title,
  String Function(int grams)? labelFor,
}) {
  return showModalBottomSheet<WeightSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      // Keep the sheet above the keyboard when «تخصيص وزن» is open.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: WeightPickerSheet(
        product: product,
        initialGrams: initialGrams,
        initialNotes: initialNotes,
        title: title,
        labelFor: labelFor,
      ),
    ),
  );
}

class WeightPickerSheet extends StatefulWidget {
  const WeightPickerSheet({
    super.key,
    required this.product,
    this.initialGrams,
    this.initialNotes,
    this.title,
    this.labelFor,
  });

  final Product product;

  /// The weight already in the cart, if any.
  final int? initialGrams;

  /// Optional existing item note to edit.
  final String? initialNotes;

  /// Defaults to [AppLocalizations.chooseWeight].
  final String? title;

  /// Chip label; defaults to [WeightOptions.label].
  final String Function(int grams)? labelFor;

  @override
  State<WeightPickerSheet> createState() => _WeightPickerSheetState();
}

enum _WeightUnit { kilo, gram }

class _WeightPickerSheetState extends State<WeightPickerSheet> {
  late int _grams = widget.initialGrams ?? WeightOptions.defaultGrams;
  var _customMode = false;
  var _unit = _WeightUnit.kilo;
  final _customCtrl = TextEditingController();
  final _customFocus = FocusNode();
  late final _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGrams;
    if (initial != null &&
        !WeightOptions.presetsInGrams.contains(initial)) {
      _customMode = true;
      _unit = initial % 1000 == 0 ? _WeightUnit.kilo : _WeightUnit.gram;
      _customCtrl.text = _unit == _WeightUnit.kilo
          ? WeightOptions.kgOf(initial)
              .toStringAsFixed(WeightOptions.maxKgDecimals)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '')
          : '$initial';
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _customFocus.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int? get _effectiveGrams {
    if (!_customMode) return _grams;
    return WeightOptions.parseCustomGrams(
      _customCtrl.text,
      inKilos: _unit == _WeightUnit.kilo,
    );
  }

  bool get _canSubmit {
    final g = _effectiveGrams;
    return g != null && g > 0;
  }

  void _selectPreset(int grams) {
    setState(() {
      _customMode = false;
      _grams = grams;
    });
  }

  void _openCustom() {
    setState(() {
      _customMode = true;
      if (_customCtrl.text.trim().isEmpty) {
        _unit = _WeightUnit.kilo;
        _customCtrl.text = WeightOptions.kgOf(_grams)
            .toStringAsFixed(WeightOptions.maxKgDecimals)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _customFocus.requestFocus();
    });
  }

  void _submit() {
    final grams = _effectiveGrams;
    if (grams == null || grams <= 0) return;
    final notes = _notesCtrl.text.trim();
    Navigator.of(context).pop(
      WeightSelection(
        grams: grams,
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isUpdate = widget.initialGrams != null;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final labelFor = widget.labelFor ?? WeightOptions.label;
    final effective = _effectiveGrams;
    final price = effective == null
        ? 0.0
        : WeightOptions.priceFor(product.effectivePrice, effective);

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
                for (final grams in WeightOptions.presetsInGrams)
                  ChoiceChip(
                    label: Text(labelFor(grams)),
                    selected: !_customMode && _grams == grams,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: palette.card,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: (!_customMode && _grams == grams)
                          ? AppColors.onPrimary
                          : palette.onSurface,
                    ),
                    side: BorderSide(
                      color: palette.accent.withValues(alpha: 0.15),
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (_) => _selectPreset(grams),
                  ),
                ChoiceChip(
                  key: const Key('weight-sheet-custom-chip'),
                  avatar: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: _customMode
                        ? AppColors.onPrimary
                        : palette.onSurface,
                  ),
                  label: const Text('تخصيص وزن'),
                  selected: _customMode,
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: palette.card,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _customMode
                        ? AppColors.onPrimary
                        : palette.onSurface,
                  ),
                  side: BorderSide(
                    color: palette.accent.withValues(alpha: 0.15),
                  ),
                  shape: const StadiumBorder(),
                  onSelected: (_) => _openCustom(),
                ),
              ],
            ),
            if (_customMode) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('weight-sheet-custom-input'),
                      controller: _customCtrl,
                      focusNode: _customFocus,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        _WeightInputFormatter(inKilos: _unit == _WeightUnit.kilo),
                      ],
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (_canSubmit) _submit();
                      },
                      decoration: InputDecoration(
                        hintText: _unit == _WeightUnit.kilo
                            ? 'مثال: 1.3'
                            : 'مثال: 125',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<_WeightUnit>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: _WeightUnit.kilo,
                        label: Text('كيلو',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      ButtonSegment(
                        value: _WeightUnit.gram,
                        label: Text('جرام',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                    selected: {_unit},
                    onSelectionChanged: (next) {
                      final unit = next.first;
                      final current = WeightOptions.parseCustomGrams(
                        _customCtrl.text,
                        inKilos: _unit == _WeightUnit.kilo,
                      );
                      setState(() {
                        _unit = unit;
                        if (current != null) {
                          _customCtrl.text = unit == _WeightUnit.kilo
                              ? WeightOptions.kgOf(current)
                                  .toStringAsFixed(
                                      WeightOptions.maxKgDecimals)
                                  .replaceFirst(RegExp(r'0+$'), '')
                                  .replaceFirst(RegExp(r'\.$'), '')
                              : '$current';
                          _customCtrl.selection = TextSelection.collapsed(
                            offset: _customCtrl.text.length,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              key: const Key('weight-sheet-item-notes'),
              controller: _notesCtrl,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'ملاحظة للصنف',
                hintText: 'مثال: على ربعين، تقطيع رفيع...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
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
                  AppCurrency.of(price),
                  key: const Key('weight-sheet-price'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _canSubmit
                        ? AppColors.secondary
                        : palette.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('weight-sheet-submit'),
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.onSecondary,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.35),
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

/// Digits + one decimal point; normalizes Arabic separators/digits as typed.
class _WeightInputFormatter extends TextInputFormatter {
  _WeightInputFormatter({required this.inKilos});

  final bool inKilos;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = WeightOptions.normalizeDecimalInput(newValue.text);
    if (normalized.isEmpty) {
      return newValue.copyWith(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // Allow intermediate "1." while typing.
    if (normalized == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    final parts = normalized.split('.');
    if (parts.length > 2) return oldValue;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(normalized)) return oldValue;

    if (parts.length == 2) {
      final maxDec = inKilos ? WeightOptions.maxKgDecimals : 0;
      if (parts[1].length > maxDec) {
        // Grams mode: no fraction; kilos: cap at 3 decimals.
        if (maxDec == 0) {
          return TextEditingValue(
            text: parts[0],
            selection: TextSelection.collapsed(offset: parts[0].length),
          );
        }
        final clipped = '${parts[0]}.${parts[1].substring(0, maxDec)}';
        return TextEditingValue(
          text: clipped,
          selection: TextSelection.collapsed(offset: clipped.length),
        );
      }
    }

    if (normalized == newValue.text) return newValue;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}
