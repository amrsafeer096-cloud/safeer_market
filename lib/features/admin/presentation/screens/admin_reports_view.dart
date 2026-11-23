import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/report_service.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/reports.dart';
import '../providers/staff_session_providers.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';

const _reportIcons = {
  ReportKind.deliveryOrders: Icons.delivery_dining_rounded,
  ReportKind.deliveryItems: Icons.shopping_basket_rounded,
  ReportKind.receivers: Icons.support_agent_rounded,
  ReportKind.preparers: Icons.inventory_2_rounded,
  ReportKind.drivers: Icons.motorcycle_rounded,
  ReportKind.followUp: Icons.track_changes_rounded,
  ReportKind.customers: Icons.people_alt_rounded,
  ReportKind.customerRatings: Icons.star_rate_rounded,
};

const _statusChoices = {
  'pending': 'جديد',
  'preparing': 'تحضير',
  'ready_for_delivery': 'للطيار',
  'out_for_delivery': 'توصيل',
  'delivered': 'مكتمل',
  'cancelled': 'ملغي',
};

String formatReportDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// «التقارير واليومية»: a sub-menu of seven reports; each has its own
/// filters and a «عرض التقرير» button.
class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key});

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  int _selected = 0;
  late ReportFilters _filters = ReportFilters.today();
  final _receiver = TextEditingController();

  ReportTable? _table;
  bool _loading = false;
  Object? _error;

  /// Ratings report: only show delivery/product scores ≤ 3.
  bool _lowRatingsOnly = false;

  /// Bumped when the sub-menu changes so the dropdowns start fresh.
  int _generation = 0;

  ReportKind get _kind => ReportKind.values[_selected];

  @override
  void dispose() {
    _receiver.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() {
        _selected = index;
        _table = null;
        _error = null;
        _lowRatingsOnly = false;
        _generation++;
      });

  Future<void> _run() async {
    final kind = _kind;
    final filters = _filters.copyWith(receiver: _receiver.text);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final table = await generateReport(
        ref.read(reportDataSourceProvider),
        kind,
        filters,
        money: AppCurrency.of,
        lowRatingsOnly: _lowRatingsOnly,
      );
      if (!mounted || kind != _kind) return;
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
    final palette = context.palette;
    final allowed = ref.watch(adminCanProvider(AdminPermission.viewReports));
    final permissions = ref.watch(myPermissionsProvider);

    if (!allowed) {
      return permissions.isLoading
          ? const Center(child: CircularProgressIndicator())
          : const AdminLockedSection(
              message: 'لا تملك صلاحية عرض التقارير');
    }

    final staff = ref.watch(adminStaffMembersProvider).valueOrNull ?? const [];
    List<String> names(String role) => [
          for (final member in staff)
            if (member.role == role) member.name,
        ];

    final kind = _kind;
    final visible = kind.filters;

    return Container(
      color: palette.isDark ? palette.background : const Color(0xFFF4F6F8),
      child: AdminSubMenuLayout(
        keyPrefix: 'report-menu',
        title: 'التقارير',
        items: [
          for (final k in ReportKind.values)
            AdminSubMenuItem(k.label, _reportIcons[k]!),
        ],
        selected: _selected,
        onSelected: _select,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionHeader(title: kind.label),
              _buildFilters(
                visible: visible,
                preparers: names('preparer'),
                drivers: names('driver'),
              ),
              const SizedBox(height: 14),
              Expanded(child: _buildResult()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters({
    required Set<ReportFilter> visible,
    required List<String> preparers,
    required List<String> drivers,
  }) {
    final palette = context.palette;

    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        );

    Widget dropdown({
      required Key key,
      required String label,
      required String? value,
      required Map<String, String> options,
      required ValueChanged<String?> onChanged,
    }) =>
        SizedBox(
          key: key,
          width: 190,
          child: DropdownButtonFormField<String?>(
            key: ValueKey('$key-$_generation'),
            initialValue: value,
            isExpanded: true,
            decoration: decoration(label),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              for (final entry in options.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: onChanged,
          ),
        );

    return Container(
      key: const Key('report-filters'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (visible.contains(ReportFilter.date))
            ReportDateRangeBar(
              from: _filters.from,
              to: _filters.to,
              onChanged: (from, to) =>
                  setState(() => _filters = _filters.copyWith(from: from, to: to)),
            ),
          if (visible.contains(ReportFilter.preparer))
            dropdown(
              key: const Key('report-preparer'),
              label: 'المحضر',
              value: _filters.preparer,
              options: {for (final n in preparers) n: n},
              onChanged: (v) => setState(() => _filters = v == null
                  ? _filters.copyWith(clearPreparer: true)
                  : _filters.copyWith(preparer: v)),
            ),
          if (visible.contains(ReportFilter.receiver))
            SizedBox(
              width: 190,
              child: TextField(
                key: const Key('report-receiver'),
                controller: _receiver,
                decoration: decoration('المتلقي'),
              ),
            ),
          if (visible.contains(ReportFilter.driver))
            dropdown(
              key: const Key('report-driver'),
              label: 'الطيار',
              value: _filters.driver,
              options: {for (final n in drivers) n: n},
              onChanged: (v) => setState(() => _filters = v == null
                  ? _filters.copyWith(clearDriver: true)
                  : _filters.copyWith(driver: v)),
            ),
          if (visible.contains(ReportFilter.status))
            dropdown(
              key: const Key('report-status'),
              label: 'حالة الطلب',
              value: _filters.status,
              options: _statusChoices,
              onChanged: (v) => setState(() => _filters = v == null
                  ? _filters.copyWith(clearStatus: true)
                  : _filters.copyWith(status: v)),
            ),
          if (_kind == ReportKind.customerRatings)
            FilterChip(
              key: const Key('report-low-ratings'),
              avatar: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: _lowRatingsOnly ? Colors.white : Colors.orange.shade800,
              ),
              label: const Text('تقييمات منخفضة (≤ 3)'),
              selected: _lowRatingsOnly,
              selectedColor: Colors.orange.shade700,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: _lowRatingsOnly ? Colors.white : null,
              ),
              onSelected: (selected) {
                setState(() => _lowRatingsOnly = selected);
                if (_table != null) _run();
              },
            ),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              key: const Key('report-run'),
              onPressed: _loading ? null : _run,
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('عرض التقرير',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return AdminMessage('تعذّر إنشاء التقرير: ${describeAdminError(_error!)}',
          icon: Icons.error_outline);
    }
    final table = _table;
    if (table == null) {
      return const AdminMessage('اختر الفلاتر ثم اضغط «عرض التقرير»',
          icon: Icons.insights_rounded);
    }
    final staffAdmin =
        ref.watch(staffSessionProvider)?.isAdmin ?? false;
    final canExport = staffAdmin ||
        ref.watch(isRealAdminProvider) ||
        ref.watch(adminCanProvider(AdminPermission.exportReports));
    return ReportResultView(table: table, canExportPdf: canExport);
  }
}

/// «من» / «إلى» date buttons with quick ranges. The same day twice is a
/// single-date report.
class ReportDateRangeBar extends StatelessWidget {
  const ReportDateRangeBar({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;

  Future<DateTime?> _pick(BuildContext context, DateTime initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = day(DateTime.now());

    Widget dateButton(Key key, String label, DateTime value,
            ValueChanged<DateTime> onPicked) =>
        OutlinedButton.icon(
          key: key,
          onPressed: () async {
            final picked = await _pick(context, value);
            if (picked != null) onPicked(day(picked));
          },
          icon: const Icon(Icons.event, size: 18),
          label: Text('$label: ${formatReportDate(value)}'),
        );

    Widget quick(Key key, String label, DateTime a, DateTime b) => ActionChip(
          key: key,
          label: Text(label),
          onPressed: () => onChanged(a, b),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        dateButton(
          const Key('report-from'),
          'من',
          from,
          (picked) => onChanged(picked, picked.isAfter(to) ? picked : to),
        ),
        dateButton(
          const Key('report-to'),
          'إلى',
          to,
          (picked) => onChanged(picked.isBefore(from) ? picked : from, picked),
        ),
        quick(const Key('report-range-today'), 'اليوم', today, today),
        quick(
          const Key('report-range-yesterday'),
          'أمس',
          DateTime(today.year, today.month, today.day - 1),
          DateTime(today.year, today.month, today.day - 1),
        ),
        quick(
          const Key('report-range-week'),
          'آخر 7 أيام',
          DateTime(today.year, today.month, today.day - 6),
          today,
        ),
        quick(
          const Key('report-range-month'),
          'هذا الشهر',
          DateTime(today.year, today.month),
          today,
        ),
      ],
    );
  }
}
