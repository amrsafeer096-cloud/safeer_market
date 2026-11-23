/// A staff member authenticated into the admin dashboard (separate from the
/// Supabase Auth account that opened the app).
class StaffSession {
  const StaffSession({
    required this.id,
    required this.name,
    required this.role,
    required this.username,
    this.phone,
  });

  final String id;
  final String name;

  /// Normalized: `admin` | `taker` | `preparer` | `driver`.
  final String role;
  final String username;
  final String? phone;

  bool get isAdmin => role == 'admin';
  bool get isTaker => role == 'taker';
  bool get isPreparer => role == 'preparer';
  bool get isDriver => role == 'driver';

  /// Main top tabs this role may open.
  ///
  /// Values match `AdminMenu` in `unified_dashboard_screen.dart`:
  /// receive=0, status=1, products=2, staff=3, reports=4, magazines=5,
  /// support=6, notifications=7, pendingSubscriptions=8, search=9.
  List<int> get allowedTabs {
    if (isAdmin) {
      return const [0, 1, 9, 4, 3]; // receive, status, search, reports, system
    }
    if (isTaker) {
      return const [0, 1, 9, 4]; // receive, status, search, reports
    }
    if (isPreparer) {
      return const [1, 9]; // status, search
    }
    // driver
    return const [1]; // status only
  }

  /// Secondary sidebar entries — must match `AdminMenu.secondary`
  /// (products=2, magazines=5, support=6, notifications=7, pending=8).
  static const systemSidebarMenus = <int>[2, 5, 6, 7, 8];

  bool get canOpenSystemMenu => isAdmin;

  /// Top tabs plus (for admin) the system sidebar sections.
  /// Without this, tapping sidebar items was immediately reset because
  /// only [allowedTabs] were treated as valid.
  bool canOpenMenu(int menu) {
    if (allowedTabs.contains(menu)) return true;
    return canOpenSystemMenu && systemSidebarMenus.contains(menu);
  }

  /// Delivery-stage orders only (ready / out for delivery).
  bool get deliveryOrdersOnly => isDriver;

  String get roleLabel => switch (role) {
        'admin' => 'أدمن',
        'taker' => 'متلقي طلبات',
        'preparer' => 'محضر',
        'driver' => 'طيار',
        _ => role,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'username': username,
        if (phone != null) 'phone': phone,
      };

  factory StaffSession.fromJson(Map<String, dynamic> json) => StaffSession(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        role: '${json['role'] ?? ''}',
        username: '${json['username'] ?? ''}',
        phone: json['phone']?.toString(),
      );
}
