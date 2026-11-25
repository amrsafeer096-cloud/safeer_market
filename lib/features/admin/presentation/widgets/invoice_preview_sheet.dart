import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/invoice_lookup_service.dart';
import '../../domain/prep_receipt.dart';

/// Receipt-style invoice preview for التقارير — **no QR** (not scannable).
Future<void> showInvoicePreviewSheet(
  BuildContext context, {
  required String orderId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _InvoicePreviewSheet(orderId: orderId),
  );
}

class _InvoicePreviewSheet extends StatefulWidget {
  const _InvoicePreviewSheet({required this.orderId});

  final String orderId;

  @override
  State<_InvoicePreviewSheet> createState() => _InvoicePreviewSheetState();
}

class _InvoicePreviewSheetState extends State<_InvoicePreviewSheet> {
  PrepReceipt? _receipt;
  Object? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final receipt = await loadInvoicePreview(
        Supabase.instance.client,
        widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return SizedBox(
      height: height,
      child: Material(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'معاينة الفاتورة',
                      key: Key('invoice-preview-title'),
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body(palette)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppPalette palette) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعذّر تحميل الفاتورة:\n$_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final r = _receipt!;
    final when = DateFormat('dd/MM/yyyy hh:mm a').format(r.createdAt);

    return ListView(
      key: const Key('invoice-preview-body'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          r.storeName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(
          r.branchName,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'عرض للمعاينة فقط — بدون رمز QR',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.orange.shade800,
          ),
        ),
        const Divider(height: 28),
        _kv('الفرع', '${r.branchName} (${r.branchCode})'),
        _kv('رقم الطلب', r.fujitsuOrderId ?? r.receiptNumber),
        _kv('وقت الطلب', when),
        _kv('المتلقي', r.takerName ?? '—'),
        _kv('المحضر', r.preparerName ?? '—'),
        _kv('الطيار', r.driverName ?? '—'),
        const Divider(height: 28),
        _kv('العميل', r.customerName ?? '—'),
        _kv('تليفون', r.phonesLabel),
        _kv('وسيلة الدفع', r.paymentLabel),
        _kv('العنوان', r.address ?? '—'),
        const Divider(height: 28),
        for (final entry in r.byCategory.entries) ...[
          Text(
            entry.key,
            style: TextStyle(fontWeight: FontWeight.w900, color: palette.accent),
          ),
          const SizedBox(height: 6),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (item.barcode != null)
                    Text(
                      'باركود: ${item.barcode}',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  if (item.hasDiscount)
                    Text(
                      'السعر: ${AppCurrency.of(item.displayPrice)}  ← بعد الخصم: ${AppCurrency.of(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade800,
                      ),
                    )
                  else
                    Text(
                      'السعر: ${AppCurrency.of(item.unitPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  Text(
                    'الكمية: ${item.quantity}  •  القيمة: ${AppCurrency.of(item.lineTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
        const Divider(height: 28),
        _kv('خدمة التوصيل', AppCurrency.of(r.deliveryFee)),
        _kv('إجمالي الأصناف', AppCurrency.of(r.itemsTotal)),
        _kv('الإجمالي شامل التوصيل', AppCurrency.of(r.totalAmount)),
        _kv('عدد الأصناف', '${r.itemCount}'),
      ],
    );
  }

  Widget _kv(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
