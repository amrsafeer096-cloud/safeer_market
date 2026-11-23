/// A granular permission an administrator can give an employee in
/// «الصلاحيات». Stored in `admin_permissions.permissions` by [key] and
/// checked server-side by `public.has_permission(key)`.
enum AdminPermission {
  // —— الشاشات / القوائم ——
  receiveOrders('receive_orders', 'تلقي الطلبات', AdminPermissionGroup.menus),
  orderStatus('order_status', 'حالة الطلب', AdminPermissionGroup.menus),
  searchOrders('search_orders', 'بحث الطلبات', AdminPermissionGroup.menus),
  viewReports('view_reports', 'عرض التقارير واليومية', AdminPermissionGroup.menus),
  exportReports(
      'export_reports', 'تصدير / طباعة التقارير PDF', AdminPermissionGroup.menus),
  manageSystem(
      'manage_system', 'فتح إدارة النظام', AdminPermissionGroup.menus),
  manageProducts(
      'manage_products', 'إدارة المنتجات', AdminPermissionGroup.menus),
  manageMagazines(
      'manage_magazines', 'إدارة المجلات', AdminPermissionGroup.menus),
  manageSupport(
      'manage_support', 'الشكاوى والمحادثات', AdminPermissionGroup.menus),
  sendNotifications(
      'send_notifications', 'إرسال الإشعارات', AdminPermissionGroup.menus),
  approveSubscriptions(
      'approve_subscriptions', 'اعتماد طلبات الترقية', AdminPermissionGroup.menus),

  // —— إدارة النظام ——
  manageCustomers(
      'manage_customers', 'إضافة وتعديل العملاء', AdminPermissionGroup.system),
  deleteCustomers(
      'delete_customers', 'حذف العملاء', AdminPermissionGroup.system),
  managePreparers(
      'manage_preparers',
      'إدارة المحضرين (إضافة / حذف)',
      AdminPermissionGroup.system),
  manageDrivers(
      'manage_drivers',
      'إدارة الطيارين (إضافة / حذف)',
      AdminPermissionGroup.system),
  manageUsers(
      'manage_users',
      'إدارة المستخدمين (إضافة / تعديل / تعطيل)',
      AdminPermissionGroup.system),
  manageZones(
      'manage_zones',
      'إدارة المناطق وأسعار التوصيل',
      AdminPermissionGroup.system),

  // —— خطوات حالة الطلب ——
  startPrep('start_prep', 'بدء التجهيز', AdminPermissionGroup.orderActions),
  finishPrep('finish_prep', 'إنهاء التجهيز', AdminPermissionGroup.orderActions),
  assignDriver(
      'assign_driver', 'تعيين طيار / بدء التوصيل', AdminPermissionGroup.orderActions),
  cancelOrder('cancel_order', 'إلغاء الطلب', AdminPermissionGroup.orderActions),
  sendAlternatives(
      'send_alternatives',
      'إرسال بدائل للمنتجات',
      AdminPermissionGroup.orderActions);

  const AdminPermission(this.key, this.label, this.group);

  /// The value stored in the database.
  final String key;
  final String label;
  final AdminPermissionGroup group;

  static AdminPermission? fromKey(String key) {
    for (final permission in values) {
      if (permission.key == key) return permission;
    }
    return null;
  }

  /// Every permission, as an administrator holds them.
  static Set<String> get allKeys => {for (final p in values) p.key};
}

/// Groups shown as section headers in «الصلاحيات».
enum AdminPermissionGroup {
  menus('الشاشات والقوائم'),
  system('إدارة النظام'),
  orderActions('خطوات حالة الطلب');

  const AdminPermissionGroup(this.label);
  final String label;
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
