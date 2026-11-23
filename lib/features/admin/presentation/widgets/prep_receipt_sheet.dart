import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/prep_receipt_pdf.dart';
import '../../domain/prep_receipt.dart';

/// Opens the prep receipt (preview + print / share) for [orderId].
Future<void> showPrepReceiptSheet(
  BuildContext context, {
  required String orderId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PrepReceiptSheet(orderId: orderId),
  );
}

class _PrepReceiptSheet extends ConsumerStatefulWidget {
  const _PrepReceiptSheet({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_PrepReceiptSheet> createState() => _PrepReceiptSheetState();
}

class _PrepReceiptSheetState extends ConsumerState<_PrepReceiptSheet> {
  PrepReceipt? _receipt;
  Object? _error;
  var _loading = true;
  var _busy = false;
  var _pollingFujitsu = false;
  Timer? _pollTimer;
  var _pollAttempts = 0;

  static const _maxPollAttempts = 15; // ~30s at 2s interval
  static const _pollInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool fromPoll = false}) async {
    if (!fromPoll) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final raw = await Supabase.instance.client.rpc(
        'get_order_prep_receipt',
        params: {'p_order_id': widget.orderId},
      );
      if (!mounted) return;
      if (raw is! Map) {
        throw Exception('استجابة غير متوقعة من السيرفر');
      }
      final receipt =
          PrepReceipt.fromJson(Map<String, dynamic>.from(raw));
      setState(() {
        _receipt = receipt;
        _loading = false;
        _error = null;
      });
      _maybeStartFujitsuPoll(receipt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _maybeStartFujitsuPoll(PrepReceipt receipt) {
    if (!receipt.waitingFujitsu || receipt.hasFujitsuIds) {
      _pollTimer?.cancel();
      _pollingFujitsu = false;
      return;
    }
    if (_pollTimer != null) return;
    _pollingFujitsu = true;
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted) {
        _pollTimer?.cancel();
        return;
      }
      _pollAttempts++;
      if (_pollAttempts > _maxPollAttempts) {
        _pollTimer?.cancel();
        _pollTimer = null;
        if (mounted) setState(() => _pollingFujitsu = false);
        return;
      }
      await _load(fromPoll: true);
      final current = _receipt;
      if (current != null &&
          (!current.waitingFujitsu || current.hasFujitsuIds)) {
        _pollTimer?.cancel();
        _pollTimer = null;
        if (mounted) setState(() => _pollingFujitsu = false);
      }
    });
  }

  Future<void> _run(Future<void> Function(PrepReceipt) action) async {
    final receipt = _receipt;
    if (receipt == null || receipt.waitingFujitsu) return;
    setState(() => _busy = true);
    try {
      await action(receipt);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر إنشاء الإيصال: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final canPrint = _receipt != null &&
        !_receipt!.waitingFujitsu &&
        _receipt!.qrPayload.isNotEmpty;

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
                      'إيصال تحضير طلب توصيل',
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
            if (_receipt != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        key: const Key('prep-receipt-print'),
                        onPressed: (_busy || !canPrint)
                            ? null
                            : () => _run(PrepReceiptPdf.print),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text('طباعة'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('prep-receipt-share'),
                        onPressed: (_busy || !canPrint)
                            ? null
                            : () => _run(PrepReceiptPdf.share),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('مشاركة PDF'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('prep-receipt-copy-qr'),
                        onPressed: (_busy || !canPrint)
                            ? null
                            : () async {
                                final qr = _receipt!.cashierQrPayload;
                                await Clipboard.setData(
                                    ClipboardData(text: qr));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم نسخ بيانات الـ QR')),
                                );
                              },
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('نسخ QR'),
                      ),
                    ],
                  ),
                ),
              ),
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
              Text('تعذّر تحميل الإيصال:\n$_error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
              const SizedBox(height: 8),
              Text(
                'شغّل في Supabase:\n20261124010000_fujitsu_order_sync.sql',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
      );
    }
    final r = _receipt!;
    if (r.waitingFujitsu) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              const Text(
                'جاري تسجيل الطلب على الكاشير...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _pollingFujitsu
                    ? 'انتظار رقم الطلب من فوجيتسو'
                    : 'أعد المحاولة بعد تشغيل جسر المزامنة',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted),
              ),
              if (r.fujitsuSyncError != null) ...[
                const SizedBox(height: 12),
                Text(
                  r.fujitsuSyncError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _pollTimer?.cancel();
                  _pollTimer = null;
                  _pollAttempts = 0;
                  _load();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
          ),
        ),
      );
    }

    final when = DateFormat('dd/MM/yyyy hh:mm a').format(r.createdAt);
    final qr = r.cashierQrPayload;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(r.storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(r.branchName,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Center(
          child: QrImageView(
            data: qr,
            size: 180,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          qr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const Divider(height: 28),
        _kv('الفرع', '${r.branchName} (${r.branchCode})'),
        _kv('رقم الطلب', r.fujitsuOrderId ?? r.receiptNumber),
        if (r.fujitsuCustomerNo != null)
          _kv('رقم العميل (فوجيتسو)', r.fujitsuCustomerNo!),
        if (r.fujitsuAddressId != null)
          _kv('عنوان فوجيتسو', r.fujitsuAddressId!),
        _kv('وقت الطلب', when),
        _kv('المتلقي', r.takerName ?? '—'),
        _kv('المحضر', r.preparerName ?? '—'),
        const Divider(height: 28),
        _kv('العميل', r.customerName ?? '—'),
        _kv('تليفون', r.phonesLabel),
        _kv('وسيلة الدفع', r.paymentLabel),
        _kv('العنوان', r.address ?? '—'),
        const Divider(height: 28),
        for (final entry in r.byCategory.entries) ...[
          Text(entry.key,
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: palette.accent)),
          const SizedBox(height: 6),
          for (final item in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (item.barcode != null)
                    Text('باركود: ${item.barcode}',
                        style:
                            TextStyle(fontSize: 12, color: palette.muted)),
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
