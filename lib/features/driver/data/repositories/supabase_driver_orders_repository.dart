import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/driver_order.dart';
import '../../domain/repositories/driver_orders_repository.dart';

class SupabaseDriverOrdersRepository implements DriverOrdersRepository {
  const SupabaseDriverOrdersRepository(this._client);

  static const _columns = 'id, created_at, status, total_amount, delivery_fee, '
      'address_details, delivery_latitude, delivery_longitude, '
      'profiles!user_id(full_name, phone)';

  final SupabaseClient _client;

  String get _driverId {
    final user = _client.auth.currentUser;
    if (user == null) throw DriverFailure(L10n.current.pleaseSignInFirst);
    return user.id;
  }

  @override
  Future<List<DriverOrder>> fetchAvailableOrders() async {
    final rows = await _client
        .from('orders')
        .select(_columns)
        .eq('status', 'ready_for_delivery')
        .isFilter('driver_id', null)
        .order('created_at');
    return rows.map(_toOrder).toList();
  }

  @override
  Future<List<DriverOrder>> fetchMyDeliveries() async {
    final rows = await _client
        .from('orders')
        .select(_columns)
        .eq('driver_id', _driverId)
        .eq('status', 'out_for_delivery')
        .order('created_at');
    return rows.map(_toOrder).toList();
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    try {
      final updated = await _client
          .from('orders')
          .update({
            'status': 'out_for_delivery',
            'driver_id': _driverId,
          })
          .eq('id', orderId)
          .eq('status', 'ready_for_delivery')
          .isFilter('driver_id', null)
          .select('id');
      if (updated.isEmpty) {
        throw DriverFailure(L10n.current.driverOrderTakenByAnother);
      }
    } on PostgrestException catch (error) {
      throw DriverFailure(L10n.current.driverAcceptOrderFailed(error.message));
    }
  }

  @override
  Future<void> markDelivered(String orderId) async {
    try {
      final updated = await _client
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId)
          .eq('driver_id', _driverId)
          .select('id');
      if (updated.isEmpty) {
        throw DriverFailure(L10n.current.noPermissionToEditOrder);
      }
    } on PostgrestException catch (error) {
      throw DriverFailure(L10n.current.orderUpdateFailed(error.message));
    }
  }

  @override
  Future<void> updateDriverLocation(
    String orderId, {
    required double latitude,
    required double longitude,
  }) async {
    final List<Map<String, dynamic>> updated;
    try {
      // `select` returns the changed rows; without it an update that row
      // level security filters out "succeeds" while changing nothing.
      updated = await _client
          .from('orders')
          .update({'driver_lat': latitude, 'driver_lng': longitude})
          .eq('id', orderId)
          .select('id');
    } on PostgrestException catch (error) {
      throw DriverFailure(
        L10n.current.driverLocationSendFailed(
          error.message,
          '${error.code}',
        ),
      );
    }
    if (updated.isEmpty) {
      throw DriverFailure(L10n.current.driverLocationSendNotAssigned);
    }
  }

  static DriverOrder _toOrder(Map<String, dynamic> row) {
    final profile = switch (row['profiles']) {
      final Map<String, dynamic> map => map,
      [final Map<String, dynamic> first, ...] => first,
      _ => null,
    };
    return DriverOrder(
      id: row['id'].toString(),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      status: (row['status'] ?? 'pending').toString(),
      totalAmount: _toDouble(row['total_amount']) ?? 0,
      deliveryFee: _toDouble(row['delivery_fee']) ?? 0,
      customerName: _text(profile?['full_name']),
      customerPhone: _text(profile?['phone']),
      addressDetails: _text(row['address_details']),
      latitude: _toDouble(row['delivery_latitude']),
      longitude: _toDouble(row['delivery_longitude']),
    );
  }

  static double? _toDouble(Object? value) => switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text),
        _ => null,
      };

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
