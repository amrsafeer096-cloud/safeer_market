import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/order_search_service.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_status.dart';
import '../providers/order_search_providers.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/order_detail_panels.dart';
import 'unified_dashboard_screen.dart';

/// «بحث»: filter every order by customer phone, source, date, staff,
/// status or number; the results are listed with the full details (and
/// products) of the selected one beside them.
class AdminOrderSearchView extends ConsumerStatefulWidget {
  const AdminOrderSearchView({super.key});

  @override
  ConsumerState<AdminOrderSearchView> createState() =>
      _AdminOrderSearchViewState();
}

class _AdminOrderSearchViewState extends ConsumerState<AdminOrderSearchView> {
  static const _fieldWidth = 190.0;

  final _phone = TextEditingController();
  final _receiver = TextEditingController();
  final _orderNumber = TextEditingController();
  OrderSearchSource _source = OrderSearchSource.all;
  DateTime? _date;
  String? _preparer;
  String? _driver;
  String? _status;

  /// Bumped by «مسح» so the dropdowns rebuild with their initial values.
  int _resetTick = 0;

  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  Object? _error;
  String? _selectedId;

  @override
  void dispose() {
    _phone.dispose();
    _receiver.dispose();
    _orderNumber.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = OrderSearchQuery(
      customerPhone: _phone.text,
      source: _source,
      date: _date,
      receiver: _receiver.text,
      preparer: _preparer,
      driver: _driver,
      status: _status,
      orderNumber: _orderNumber.text,
    );
    final number = _orderNumber.text;
    setState(() {
      _loading = true;
      _error = null;
      _selectedId = null;
    });
    try {
      final rows = await ref.read(orderSearchProvider)(query);
      if (!mounted) return;
      setState(() {
        _results = rows.where((o) => orderMatchesNumber(o, number)).toList();
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

  void _clear() {
    _phone.clear();
    _receiver.clear();
    _orderNumber.clear();
    setState(() {
      _source = OrderSearchSource.all;
      _date = null;
      _preparer = null;
      _driver = null;
      _status = null;
      _results = null;
      _error = null;
      _selectedId = null;
      _resetTick++;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final selected = _selectedOrder();
            final results = _buildResults(context);
            final details = _buildDetails(context, selected);

            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: results),
                    const SizedBox(width: 12),
                    Expanded(flex: 6, child: details),
                  ],
                ),
              );
            }
            if (selected == null) {
              return Padding(padding: const EdgeInsets.all(12), child: results);
            }
            return Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('search-back'),
                    onPressed: () => setState(() => _selectedId = null),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('رجوع للنتائج'),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: details,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Map<String, dynamic>? _selectedOrder() {
    final id = _selectedId;
    if (id == null) return null;
    for (final order in _results ?? const <Map<String, dynamic>>[]) {
      if (order['id'] == id) return order;
    }
    return null;
  }

  // ---------------------------------------------------------- filter bar

  Widget _buildFilterBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final staff = ref.watch(activeStaffProvider).valueOrNull ?? const [];
    List<String> names(String role) => [
          for (final member in staff)
            if (member['role'] == role) '${member['name']}',
        ];

    Widget field(Widget child) => SizedBox(width: _fieldWidth, child: child);

    InputDecoration decoration(String label, {IconData? icon}) =>
        InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          prefixIcon: icon == null ? null : Icon(icon, size: 18),
        );

    Widget dropdown<T>({
      required Key key,
      required String label,
      required T? value,
      required List<DropdownMenuItem<T?>> items,
      required ValueChanged<T?> onChanged,
    }) =>
        field(DropdownButtonFormField<T?>(
          key: ValueKey('${key.toString()}-$_resetTick'),
          initialValue: value,
          isExpanded: true,
          decoration: decoration(label),
          items: items,
          onChanged: onChanged,
        ));

    DropdownMenuItem<String?> nameItem(String name) =>
        DropdownMenuItem(value: name, child: Text(name));
    const allLabel = Text('الكل');

    final statusLabels = <String, String>{
      OrderStatus.pending.value: l10n.statusNew,
      OrderStatus.preparing.value: l10n.adminStatusPreparingShort,
      OrderStatus.readyForDelivery.value: l10n.adminStatusReadyForDriverShort,
      OrderStatus.outForDelivery.value: l10n.adminStatusDeliveryShort,
      OrderStatus.delivered.value: l10n.adminStatusCompletedShort,
      OrderStatus.cancelled.value: l10n.adminStatusCancelledShort,
    };

    return Container(
      key: const Key('search-filter-bar'),
      width: double.infinity,
      color: palette.card,
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          field(TextField(
            key: const Key('search-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: decoration(
              'رقم العميل / فوجيتسو',
              icon: Icons.phone,
            ),
          )),
          dropdown<OrderSearchSource>(
            key: const Key('search-source'),
            label: 'مصدر الطلب',
            value: _source,
            items: const [
              DropdownMenuItem(value: OrderSearchSource.all, child: allLabel),
              DropdownMenuItem(
                  value: OrderSearchSource.app, child: Text('التطبيق')),
              DropdownMenuItem(
                  value: OrderSearchSource.phone, child: Text('المتلقي')),
            ],
            onChanged: (v) => setState(() => _source = v ?? OrderSearchSource.all),
          ),
          field(InkWell(
            key: const Key('search-date'),
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: decoration('التاريخ', icon: Icons.event).copyWith(
                suffixIcon: _date == null
                    ? null
                    : IconButton(
                        key: const Key('search-date-clear'),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _date = null),
                      ),
              ),
              child: Text(
                _date == null
                    ? 'الكل'
                    : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: _date == null ? palette.muted : palette.onSurface),
              ),
            ),
          )),
          field(TextField(
            key: const Key('search-receiver'),
            controller: _receiver,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: decoration('المتلقي', icon: Icons.support_agent),
          )),
          dropdown<String>(
            key: const Key('search-preparer'),
            label: 'المحضر',
            value: _preparer,
            items: [
              const DropdownMenuItem(value: null, child: allLabel),
              for (final name in names('preparer')) nameItem(name),
            ],
            onChanged: (v) => setState(() => _preparer = v),
          ),
          dropdown<String>(
            key: const Key('search-driver'),
            label: 'الطيار',
            value: _driver,
            items: [
              const DropdownMenuItem(value: null, child: allLabel),
              for (final name in names('driver')) nameItem(name),
            ],
            onChanged: (v) => setState(() => _driver = v),
          ),
          dropdown<String>(
            key: const Key('search-status'),
            label: 'حالة الطلب',
            value: _status,
            items: [
              const DropdownMenuItem(value: null, child: allLabel),
              for (final entry in statusLabels.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          field(TextField(
            key: const Key('search-order-number'),
            controller: _orderNumber,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: decoration(
              'رقم الطلب / فوجيتسو',
              icon: Icons.tag,
            ),
          )),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              key: const Key('search-submit'),
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search_rounded),
              label: const Text('بحث',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          TextButton(
            key: const Key('search-clear'),
            onPressed: _clear,
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- results

  Widget _buildResults(BuildContext context) {
    final palette = context.palette;
    final results = _results;

    Widget message(String text, {IconData icon = Icons.search_rounded}) =>
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: palette.muted),
              const SizedBox(height: 8),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: palette.muted)),
            ],
          ),
        );

    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = message('تعذّر البحث: $_error', icon: Icons.error_outline);
    } else if (results == null) {
      body = message('حدّد معايير البحث ثم اضغط «بحث»');
    } else if (results.isEmpty) {
      body = message('لا توجد طلبات مطابقة',
          icon: Icons.search_off_rounded);
    } else {
      body = _ResultsTable(
        orders: results,
        selectedId: _selectedId,
        onSelect: (id) => setState(() => _selectedId = id),
      );
    }

    return Container(
      key: const Key('search-results'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              results == null
                  ? 'النتائج'
                  : 'النتائج (${results.length})',
              key: const Key('search-results-title'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: palette.accent),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- details

  Widget _buildDetails(BuildContext context, Map<String, dynamic>? order) {
    final palette = context.palette;
    if (order == null) {
      return Container(
        key: const Key('search-details-empty'),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'اختر طلباً من النتائج لعرض تفاصيله',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: palette.muted),
        ),
      );
    }
    return _SearchOrderDetails(key: ValueKey(order['id']), order: order);
  }
}

String? _clean(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

({String? name, String? phone}) _resolveCustomer(
  Map<String, dynamic> order,
  Map<String, OrderCustomer> profiles,
) {
  final profile = profiles[order['user_id']?.toString()];
  return (
    name: _clean(order['customer_name']) ?? profile?.fullName,
    phone: _clean(order['customer_phone']) ?? profile?.phone,
  );
}

String _customerIdsKey(List<Map<String, dynamic>> orders) {
  final ids = {
    for (final order in orders)
      if (order['user_id'] != null) order['user_id'].toString(),
  }.toList()
    ..sort();
  return ids.join(',');
}

class _ResultsTable extends ConsumerWidget {
  const _ResultsTable({
    required this.orders,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> orders;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final profiles = ref
            .watch(orderCustomersProvider(_customerIdsKey(orders)))
            .valueOrNull ??
        const <String, OrderCustomer>{};

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = '${order['id']}';
        final customer = _resolveCustomer(order, profiles);
        final created =
            DateTime.tryParse('${order['created_at'] ?? ''}')?.toLocal();
        final total = double.tryParse('${order['total_amount']}') ?? 0;
        final isPhone = order['order_source'] == 'phone';
        final selected = id == selectedId;

        return InkWell(
          key: Key('search-result-$id'),
          onTap: () => onSelect(id),
          child: Container(
            color: selected ? palette.accent.withValues(alpha: 0.1) : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${id.length > 6 ? id.substring(0, 6) : id}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      Text(
                        isPhone ? 'المتلقي' : 'التطبيق',
                        style: TextStyle(fontSize: 11, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (customer.phone != null)
                        Text(
                          customer.phone!,
                          textDirection: TextDirection.ltr,
                          style:
                              TextStyle(fontSize: 12, color: palette.muted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DashboardStatusBadge(status: '${order['status'] ?? ''}'),
                    const SizedBox(height: 4),
                    Text(
                      AppCurrency.of(total),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                    if (created != null)
                      Text(
                        adminDateFormat.format(created),
                        style: TextStyle(fontSize: 11, color: palette.muted),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchOrderDetails extends ConsumerWidget {
  const _SearchOrderDetails({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref
            .watch(orderCustomersProvider(_customerIdsKey([order])))
            .valueOrNull ??
        const <String, OrderCustomer>{};
    final customer = _resolveCustomer(order, profiles);

    return SingleChildScrollView(
      key: const Key('search-details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderInfoCard(
            order: order,
            customerName: customer.name,
            customerPhone: customer.phone,
          ),
          const SizedBox(height: 12),
          OrderPanel(
            title: 'المنتجات',
            icon: Icons.shopping_basket_outlined,
            child: OrderProductsList(orderId: '${order['id']}'),
          ),
        ],
      ),
    );
  }
}
