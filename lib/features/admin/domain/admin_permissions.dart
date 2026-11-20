/// A granular permission an administrator can give an employee in
/// «الصلاحيات». Stored in `admin_permissions.permissions` by [key] and
/// checked server-side by `public.has_permission(key)`.
enum AdminPermission {
  viewReports('view_reports', 'عرض التقارير واليومية'),
  manageCustomers('manage_customers', 'إضافة وتعديل العملاء'),
  deleteCustomers('delete_customers', 'حذف العملاء'),
  managePreparers('manage_preparers', 'إدارة المحضرين (إضافة / حذف)'),
  manageDrivers('manage_drivers', 'إدارة الطيارين (إضافة / حذف)'),
  manageUsers('manage_users', 'إدارة المستخدمين (إضافة / تعديل / تعطيل)'),
  manageZones('manage_zones', 'إدارة المناطق وأسعار التوصيل'),
  approveSubscriptions('approve_subscriptions', 'اعتماد طلبات الترقية');

  const AdminPermission(this.key, this.label);

  /// The value stored in the database.
  final String key;
  final String label;

  static AdminPermission? fromKey(String key) {
    for (final permission in values) {
      if (permission.key == key) return permission;
    }
    return null;
  }

  /// Every permission, as an administrator holds them.
  static Set<String> get allKeys => {for (final p in values) p.key};
}

/// The roles that may use the dashboard («المستخدمين»).
enum DashboardUserRole {
  admin('admin', 'مدير'),
  warehouse('warehouse', 'مخزن / تحضير'),
  cashier('cashier', 'كاشير / متلقي طلبات');

  const DashboardUserRole(this.value, this.label);

  /// `profiles.role`.
  final String value;
  final String label;

  static DashboardUserRole? fromValue(String? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}
