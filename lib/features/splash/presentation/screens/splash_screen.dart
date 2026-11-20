import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const introDuration = Duration(milliseconds: 400);

  /// Logo pop-in plus a short beat so the brand registers.
  static const duration = Duration(milliseconds: 900);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _leave();
  }

  Future<void> _leave() async {
    // The saved session's role loads during the animation so drivers land
    // straight on their dashboard instead of flashing the store first.
    final role = ref
        .read(userRoleProvider.future)
        .timeout(const Duration(seconds: 5))
        .then<UserRole?>((role) => role)
        // The router redirect still catches a late answer.
        .catchError((_) => null);
    await Future<void>.delayed(SplashScreen.duration);
    final resolved = await role;
    if (!mounted) return;
    context.go(homeRouteFor(resolved));
  }

  @override
  Widget build(BuildContext context) {
    const intro = SplashScreen.introDuration;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.card,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(36),
                boxShadow: palette.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
              ),
              child: const AppLogo(size: 120),
            )
                .animate()
                .fadeIn(duration: intro)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: intro,
                  curve: Curves.easeOutBack,
                )
                .rotate(begin: 0.2, duration: intro, curve: Curves.easeOutBack),
            const SizedBox(height: 28),
            Text(
              AppLocalizations.of(context)!.appTitle,
              style: GoogleFonts.cairo(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: palette.accent,
                letterSpacing: 0.5,
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 300.ms).slideY(
                begin: 0.4, duration: 300.ms, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
