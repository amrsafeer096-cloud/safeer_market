import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/settings_providers.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/google_logo.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../core/widgets/theme_selector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/phone_auth_sheet.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// First launch: language, then appearance, then sign in — or browse as a
/// guest. Either way it ends by clearing [isFirstLaunchProvider], and the
/// router then takes the user home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const pageCount = 3;
  static const pageTransition = Duration(milliseconds: 350);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _googlePending = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
        page,
        duration: OnboardingScreen.pageTransition,
        curve: Curves.easeOutCubic,
      );

  void _finish() {
    ref.read(isFirstLaunchProvider.notifier).state = false;
    if (mounted) {
      context.go(homeRouteFor(ref.read(userRoleProvider).valueOrNull));
    }
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
    if (await showPhoneAuthSheet(context) == true && mounted) _finish();
  }

  Future<void> _signInOrRegister() async {
    final signedIn = await context.push<bool>(AppRoutes.auth);
    if (signedIn == true && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    // Browser sign-in (Google on the web) comes back through a deep link.
    // Skipped while the sign-in screen or a sheet is on top; those flows
    // finish through their own result.
    ref.listen(currentUserProvider.select((user) => user?.id), (prev, next) {
      if (prev == null && next != null && mounted) {
        if (ModalRoute.of(context)?.isCurrent ?? true) _finish();
      }
    });
    ref.listen(authControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(
              error is AuthFailure ? error.message : l10n.unexpectedError,
            ),
          ));
      }
    });

    final onLastPage = _page == OnboardingScreen.pageCount - 1;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _page > 0 ? 1 : 0,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: _page > 0 ? () => _goTo(_page - 1) : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_page + 1}/${OnboardingScreen.pageCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    const _LanguagePage(),
                    const _AppearancePage(),
                    _AccountPage(
                      googlePending: _googlePending,
                      onGoogle: _continueWithGoogle,
                      onPhone: ref.watch(phoneAuthEnabledProvider)
                          ? _continueWithPhone
                          : null,
                      onSignInOrRegister: _signInOrRegister,
                      onBrowseFirst: _finish,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    _PageDots(
                      count: OnboardingScreen.pageCount,
                      current: _page,
                      color: colors.primary,
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: onLastPage
                          ? const SizedBox(height: 52)
                          : SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: () => _goTo(_page + 1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                // Mirrors to point forward in RTL.
                                icon: const Icon(Icons.arrow_forward_rounded),
                                iconAlignment: IconAlignment.end,
                                label: Text(
                                  l10n.onboardingNext,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
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

/// Shared layout: an icon in a soft circle, a title, a subtitle, then [child].
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  /// Replaces the icon (e.g. with the store logo on the first page).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: leading ??
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: primary),
                ),
          ).animate().fadeIn(duration: 350.ms).scale(
              begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          )
              .animate(delay: 80.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: context.palette.muted,
            ),
          ).animate(delay: 140.ms).fadeIn(duration: 300.ms),
          const SizedBox(height: 32),
          child
              .animate(delay: 200.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage();

  /// The onboarding offers the two main store languages; the rest are in
  /// Settings.
  static const _choices = [Locale('ar'), Locale('en')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);
    return _OnboardingPage(
      icon: Icons.translate_rounded,
      leading: const AppLogo(size: 96),
      title: l10n.onboardingLanguageTitle,
      subtitle: l10n.onboardingLanguageSubtitle,
      child: Column(
        children: [
          for (final locale in _choices) ...[
            _ChoiceCard(
              badge: locale.languageCode == 'ar' ? 'ع' : 'EN',
              label: AppLanguage.forLocale(locale).nativeName,
              selected: current.languageCode == locale.languageCode,
              onTap: () => ref.read(localeProvider.notifier).state = locale,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _OnboardingPage(
      icon: Icons.palette_outlined,
      title: l10n.onboardingAppearanceTitle,
      subtitle: l10n.onboardingAppearanceSubtitle,
      child: const ThemeSelectorWidget(),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.googlePending,
    required this.onGoogle,
    required this.onPhone,
    required this.onSignInOrRegister,
    required this.onBrowseFirst,
  });

  final bool googlePending;
  final VoidCallback onGoogle;

  /// Null hides phone sign-in (no SMS provider yet).
  final VoidCallback? onPhone;
  final VoidCallback onSignInOrRegister;
  final VoidCallback onBrowseFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

    return _OnboardingPage(
      icon: Icons.person_outline_rounded,
      title: l10n.onboardingAccountTitle,
      subtitle: l10n.onboardingAccountSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: googlePending ? null : onGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
                side: BorderSide(
                  color: context.palette.muted.withValues(alpha: 0.3),
                ),
                shape: shape,
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
                            style: label,
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
                onPressed: onPhone,
                style: FilledButton.styleFrom(shape: shape),
                icon: const Icon(Icons.phone_iphone_rounded),
                label: Text(l10n.authContinueWithPhone, style: label),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onSignInOrRegister,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: shape,
              ),
              icon: const Icon(Icons.login_rounded),
              label: Text(l10n.onboardingSignInOrRegister, style: label),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onBrowseFirst,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.onboardingBrowseFirst,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.badge,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String badge;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : palette.muted.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(selected),
                  color: selected ? colors.primary : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.current,
    required this.color,
  });

  final int count;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? color : color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
