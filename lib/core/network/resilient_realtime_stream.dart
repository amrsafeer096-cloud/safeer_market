import 'dart:async';

import 'live_query.dart';
import 'realtime_session.dart';

/// HTTP-first live stream that never emits errors for Realtime / WebSocket
/// failures. Prefer this over binding UI to a raw Supabase `.stream()`.
///
/// - Emits the first [fetch] result immediately.
/// - Mirrors Realtime [create] updates while the socket is healthy.
/// - On `RealtimeSubscribeException` / `WebSocketChannelException` /
///   `channelError` / expired token: keeps the last value, refreshes auth,
///   refetches over HTTP, and resubscribes with 3s → 5s → 10s backoff.
/// - Polls [fetch] every 20s while the socket is disconnected.
/// - On app/tab resume: HTTP refetch + Realtime recreate.
Stream<T> resilientRealtimeStream<T>({
  required Future<T> Function() fetch,
  required Stream<T> Function() create,
  Future<void> Function()? onReconnect,
  Duration disconnectedPollInterval = const Duration(seconds: 20),
  List<Duration> backoff = const [
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ],
}) {
  late final StreamController<T> controller;
  LiveQuery<T>? live;
  void Function()? removeListener;

  controller = StreamController<T>(
    onListen: () {
      live = LiveQuery<T>(
        fetch: fetch,
        onReconnect: onReconnect ?? ensureRealtimeAuth,
        disconnectedPollInterval: disconnectedPollInterval,
        backoff: backoff,
        subscribe: (onData, onError) {
          final subscription = create().listen(
            onData,
            onError: onError,
            onDone: () => onError(StateError('Realtime stream closed')),
            cancelOnError: false,
          );
          return subscription.cancel;
        },
      );

      void push() {
        final query = live;
        if (query == null || !query.hasValue || controller.isClosed) return;
        controller.add(query.value as T);
      }

      live!.addListener(push);
      removeListener = () => live?.removeListener(push);

      unawaited(live!.start().then((_) {
        // start() already notified; ensure the first HTTP snapshot is out
        // even if identical to a later Realtime event.
        push();
      }));
    },
    onCancel: () async {
      removeListener?.call();
      live?.dispose();
      live = null;
    },
  );

  return controller.stream;
}
