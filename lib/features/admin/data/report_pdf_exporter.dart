import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/reports.dart';

/// Builds a printable Arabic RTL PDF from a [ReportTable].
abstract final class ReportPdfExporter {
  static Future<Uint8List> buildBytes(ReportTable table) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final theme = pw.ThemeData.withFont(base: font, bold: bold);

    final doc = pw.Document(theme: theme);
    final generatedAt =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'سفير ماركت — ${table.title}',
              style: pw.TextStyle(
                font: bold,
                fontSize: 16,
              ),
              textAlign: pw.TextAlign.right,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'تاريخ التصدير: $generatedAt',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700),
              textAlign: pw.TextAlign.right,
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (context) => [
          if (table.summary.isNotEmpty) ...[
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final stat in table.summary)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blueGrey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(stat.label,
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 9,
                                color: PdfColors.grey700)),
                        pw.Text(stat.value,
                            style: pw.TextStyle(font: bold, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
          if (table.columns.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: [for (final c in table.columns) c.label],
              data: [
                for (final row in table.rows) [for (final cell in row) cell],
              ],
              headerStyle: pw.TextStyle(
                font: bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4, vertical: 3),
            )
          else
            pw.Text('لا توجد أعمدة في هذا التقرير',
                style: pw.TextStyle(font: font)),
        ],
        footer: (context) => pw.Text(
          'صفحة ${context.pageNumber} / ${context.pagesCount}',
          style: pw.TextStyle(
              font: font, fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );

    return doc.save();
  }

  static String _safeFileName(String title) {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final clean = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return 'safeer_${clean}_$stamp.pdf';
  }

  /// Opens the system print / PDF dialog.
  static Future<void> print(ReportTable table) async {
    final bytes = await buildBytes(table);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: table.title,
    );
  }

  /// Share / save the PDF (native share sheet, or browser download on web).
  static Future<void> share(ReportTable table) async {
    final bytes = await buildBytes(table);
    final name = _safeFileName(table.title);
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: name);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: name,
          ),
        ],
        subject: table.title,
        fileNameOverrides: [name],
      ),
    );
  }

  /// Download / export as PDF.
  static Future<void> export(ReportTable table) async {
    final bytes = await buildBytes(table);
    final name = _safeFileName(table.title);
    await Printing.sharePdf(bytes: bytes, filename: name);
  }
}
