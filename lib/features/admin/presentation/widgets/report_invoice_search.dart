import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/invoice_lookup_service.dart';
import '../../domain/entities/order_status.dart';
import 'invoice_preview_sheet.dart';

/// Search bar + results for invoice preview inside «التقارير واليومية».
class ReportInvoiceSearch extends StatefulWidget {
  const ReportInvoiceSearch({super.key});

  @override
  State<ReportInvoiceSearch> createState() => _ReportInvoiceSearchState();
}

class _ReportInvoiceSearchState extends State<ReportInvoiceSearch> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _loading = false;
  Object? _error;
  List<Map<String, dynamic>> _hits = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.length < 2) {
      setState(() {
        _hits = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    try {
      final hits = await searchReportInvoices(
        Supabase.instance.client,
        query,
      );
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _hits = hits;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
        _hits = const [];
      });
    }
  }

  String _statusLabel(Object? raw) {
    final status = OrderStatus.normalize('${raw ?? ''}');
    return switch (status) {
      'pending' => 'جديد',
      'preparing' => 'تحضير',
      'ready_for_delivery' => 'للطيار',
      'out_for_delivery' => 'توصيل',
      'delivered' => 'مكتمل',
      'cancelled' => 'ملغي',
      _ => status,
    };
  }

  String _shortId(Map<String, dynamic> order) {
    final fujitsu = order['fujitsu_order_id']?.toString().trim();
    if (fujitsu != null && fujitsu.isNotEmpty) return fujitsu;
    final receipt = order['pos_receipt_number']?.toString().trim();
    if (receipt != null && receipt.isNotEmpty) return receipt;
    final id = '${order['id']}';
    return id.length >= 8 ? id.substring(0, 8) : id;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final query = _controller.text.trim();

    return Container(
      key: const Key('report-invoice-search'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بحث عن فاتورة',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ابحث باسم العميل أو رقم التليفون أو رقم الطلب / الفاتورة',
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('report-invoice-search-field'),
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _debounce?.cancel();
              if (value.trim().length >= 2) _run(value.trim());
            },
            decoration: InputDecoration(
              hintText: 'اسم / تليفون / رقم الطلب',
              isDense: true,
              prefixIcon: const Icon(Icons.receipt_long_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'مسح',
                      onPressed: () {
                        _debounce?.cancel();
                        _controller.clear();
                        setState(() {
                          _hits = const [];
                          _error = null;
                          _loading = false;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              'تعذّر البحث: $_error',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
          if (!_loading && query.length >= 2 && _hits.isEmpty && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'لا توجد نتائج',
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ),
          if (_hits.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                key: const Key('report-invoice-results'),
                shrinkWrap: true,
                itemCount: _hits.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: palette.border),
                itemBuilder: (context, index) {
                  final order = _hits[index];
                  final name =
                      (order['customer_name']?.toString().trim().isNotEmpty ??
                              false)
                          ? order['customer_name'].toString()
                          : 'عميل';
                  final phone =
                      (order['customer_phone'] ?? '').toString().trim();
                  final when = DateTime.tryParse('${order['created_at']}');
                  final whenLabel = when == null
                      ? ''
                      : DateFormat('dd/MM/yyyy HH:mm').format(when.toLocal());
                  final total = switch (order['total_amount']) {
                    final num n => n.toDouble(),
                    final String t => double.tryParse(t) ?? 0,
                    _ => 0.0,
                  };

                  return ListTile(
                    key: Key('report-invoice-hit-${order['id']}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        if (phone.isNotEmpty) phone,
                        '#${_shortId(order)}',
                        _statusLabel(order['status']),
                        if (whenLabel.isNotEmpty) whenLabel,
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    trailing: Text(
                      AppCurrency.of(total),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: palette.accent,
                      ),
                    ),
                    onTap: () => showInvoicePreviewSheet(
                      context,
                      orderId: '${order['id']}',
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
