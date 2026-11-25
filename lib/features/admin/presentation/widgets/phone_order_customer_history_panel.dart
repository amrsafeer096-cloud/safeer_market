import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';

/// Far-left Trusty-style panel: previous orders + frequent items.
class PhoneOrderCustomerHistoryPanel extends ConsumerStatefulWidget {
  const PhoneOrderCustomerHistoryPanel({
    super.key,
    required this.customer,
    this.onAddProduct,
  });

  final PhoneOrderCustomer customer;
  final Future<void> Function(Product product)? onAddProduct;

  @override
  ConsumerState<PhoneOrderCustomerHistoryPanel> createState() =>
      _PhoneOrderCustomerHistoryPanelState();
}

class _PhoneOrderCustomerHistoryPanelState
    extends ConsumerState<PhoneOrderCustomerHistoryPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      key: const Key('phone-order-customer-history'),
      color: palette.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'الطلبات السابقة'),
              Tab(text: 'أصناف العميل'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PastOrdersTab(customerKey: widget.customer.key),
                _FrequentItemsTab(
                  customerKey: widget.customer.key,
                  onAddProduct: widget.onAddProduct,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastOrdersTab extends ConsumerWidget {
  const _PastOrdersTab({required this.customerKey});

  final String customerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final async = ref.watch(phoneOrderCustomerPastOrdersProvider(customerKey));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات سابقة',
              style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
            ),
          );
        }
        final dateFmt = DateFormat('dd/MM/yyyy');
        return Column(
          children: [
            Container(
              color: palette.background,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('رقم الطلب',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('التاريخ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('الإجمالي',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final o = orders[i];
                  return InkWell(
                    onTap: () => showPastOrderDetailDialog(context, o.orderId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              o.displayNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              dateFmt.format(o.createdAt),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: palette.muted),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              AppCurrency.of(o.totalAmount),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FrequentItemsTab extends ConsumerWidget {
  const _FrequentItemsTab({
    required this.customerKey,
    this.onAddProduct,
  });

  final String customerKey;
  final Future<void> Function(Product product)? onAddProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final async = ref.watch(phoneOrderCustomerHistoryProvider(customerKey));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (history) {
        final items = history.mostFrequent;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'لا توجد أصناف سابقة',
              style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = items[i];
            final product = item.product;
            return InkWell(
              onTap: () => _addOrDetails(context, ref, product),
              onDoubleTap: () => _addOrDetails(context, ref, product),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.barcode ?? '—',
                            style: TextStyle(
                                fontSize: 11.5, color: palette.muted),
                          ),
                        ),
                        Text(
                          AppCurrency.of(product.effectivePrice),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'طُلب ${item.timesOrdered} مرة',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addOrDetails(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    if (onAddProduct != null) {
      await onAddProduct!(product);
      return;
    }
    ref.read(phoneOrderControllerProvider.notifier).add(product);
  }
}

Future<void> showPastOrderDetailDialog(
  BuildContext context,
  String orderId,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _PastOrderDetailDialog(orderId: orderId),
  );
}

class _PastOrderDetailDialog extends ConsumerStatefulWidget {
  const _PastOrderDetailDialog({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_PastOrderDetailDialog> createState() =>
      _PastOrderDetailDialogState();
}

class _PastOrderDetailDialogState
    extends ConsumerState<_PastOrderDetailDialog> {
  CustomerPastOrderDetail? _detail;
  Object? _error;
  var _loading = true;
  var _repeating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ref
          .read(phoneOrdersRepositoryProvider)
          .fetchCustomerPastOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _repeat() async {
    final detail = _detail;
    if (detail == null || detail.lines.isEmpty) return;
    setState(() => _repeating = true);
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    for (final line in detail.lines) {
      if (line.weightInGrams != null && line.weightInGrams! > 0) {
        controller.setWeight(line.product, line.weightInGrams!);
      } else {
        controller.addQuantity(line.product, line.quantity);
      }
    }
    if (detail.summary.deliveryFee > 0) {
      controller.setDeliveryFee(detail.summary.deliveryFee);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _paymentLabel(String? raw) => switch ((raw ?? '').toLowerCase()) {
        'cash' || 'cash_on_delivery' => 'نقدي',
        'visa_on_delivery' => 'فيزا عند الاستلام',
        'card' || 'visa' => 'ائتمان',
        'instapay' => 'إنستا باي',
        _ => (raw?.trim().isNotEmpty ?? false) ? raw!.trim() : '—',
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dateFmt = DateFormat('dd/MM/yyyy hh:mm a');
    return AlertDialog(
      title: const Text('تفاصيل الطلب',
          style: TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 460,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('$_error', textAlign: TextAlign.center))
                : _detail == null
                    ? const Center(child: Text('لا بيانات'))
                    : ListView(
                        children: [
                          _kv('رقم الطلب', _detail!.summary.displayNumber),
                          _kv('التاريخ',
                              dateFmt.format(_detail!.summary.createdAt)),
                          _kv('المتلقي', _detail!.summary.takerName ?? '—'),
                          _kv('المحضر', _detail!.summary.preparerName ?? '—'),
                          _kv('السائق', _detail!.summary.driverName ?? '—'),
                          _kv(
                            'الدفع',
                            _paymentLabel(_detail!.summary.paymentMethod),
                          ),
                          _kv(
                            'التوصيل',
                            AppCurrency.of(_detail!.summary.deliveryFee),
                          ),
                          _kv(
                            'الإجمالي',
                            AppCurrency.of(_detail!.summary.totalAmount),
                          ),
                          const Divider(height: 20),
                          Text(
                            'الأصناف (${_detail!.lines.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final line in _detail!.lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      line.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    line.isWeightBased
                                        ? WeightOptions.phoneOrderLabel(
                                            line.weightInGrams ?? 0)
                                        : '× ${line.quantity}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton.icon(
          onPressed: (_detail == null ||
                  _detail!.lines.isEmpty ||
                  _repeating)
              ? null
              : _repeat,
          icon: _repeating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.replay_rounded),
          label: const Text('تكرار الطلب'),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(k,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
