import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/egyptian_phone.dart';
import '../../domain/password_rules.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../widgets/password_strength_checklist.dart';
import '../widgets/phone_auth_sheet.dart';

/// Pops with `true` once the user is signed in.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Google and phone come first; email/password is kept for existing
  /// accounts behind "Continue with email".
  bool _showEmailForm = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _googlePending = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (!_isLogin && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    _formKey.currentState?.reset();
    setState(() => _isLogin = isLogin);
  }

  void _setEmailFormVisible(bool visible) {
    FocusScope.of(context).unfocus();
    setState(() => _showEmailForm = visible);
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googlePending = true);
    final signedIn =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _googlePending = false);
    if (signedIn) _finish();
  }

  Future<void> _continueWithPhone() async {
    final signedIn = await showPhoneAuthSheet(context);
    if (signedIn == true && mounted) _finish();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      final success = await controller.signIn(email: email, password: password);
      if (success && mounted) _finish();
      return;
    }

    if (!PasswordRules.isStrong(password)) {
      setState(() {});
      return;
    }

    final result = await controller.signUp(
      fullName: _nameController.text.trim(),
      email: email,
      phone: _phoneController.text.trim(),
      password: password,
    );
    if (!mounted || result == null) return;

    switch (result) {
      case SignUpResult.signedIn:
        _finish();
      case SignUpResult.confirmationRequired:
        _showMessage(
          AppLocalizations.of(context)!.authAccountCreatedConfirmEmail(email),
          color: AppColors.success,
        );
        _passwordController.clear();
        setState(() => _isLogin = true);
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    if (context.canPop()) {
      context.pop(true);
    } else {
      goToHomeTab(context, ref);
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      goToHomeTab(context, ref);
    }
  }

  void _showMessage(String message, {required Color color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          duration: const Duration(seconds: 5),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    // Browser sign-in (Google on the web, or on mobile without the native
    // client IDs) comes back through a deep link rather than the button's
    // future. Skipped while a sheet is open on top; that flow finishes itself.
    ref.listen(currentUserProvider.select((user) => user?.id),
        (previous, next) {
      if (previous == null && next != null && mounted) {
        if (ModalRoute.of(context)?.isCurrent ?? true) _finish();
      }
    });

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final error = next.error;
        _showMessage(
          error is AuthFailure ? error.message : l10n.unexpectedError,
          color: AppColors.secondary,
        );
      }
    });

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AuthHeader(
                mode: !_showEmailForm
                    ? _HeaderMode.welcome
                    : _isLogin
                        ? _HeaderMode.login
                        : _HeaderMode.signUp,
                onClose: _close,
              ),
              Transform.translate(
                offset: const Offset(0, -36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      color: palette.card,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: palette.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showEmailForm
                          ? _buildEmailForm(isLoading, l10n)
                          : _SignInOptions(
                              isLoading: isLoading,
                              googlePending: _googlePending,
                              onGoogle: _continueWithGoogle,
                              onPhone: ref.watch(phoneAuthEnabledProvider)
                                  ? _continueWithPhone
                                  : null,
                              onEmail: () => _setEmailFormVisible(true),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(bool isLoading, AppLocalizations l10n) {
    final palette = context.palette;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: isLoading ? null : () => _setEmailFormVisible(false),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.authOtherSignInOptions),
            ),
          ),
          const SizedBox(height: 8),
          _ModeToggle(isLogin: _isLogin, onChanged: _toggleMode),
          const SizedBox(height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isLogin
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: l10n.authFullNameLabel,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 3)
                                ? l10n.authEnterFullName
                                : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) => _emailPattern.hasMatch(value?.trim() ?? '')
                ? null
                : l10n.authEnterValidEmail,
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isLogin
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          hintText: '01xxxxxxxxx',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded),
                        ),
                        validator: (value) =>
                            EgyptianPhone.isValid(value?.trim() ?? '')
                                ? null
                                : l10n.authEnterValidEgyptianPhone,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            autofillHints: [
              _isLogin ? AutofillHints.password : AutofillHints.newPassword,
            ],
            onFieldSubmitted: (_) => isLoading ? null : _submit(),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? l10n.authShowPassword
                    : l10n.authHidePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (_isLogin) {
                return (value == null || value.length < 6)
                    ? l10n.authPasswordMinLength
                    : null;
              }
              if (value == null || !PasswordRules.isStrong(value)) {
                return l10n.passwordRequirementsTitle;
              }
              return null;
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_isLogin
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: PasswordStrengthChecklist(
                      password: _passwordController.text,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: isLoading ||
                      (!_isLogin &&
                          !PasswordRules.isStrong(_passwordController.text))
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor:
                    AppColors.secondary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isLogin
                          ? l10n.authSignInButton
                          : l10n.authCreateAccountButton,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : () => _toggleMode(!_isLogin),
            child: Text.rich(
              TextSpan(
                text: _isLogin
                    ? l10n.authNoAccountPrompt
                    : l10n.authHaveAccountPrompt,
                style: TextStyle(color: palette.muted),
                children: [
                  TextSpan(
                    text: _isLogin
                        ? l10n.authCreateNewAccountLink
                        : l10n.authSignInLink,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInOptions extends StatelessWidget {
  const _SignInOptions({
    required this.isLoading,
    required this.googlePending,
    required this.onGoogle,
    this.onPhone,
    required this.onEmail,
  });

  final bool isLoading;
  final bool googlePending;
  final VoidCallback onGoogle;

  /// Null hides the button (phone sign-in not set up).
  final VoidCallback? onPhone;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: isLoading ? null : onGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.card,
              foregroundColor: palette.onSurface,
              side: BorderSide(color: palette.muted.withValues(alpha: 0.3)),
              shape: buttonShape,
            ),
            child: googlePending
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          l10n.authContinueWithGoogle,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (onPhone case final onPhone?) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onPhone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.6),
                shape: buttonShape,
              ),
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(l10n.authContinueWithPhone, style: labelStyle),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.authOr,
                style: TextStyle(color: palette.muted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: isLoading ? null : onEmail,
          icon: const Icon(Icons.alternate_email_rounded, size: 20),
          label: Text(
            l10n.authContinueWithEmail,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.authTermsNotice,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
      ],
    );
  }
}

enum _HeaderMode { welcome, login, signUp }

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.mode, required this.onClose});

  final _HeaderMode mode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: l10n.close,
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const AppLogo(size: 60),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  switch (mode) {
                    _HeaderMode.welcome => l10n.authWelcomeTitle,
                    _HeaderMode.login => l10n.authWelcomeBack,
                    _HeaderMode.signUp => l10n.authJoinSafeerMarket,
                  },
                  key: ValueKey(mode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                switch (mode) {
                  _HeaderMode.welcome => l10n.authWelcomeSubtitle,
                  _HeaderMode.login => l10n.authSignInSubtitle,
                  _HeaderMode.signUp => l10n.authSignUpSubtitle,
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: l10n.authSignInButton,
            selected: isLogin,
            onTap: () => onChanged(true),
          ),
          _ToggleOption(
            label: l10n.authNewAccountTab,
            selected: !isLogin,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.onPrimary : context.palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}
