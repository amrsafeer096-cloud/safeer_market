import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/addresses_repository.dart';

/// Maps the form onto `addresses`: Area is stored in `region` and Landmark in
/// `notes`; `title`, `building` and `floor_apt` are app-specific columns.
/// Every column written here exists in public.addresses; `region` and
/// `street` are NOT NULL there, and `user_id` must have a `profiles` row.
class SupabaseAddressesRepository implements AddressesRepository {
  const SupabaseAddressesRepository(this._client);

  static const _table = 'addresses';
  static const _columns =
      'id, title, region, street, building, floor_apt, notes, latitude, longitude';

  /// Postgres foreign_key_violation: here, no `profiles` row for user_id.
  static const _missingProfile = '23503';

  final SupabaseClient _client;

  @override
  Future<List<Address>> fetchAddresses(String userId) async {
    try {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map(_toAddress).toList();
    } on PostgrestException catch (error) {
      debugPrint('addresses select failed: ${_describe(error)}');
      rethrow;
    }
  }

  @override
  Future<Address> addAddress(String userId, AddressDraft draft) async {
    // Without a session the insert runs as `anon`, and RLS reports it as a
    // policy violation instead of an auth problem.
    if (_client.auth.currentSession == null ||
        _client.auth.currentUser?.id != userId) {
      throw AddressFailure(L10n.current.sessionExpired);
    }
    final values = {
      'user_id': userId,
      'title': draft.title,
      'region': draft.area,
      'street': draft.street,
      'building': draft.building,
      'floor_apt': draft.floorApt,
      'notes': draft.landmark,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    };
    Future<Map<String, dynamic>> insert() =>
        _client.from(_table).insert(values).select(_columns).single();

    try {
      try {
        return _toAddress(await insert());
      } on PostgrestException catch (error) {
        if (error.code != _missingProfile) rethrow;
        debugPrint('addresses insert: no profiles row for $userId '
            '(${_describe(error)}); creating it and retrying');
        await _client
            .from('profiles')
            .upsert({'id': userId}, onConflict: 'id', ignoreDuplicates: true);
        return _toAddress(await insert());
      }
    } on PostgrestException catch (error) {
      debugPrint('addresses insert failed: ${_describe(error)}\n'
          'payload: $values');
      throw AddressFailure(L10n.current.addressSaveFailed(_describe(error)));
    } catch (error) {
      debugPrint('addresses insert failed: $error');
      throw AddressFailure(L10n.current.addressSaveFailed('$error'));
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      await _client.from(_table).delete().eq('id', addressId);
    } on PostgrestException catch (error) {
      debugPrint('addresses delete $addressId failed: ${_describe(error)}');
      throw AddressFailure(_describe(error));
    }
  }

  @override
  Future<void> updateLocation(
    String addressId, {
    required double latitude,
    required double longitude,
  }) async {
    final List<Map<String, dynamic>> updated;
    try {
      updated = await _client
          .from(_table)
          .update({'latitude': latitude, 'longitude': longitude})
          .eq('id', addressId)
          .select('id');
    } on PostgrestException catch (error) {
      debugPrint('addresses update $addressId failed: ${_describe(error)}');
      throw AddressFailure(
        L10n.current.addressLocationSaveFailedWithError(_describe(error)),
      );
    } catch (error) {
      debugPrint('addresses update $addressId failed: $error');
      throw AddressFailure(
        L10n.current.addressLocationSaveFailedWithError('$error'),
      );
    }
    // RLS rejects updates silently by matching zero rows.
    if (updated.isEmpty) {
      final reason = '0 rows updated for address $addressId: no UPDATE '
          'policy lets this user change it, or it was deleted';
      debugPrint('addresses update: $reason');
      throw AddressFailure(
        L10n.current.addressLocationSaveFailedWithError(reason),
      );
    }
  }

  /// Everything PostgREST says about [error], for logs and the UI.
  static String _describe(PostgrestException error) => [
        error.message,
        if (error.code case final code? when code.isNotEmpty) 'code $code',
        if (error.details case final details? when '$details'.trim().isNotEmpty)
          'details: $details',
        if (error.hint case final hint? when hint.trim().isNotEmpty)
          'hint: $hint',
      ].join(' | ');

  static Address _toAddress(Map<String, dynamic> row) {
    String text(String key) => (row[key] ?? '').toString().trim();
    String? optional(String key) {
      final value = text(key);
      return value.isEmpty ? null : value;
    }

    return Address(
      id: row['id'].toString(),
      title: optional('title') ?? L10n.current.addressDefaultTitle,
      area: text('region'),
      street: text('street'),
      building: text('building'),
      floorApt: optional('floor_apt'),
      landmark: optional('notes'),
      latitude: _toDouble(row['latitude']),
      longitude: _toDouble(row['longitude']),
    );
  }

  /// `latitude` / `longitude` are numeric columns, which may arrive as text.
  static double? _toDouble(Object? value) => switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text.trim()),
        _ => null,
      };
}
