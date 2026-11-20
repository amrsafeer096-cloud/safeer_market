import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/sign_in_prompt.dart';
import '../../../support/presentation/providers/support_providers.dart';
import '../providers/profile_providers.dart';
// تم تصحيح مسار الاستيراد هنا (إضافة ../ إضافية للرجوع للمجلد الصحيح)
import '../../domain/entities/user_role.dart';
import '../widgets/info_sheets.dart';
import '../widgets/menu_tile.dart';

/// Opens an account screen (orders, favorites, profile, …), asking guests to
/// sign in first.
Future<void> openForMember(
  BuildContext context,
  WidgetRef ref,
  String route,
) async {
  final l10n = AppLocalizations.of(context)!;
  if (!await ensureSignedIn(context, ref, message: l10n.guestProfileMessage) ||
      !context.mounted) {
    return;
  }
  await context.push(route);
}

/// Body of the المزيد tab; hosted inside the home screen's Scaffold.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(isSignedInProvider);

    // سحب صلاحيات المستخدم لمعرفة هل هو موظف أم عميل
    final userRole = ref.watch(userRoleProvider).value;
    final isStaff = userRole == UserRole.admin ||
        userRole == UserRole.warehouse ||
        userRole == UserRole.driver;

    return Column(
      children: [
        const _MoreHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            children: [
              MenuGroup(
                children: [
                  MenuTile(
                    icon: Icons.emoji_events_outlined,
                    label: l10n.loyaltyPoints,
                    subtitle: l10n.spinWheelCollectPoints,
                    onTap: () => context.push(AppRoutes.rewards),
                  ),
                  MenuTile(
                    icon: Icons.favorite_border_rounded,
                    label: l10n.favoriteProducts,
                    onTap: () =>
                        openForMember(context, ref, AppRoutes.favorites),
                  ),
                  MenuTile(
                    icon: Icons.receipt_long_outlined,
                    label: l10n.myOrders,
                    onTap: () => openForMember(context, ref, AppRoutes.orders),
                  ),
                  MenuTile(
                    icon: Icons.settings_outlined,
                    label: l10n.settings,
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              MenuGroup(
                children: [
                  MenuTile(
                    icon: Icons.support_agent_rounded,
                    label: l10n.contactUs,
                    badgeCount:
                        ref.watch(customerSupportUnreadProvider).valueOrNull ??
                            0,
                    onTap: () => showContactSheet(context, ref),
                  ),
                  MenuTile(
                    icon: Icons.help_outline_rounded,
                    label: l10n.help,
                    onTap: () => showHelpDialog(context, ref),
                  ),
                ],
              ),

              // ==========================================
              // زر الإدارة: يظهر فقط إذا كان الحساب (أدمن، محضر، طيار)
              // ==========================================
              if (isStaff) ...[
                const SizedBox(height: 14),
                _AdminEntry(onTap: () => context.push(AppRoutes.adminOrders)),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: signedIn
                ? OutlinedButton.icon(
                    onPressed: () => _confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.signOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.auth),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(l10n.signIn),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOut,
      message: l10n.signOutConfirmMessage,
      confirmLabel: l10n.signOut,
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authControllerProvider.notifier).signOut();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.signedOut)));
  }
}

class _AdminEntry extends StatelessWidget {
  const _AdminEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.onSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminDashboard,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n.adminDashboardSubtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xB3FFFFFF)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.dashboard_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreHeader extends ConsumerWidget {
  const _MoreHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    final l10n = AppLocalizations.of(context)!;
    final name = signedIn ? profile?.displayName ?? '' : l10n.guestName;
    final initial = signedIn && name.isNotEmpty ? name.characters.first : null;
    final avatarUrl = signedIn ? profile?.avatarUrl : null;
    final palette = context.palette;
    final fallbackAvatar = initial == null
        ? Icon(
            Icons.person_rounded,
            size: 32,
            color: palette.accent,
          )
        : Text(
            initial,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 3),
            ),
            child: avatarUrl == null
                ? fallbackAvatar
                : Image.network(
                    avatarUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => fallbackAvatar,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: signedIn && profileAsync.isLoading && profile == null
                ? const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcomeUser(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      Text(
                        signedIn
                            ? profile?.email ?? profile?.phone ?? ''
                            : l10n.guestSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
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
