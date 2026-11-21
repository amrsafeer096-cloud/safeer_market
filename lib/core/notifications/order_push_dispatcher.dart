import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_providers.dart';

/// Invokes the `send-push` Edge Function after order create / status / GPS
/// events. The DB webhook is optional; the app call is what guarantees a log
/// line appears in Supabase → Edge Functions → send-push.
final orderPushDispatcherProvider = Provider<OrderPushDispatcher>(
  (ref) => OrderPushDispatcher(ref.watch(supabaseClientProvider)),
);

class OrderPushDispatcher {
  const OrderPushDispatcher(this._client);

  final SupabaseClient _client;

  /// ~3 minutes at city delivery speed (matches send-push ARRIVING_SOON_METERS).
  static const arrivingSoonMeters = 600.0;

  /// New order → notify admin + taker devices.
  Future<void> notifyOrderCreated(String orderId) =>
      invoke(orderId: orderId, trigger: 'insert');

  /// Status moved (preparing / out_for_delivery / delivered / …).
  Future<void> notifyStatusChanged(
    String orderId, {
    required String previousStatus,
  }) =>
      invoke(
        orderId: orderId,
        trigger: 'status',
        previousStatus: previousStatus,
      );

  /// Driver GPS update — only hits the network when within [arrivingSoonMeters].
  Future<void> maybeNotifyArrivingSoon({
    required String orderId,
    required double driverLat,
    required double driverLng,
    required double? deliveryLat,
    required double? deliveryLng,
    bool alreadyNotified = false,
  }) async {
    if (alreadyNotified) return;
    if (deliveryLat == null || deliveryLng == null) return;
    if (_haversineMeters(driverLat, driverLng, deliveryLat, deliveryLng) >
        arrivingSoonMeters) {
      return;
    }
    await invoke(orderId: orderId, trigger: 'location');
  }

  Future<void> invoke({
    required String orderId,
    required String trigger,
    String? previousStatus,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-push',
        body: {
          'order_id': orderId,
          'trigger': trigger,
          if (previousStatus != null && previousStatus.isNotEmpty)
            'previous_status': previousStatus,
        },
      );
      final status = response.status;
      final data = response.data;
      debugPrint('send-push [$trigger] order=$orderId → HTTP $status $data');
      if (status >= 400) {
        debugPrint('send-push FAILED [$trigger] order=$orderId: $data');
      }
    } on FunctionException catch (error) {
      debugPrint(
        'send-push FunctionException [$trigger] order=$orderId: '
        'status=${error.status} details=${error.details} reason=${error.reasonPhrase}',
      );
    } catch (error, stack) {
      debugPrint('send-push invoke error [$trigger] order=$orderId: $error');
      debugPrint('$stack');
    }
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earth = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earth * math.asin(math.sqrt(a));
  }
}

/// Fire-and-forget when a [SupabaseClient] is handy but Riverpod is not
/// (e.g. admin dashboard inline updates).
void dispatchOrderPush(
  SupabaseClient client, {
  required String orderId,
  required String trigger,
  String? previousStatus,
}) {
  unawaited(
    OrderPushDispatcher(client).invoke(
      orderId: orderId,
      trigger: trigger,
      previousStatus: previousStatus,
    ),
  );
}
