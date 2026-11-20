import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../domain/entities/saved_card.dart';
import '../providers/wallet_providers.dart';
import 'bank_card_view.dart';
import 'card_form_fields.dart';
import 'card_input_formatters.dart';

Future<void> showAddCardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.card,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const AddCardSheet(),
  );
}

class AddCardSheet extends ConsumerStatefulWidget {
  const AddCardSheet({super.key});

  @override
  ConsumerState<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<AddCardSheet> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _holder = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final controller in [_number, _expiry, _holder]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in [_number, _expiry, _cvv, _holder]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _digits => CardValidators.digitsOf(_number.text);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final digits = _digits;
    final id = 'card_${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(savedCardsProvider.notifier).add(
          SavedCard(
            id: id,
            last4: digits.substring(digits.length - 4),
            brand: CardBrand.fromNumber(digits),
            holderName: _holder.text.trim(),
            expiry: _expiry.text,
            token: id,
          ),
          cvv: _cvv.text.trim(),
          pan: digits,
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    TextInput.finishAutofillContext(shouldSave: true);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.walletCardSaved),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final digits = _digits;
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.addBankCard,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BankCardView(
                  brand: CardBrand.fromNumber(digits),
                  number: _number.text,
                  holderName: _holder.text,
                  expiry: _expiry.text,
                ),
                const SizedBox(height: 20),
                CardLtrField(
                  controller: _number,
                  label: l10n.cardNumber,
                  hint: '0000 0000 0000 0000',
                  icon: Icons.credit_card_rounded,
                  formatters: const [CardNumberFormatter()],
                  validator: CardValidators.number,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.creditCardNumber],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CardLtrField(
                        controller: _expiry,
                        label: l10n.expiryDate,
                        hint: 'MM/YY',
                        icon: Icons.event_rounded,
                        formatters: const [ExpiryDateFormatter()],
                        validator: CardValidators.expiry,
                        keyboardType: TextInputType.datetime,
                        autofillHints: const [
                          AutofillHints.creditCardExpirationDate,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CardLtrField(
                        controller: _cvv,
                        label: 'CVV',
                        hint: '123',
                        icon: Icons.lock_outline_rounded,
                        obscure: true,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: CardValidators.cvv,
                        keyboardType: TextInputType.number,
                        autofillHints: const [
                          AutofillHints.creditCardSecurityCode,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _holder,
                  keyboardType: TextInputType.name,
                  autofillHints: const [
                    AutofillHints.creditCardName,
                    AutofillHints.name,
                  ],
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: l10n.cardholderName,
                    hintText: l10n.asWrittenOnCard,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: CardValidators.holder,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.walletCardDataProtected,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(l10n.walletSaveCard),
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
