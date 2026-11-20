import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../subscriptions/data/paymob_service.dart';
import '../../../subscriptions/domain/subscription.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../wallet/domain/entities/saved_card.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/bank_card_view.dart';
import '../../../wallet/presentation/widgets/card_form_fields.dart';
import '../../../wallet/presentation/widgets/card_input_formatters.dart';
import 'paymob_checkout_webview.dart';

/// Args for [AppRoutes.payment] via `GoRouterState.extra`.
class PaymentRouteArgs {
  const PaymentRouteArgs({
    required this.amount,
    this.savedCard,
    this.orderId,
  });

  final double amount;
  final SavedCard? savedCard;

  /// When set, «ادفع الآن» starts a Paymob checkout for this grocery order.
  final String? orderId;
}

/// Card payment. Pops `true` once paid (Paymob success or mock fallback);
/// any other pop means the customer backed out.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.amount,
    this.initialCard,
    this.orderId,
  });

  static const processingDelay = Duration(milliseconds: 1500);
  static const confirmTimeout = Duration(seconds: 12);
  static const confirmPollInterval = Duration(seconds: 2);

  final double amount;
  final SavedCard? initialCard;
  final String? orderId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _holder = TextEditingController();
  final _cvvFocus = FocusNode();
  bool _processing = false;
  bool _verifying = false;
  SavedCard? _selectedSaved;
  bool _useNewCard = false;
  PaymobCheckout? _checkout;
  AppLifecycleListener? _lifecycle;
  var _awaitingBrowserReturn = false;

  @override
  void initState() {
    super.initState();
    _selectedSaved = widget.initialCard;
    _useNewCard = widget.initialCard == null;
    for (final controller in [_number, _expiry, _holder]) {
      controller.addListener(() => setState(() {}));
    }
    if (widget.initialCard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedCvv(widget.initialCard!);
      });
    }
    _lifecycle = AppLifecycleListener(onResume: _onAppResumed);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    for (final controller in [_number, _expiry, _cvv, _holder]) {
      controller.dispose();
    }
    _cvvFocus.dispose();
    super.dispose();
  }

  /// User closed Paymob / returned without a deep-link success → unblock UI.
  void _onAppResumed() {
    if (!_awaitingBrowserReturn || !mounted) return;
    _awaitingBrowserReturn = false;
    if (_processing || _verifying) {
      setState(() {
        _processing = false;
        _verifying = false;
      });
    }
  }

  void _clearLoading() {
    if (!mounted) return;
    if (_processing || _verifying || _awaitingBrowserReturn) {
      setState(() {
        _processing = false;
        _verifying = false;
        _awaitingBrowserReturn = false;
      });
    }
  }

  Future<void> _loadSavedCvv(SavedCard card) async {
    final cvv = await ref.read(savedCardsProvider.notifier).readCvv(card);
    if (!mounted || cvv == null || cvv.isEmpty) return;
    if (_selectedSaved?.id != card.id || _useNewCard) return;
    _cvv.text = cvv;
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pay() async {
    if (_processing || _verifying) return;

    final usingSaved = !_useNewCard && _selectedSaved != null;
    if (usingSaved) {
      if (CardValidators.cvv(_cvv.text) != null) {
        _formKey.currentState?.validate();
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext(shouldSave: !usingSaved);

    final orderId = widget.orderId;
    if (orderId != null && orderId.isNotEmpty) {
      await _payWithPaymob(orderId);
      return;
    }

    // Tests / fallback when no order is attached yet.
    setState(() => _processing = true);
    await Future<void>.delayed(PaymentScreen.processingDelay);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<PaymobCardAutofill?> _cardAutofill({required bool usingSaved}) async {
    final l10n = AppLocalizations.of(context)!;
    final expiryText = usingSaved
        ? (_selectedSaved?.expiry ?? '')
        : _expiry.text.trim();
    final parts = expiryText.split('/');
    final month = parts.isNotEmpty ? parts.first.padLeft(2, '0') : '';
    final year = parts.length > 1 ? parts[1].padLeft(2, '0') : '';

    String? number;
    if (usingSaved) {
      final saved = _selectedSaved!;
      number = await ref.read(savedCardsProvider.notifier).readPan(saved);
      if (number == null || number.length < 13) {
        // Legacy saved cards only stored last4 — ask to re-enter once.
        _showMessage(l10n.cardNumberRequired);
        setState(() {
          _useNewCard = true;
          _selectedSaved = null;
          _holder.text = saved.holderName;
          _expiry.text = saved.expiry;
        });
        return null;
      }
    } else {
      number = CardValidators.digitsOf(_number.text);
      if (number.length < 13) {
        _showMessage(l10n.cardNumberRequired);
        return null;
      }
      // Persist PAN for this session's typed card so a later "save card"
      // / retry still has the full 16 digits.
      final digits = number;
      final holder = _holder.text.trim();
      final expiry = _expiry.text.trim();
      if (digits.length >= 13 && holder.isNotEmpty && expiry.isNotEmpty) {
        final id =
            'card_pay_${digits.substring(digits.length - 4)}_$expiry';
        await ref.read(savedCardsProvider.notifier).add(
              SavedCard(
                id: id,
                last4: digits.substring(digits.length - 4),
                brand: CardBrand.fromNumber(digits),
                holderName: holder,
                expiry: expiry,
                token: id,
              ),
              cvv: _cvv.text.trim(),
              pan: digits,
            );
      }
    }

    return PaymobCardAutofill(
      number: number,
      holderName: usingSaved
          ? _selectedSaved?.holderName
          : _holder.text.trim(),
      expiryMonth: month.length == 2 ? month : null,
      expiryYear: year.length == 2 ? year : null,
      cvv: _cvv.text.trim(),
    );
  }

  Future<void> _payWithPaymob(String orderId) async {
    final l10n = AppLocalizations.of(context)!;
    final usingSaved = !_useNewCard && _selectedSaved != null;
    final autofill = await _cardAutofill(usingSaved: usingSaved);
    if (autofill == null) {
      _clearLoading();
      return;
    }
    final pan = (autofill.number ?? '').replaceAll(RegExp(r'\D'), '');
    if (pan.length < 13) {
      _showMessage(l10n.cardNumberRequired);
      _clearLoading();
      return;
    }
    setState(() {
      _processing = true;
      _awaitingBrowserReturn = false;
    });
    try {
      // Always generate a payment key then open the Accept iframe WebView.
      final checkout =
          await ref.read(paymobServiceProvider).createOrderCheckout(
                orderId: orderId,
              );
      if (!mounted) return;
      _checkout = checkout;

      final paymentUrl = checkout.paymentUrl;
      if (paymentUrl == null) {
        _showMessage(l10n.paymentFailedMessage);
        return;
      }

      _awaitingBrowserReturn = true;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PaymobCheckoutWebView(
            paymentUrl: paymentUrl,
            autofill: autofill,
          ),
        ),
      );
      _awaitingBrowserReturn = false;
      if (!mounted) return;
      setState(() => _processing = false);

      if (completed == false) {
        _showMessage(l10n.paymentFailedMessage);
        return;
      }
      if (completed == true) {
        await _confirm(
          checkout.transactionId,
          poll: false,
          forceSuccess: true,
        );
        return;
      }
      // User closed the WebView — short status poll only.
      await _confirm(checkout.transactionId, poll: true);
    } on PaymentFailure catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e, st) {
      debugPrint('Order Paymob checkout failed: $e\n$st');
      if (mounted) _showMessage(l10n.paymentFailedMessage);
    } finally {
      _clearLoading();
    }
  }

  void _onReturnLink(Uri link) {
    final transactionId =
        link.queryParameters['transaction_id'] ?? _checkout?.transactionId;
    if (transactionId == null) return;
    final successParam = link.queryParameters['success'] ??
        link.queryParameters['status'] ??
        '';
    final forceSuccess = successParam == 'true' ||
        successParam == 'success' ||
        successParam == '1';
    // If the Paymob WebView is open, close it and let `_payWithPaymob`
    // run confirmation with the pop result (avoids double-confirm).
    if (_awaitingBrowserReturn && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(forceSuccess);
      return;
    }
    unawaited(ref.read(paymentPageProvider).close());
    unawaited(_confirm(
      transactionId,
      poll: !forceSuccess,
      forceSuccess: forceSuccess,
    ));
  }

  Future<void> _confirm(
    String transactionId, {
    required bool poll,
    bool forceSuccess = false,
  }) async {
    if (_verifying) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _verifying = true);
    final service = ref.read(paymobServiceProvider);
    final deadline = DateTime.now().add(PaymentScreen.confirmTimeout);
    var status = forceSuccess ? PaymentStatus.success : PaymentStatus.pending;
    try {
      if (!forceSuccess) {
        while (true) {
          status = await service.fetchPaymentStatus(transactionId);
          if (status != PaymentStatus.pending ||
              !poll ||
              !DateTime.now().isBefore(deadline)) {
            break;
          }
          await Future<void>.delayed(PaymentScreen.confirmPollInterval);
          if (!mounted) return;
        }
      }
    } catch (error) {
      debugPrint('Checking payment $transactionId failed: $error');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
    if (!mounted) return;

    switch (status) {
      case PaymentStatus.success:
        final orderId = widget.orderId ?? _checkout?.orderId;
        if (orderId != null && orderId.isNotEmpty) {
          try {
            await service.markOrderPaidVisa(orderId);
          } catch (e, st) {
            debugPrint('markOrderPaidVisa failed: $e\n$st');
            _showMessage(l10n.paymentFailedMessage);
            return;
          }
        }
        _checkout = null;
        if (mounted) Navigator.of(context).pop(true);
      case PaymentStatus.failed:
        _checkout = null;
        _showMessage(l10n.paymentFailedMessage);
      case PaymentStatus.pending:
        if (poll) _showMessage(l10n.paymentStillProcessing);
    }
  }

  void _selectSaved(SavedCard card) {
    setState(() {
      _selectedSaved = card;
      _useNewCard = false;
      _cvv.clear();
    });
    ref.read(selectedCheckoutCardProvider.notifier).state = card;
    unawaited(_loadSavedCvv(card));
  }

  void _selectNewCard() {
    setState(() {
      _useNewCard = true;
      _selectedSaved = null;
      _cvv.clear();
    });
    ref.read(selectedCheckoutCardProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final digits = CardValidators.digitsOf(_number.text);
    final savedCards = ref.watch(savedCardsProvider);
    final usingSaved = !_useNewCard && _selectedSaved != null;

    ref.listen(paymentReturnLinksProvider, (_, next) {
      if (next.valueOrNull case final link?) _onReturnLink(link);
    });

    return PopScope(
      // Always allow back so a cancelled Paymob session can't trap the UI.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _clearLoading();
      },
      child: MobileFrame(
        child: Scaffold(
          backgroundColor: context.palette.surface,
          appBar: AppBar(title: Text(l10n.paymentCardTitle)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _AmountDue(amount: widget.amount),
                if (savedCards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.checkoutSavedCards,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final card in savedCards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SavedCardOption(
                        card: card,
                        selected: !_useNewCard && _selectedSaved?.id == card.id,
                        onTap: () => _selectSaved(card),
                      ),
                    ),
                  _NewCardOption(
                    label: l10n.checkoutUseOrAddNewCard,
                    selected: _useNewCard,
                    onTap: _selectNewCard,
                  ),
                  const SizedBox(height: 12),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: usingSaved
                        ? KeyedSubtree(
                            key: const ValueKey('saved-card'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BankCardView(
                                  brand: _selectedSaved!.brand,
                                  number:
                                      '•••• •••• •••• ${_selectedSaved!.last4}',
                                  holderName: _selectedSaved!.holderName,
                                  expiry: _selectedSaved!.expiry,
                                ),
                                const SizedBox(height: 20),
                                CardLtrField(
                                  controller: _cvv,
                                  focusNode: _cvvFocus,
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
                              ],
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('new-card'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                BankCardView(
                                  brand: CardBrand.fromNumber(digits),
                                  number: _number.text,
                                  holderName: _holder.text,
                                  expiry: _expiry.text,
                                ),
                                const SizedBox(height: 20),
                                AutofillGroup(
                                  child: Column(
                                    children: [
                                      CardLtrField(
                                        controller: _number,
                                        label: l10n.cardNumber,
                                        hint: '0000 0000 0000 0000',
                                        icon: Icons.credit_card_rounded,
                                        formatters: const [
                                          CardNumberFormatter(),
                                        ],
                                        validator: CardValidators.number,
                                        keyboardType: TextInputType.number,
                                        autofillHints: const [
                                          AutofillHints.creditCardNumber,
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: CardLtrField(
                                              controller: _expiry,
                                              label: l10n.expiryDate,
                                              hint: 'MM/YY',
                                              icon: Icons.event_rounded,
                                              formatters: const [
                                                ExpiryDateFormatter(),
                                              ],
                                              validator: CardValidators.expiry,
                                              keyboardType:
                                                  TextInputType.datetime,
                                              autofillHints: const [
                                                AutofillHints
                                                    .creditCardExpirationDate,
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: CardLtrField(
                                              controller: _cvv,
                                              focusNode: _cvvFocus,
                                              label: 'CVV',
                                              hint: '123',
                                              icon:
                                                  Icons.lock_outline_rounded,
                                              obscure: true,
                                              formatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  4,
                                                ),
                                              ],
                                              validator: CardValidators.cvv,
                                              keyboardType:
                                                  TextInputType.number,
                                              autofillHints: const [
                                                AutofillHints
                                                    .creditCardSecurityCode,
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
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _pay(),
                                        decoration: InputDecoration(
                                          labelText: l10n.cardholderName,
                                          hintText: l10n.asWrittenOnCard,
                                          prefixIcon: const Icon(
                                            Icons.person_outline_rounded,
                                          ),
                                        ),
                                        validator: CardValidators.holder,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
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
                        l10n.paymentSecureNotice,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: (_processing || _verifying) ? null : _pay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: (_processing || _verifying)
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.paymentPayNow(AppCurrency.of(widget.amount))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedCardOption extends StatelessWidget {
  const _SavedCardOption({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final SavedCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.06) : palette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : palette.muted.withValues(alpha: 0.25),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? palette.accent : palette.muted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.maskedLabel,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${card.holderName} · ${card.expiry}',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCardOption extends StatelessWidget {
  const _NewCardOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.06) : palette.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? palette.accent
                  : palette.muted.withValues(alpha: 0.25),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? palette.accent : palette.muted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? palette.accent : palette.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountDue extends StatelessWidget {
  const _AmountDue({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, color: palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.paymentAmountDue,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            AppCurrency.of(amount),
            key: const Key('payment-amount'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
        ],
      ),
    );
  }
}
