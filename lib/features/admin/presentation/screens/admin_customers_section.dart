import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/phone_order.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';
import '../widgets/new_customer_dialogs.dart';

/// «العملاء»: search the customer list (phone, name or address), see a
/// customer's details, add one and — with permission — delete one.
class AdminCustomersSection extends ConsumerStatefulWidget {
  const AdminCustomersSection({super.key});

  @override
  ConsumerState<AdminCustomersSection> createState() =>
      _AdminCustomersSectionState();
}

class _AdminCustomersSectionState extends ConsumerState<AdminCustomersSection> {
  static const searchDebounce = Duration(milliseconds: 350);

  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int? _selectedId;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  Future<void> _add() async {
    final customer = await showDialog<PhoneOrderCustomer>(
      context: context,
      builder: (_) => const NewCustomerDialog(initialName: '', initialPhone: ''),
    );
    if (customer == null || !mounted) return;
    showAdminSnack(context, 'تمت إضافة العميل');
    _search.text = customer.phone ?? customer.fullName ?? '';
    setState(() {
      _query = _search.text.trim();
      _selectedId = customer.posCustomerId;
    });
    ref.invalidate(adminCustomersProvider);
  }

  Future<void> _delete(AdminCustomer customer) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'حذف العميل',
      message: 'سيتم حذف «${customer.name}» نهائياً. هل أنت متأكد؟',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(systemAdminServiceProvider).deleteCustomer(customer.id);
      if (!mounted) return;
      showAdminSnack(context, 'تم حذف العميل');
      setState(() => _selectedId = null);
      ref.invalidate(adminCustomersProvider);
    } catch (error) {
      if (mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = ref.watch(adminCanProvider(AdminPermission.manageCustomers));
    final customers = ref.watch(adminCustomersProvider(_query));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            title: 'العملاء',
            actions: [
              if (canAdd)
                FilledButton.icon(
                  key: const Key('customers-add'),
                  onPressed: _add,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('إضافة عميل'),
                ),
            ],
          ),
          TextField(
            key: const Key('customers-search'),
            controller: _search,
            onChanged: _onChanged,
            onSubmitted: (text) => setState(() => _query = text.trim()),
            decoration: const InputDecoration(
              hintText: 'ابحث برقم الهاتف أو الاسم أو العنوان',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: customers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AdminMessage(describeAdminError(error),
                  icon: Icons.error_outline),
              data: (list) => _buildList(list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AdminCustomer> customers) {
    if (customers.isEmpty) {
      return const AdminMessage('لا يوجد عملاء مطابقون',
          icon: Icons.person_search_rounded);
    }
    AdminCustomer? selected;
    for (final customer in customers) {
      if (customer.id == _selectedId) selected = customer;
    }

    final list = _CustomerList(
      customers: customers,
      selectedId: _selectedId,
      onSelect: (customer) {
        if (MediaQuery.sizeOf(context).width >= 900) {
          setState(() => _selectedId = customer.id);
        } else {
          setState(() => _selectedId = customer.id);
          showDialog<void>(
            context: context,
            builder: (ctx) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _CustomerDetails(
                    customer: customer,
                    canDelete: ref
                        .read(adminCanProvider(AdminPermission.deleteCustomers)),
                    onDelete: () {
                      Navigator.pop(ctx);
                      _delete(customer);
                    },
                  ),
                ),
              ),
            ),
          );
        }
      },
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 900) return list;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: list),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: selected == null
                ? const _Panel(
                    child: AdminMessage('اختر عميلاً لعرض بياناته',
                        icon: Icons.person_outline_rounded),
                  )
                : SingleChildScrollView(
                    child: _CustomerDetails(
                      customer: selected,
                      canDelete: ref.watch(
                          adminCanProvider(AdminPermission.deleteCustomers)),
                      onDelete: () => _delete(selected!),
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.customers,
    required this.selectedId,
    required this.onSelect,
  });

  final List<AdminCustomer> customers;
  final int? selectedId;
  final ValueChanged<AdminCustomer> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('customers-list'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView.separated(
        itemCount: customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return ListTile(
            key: Key('customer-${customer.id}'),
            selected: customer.id == selectedId,
            selectedTileColor: palette.accent.withValues(alpha: 0.1),
            onTap: () => onSelect(customer),
            leading: CircleAvatar(
              backgroundColor: palette.accent.withValues(alpha: 0.12),
              child: Icon(
                customer.isVip ? Icons.workspace_premium : Icons.person,
                color: customer.isVip ? Colors.amber.shade800 : palette.accent,
              ),
            ),
            title: Text(customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              [
                for (final p in customer.phoneSlots)
                  if ((p ?? '').trim().isNotEmpty) p!,
                if (customer.address != null) customer.address!,
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: customer.ordersCount == 0
                ? null
                : Text('${customer.ordersCount} طلب',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: palette.muted)),
          );
        },
        ),
      ),
    );
  }
}

class _CustomerDetails extends StatelessWidget {
  const _CustomerDetails({
    required this.customer,
    required this.canDelete,
    required this.onDelete,
  });

  final AdminCustomer customer;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget row(String label, String? value, {bool ltr = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: palette.muted)),
              ),
              Expanded(
                child: Text(
                  value ?? '—',
                  textDirection: ltr ? TextDirection.ltr : null,
                  textAlign: ltr ? TextAlign.start : null,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );

    final last = customer.lastOrderAt;
    return Container(
      key: const Key('customer-details'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(customer.name,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900)),
              ),
              if (customer.isVip)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('VIP',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900)),
                ),
            ],
          ),
          const Divider(height: 24),
          row(
            'الهواتف',
            [
              for (final p in customer.phoneSlots)
                if ((p ?? '').trim().isNotEmpty) p!,
            ].toSet().join(' / '),
            ltr: true,
          ),
          row('العنوان', customer.address),
          row('المحافظة', customer.governorate),
          row('المدينة', customer.city),
          row('المنطقة', customer.zone),
          row('المبنى / الدور / الشقة', [
            customer.building,
            customer.floor,
            customer.apartment,
          ].map((e) => e ?? '—').join(' / ')),
          row(
              'موقع GPS',
              customer.hasPin
                  ? '${customer.latitude!.toStringAsFixed(5)}, ${customer.longitude!.toStringAsFixed(5)}'
                  : null,
              ltr: true),
          const Divider(height: 24),
          row('عدد الطلبات', '${customer.ordersCount}'),
          row('إجمالي المشتريات', AppCurrency.of(customer.totalSpent)),
          row(
              'آخر طلب',
              last == null
                  ? null
                  : '${last.year}-${last.month.toString().padLeft(2, '0')}-${last.day.toString().padLeft(2, '0')}'),
          if (canDelete) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('customer-delete'),
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('حذف العميل'),
            ),
          ],
        ],
      ),
    );
  }
}
