/// `profiles.role`. Assigned by an administrator, never by the app.
enum UserRole {
  customer('customer'),
  driver('driver'),
  warehouse('warehouse'),
  admin('admin'),

  /// Shops like a customer, and can redeem customers' loyalty points.
  cashier('cashier');

  const UserRole(this.value);

  final String value;

  /// May scan customers' codes and redeem their loyalty points.
  bool get canRedeemLoyalty => this == cashier || this == admin;

  /// Unknown or missing values are treated as a regular customer.
  static UserRole fromValue(Object? value) {
    for (final role in values) {
      if (role.value == value?.toString().trim().toLowerCase()) return role;
    }
    return UserRole.customer;
  }
}
