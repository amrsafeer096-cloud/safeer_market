import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/password_rules.dart';

/// Interactive checklist shown under the sign-up password field.
class PasswordStrengthChecklist extends StatelessWidget {
  const PasswordStrengthChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final rules = [
      (PasswordRules.hasMinLength(password), l10n.passwordRuleMinLength),
      (PasswordRules.hasUppercase(password), l10n.passwordRuleUppercase),
      (PasswordRules.hasLowercase(password), l10n.passwordRuleLowercase),
      (PasswordRules.hasDigit(password), l10n.passwordRuleDigit),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordRequirementsTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          for (final (ok, label) in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                      key: ValueKey(ok),
                      size: 18,
                      color: ok
                          ? AppColors.success
                          : palette.muted.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
                        color: ok ? AppColors.success : palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
