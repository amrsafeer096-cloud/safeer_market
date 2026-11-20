import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_providers.dart';

/// FCM topic every driver device subscribes to.
const driversTopic = 'drivers';

final newOrderNotifierProvider = Provider<NewOrderNotifier>(
  (ref) => EdgeFunctionNewOrderNotifier(ref.watch(supabaseClientProvider)),
);

abstract interface class NewOrderNotifier {
  /// Pushes "طلب جديد متاح للتوصيل!" to the [driversTopic].
  Future<void> notifyDrivers(String orderId);
}

/// FCM can only be sent with the Firebase service-account key, which must
/// never ship inside the app, so the `notify-drivers` Edge Function sends it.
class EdgeFunctionNewOrderNotifier implements NewOrderNotifier {
  const EdgeFunctionNewOrderNotifier(this._client);

  final SupabaseClient _client;

  @override
  Future<void> notifyDrivers(String orderId) async {
    await _client.functions.invoke(
      'notify-drivers',
      body: {'order_id': orderId},
    );
  }
}
