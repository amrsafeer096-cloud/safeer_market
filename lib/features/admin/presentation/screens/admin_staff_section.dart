import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/report_service.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/reports.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';
import 'admin_reports_view.dart';

/// «المحضرين» / «الطيارين»: search, add and delete, and open a member's
/// productivity report.
class AdminStaffSection extends ConsumerStatefulWidget {
  const AdminStaffSection({super.key, required this.role});

  /// `preparer` or `driver`.
  final String role;

  @override
  ConsumerState<AdminStaffSection> createState() => _AdminStaffSectionState();
}

class _AdminStaffSectionState extends ConsumerState<AdminStaffSection> {
  final _search = TextEditingController();
  String _query = '';

  bool get _isPreparer => widget.role == 'preparer';
  AdminPermission get _managePermission => _isPreparer
      ? AdminPermission.managePreparers
      : AdminPermission.manageDrivers;
  String get _title => _isPreparer ? 'المحضرين' : 'الطيارين';
  String get _single => _isPreparer ? 'محضر' : 'طيار';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final result = await showDialog<({String name, String? phone})>(
      context: context,
      builder: (_) => _AddStaffDialog(title: 'إضافة $_single'),
    );
    if (result == null || !mounted) return;
    try {
      await ref.read(systemAdminServiceProvider).addStaff(
            name: result.name,
            role: widget.role,
            phone: result.phone,
          );
      ref.invalidate(adminStaffMembersProvider);
      if (mounted) showAdminSnack(context, 'تمت إضافة $_single');
    } catch (error) {
      if (mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  Future<void> _delete(StaffMember member) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'حذف $_single',
      message: 'سيتم حذف «${member.name}» من القائمة. هل أنت متأكد؟',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(systemAdminServiceProvider).deleteStaff(member.id);
      ref.invalidate(adminStaffMembersProvider);
      if (mounted) showAdminSnack(context, 'تم الحذف');
    } catch (error) {
      if (mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canManage = ref.watch(adminCanProvider(_managePermission));
    final canReport = ref.watch(adminCanProvider(AdminPermission.viewReports));
    final members = ref.watch(adminStaffMembersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            title: _title,
            actions: [
              if (canManage)
                FilledButton.icon(
                  key: const Key('staff-add'),
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: Text('إضافة $_single'),
                ),
            ],
          ),
          TextField(
            key: const Key('staff-search'),
            controller: _search,
            onChanged: (text) => setState(() => _query = text.trim()),
            decoration: InputDecoration(
              hintText: 'ابحث باسم $_single أو رقم هاتفه',
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AdminMessage(describeAdminError(error),
                  icon: Icons.error_outline),
              data: (all) {
                final needle = _query.toLowerCase();
                final list = [
                  for (final member in all)
                    if (member.role == widget.role &&
                        (needle.isEmpty ||
                            member.name.toLowerCase().contains(needle) ||
                            (member.phone ?? '').contains(needle)))
                      member,
                ];
                if (list.isEmpty) {
                  return AdminMessage(
                    _query.isEmpty ? 'لا يوجد $_title بعد' : 'لا توجد نتائج',
                    icon: Icons.groups_outlined,
                  );
                }
                return GridView.builder(
                  key: const Key('staff-list'),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 128,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final member = list[index];
                    return Container(
                      key: Key('staff-${member.id}'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.card,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    palette.accent.withValues(alpha: 0.12),
                                child: Icon(
                                  _isPreparer
                                      ? Icons.inventory_2_rounded
                                      : Icons.motorcycle_rounded,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900)),
                                    Text(member.phone ?? 'بدون رقم',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: palette.muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              if (canReport)
                                Flexible(
                                  child: TextButton.icon(
                                    key: Key('staff-report-${member.id}'),
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => StaffProductivityDialog(
                                          member: member),
                                    ),
                                    icon: const Icon(Icons.bar_chart_rounded,
                                        size: 18),
                                    label: const Text('تقرير الإنتاجية',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              const Spacer(),
                              if (canManage)
                                IconButton(
                                  key: Key('staff-delete-${member.id}'),
                                  tooltip: 'حذف',
                                  onPressed: () => _delete(member),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStaffDialog extends StatefulWidget {
  const _AddStaffDialog({required this.title});

  final String title;

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final phone = _phone.text.trim();
    Navigator.pop(context, (
      name: _name.text.trim(),
      phone: phone.isEmpty ? null : phone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('staff-name'),
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الاسم'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'اكتب الاسم' : null,
            ),
            TextFormField(
              key: const Key('staff-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration:
                  const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('staff-save'),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

/// A preparer's or driver's productivity (and orders) over a date range.
class StaffProductivityDialog extends ConsumerStatefulWidget {
  const StaffProductivityDialog({super.key, required this.member});

  final StaffMember member;

  @override
  ConsumerState<StaffProductivityDialog> createState() =>
      _StaffProductivityDialogState();
}

class _StaffProductivityDialogState
    extends ConsumerState<StaffProductivityDialog> {
  late DateTime _from;
  late DateTime _to;
  bool _showOrders = false;

  ReportTable? _table;
  bool _loading = true;
  Object? _error;

  bool get _isPreparer => widget.member.role == 'preparer';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(now.year, now.month, now.day - 6);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final kind = _showOrders
        ? ReportKind.deliveryOrders
        : (_isPreparer ? ReportKind.preparers : ReportKind.drivers);
    final filters = ReportFilters(
      from: _from,
      to: _to,
      preparer: _isPreparer ? widget.member.name : null,
      driver: _isPreparer ? null : widget.member.name,
    );
    try {
      final table = await generateReport(
        ref.read(reportDataSourceProvider),
        kind,
        filters,
        money: AppCurrency.of,
      );
      if (!mounted) return;
      setState(() {
        _table = table;
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
    final size = MediaQuery.sizeOf(context);
    final table = _table;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        key: const Key('staff-report-dialog'),
        width: size.width.clamp(0, 900).toDouble(),
        height: size.height.clamp(0, 640).toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'إنتاجية ${widget.member.name}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ReportDateRangeBar(
                from: _from,
                to: _to,
                onChanged: (from, to) {
                  setState(() {
                    _from = from;
                    _to = to;
                  });
                  _run();
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('staff-report-summary'),
                    label: const Text('الإنتاجية'),
                    selected: !_showOrders,
                    onSelected: (_) {
                      setState(() => _showOrders = false);
                      _run();
                    },
                  ),
                  ChoiceChip(
                    key: const Key('staff-report-orders'),
                    label: const Text('الطلبات'),
                    selected: _showOrders,
                    onSelected: (_) {
                      setState(() => _showOrders = true);
                      _run();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? AdminMessage(describeAdminError(_error!),
                            icon: Icons.error_outline)
                        : table == null
                            ? const SizedBox.shrink()
                            : ReportResultView(table: table),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
