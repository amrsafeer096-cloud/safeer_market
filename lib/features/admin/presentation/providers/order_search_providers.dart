import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/order_search_service.dart';

/// Runs the advanced order search. Overridden in tests.
final orderSearchProvider = Provider<OrderSearchFn>(
  (ref) => (query) => searchOrdersInSupabase(Supabase.instance.client, query),
);
