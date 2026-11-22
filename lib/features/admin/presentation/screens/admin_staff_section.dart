import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/domain/egyptian_phone.dart';
import '../../data/report_service.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/reports.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';
import 'admin_reports_view.dart';

/// «المحضرين» / «الطيارين»: search, add, edit and delete, and open a member's
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

  Future<void> _openEditor({StaffMember? existing}) async {
    final result = await showDialog<_StaffFormResult>(
      context: context,
      builder: (_) => _StaffCredentialsDialog(
        title: existing == null ? 'إضافة $_single' : 'تعديل $_single',
        existing: existing,
      ),
    );
    if (result == null || !mounted) return;
    try {
      final service = ref.read(systemAdminServiceProvider);
      if (existing == null) {
        await service.addStaff(
          name: result.name,
          role: widget.role,
          phone: result.phone,
          username: result.username,
          password: result.password!,
        );
      } else {
        await service.updateStaff(
          id: existing.id,
          name: result.name,
          phone: result.phone,
          username: result.username,
          password: result.password,
        );
      }
      ref.invalidate(adminStaffMembersProvider);
      if (mounted) {
        showAdminSnack(
          context,
          existing == null ? 'تمت إضافة $_single' : 'تم حفظ التعديل',
        );
      }
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

  Future<void> _toggleActive(StaffMember member) async {
    final enable = !member.isActive;
    if (!enable) {
      final ok = await confirmAdminAction(
        context,
        title: 'تعطيل $_single',
        message:
            'لن يتمكن «${member.name}» من دخول لوحة التحكم حتى يُعاد تفعيله.',
        confirmLabel: 'تعطيل',
      );
      if (!ok || !mounted) return;
    }
    try {
      await ref.read(systemAdminServiceProvider).setStaffActive(
            id: member.id,
            active: enable,
          );
      ref.invalidate(adminStaffMembersProvider);
      if (mounted) {
        showAdminSnack(
          context,
          enable ? 'تم تفعيل $_single' : 'تم تعطيل $_single',
        );
      }
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
                  onPressed: () => _openEditor(),
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
              hintText: 'ابحث باسم $_single أو رقم هاتفه أو اسم المستخدم',
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
                            (member.phone ?? '').contains(needle) ||
                            (member.username ?? '')
                                .toLowerCase()
                                .contains(needle)))
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
                    mainAxisExtent: 160,
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
                                backgroundColor: (member.isActive
                                        ? palette.accent
                                        : Colors.grey)
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  _isPreparer
                                      ? Icons.inventory_2_rounded
                                      : Icons.motorcycle_rounded,
                                  color: member.isActive
                                      ? palette.accent
                                      : Colors.grey,
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
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: member.isActive
                                                ? null
                                                : palette.muted)),
                                    Text(member.phone ?? 'بدون رقم',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: palette.muted)),
                                    if (member.username != null)
                                      Text('@${member.username}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: palette.muted)),
                                  ],
                                ),
                              ),
                              if (!member.isActive)
                                Container(
                                  key: Key('staff-disabled-${member.id}'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text('معطّل',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
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
                              if (canManage) ...[
                                IconButton(
                                  key: Key('staff-toggle-${member.id}'),
                                  tooltip:
                                      member.isActive ? 'تعطيل' : 'تفعيل',
                                  onPressed: () => _toggleActive(member),
                                  icon: Icon(
                                    member.isActive
                                        ? Icons.block_rounded
                                        : Icons.check_circle_outline,
                                    color: member.isActive
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                IconButton(
                                  key: Key('staff-edit-${member.id}'),
                                  tooltip: 'تعديل',
                                  onPressed: () =>
                                      _openEditor(existing: member),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: Key('staff-delete-${member.id}'),
                                  tooltip: 'حذف',
                                  onPressed: () => _delete(member),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                ),
                              ],
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

class _StaffFormResult {
  const _StaffFormResult({
    required this.name,
    required this.phone,
    required this.username,
    this.password,
  });

  final String name;
  final String phone;
  final String username;

  /// Null on edit when the password field is left blank (keep current).
  final String? password;
}

class _StaffCredentialsDialog extends StatefulWidget {
  const _StaffCredentialsDialog({required this.title, this.existing});

  final String title;
  final StaffMember? existing;

  @override
  State<_StaffCredentialsDialog> createState() =>
      _StaffCredentialsDialogState();
}

class _StaffCredentialsDialogState extends State<_StaffCredentialsDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _username =
      TextEditingController(text: widget.existing?.username ?? '');
  final _password = TextEditingController();
  var _obscure = true;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final password = _password.text;
    Navigator.pop(
      context,
      _StaffFormResult(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        username: _username.text.trim(),
        password: password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
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
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '01XXXXXXXXX',
                ),
                validator: (v) {
                  final phone = (v ?? '').trim();
                  if (phone.isEmpty) return 'رقم الهاتف مطلوب';
                  if (!EgyptianPhone.isValid(phone)) {
                    return 'اكتب رقم موبايل مصري صحيح (01XXXXXXXXX)';
                  }
                  return null;
                },
              ),
              TextFormField(
                key: const Key('staff-username'),
                controller: _username,
                textDirection: TextDirection.ltr,
                decoration:
                    const InputDecoration(labelText: 'اسم المستخدم'),
                validator: (v) {
                  final u = (v ?? '').trim();
                  if (u.length < 3) {
                    return 'اسم المستخدم مطلوب (٣ أحرف على الأقل)';
                  }
                  return null;
                },
              ),
              TextFormField(
                key: const Key('staff-password'),
                controller: _password,
                obscureText: _obscure,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: _editing
                      ? 'كلمة المرور (اتركها فارغة للإبقاء)'
                      : 'كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (v) {
                  final p = v ?? '';
                  if (!_editing && p.length < 4) {
                    return 'كلمة المرور مطلوبة (٤ أحرف على الأقل)';
                  }
                  if (p.isNotEmpty && p.length < 4) {
                    return 'كلمة المرور قصيرة جداً (٤ أحرف على الأقل)';
                  }
                  return null;
                },
              ),
            ],
          ),
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
