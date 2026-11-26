import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/prep_receipt.dart';

/// Builds the thermal-style «إيصال تحضير طلب توصيل» PDF with cashier QR.
abstract final class PrepReceiptPdf {
  static String _money(num value) => value.toStringAsFixed(2);

  static Future<Uint8List> buildBytes(PrepReceipt receipt) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final theme = pw.ThemeData.withFont(base: font, bold: bold);
    final when = DateFormat('dd/MM/yyyy hh:mm a').format(receipt.createdAt);

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        build: (context) {
          pw.Widget line(String label, String value) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$label: ',
                        style: pw.TextStyle(font: bold, fontSize: 9)),
                    pw.Expanded(
                      child: pw.Text(value,
                          style: pw.TextStyle(font: font, fontSize: 9)),
                    ),
                  ],
                ),
              );

          pw.Widget sep() => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Divider(thickness: 0.6, color: PdfColors.grey600),
              );

          final blocks = <pw.Widget>[
            pw.Center(
              child: pw.Text(
                'إيصال تحضير طلب توصيل',
                style: pw.TextStyle(font: bold, fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                receipt.storeName,
                style: pw.TextStyle(font: bold, fontSize: 11),
              ),
            ),
            pw.Center(
              child: pw.Text(
                receipt.branchName,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: receipt.cashierQrPayload,
                width: 110,
                height: 110,
                drawText: false,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                receipt.cashierQrPayload,
                style: pw.TextStyle(font: font, fontSize: 6.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            sep(),
            // Order source — bold header cue (app = inverted black box).
            if (receipt.isAppOrder)
              pw.Container(
                width: double.infinity,
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  border: pw.Border.all(color: PdfColors.black, width: 1.2),
                ),
                child: pw.Center(
                  child: pw.Text(
                    receipt.orderSourceLabel,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              )
            else
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Center(
                  child: pw.Text(
                    receipt.orderSourceLabel,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 10,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            line('الفرع', '${receipt.branchName} (${receipt.branchCode})'),
            line(
              'رقم الطلب',
              receipt.fujitsuOrderId ?? receipt.receiptNumber,
            ),
            line('وقت الطلب', when),
            line('المتلقي', receipt.takerName ?? '—'),
            line('المحضر', receipt.preparerName ?? '—'),
            sep(),
            line('العميل', receipt.customerName ?? '—'),
            line('تليفون', receipt.phonesLabel),
            line('وسيلة الدفع', receipt.paymentLabel),
            line('العنوان', receipt.address ?? '—'),
            sep(),
            pw.Row(
              children: [
                pw.Expanded(
                    child: pw.Text('الصنف',
                        style: pw.TextStyle(font: bold, fontSize: 8))),
                pw.SizedBox(
                    width: 36,
                    child: pw.Text('السعر',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: bold, fontSize: 8))),
                pw.SizedBox(
                    width: 42,
                    child: pw.Text('الكمية',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: bold, fontSize: 8))),
                pw.SizedBox(
                    width: 40,
                    child: pw.Text('القيمة',
                        textAlign: pw.TextAlign.left,
                        style: pw.TextStyle(font: bold, fontSize: 8))),
              ],
            ),
            pw.Divider(thickness: 0.4),
          ];

          for (final entry in receipt.byCategory.entries) {
            blocks.add(pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
              child: pw.Text(entry.key,
                  style: pw.TextStyle(font: bold, fontSize: 8.5)),
            ));
            for (final item in entry.value) {
              blocks.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(item.productName,
                        style: pw.TextStyle(font: font, fontSize: 8)),
                    if (item.barcode != null)
                      pw.Text(item.barcode!,
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 7,
                              color: PdfColors.grey700)),
                    if (item.trimmedNotes case final note?)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 1, bottom: 1),
                        child: pw.Text(
                          'ملاحظة: $note',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 8,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    if (item.hasDiscount)
                      pw.Text(
                        'خصم: ${_money(item.displayPrice)} ← ${_money(item.unitPrice)}',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 7,
                            color: PdfColors.orange800),
                      ),
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.SizedBox()),
                        pw.SizedBox(
                          width: 36,
                          child: pw.Text(_money(item.unitPrice),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(font: font, fontSize: 8)),
                        ),
                        pw.SizedBox(
                          width: 42,
                          child: pw.Text(item.quantityLabel,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(font: font, fontSize: 7.5)),
                        ),
                        pw.SizedBox(
                          width: 40,
                          child: pw.Text(_money(item.lineTotal),
                              textAlign: pw.TextAlign.left,
                              style: pw.TextStyle(font: bold, fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ));
            }
          }

          blocks.addAll([
            sep(),
            line('خدمة التوصيل', _money(receipt.deliveryFee)),
            line('إجمالي الأصناف', _money(receipt.itemsTotal)),
            line('الإجمالي شامل التوصيل', _money(receipt.totalAmount)),
            line('عدد الأصناف', '${receipt.itemCount}'),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'امسح الـ QR على الكاشير',
                style: pw.TextStyle(font: bold, fontSize: 9),
              ),
            ),
          ]);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: blocks,
          );
        },
      ),
    );
    return doc.save();
  }

  static Future<void> print(PrepReceipt receipt) async {
    final bytes = await buildBytes(receipt);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'إيصال-${receipt.receiptNumber}',
    );
  }

  static Future<void> share(PrepReceipt receipt) async {
    final bytes = await buildBytes(receipt);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'prep_receipt_${receipt.receiptNumber}.pdf',
    );
  }
}
