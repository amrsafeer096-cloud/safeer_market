import 'dart:async';

import 'package:flutter/foundation.dart';

import 'realtime_session.dart';

/// Wraps a Supabase `.stream(...)` (or any Realtime-backed stream) so a
/// `RealtimeSubscribeException` / `channelError` never kills the UI.
///
/// - Keeps emitting the last successful value while reconnecting.
/// - On error: refreshes the auth session, calls `realtime.setAuth`, waits
///   [backoff], then recreates the stream.
/// - Optional [poll] every [pollInterval] so a brief WebSocket drop cannot
///   hide new orders on admin / taker screens.
Stream<T> resilientRealtimeStream<T>({
  required Stream<T> Function() create,
  Future<T> Function()? poll,
  Duration backoff = const Duration(seconds: 2),
  Duration pollInterval = const Duration(seconds: 45),
  Future<void> Function()? onReconnect,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? pollTimer;
  Timer? reconnectTimer;
  var disposed = false;
  var reconnecting = false;
  T? lastValue;
  var attempt = 0;

  Future<void> refreshAuth() async {
    if (onReconnect != null) {
      await onReconnect();
    } else {
      await ensureRealtimeAuth();
    }
  }

  void emit(T value) {
    lastValue = value;
    attempt = 0;
    if (!controller.isClosed) controller.add(value);
  }

  Future<void> runPoll() async {
    if (poll == null || disposed || controller.isClosed) return;
    try {
      emit(await poll());
    } catch (error) {
      debugPrint('Realtime poll skipped: $error');
    }
  }

  void schedulePoll() {
    pollTimer?.cancel();
    if (poll == null) return;
    pollTimer = Timer.periodic(pollInterval, (_) => unawaited(runPoll()));
  }

  void subscribe() {
    if (disposed || controller.isClosed) return;
    subscription?.cancel();
    try {
      subscription = create().listen(
        emit,
        onError: (Object error, StackTrace stack) {
          debugPrint('Realtime stream error (will reconnect): $error');
          scheduleReconnect(error);
        },
        onDone: () {
          if (!disposed) scheduleReconnect('stream closed');
        },
        cancelOnError: false,
      );
    } catch (error) {
      scheduleReconnect(error);
    }
  }

  /// Synchronous gate so onError + onDone from the same dead socket cannot
  /// schedule two overlapping reconnects.
  void scheduleReconnect(Object reason) {
    if (disposed || controller.isClosed || reconnecting) return;
    reconnecting = true;
    unawaited(reconnect(reason));
  }

  Future<void> reconnect(Object reason) async {
    subscription?.cancel();
    subscription = null;
    attempt++;
    final delay = Duration(
      milliseconds: (backoff.inMilliseconds * attempt).clamp(
        backoff.inMilliseconds,
        15000,
      ),
    );
    debugPrint('Realtime reconnect #$attempt in ${delay.inMilliseconds}ms '
        '($reason)');
    try {
      await refreshAuth();
    } catch (_) {}
    reconnectTimer?.cancel();
    reconnectTimer = Timer(delay, () {
      reconnecting = false;
      if (disposed || controller.isClosed) return;
      // Re-emit the last list so StreamProvider stays in AsyncData, never
      // AsyncError, while the new socket catches up.
      final cached = lastValue;
      if (cached != null && !controller.isClosed) controller.add(cached);
      subscribe();
      unawaited(runPoll());
    });
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(() async {
        await refreshAuth();
        if (disposed || controller.isClosed) return;
        subscribe();
        await runPoll();
        schedulePoll();
      }());
    },
    onCancel: () async {
      disposed = true;
      reconnectTimer?.cancel();
      pollTimer?.cancel();
      await subscription?.cancel();
    },
  );

  return controller.stream;
}
