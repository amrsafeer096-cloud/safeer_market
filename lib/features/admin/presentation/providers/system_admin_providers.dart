import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/report_service.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import 'staff_session_providers.dart';

final systemAdminServiceProvider = Provider<SystemAdminService>(
  (ref) => SupabaseSystemAdminService(ref.watch(supabaseClientProvider)),
);

final reportDataSourceProvider = Provider<ReportDataSource>(
  (ref) => SupabaseReportDataSource(ref.watch(supabaseClientProvider)),
);

/// Whether the signed-in account is a real administrator (not just the
/// supervisor PIN): only they see «الصلاحيات».
final isRealAdminProvider = Provider<bool>(
  (ref) => ref.watch(userRoleProvider).valueOrNull == UserRole.admin,
);

/// Permission keys of the signed-in Auth profile.
final myPermissionsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  if (ref.watch(isRealAdminProvider)) {
    return Future.value(AdminPermission.allKeys);
  }
  return ref.watch(systemAdminServiceProvider).myPermissions();
});

/// Permission keys for the active staff-login member (linked profile).
///
/// Store tablets often stay signed in as an Auth admin while staff switch
/// via `staff_login`; this provider loads the *staff* grants so toggles in
/// «الصلاحيات» actually apply after that staff member logs in.
final staffPermissionsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final staff = ref.watch(staffSessionProvider);
  if (staff == null) return {};
  if (staff.isAdmin) return AdminPermission.allKeys;
  return ref
      .watch(systemAdminServiceProvider)
      .staffMemberPermissions(staff.id);
});

/// Whether the current dashboard actor may do [permission].
///
/// Only staff/profile admins have full access. While permissions are still
/// loading, returns `false` (fail closed) so disabled tabs stay hidden.
final adminCanProvider =
    Provider.autoDispose.family<bool, AdminPermission>((ref, permission) {
  final staff = ref.watch(staffSessionProvider);
  if (staff?.isAdmin == true) return true;

  if (staff != null) {
    // Non-admin staff: use staff-linked grants, not the device Auth role.
    return ref
            .watch(staffPermissionsProvider)
            .valueOrNull
            ?.contains(permission.key) ??
        false;
  }

  if (ref.watch(isRealAdminProvider)) return true;
  return ref
          .watch(myPermissionsProvider)
          .valueOrNull
          ?.contains(permission.key) ??
      false;
});

/// Alias matching the product wording: `hasPermission(key)`.
bool hasPermission(WidgetRef ref, AdminPermission permission) =>
    ref.read(adminCanProvider(permission));

/// Top-tab menu index → required [AdminPermission] (see [AdminMenu]).
AdminPermission? topTabPermission(int menu) => switch (menu) {
      0 => AdminPermission.receiveOrders, // تلقي الطلبات
      1 => AdminPermission.orderStatus, // حالة الطلب
      9 => AdminPermission.searchOrders, // بحث
      4 => AdminPermission.viewReports, // التقارير واليومية
      3 => AdminPermission.manageSystem, // إدارة النظام
      _ => null,
    };

/// Role tabs intersected with granted menu permissions.
///
/// Preparers / drivers keep their role tabs (they are not managed through
/// cashier «الصلاحيات» rows). Takers must have each menu key enabled.
final staffAllowedMenusProvider = Provider<List<int>>((ref) {
  final staff = ref.watch(staffSessionProvider);
  if (staff == null) return const [];
  final roleTabs = staff.allowedTabs;
  if (staff.isAdmin) return roleTabs;
  if (staff.isPreparer || staff.isDriver) return roleTabs;

  final allowed = <int>[];
  for (final menu in roleTabs) {
    final perm = topTabPermission(menu);
    if (perm == null || ref.watch(adminCanProvider(perm))) {
      allowed.add(menu);
    }
  }
  return allowed;
});

final adminCustomersProvider = FutureProvider.autoDispose
    .family<List<AdminCustomer>, String>((ref, query) {
  return ref.watch(systemAdminServiceProvider).searchCustomers(query);
});

final adminStaffMembersProvider =
    FutureProvider.autoDispose<List<StaffMember>>((ref) {
  return ref.watch(systemAdminServiceProvider).staff();
});

final adminDashboardUsersProvider =
    FutureProvider.autoDispose<List<DashboardUser>>((ref) {
  return ref.watch(systemAdminServiceProvider).dashboardUsers();
});

final adminZonesProvider = FutureProvider.autoDispose<List<DeliveryZone>>((ref) {
  return ref.watch(systemAdminServiceProvider).zones();
});
