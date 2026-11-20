import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

/// Guests can browse freely; actions that need an account call this first.
/// Resolves to true when the user is (or has just become) signed in, so the
/// caller carries on with what they were doing.
Future<bool> ensureSignedIn(
  BuildContext context,
  WidgetRef ref, {
  required String message,
}) async {
  if (ref.read(isSignedInProvider)) return true;

  final wantsToSignIn = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SignInPromptSheet(message: message),
  );
  if (wantsToSignIn != true || !context.mounted) return false;

  await context.push<bool>(AppRoutes.auth);
  return ref.read(isSignedInProvider);
}

class SignInPromptSheet extends StatelessWidget {
  const SignInPromptSheet({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_person_rounded, size: 36, color: primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.guestSignInTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.signIn,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.notNow),
          ),
        ],
      ),
    );
  }
}
