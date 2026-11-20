import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/support_contact.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/external_url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/sign_in_prompt.dart';
import '../providers/preferences_providers.dart';

Future<void> _showSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Widget child,
}) {
  final palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: palette.card,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  );
}

Future<void> _showInfoDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Widget content,
  List<Widget> extraActions = const [],
}) {
  final l10n = AppLocalizations.of(context)!;
  final palette = context.palette;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: Icon(icon, size: 36, color: palette.accent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: content,
      actions: [
        ...extraActions,
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

void showEmailDialog(BuildContext context, String? email) {
  final l10n = AppLocalizations.of(context)!;
  final palette = context.palette;
  _showInfoDialog(
    context,
    icon: Icons.email_outlined,
    title: l10n.email,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            email ?? l10n.noEmail,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.changeEmailContactSupport,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
      ],
    ),
  );
}

void showPrivacyDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  _showInfoDialog(
    context,
    icon: Icons.privacy_tip_outlined,
    title: l10n.privacyAndTerms,
    content: SingleChildScrollView(
      child: Text(
        l10n.privacyPolicyBody,
        style: const TextStyle(fontSize: 14, height: 1.8),
      ),
    ),
  );
}

void showHelpDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  _showInfoDialog(
    context,
    icon: Icons.support_rounded,
    title: l10n.helpTitle,
    content: Text(
      l10n.helpBody,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, height: 1.8),
    ),
    extraActions: [
      Builder(
        builder: (dialogContext) => TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openSupportChat(context, ref);
          },
          child: Text(l10n.contactUs),
        ),
      ),
    ],
  );
}

/// The in-app live chat with customer service; guests sign in first.
Future<void> openSupportChat(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  if (!await ensureSignedIn(context, ref, message: l10n.supportSignInMessage) ||
      !context.mounted) {
    return;
  }
  await context.push(AppRoutes.supportChat);
}

Future<void> _openExternal(
  BuildContext context,
  WidgetRef ref,
  Uri uri,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (await ref.read(externalUrlLauncherProvider)(uri)) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.secondary,
      content: Text(l10n.supportLaunchFailed(SupportContact.phone)),
    ));
}

void showContactSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  Widget option(
    BuildContext sheetContext, {
    required Key key,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: key,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () {
        Navigator.of(sheetContext).pop();
        onTap();
      },
    );
  }

  _showSheet(
    context,
    title: l10n.contactUs,
    icon: Icons.support_agent_rounded,
    child: Builder(
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(
            sheetContext,
            key: const Key('contact-call'),
            icon: Icons.phone_in_talk_rounded,
            color: context.palette.accent,
            title: l10n.callUs,
            subtitle: l10n.callUsSubtitle,
            onTap: () => _openExternal(context, ref, SupportContact.callUri),
          ),
          option(
            sheetContext,
            key: const Key('contact-whatsapp'),
            icon: Icons.chat_rounded,
            color: AppColors.success,
            title: l10n.whatsapp,
            subtitle: l10n.whatsappSubtitle,
            onTap: () =>
                _openExternal(context, ref, SupportContact.whatsappUri),
          ),
          option(
            sheetContext,
            key: const Key('contact-live-chat'),
            icon: Icons.forum_rounded,
            color: AppColors.secondary,
            title: l10n.supportLiveChat,
            subtitle: l10n.supportLiveChatSubtitle,
            onTap: () => openSupportChat(context, ref),
          ),
        ],
      ),
    ),
  );
}

void showNotificationsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  _showSheet(
    context,
    title: l10n.messageAlerts,
    icon: Icons.notifications_active_outlined,
    child: Consumer(
      builder: (context, ref, child) {
        final prefs = ref.watch(notificationPrefsProvider);
        final notifier = ref.read(notificationPrefsProvider.notifier);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: prefs.app,
              activeThumbColor: AppColors.secondary,
              secondary: const Icon(Icons.phone_iphone_rounded),
              title: Text(
                l10n.appNotifications,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.appNotificationsSubtitle),
              onChanged: (value) =>
                  notifier.state = (app: value, sms: prefs.sms),
            ),
            SwitchListTile(
              value: prefs.sms,
              activeThumbColor: AppColors.secondary,
              secondary: const Icon(Icons.sms_outlined),
              title: Text(
                l10n.smsMessages,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.smsMessagesSubtitle),
              onChanged: (value) =>
                  notifier.state = (app: prefs.app, sms: value),
            ),
          ],
        );
      },
    ),
  );
}

void showLanguageSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  _showSheet(
    context,
    title: l10n.language,
    icon: Icons.language_rounded,
    child: Consumer(
      builder: (sheetContext, ref, _) {
        final current = ref.watch(localeProvider);
        return RadioGroup<String>(
          groupValue: current.languageCode,
          onChanged: (value) {
            if (value == null) return;
            Navigator.of(sheetContext).pop();
            ref.read(localeProvider.notifier).state = Locale(value);
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<String>(
                    value: language.locale.languageCode,
                    title: Text(
                      language.nativeName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
