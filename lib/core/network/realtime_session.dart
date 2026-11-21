import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'page_visibility.dart';
import 'supabase_providers.dart';

/// Pushes the current access token into the Realtime socket, refreshing the
/// session first when it is missing or already expired. Safe to call often.
Future<void> ensureRealtimeAuth([SupabaseClient? client]) async {
  final supabase = client ?? Supabase.instance.client;
  try {
    var session = supabase.auth.currentSession;
    if (session == null || session.isExpired) {
      final response = await supabase.auth.refreshSession();
      session = response.session ?? supabase.auth.currentSession;
    }
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return;
    await supabase.realtime.setAuth(token);
  } catch (error) {
    debugPrint('Realtime auth sync skipped: $error');
  }
}

/// Keeps Realtime's JWT in sync for the life of the app:
/// - [AuthChangeEvent.signedIn] / [AuthChangeEvent.tokenRefreshed]
/// - app / tab resume (mobile lifecycle + web `visibilitychange`)
///
/// Watch it once at the app root so Admin / Warehouse / Orders stay connected
/// without a manual refresh.
final realtimeAuthSyncProvider = Provider<void>((ref) {
  final client = ref.watch(supabaseClientProvider);

  Future<void> syncFromSession(Session? session) async {
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      await client.realtime.setAuth(token);
    } catch (error) {
      debugPrint('Realtime setAuth skipped: $error');
    }
  }

  Future<void> onWake() async {
    await ensureRealtimeAuth(client);
  }

  // Current session (e.g. restored after a cold start).
  unawaited(syncFromSession(client.auth.currentSession));

  final authSub = client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.initialSession ||
        event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.tokenRefreshed) {
      unawaited(syncFromSession(data.session));
    }
  });

  final lifecycle = AppLifecycleListener(onResume: () => unawaited(onWake()));
  final visibility = listenPageBecameVisible(() => unawaited(onWake()));

  ref.onDispose(() {
    authSub.cancel();
    lifecycle.dispose();
    visibility?.cancel();
  });
});
