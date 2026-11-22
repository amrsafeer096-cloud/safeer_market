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

  /// Secondary sidebar entries (products, magazines, …) — admin only.
  bool get canOpenSystemMenu => isAdmin;

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
