import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/report_service.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';

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

/// The permissions of the signed-in user. Administrators hold all of them.
final myPermissionsProvider = FutureProvider.autoDispose<Set<String>>((ref) {
  if (ref.watch(isRealAdminProvider)) {
    return Future.value(AdminPermission.allKeys);
  }
  return ref.watch(systemAdminServiceProvider).myPermissions();
});

/// Whether the signed-in user may do [permission]; false while loading.
final adminCanProvider =
    Provider.autoDispose.family<bool, AdminPermission>((ref, permission) {
  if (ref.watch(isRealAdminProvider)) return true;
  return ref
          .watch(myPermissionsProvider)
          .valueOrNull
          ?.contains(permission.key) ??
      false;
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
