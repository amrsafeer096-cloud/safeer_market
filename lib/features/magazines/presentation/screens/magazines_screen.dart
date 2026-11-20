import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/screens/admin_magazines_view.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/magazine.dart';
import '../providers/magazines_provider.dart';
import 'magazine_reader_screen.dart';

class MagazinesScreen extends ConsumerWidget {
  const MagazinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magazinesAsync = ref.watch(magazinesProvider);
    final isAdmin = ref.watch(userRoleProvider).valueOrNull == UserRole.admin;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          title: Text(l10n.magazines),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          actions: [
            if (isAdmin)
              IconButton(
                tooltip: l10n.addMagazine,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const MagazineFormDialog(),
                ),
              ),
          ],
        ),
        body: magazinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.magazinesLoadFailed,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted),
              ),
            ),
          ),
          data: (magazines) {
            if (magazines.isEmpty) {
              return Center(
                child: Text(
                  l10n.noMagazinesCurrently,
                  style: TextStyle(color: palette.muted, fontSize: 16),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(magazinesProvider.future),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: magazines.length,
                itemBuilder: (context, index) {
                  final magazine = magazines[index];
                  return _MagazineCard(magazine: magazine);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MagazineCard extends StatelessWidget {
  const _MagazineCard({required this.magazine});

  final Magazine magazine;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () => MagazineReaderScreen.open(context, magazine),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: palette.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: magazine.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: palette.imageBackdrop,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: palette.imageBackdrop,
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                magazine.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
