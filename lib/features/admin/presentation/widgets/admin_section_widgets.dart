import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../data/report_pdf_exporter.dart';
import '../../domain/reports.dart';

class AdminSubMenuItem {
  const AdminSubMenuItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// A tab's sub-menu column (at the start edge, the right in Arabic) with the
/// selected section beside it. On narrow screens the menu becomes a row of
/// chips above the section.
class AdminSubMenuLayout extends StatelessWidget {
  const AdminSubMenuLayout({
    super.key,
    required this.keyPrefix,
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.body,
  });

  /// Items are keyed `<keyPrefix>-<index>`.
  final String keyPrefix;
  final String title;
  final List<AdminSubMenuItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final Widget body;

  static const menuWidth = 220.0;
  static const wideMinWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= wideMinWidth) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: Key('$keyPrefix-menu'),
              width: menuWidth,
              child: Material(
                color: palette.card,
                child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  for (var i = 0; i < items.length; i++)
                    ListTile(
                      key: Key('$keyPrefix-$i'),
                      dense: true,
                      leading: Icon(items[i].icon,
                          color: i == selected ? palette.accent : palette.muted),
                      title: Text(
                        items[i].label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i == selected ? palette.accent : palette.muted,
                        ),
                      ),
                      selected: i == selected,
                      selectedTileColor: palette.accent.withValues(alpha: 0.1),
                      onTap: () => onSelected(i),
                    ),
                ],
                ),
              ),
            ),
            VerticalDivider(width: 1, color: palette.border),
            Expanded(child: body),
          ],
        );
      }
      return Column(
        children: [
          Container(
            key: Key('$keyPrefix-menu'),
            height: 52,
            color: palette.card,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      key: Key('$keyPrefix-$i'),
                      avatar: Icon(items[i].icon, size: 16),
                      label: Text(items[i].label),
                      selected: i == selected,
                      showCheckmark: false,
                      onSelected: (_) => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: body),
        ],
      );
    });
  }
}

/// A section's title row, with optional [actions] at the far end.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          if (actions.isNotEmpty)
            Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions),
        ],
      ),
    );
  }
}

/// «لا تملك صلاحية …» in place of a section.
class AdminLockedSection extends StatelessWidget {
  const AdminLockedSection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      key: const Key('admin-locked-section'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 44, color: palette.muted),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.muted)),
        ],
      ),
    );
  }
}

/// Centered grey message (empty states, hints, errors).
class AdminMessage extends StatelessWidget {
  const AdminMessage(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: palette.muted),
              const SizedBox(height: 8),
            ],
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: palette.muted)),
          ],
        ),
      ),
    );
  }
}

/// Shows [message] as a snack bar.
void showAdminSnack(BuildContext context, String message,
    {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFD32F2F) : null,
    ));
}

/// «هل أنت متأكد؟» for destructive actions.
Future<bool> confirmAdminAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Text(message),
      actions: [
        TextButton(
          key: const Key('confirm-cancel'),
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('confirm-ok'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

// ----------------------------------------------------------- report table

/// A report: summary cards over a scrollable table.
class ReportResultView extends StatelessWidget {
  const ReportResultView({
    super.key,
    required this.table,
    this.canExportPdf = true,
  });

  final ReportTable table;

  /// When false, hides PDF export / share / print actions.
  final bool canExportPdf;

  Future<void> _runPdf(
    BuildContext context,
    Future<void> Function(ReportTable) action,
    String okMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(table);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(okMessage)));
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('تعذّر إنشاء ملف PDF: $error'),
          backgroundColor: const Color(0xFFD32F2F),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = table.columns.fold<double>(0, (s, c) => s + c.width) + 24;

    return Column(
      key: const Key('report-result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(table.title,
                  key: const Key('report-title'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: palette.accent)),
            ),
            Text('عدد الصفوف: ${table.rows.length}',
                key: const Key('report-row-count'),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: palette.muted)),
          ],
        ),
        if (canExportPdf) ...[
          const SizedBox(height: 10),
          Wrap(
            key: const Key('report-pdf-actions'),
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const Key('report-pdf-export'),
                onPressed: () => _runPdf(
                  context,
                  ReportPdfExporter.export,
                  'تم تجهيز ملف PDF للتصدير',
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('تصدير PDF'),
              ),
              OutlinedButton.icon(
                key: const Key('report-pdf-share'),
                onPressed: () => _runPdf(
                  context,
                  ReportPdfExporter.share,
                  'جاهز للمشاركة',
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('مشاركة PDF'),
              ),
              OutlinedButton.icon(
                key: const Key('report-pdf-print'),
                onPressed: () => _runPdf(
                  context,
                  ReportPdfExporter.print,
                  'تم فتح نافذة الطباعة',
                ),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          key: const Key('report-summary'),
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final stat in table.summary)
              Container(
                constraints: const BoxConstraints(minWidth: 130),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: palette.accent.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.muted)),
                    const SizedBox(height: 2),
                    Text(stat.value,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: palette.accent)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: table.rows.isEmpty
                ? const AdminMessage('لا توجد بيانات في هذه الفترة',
                    icon: Icons.inbox_outlined)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          Container(
                            color: palette.accent.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                for (final column in table.columns)
                                  _Cell(column.label, column.width,
                                      header: true),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              key: const Key('report-rows'),
                              itemCount: table.rows.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: palette.border),
                              itemBuilder: (context, index) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    for (var c = 0;
                                        c < table.columns.length;
                                        c++)
                                      _Cell(table.rows[index][c],
                                          table.columns[c].width),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, this.width, {this.header = false});

  final String text;
  final double width;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: header ? 13 : 13.5,
            fontWeight: header ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
