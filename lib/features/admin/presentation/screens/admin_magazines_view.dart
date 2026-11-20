import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../magazines/data/models/magazine_model.dart';
import '../../../magazines/domain/entities/magazine.dart';
import '../../../magazines/presentation/providers/magazines_provider.dart';

/// The dashboard's «المجلات» page: every magazine with its date range and
/// status, plus a form to upload a new one.
class AdminMagazinesView extends ConsumerWidget {
  const AdminMagazinesView({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Magazine magazine,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteMagazineTitle),
        content: Text(l10n.adminDeleteMagazineConfirm(magazine.title)),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(magazinesRepositoryProvider).deleteMagazine(magazine.id);
      ref
        ..invalidate(adminMagazinesProvider)
        ..invalidate(magazinesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminDeleteMagazineFailed('$error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final magazinesAsync = ref.watch(adminMagazinesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const MagazineFormDialog(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addMagazine),
      ),
      body: magazinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.adminErrorWithDetails('$error'))),
        data: (magazines) {
          if (magazines.isEmpty) {
            return Center(
              child: Text(
                l10n.adminNoMagazinesYet,
                style: TextStyle(color: context.palette.muted, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: magazines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final magazine = magazines[index];
              return _MagazineTile(
                magazine: magazine,
                onDelete: () => _delete(context, ref, magazine),
              );
            },
          );
        },
      ),
    );
  }
}

class _MagazineTile extends StatelessWidget {
  const _MagazineTile({required this.magazine, required this.onDelete});

  final Magazine magazine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color) = magazine.isExpired
        ? (l10n.adminMagazineExpired, Colors.grey)
        : magazine.isUpcoming
            ? (l10n.adminMagazineUpcoming, Colors.orange)
            : (l10n.adminMagazineActive, AppColors.success);
    final palette = context.palette;

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 76,
                child: CachedNetworkImage(
                  imageUrl: magazine.coverImageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: palette.imageBackdrop,
                    child: Icon(Icons.menu_book_outlined, color: palette.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    magazine.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.adminMagazineDateRange(
                      MagazineModel.dateOnly(magazine.startDate),
                      MagazineModel.dateOnly(magazine.endDate),
                    ),
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title, cover, PDF and the start/end dates of a new magazine.
class MagazineFormDialog extends ConsumerStatefulWidget {
  const MagazineFormDialog({super.key});

  @override
  ConsumerState<MagazineFormDialog> createState() => _MagazineFormDialogState();
}

class _MagazineFormDialogState extends ConsumerState<MagazineFormDialog> {
  final _titleController = TextEditingController();
  Uint8List? _coverBytes;
  String? _coverName;
  Uint8List? _pdfBytes;
  String? _pdfName;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _coverBytes = bytes;
      _coverName = picked.name;
      _error = null;
    });
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: AppLocalizations.of(context)!.adminPickMagazinePdfTitle,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final file = files.singleOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pdfBytes = bytes;
      _pdfName = file.name;
      _error = null;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final l10n = AppLocalizations.of(context)!;
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
      helpText: start ? l10n.adminMagazineStartDate : l10n.adminMagazineEndDate,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final cover = _coverBytes;
    final pdf = _pdfBytes;
    if (title.isEmpty) {
      setState(() => _error = l10n.adminMagazineTitleRequired);
      return;
    }
    if (cover == null) {
      setState(() => _error = l10n.adminMagazineCoverRequired);
      return;
    }
    if (pdf == null) {
      setState(() => _error = l10n.adminMagazinePdfRequired);
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() => _error = l10n.adminMagazineEndBeforeStart);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(magazinesRepositoryProvider).createMagazine(
            title: title,
            coverBytes: cover,
            coverFileName: _coverName ?? 'cover.jpg',
            pdfBytes: pdf,
            pdfFileName: _pdfName ?? 'magazine.pdf',
            startDate: _startDate,
            endDate: _endDate,
          );
      ref
        ..invalidate(adminMagazinesProvider)
        ..invalidate(magazinesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.adminMagazineAdded),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.adminMagazineSaveFailed('$error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cover = _coverBytes;
    final palette = context.palette;

    return AlertDialog(
      title: Text(l10n.adminAddNewMagazine),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.adminMagazineTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 72,
                      height: 96,
                      color: palette.imageBackdrop,
                      child: cover == null
                          ? Icon(Icons.image_outlined, color: palette.muted)
                          : Image.memory(cover, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickCover,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            cover == null
                                ? l10n.adminPickCoverImage
                                : l10n.adminChangeCover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(
                            _pdfName ?? l10n.adminPickPdfFile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: l10n.adminMagazineStartDate,
                      date: _startDate,
                      onTap: _saving ? null : () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: l10n.adminMagazineEndDate,
                      date: _endDate,
                      onTap: _saving ? null : () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
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
          label: Text(_saving ? l10n.adminUploading : l10n.save),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(MagazineModel.dateOnly(date)),
      ),
    );
  }
}
