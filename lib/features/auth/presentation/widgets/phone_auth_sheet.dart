import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/egyptian_phone.dart';
import '../providers/auth_providers.dart';

/// Phone number + SMS code sign-in. Resolves to true once signed in.
Future<bool?> showPhoneAuthSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.card,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const PhoneAuthSheet(),
  );
}

class PhoneAuthSheet extends ConsumerStatefulWidget {
  const PhoneAuthSheet({super.key});

  static const codeLength = 6;
  static const resendDelay = Duration(seconds: 60);

  @override
  ConsumerState<PhoneAuthSheet> createState() => _PhoneAuthSheetState();
}

class _PhoneAuthSheetState extends ConsumerState<PhoneAuthSheet> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  Timer? _resendTimer;
  int _resendIn = 0;

  PhoneAuthController get _controller =>
      ref.read(phoneAuthControllerProvider.notifier);

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = PhoneAuthSheet.resendDelay.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!_phoneFormKey.currentState!.validate()) return;
    if (await _controller.sendCode(_phone.text.trim())) {
      _code.clear();
      _startResendCountdown();
    }
  }

  Future<void> _resendCode() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (await _controller.resendCode()) {
      _code.clear();
      _startResendCountdown();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.authCodeResent),
        ));
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != PhoneAuthSheet.codeLength) return;
    FocusScope.of(context).unfocus();
    if (await _controller.verify(code) && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _changeNumber() {
    _resendTimer?.cancel();
    _code.clear();
    _controller.changeNumber();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(phoneAuthControllerProvider);
    final onCodeStep = state.step == PhoneAuthStep.enterCode;
    final palette = context.palette;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    onCodeStep
                        ? Icons.sms_outlined
                        : Icons.phone_iphone_rounded,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    onCodeStep
                        ? l10n.authEnterCodeTitle
                        : l10n.authPhoneSheetTitle,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: palette.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              onCodeStep
                  ? l10n.authCodeSentTo(state.phone ?? '')
                  : l10n.authPhoneSheetSubtitle,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: onCodeStep
                  ? _CodeField(
                      key: const ValueKey('code'),
                      controller: _code,
                      enabled: !state.isLoading,
                      onCompleted: _verify,
                    )
                  : Form(
                      key: _phoneFormKey,
                      child: _PhoneField(
                        controller: _phone,
                        enabled: !state.isLoading,
                        onSubmitted: _sendCode,
                      ),
                    ),
            ),
            if (state.error case final error?) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: error),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: state.isLoading
                    ? null
                    : onCodeStep
                        ? _verify
                        : _sendCode,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  disabledBackgroundColor:
                      AppColors.secondary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        onCodeStep ? l10n.authVerifyCode : l10n.authSendCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (onCodeStep) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: state.isLoading ? null : _changeNumber,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.authChangeNumber),
                  ),
                  TextButton(
                    onPressed:
                        state.isLoading || _resendIn > 0 ? null : _resendCode,
                    child: Text(
                      _resendIn > 0
                          ? l10n.authResendCodeIn('$_resendIn')
                          : l10n.authResendCode,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.send,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: '01xxxxxxxxx',
        hintTextDirection: TextDirection.ltr,
        prefixIcon: const Icon(Icons.phone_iphone_rounded),
      ),
      onFieldSubmitted: (_) => onSubmitted(),
      validator: (value) => EgyptianPhone.isValid(value?.trim() ?? '')
          ? null
          : l10n.authEnterValidEgyptianPhone,
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(PhoneAuthSheet.codeLength),
      ],
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 14,
        color: palette.accent,
      ),
      decoration: InputDecoration(
        hintText: '••••••',
        hintStyle: TextStyle(
          fontSize: 28,
          letterSpacing: 14,
          color: palette.muted.withValues(alpha: 0.4),
        ),
        helperText: l10n.authEnterSixDigitCode,
        helperStyle: TextStyle(color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onChanged: (value) {
        if (value.length == PhoneAuthSheet.codeLength) onCompleted();
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.secondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
