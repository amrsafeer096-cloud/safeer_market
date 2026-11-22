import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/admin_permissions.dart';
import '../domain/repositories/admin_orders_repository.dart';

// ------------------------------------------------------------------ models

/// A `pos_customers` row with its order totals.
class AdminCustomer {
  const AdminCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.phone2,
    this.address,
    this.zone,
    this.isVip = false,
    this.governorate,
    this.city,
    this.building,
    this.floor,
    this.apartment,
    this.latitude,
    this.longitude,
    this.ordersCount = 0,
    this.totalSpent = 0,
    this.lastOrderAt,
  });

  final int id;
  final String name;
  final String? phone;
  final String? phone2;
  final String? address;
  final String? zone;
  final bool isVip;
  final String? governorate;
  final String? city;
  final String? building;
  final String? floor;
  final String? apartment;
  final double? latitude;
  final double? longitude;
  final int ordersCount;
  final double totalSpent;
  final DateTime? lastOrderAt;

  bool get hasPin => latitude != null && longitude != null;
}

/// A preparer, driver, taker or admin (`staff` row with login credentials).
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.username,
    this.profileId,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// `preparer` | `driver` | `taker` | `admin`.
  final String role;
  final String? phone;
  final String? username;
  final String? profileId;
  final bool isActive;
}

/// An account that can use the dashboard (`profiles.role` admin, warehouse,
/// cashier), or one an administrator disabled.
class DashboardUser {
  const DashboardUser({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.email,
    this.disabled = false,
    this.staffId,
    this.staffUsername,
  });

  final String id;
  final String? name;
  final String? phone;
  final String? email;

  /// The dashboard role; for a disabled user, the role it will return to.
  final String role;
  final bool disabled;

  /// Linked `staff` row used by Staff Login (may be the seeded `admin`).
  final String? staffId;
  final String? staffUsername;

  bool get isAdmin => role == DashboardUserRole.admin.value;

  String get title => name ?? phone ?? email ?? id;
}

/// A registered account that can be given a dashboard role.
class AccountMatch {
  const AccountMatch({required this.id, this.name, this.phone, this.email});

  final String id;
  final String? name;
  final String? phone;
  final String? email;

  String get title => name ?? phone ?? email ?? id;
}

/// A delivery zone (`delivery_zones` row), identified by its Fujitsu id.
class DeliveryZone {
  const DeliveryZone({
    required this.fujitsuZoneId,
    required this.governorate,
    required this.city,
    required this.name,
    this.deliveryFee,
    this.isActive = true,
  });

  final String fujitsuZoneId;
  final String governorate;
  final String city;
  final String name;
  final double? deliveryFee;
  final bool isActive;
}

// ----------------------------------------------------------------- service

/// Everything «إدارة النظام» reads and writes. Writes go through
/// security-definer functions that check the caller's permission.
abstract class SystemAdminService {
  /// Newest customers when [query] is empty; else matches on phone, name or
  /// address.
  Future<List<AdminCustomer>> searchCustomers(String query);

  /// Fails for customers that have orders.
  Future<void> deleteCustomer(int id);

  Future<List<StaffMember>> staff({List<String>? roles});
  Future<void> addStaff({
    required String name,
    required String role,
    required String phone,
    required String username,
    required String password,
    String? profileId,
  });
  Future<void> updateStaff({
    required String id,
    String? name,
    String? phone,
    String? username,
    String? password,
  });
  Future<void> setStaffActive({required String id, required bool active});
  Future<void> deleteStaff(String id);

  Future<List<DashboardUser>> dashboardUsers();
  Future<List<AccountMatch>> findAccounts(String query);

  /// Gives [userId] the dashboard [role]; [disabled] switches the account
  /// off (it keeps [role] for when it is enabled again).
  Future<void> setUserRole({
    required String userId,
    required String role,
    String? fullName,
    bool disabled = false,
  });

  /// Permission keys of the signed-in user.
  Future<Set<String>> myPermissions();
  Future<Set<String>> permissionsOf(String userId);
  Future<void> setPermissions(String userId, Set<String> permissions);

  Future<List<DeliveryZone>> zones();
  Future<void> saveZone({
    required String fujitsuZoneId,
    required bool isNew,
    required String governorate,
    required String city,
    required String name,
    double? deliveryFee,
    bool isActive = true,
  });
  Future<void> deleteZone(String fujitsuZoneId);
}

/// A readable (Arabic) message for [error].
String describeAdminError(Object error) {
  if (error is AdminFailure) return error.message;
  final text = error is PostgrestException
      ? '${error.message} ${error.details ?? ''} ${error.code ?? ''}'
      : '$error';
  if (text.contains('customer_has_orders')) {
    return 'لا يمكن حذف عميل له طلبات سابقة';
  }
  if (text.contains('cannot_change_self')) {
    return 'لا يمكنك تعديل حسابك أنت';
  }
  if (text.contains('admin_required')) {
    return 'هذا الإجراء للمدير فقط';
  }
  if (text.contains('forbidden') || text.contains('42501')) {
    return 'لا تملك صلاحية لتنفيذ هذا الإجراء';
  }
  if (text.contains('23505') || text.contains('duplicate key')) {
    return 'هذا السجل موجود بالفعل';
  }
  if (text.contains('invalid_phone')) {
    return 'اكتب رقم موبايل مصري صحيح (01XXXXXXXXX)';
  }
  if (text.contains('username_required')) {
    return 'اسم المستخدم مطلوب (٣ أحرف على الأقل)';
  }
  if (text.contains('password_required')) {
    return 'كلمة المرور مطلوبة (٤ أحرف على الأقل)';
  }
  if (text.contains('invalid_credentials')) {
    return 'اسم المستخدم أو كلمة المرور غير صحيحة';
  }
  if (text.contains('account_disabled')) {
    return 'هذا الحساب معطّل، تواصل مع الإدارة';
  }
  return error is PostgrestException ? error.message : text;
}

class SupabaseSystemAdminService implements SystemAdminService {
  const SupabaseSystemAdminService(this._client);

  final SupabaseClient _client;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _double(Object? value) => switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text),
        _ => null,
      };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      throw AdminFailure(describeAdminError(error));
    }
  }

  // ------------------------------------------------------------ customers

  @override
  Future<List<AdminCustomer>> searchCustomers(String query) => _guard(() async {
        final rows = await _client.rpc('admin_search_customers', params: {
          'p_query': query.trim(),
          'p_limit': 40,
        });
        return [
          for (final row in List<Map<String, dynamic>>.from(rows as List))
            AdminCustomer(
              id: (row['id'] as num).toInt(),
              name: _text(row['full_name']) ?? '—',
              phone: _text(row['phone']),
              phone2: _text(row['phone2']),
              address: _text(row['address']),
              zone: _text(row['zone']),
              isVip: row['customer_type'] == 'vip',
              governorate: _text(row['governorate']),
              city: _text(row['city']),
              building: _text(row['building']),
              floor: _text(row['floor']),
              apartment: _text(row['apartment']),
              latitude: _double(row['latitude']),
              longitude: _double(row['longitude']),
              ordersCount: (_double(row['orders_count']) ?? 0).toInt(),
              totalSpent: _double(row['total_spent']) ?? 0,
              lastOrderAt: DateTime.tryParse('${row['last_order_at'] ?? ''}')
                  ?.toLocal(),
            ),
        ];
      });

  @override
  Future<void> deleteCustomer(int id) => _guard(() async {
        await _client.rpc('admin_delete_customer', params: {'p_id': id});
      });

  // ---------------------------------------------------------------- staff

  @override
  Future<List<StaffMember>> staff({List<String>? roles}) => _guard(() async {
        final filter = roles ?? const ['preparer', 'driver'];
        final rows = await _client
            .from('staff')
            .select('id, name, role, phone, username, profile_id, is_active')
            .inFilter('role', filter)
            .order('name');
        return [
          for (final row in rows)
            StaffMember(
              id: '${row['id']}',
              name: _text(row['name']) ?? '—',
              role: '${row['role']}',
              phone: _text(row['phone']),
              username: _text(row['username']),
              profileId: _text(row['profile_id']),
              isActive: row['is_active'] != false,
            ),
        ];
      });

  @override
  Future<void> addStaff({
    required String name,
    required String role,
    required String phone,
    required String username,
    required String password,
    String? profileId,
  }) =>
      _guard(() async {
        await _client.rpc('admin_add_staff', params: {
          'p_name': name.trim(),
          'p_role': role,
          'p_phone': phone.trim(),
          'p_username': username.trim(),
          'p_password': password,
          'p_profile_id': profileId,
        });
      });

  @override
  Future<void> updateStaff({
    required String id,
    String? name,
    String? phone,
    String? username,
    String? password,
  }) =>
      _guard(() async {
        await _client.rpc('admin_update_staff', params: {
          'p_id': id,
          'p_name': name?.trim(),
          'p_phone': phone?.trim(),
          'p_username': username?.trim(),
          'p_password': password == null || password.isEmpty ? null : password,
        });
      });

  @override
  Future<void> setStaffActive({required String id, required bool active}) =>
      _guard(() async {
        await _client.rpc('admin_set_staff_active', params: {
          'p_id': id,
          'p_active': active,
        });
      });

  @override
  Future<void> deleteStaff(String id) => _guard(() async {
        await _client.rpc('admin_delete_staff', params: {'p_id': id});
      });

  // ---------------------------------------------------------------- users

  @override
  Future<List<DashboardUser>> dashboardUsers() => _guard(() async {
        final rows = await _client.rpc('admin_list_dashboard_users');
        return [
          for (final row in List<Map<String, dynamic>>.from(rows as List))
            DashboardUser(
              id: '${row['id']}',
              name: _text(row['full_name']),
              phone: _text(row['phone']),
              email: _text(row['email']),
              role: '${row['role']}',
              disabled: row['is_disabled'] == true,
              staffId: _text(row['staff_id']),
              staffUsername: _text(row['staff_username']),
            ),
        ];
      });

  @override
  Future<List<AccountMatch>> findAccounts(String query) => _guard(() async {
        final rows =
            await _client.rpc('admin_find_accounts', params: {'p_query': query});
        return [
          for (final row in List<Map<String, dynamic>>.from(rows as List))
            AccountMatch(
              id: '${row['id']}',
              name: _text(row['full_name']),
              phone: _text(row['phone']),
              email: _text(row['email']),
            ),
        ];
      });

  @override
  Future<void> setUserRole({
    required String userId,
    required String role,
    String? fullName,
    bool disabled = false,
  }) =>
      _guard(() async {
        await _client.rpc('admin_set_user_role', params: {
          'p_user_id': userId,
          'p_role': role,
          'p_full_name': fullName?.trim().isEmpty ?? true ? null : fullName,
          'p_disabled': disabled,
        });
      });

  // ---------------------------------------------------------- permissions

  Set<String> _keys(Object? value) =>
      {for (final key in (value as List? ?? const [])) '$key'};

  @override
  Future<Set<String>> myPermissions() => _guard(() async {
        return _keys(await _client.rpc('my_permissions'));
      });

  @override
  Future<Set<String>> permissionsOf(String userId) => _guard(() async {
        return _keys(await _client
            .rpc('admin_get_permissions', params: {'p_user_id': userId}));
      });

  @override
  Future<void> setPermissions(String userId, Set<String> permissions) =>
      _guard(() async {
        await _client.rpc('admin_set_permissions', params: {
          'p_user_id': userId,
          'p_permissions': permissions.toList()..sort(),
        });
      });

  // ---------------------------------------------------------------- zones

  static const _zoneColumns =
      'fujitsu_zone_id, governorate, city, name, delivery_fee, is_active';

  /// `delivery_zones.fujitsu_zone_id` may be a number or text column.
  static Object _zoneKey(String id) => int.tryParse(id) ?? id;

  @override
  Future<List<DeliveryZone>> zones() => _guard(() async {
        final rows = await _client
            .from('delivery_zones')
            .select(_zoneColumns)
            .order('governorate')
            .order('city')
            .order('name');
        return [
          for (final row in rows)
            DeliveryZone(
              fujitsuZoneId: '${row['fujitsu_zone_id']}',
              governorate: '${row['governorate'] ?? ''}',
              city: '${row['city'] ?? ''}',
              name: '${row['name'] ?? ''}',
              deliveryFee: _double(row['delivery_fee']),
              isActive: row['is_active'] != false,
            ),
        ];
      });

  @override
  Future<void> saveZone({
    required String fujitsuZoneId,
    required bool isNew,
    required String governorate,
    required String city,
    required String name,
    double? deliveryFee,
    bool isActive = true,
  }) =>
      _guard(() async {
        final values = {
          'governorate': governorate.trim(),
          'city': city.trim(),
          'name': name.trim(),
          'delivery_fee': deliveryFee,
          'is_active': isActive,
        };
        final key = _zoneKey(fujitsuZoneId.trim());
        final saved = isNew
            ? await _client
                .from('delivery_zones')
                .insert({'fujitsu_zone_id': key, ...values})
                .select('fujitsu_zone_id')
            : await _client
                .from('delivery_zones')
                .update(values)
                .eq('fujitsu_zone_id', key)
                .select('fujitsu_zone_id');
        if (saved.isEmpty) {
          throw const AdminFailure('لا تملك صلاحية لتنفيذ هذا الإجراء');
        }
      });

  @override
  Future<void> deleteZone(String fujitsuZoneId) => _guard(() async {
        final deleted = await _client
            .from('delivery_zones')
            .delete()
            .eq('fujitsu_zone_id', _zoneKey(fujitsuZoneId))
            .select('fujitsu_zone_id');
        if (deleted.isEmpty) {
          throw const AdminFailure('لا تملك صلاحية لتنفيذ هذا الإجراء');
        }
      });}
