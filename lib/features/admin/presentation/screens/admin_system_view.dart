import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/admin_permissions.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';
import 'admin_customers_section.dart';
import 'admin_permissions_section.dart';
import 'admin_staff_section.dart';
import 'admin_users_section.dart';
import 'admin_zones_section.dart';

/// The «إدارة النظام» tab: customers, preparers, drivers, dashboard users,
/// delivery zones and (administrators only) permissions.
class AdminSystemView extends ConsumerStatefulWidget {
  const AdminSystemView({super.key});

  @override
  ConsumerState<AdminSystemView> createState() => _AdminSystemViewState();
}

enum _SystemSection {
  customers('العملاء', Icons.people_alt_rounded, AdminPermission.manageCustomers),
  preparers('المحضرين', Icons.inventory_2_rounded, AdminPermission.managePreparers),
  drivers('الطيارين', Icons.motorcycle_rounded, AdminPermission.manageDrivers),
  users('المستخدمين', Icons.badge_rounded, AdminPermission.manageUsers),
  zones('المناطق', Icons.map_rounded, AdminPermission.manageZones),
  permissions('الصلاحيات', Icons.admin_panel_settings_rounded, null);

  const _SystemSection(this.label, this.icon, this.permission);

  final String label;
  final IconData icon;

  /// Null = administrators only (الصلاحيات).
  final AdminPermission? permission;
}

class _AdminSystemViewState extends ConsumerState<AdminSystemView> {
  _SystemSection _section = _SystemSection.customers;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isRealAdminProvider);

    // «الصلاحيات» exists only for administrators; other sections need their key.
    final sections = [
      for (final section in _SystemSection.values)
        if (section == _SystemSection.permissions
            ? isAdmin
            : isAdmin ||
                ref.watch(adminCanProvider(section.permission!)))
          section,
    ];

    if (sections.isEmpty) {
      return const AdminLockedSection(
          message: 'لا توجد أقسام متاحة حسب صلاحياتك');
    }

    final current = sections.contains(_section) ? _section : sections.first;

    return AdminSubMenuLayout(
      keyPrefix: 'system-menu',
      title: 'إدارة النظام',
      items: [
        for (final section in sections)
          AdminSubMenuItem(section.label, section.icon),
      ],
      selected: sections.indexOf(current),
      onSelected: (index) => setState(() => _section = sections[index]),
      body: KeyedSubtree(
        key: ValueKey(current),
        child: switch (current) {
          _SystemSection.customers => const AdminCustomersSection(),
          _SystemSection.preparers => const AdminStaffSection(role: 'preparer'),
          _SystemSection.drivers => const AdminStaffSection(role: 'driver'),
          _SystemSection.users => const AdminUsersSection(),
          _SystemSection.zones => const AdminZonesSection(),
          _SystemSection.permissions => const AdminPermissionsSection(),
        },
      ),
    );
  }
}
