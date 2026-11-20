import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/settings_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../core/widgets/theme_selector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/sign_in_prompt.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../widgets/info_sheets.dart';
import '../widgets/menu_tile.dart';
import 'more_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final languageName =
        AppLanguage.forLocale(ref.watch(localeProvider)).nativeName;

    final items = <({
      IconData icon,
      String label,
      String? value,
      String? route,
      VoidCallback? action,
      bool needsAccount,
    })>[
      (
        icon: Icons.badge_outlined,
        label: l10n.personalData,
        value: null,
        route: AppRoutes.editProfile,
        action: null,
        needsAccount: true,
      ),
      (
        icon: Icons.email_outlined,
        label: l10n.email,
        value: user?.email,
        route: null,
        action: () => showEmailDialog(context, user?.email),
        needsAccount: true,
      ),
      (
        icon: Icons.location_on_outlined,
        label: l10n.savedAddresses,
        value: null,
        route: AppRoutes.addresses,
        action: null,
        needsAccount: true,
      ),
      (
        icon: Icons.credit_card_rounded,
        label: l10n.savedCards,
        value: null,
        route: AppRoutes.wallet,
        action: null,
        needsAccount: true,
      ),
      (
        icon: Icons.notifications_none_rounded,
        label: l10n.messageAndSmsAlerts,
        value: null,
        route: null,
        action: () => showNotificationsSheet(context),
        needsAccount: false,
      ),
      (
        icon: Icons.privacy_tip_outlined,
        label: l10n.privacyAndTerms,
        value: null,
        route: null,
        action: () => showPrivacyDialog(context),
        needsAccount: false,
      ),
    ];

    Future<void> open(
        ({
          IconData icon,
          String label,
          String? value,
          String? route,
          VoidCallback? action,
          bool needsAccount,
        }) item) async {
      if (item.route case final route?) {
        if (item.needsAccount) {
          await openForMember(context, ref, route);
        } else {
          await context.push(route);
        }
        return;
      }
      if (item.needsAccount &&
          !await ensureSignedIn(
            context,
            ref,
            message: l10n.guestProfileMessage,
          )) {
        return;
      }
      if (item.action case final action?) {
        action();
      } else if (context.mounted) {
        showComingSoon(context, item.label);
      }
    }

    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(title: Text(l10n.settings)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(l10n.appearance),
            const SizedBox(height: 10),
            const ThemeSelectorWidget(),
            const SizedBox(height: 14),
            MenuGroup(
              children: [
                MenuTile(
                  icon: Icons.language_rounded,
                  label: l10n.language,
                  subtitle: languageName,
                  onTap: () => showLanguageSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle(l10n.settingsAccountSection),
            const SizedBox(height: 10),
            MenuGroup(
              children: [
                for (final item in items)
                  MenuTile(
                    icon: item.icon,
                    label: item.label,
                    subtitle: item.value,
                    onTap: () => open(item),
                  ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _confirmDeleteAccount(context, ref),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(l10n.deleteAccount),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountConfirmMessage,
      confirmLabel: l10n.deleteAccount,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success =
        await ref.read(authControllerProvider.notifier).deleteAccount(
      clearLocalData: () async {
        ref.read(cartProvider.notifier).clear();
        await ref.read(savedCardSecretsProvider).deleteAll();
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs?.clear();
        // Secure storage wipe covers any leftover CVVs / tokens.
        try {
          await const FlutterSecureStorage().deleteAll();
        } catch (_) {}
      },
    );

    if (!context.mounted) return;
    if (!success) {
      final error = ref.read(authControllerProvider).error;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error?.toString() ?? l10n.unexpectedError,
            ),
          ),
        );
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.deleteAccountSuccess),
        ),
      );
    context.go(AppRoutes.auth);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: context.palette.muted,
        ),
      ),
    );
  }
}
