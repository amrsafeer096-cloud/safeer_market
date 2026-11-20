import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/home_banner.dart';
import '../providers/home_banners_providers.dart';

/// Admin quick-manage for the home deck: upload a company banner image with
/// its title and the product keyword it opens, and remove existing ones.
class BannerFormDialog extends ConsumerStatefulWidget {
  const BannerFormDialog({super.key, this.existing = const []});

  final List<HomeBanner> existing;

  @override
  ConsumerState<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<BannerFormDialog> {
  final _title = TextEditingController();
  final _keyword = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
      _error = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final image = _imageBytes;
    if (image == null) {
      setState(() => _error = l10n.bannerImageRequired);
      return;
    }
    if (_keyword.text.trim().isEmpty) {
      setState(() => _error = l10n.bannerKeywordRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(homeBannersRepositoryProvider).createBanner(
            title: _title.text,
            brandQuery: _keyword.text,
            imageBytes: image,
            imageFileName: _imageName ?? 'banner.jpg',
          );
      ref.invalidate(homeBannersProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bannerSaved),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.bannerSaveFailed('$error');
      });
    }
  }

  Future<void> _delete(HomeBanner banner) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.bannerDeleteConfirm(banner.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(homeBannersRepositoryProvider).deleteBanner(banner.id);
      ref.invalidate(homeBannersProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = l10n.bannerSaveFailed('$error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = _imageBytes;
    final palette = context.palette;

    return AlertDialog(
      title: Text(l10n.bannerAdd),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _saving ? null : _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 140,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: palette.imageBackdrop,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.isDark
                          ? palette.border
                          : const Color(0xFFE3E6EB),
                    ),
                  ),
                  child: image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: palette.muted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.bannerChooseImage,
                              style: TextStyle(color: palette.muted),
                            ),
                          ],
                        )
                      : Image.memory(image, fit: BoxFit.cover),
                ),
              ),
              if (image != null)
                TextButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.bannerChangeImage),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.bannerTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keyword,
                decoration: InputDecoration(
                  labelText: l10n.bannerKeywordLabel,
                  hintText: l10n.bannerKeywordHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (widget.existing.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.bannerExistingHeader,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final banner in widget.existing)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 36,
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: palette.imageBackdrop,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      banner.title.isEmpty ? banner.brandQuery : banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      banner.brandQuery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: l10n.delete,
                      onPressed: _saving ? null : () => _delete(banner),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(l10n.save),
        ),
      ],
    );
  }
}
