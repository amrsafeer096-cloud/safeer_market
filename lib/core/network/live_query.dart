import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'page_visibility.dart';
import 'realtime_session.dart';

/// Cancel callback returned by [LiveQuery.subscribe].
typedef LiveQueryCancel = void Function();

/// Opens a Realtime (or other push) subscription.
///
/// Call [onData] with each update. Call [onError] on channel / WebSocket /
/// token failures — they are never shown in the UI; [LiveQuery] refetches
/// over HTTP and resubscribes instead.
typedef LiveQuerySubscribe<T> = LiveQueryCancel Function(
  void Function(T data) onData,
  void Function(Object error) onError,
);

/// HTTP-first live table subscription that never surfaces WebSocket failures
/// to the UI.
///
/// 1. Loads via [fetch] immediately (works with Realtime down).
/// 2. Subscribes via [subscribe] in the background for instant updates.
/// 3. On `RealtimeSubscribeException` / `WebSocketChannelException` /
///    `channelError` / expired JWT: keeps [value], refreshes auth, refetches
///    over HTTP, and resubscribes with exponential backoff (3s → 5s → 10s…).
/// 4. While the socket is down, polls [fetch] every [disconnectedPollInterval].
/// 5. On app/tab resume, refetches and recreates the Realtime channel.
class LiveQuery<T> extends ChangeNotifier {
  LiveQuery({
    required this.fetch,
    required this.subscribe,
    this.onReconnect,
    this.disconnectedPollInterval = const Duration(seconds: 20),
    List<Duration> backoff = const [
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
  }) : _backoff = backoff;

  /// Standard PostgREST `.select()` (or any HTTP load).
  final Future<T> Function() fetch;

  final LiveQuerySubscribe<T> subscribe;

  final Future<void> Function()? onReconnect;

  /// How often to `.select()` while the WebSocket is disconnected.
  final Duration disconnectedPollInterval;

  final List<Duration> _backoff;

  T? _value;
  T? get value => _value;

  var _hasValue = false;

  /// True after at least one successful [fetch] / Realtime emission (even if
  /// the value itself is null, e.g. a missing order row).
  bool get hasValue => _hasValue;

  var _loading = false;

  /// True only before the first successful [value] arrives.
  bool get loading => _loading && !_hasValue;

  /// Last HTTP failure that blocked the *first* load only. Realtime errors
  /// never set this once data is on screen.
  Object? _fatalError;
  Object? get fatalError => !_hasValue ? _fatalError : null;

  var _socketConnected = false;
  bool get socketConnected => _socketConnected;

  var _disposed = false;
  var _reconnecting = false;
  var _attempt = 0;
  LiveQueryCancel? _cancelSubscription;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<void>? _visibility;

  /// Starts the HTTP load, Realtime subscription, resume hooks and polling.
  Future<T?> start() async {
    if (_disposed) return _value;
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(onResume()));
    _visibility = listenPageBecameVisible(() => unawaited(onResume()));
    await refresh();
    _attachRealtime();
    _syncPollTimer();
    return _value;
  }

  /// Force an HTTP refetch (pull-to-refresh / resume).
  Future<void> refresh() async {
    if (_disposed) return;
    _loading = true;
    notifyListeners();
    try {
      final next = await fetch();
      if (_disposed) return;
      _value = next;
      _hasValue = true;
      _fatalError = null;
    } catch (error) {
      debugPrint('LiveQuery fetch failed: $error');
      if (!_hasValue) _fatalError = error;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> onResume() async {
    if (_disposed) return;
    await _refreshAuth();
    await refresh();
    _attachRealtime(force: true);
  }

  void _attachRealtime({bool force = false}) {
    if (_disposed) return;
    if (_socketConnected && !force) return;
    _cancelSubscription?.call();
    _cancelSubscription = null;
    _socketConnected = false;

    try {
      _cancelSubscription = subscribe(
        (data) {
          if (_disposed) return;
          _value = data;
          _hasValue = true;
          _fatalError = null;
          _attempt = 0;
          final wasConnected = _socketConnected;
          _socketConnected = true;
          if (!wasConnected) _syncPollTimer();
          _reconnecting = false;
          notifyListeners();
        },
        (error) {
          debugPrint('LiveQuery Realtime error (keeping last data): $error');
          _markDisconnected();
          _scheduleReconnect(error);
        },
      );
    } catch (error) {
      debugPrint('LiveQuery subscribe threw: $error');
      _markDisconnected();
      _scheduleReconnect(error);
    }
  }

  void _markDisconnected() {
    _socketConnected = false;
    _syncPollTimer();
  }

  void _scheduleReconnect(Object reason) {
    if (_disposed || _reconnecting) return;
    _reconnecting = true;
    _socketConnected = false;
    _cancelSubscription?.call();
    _cancelSubscription = null;
    _syncPollTimer();

    final index = _attempt.clamp(0, _backoff.length - 1);
    final delay = _backoff[index];
    _attempt++;
    debugPrint(
      'LiveQuery reconnect #$_attempt in ${delay.inSeconds}s ($reason)',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _reconnecting = false;
      if (_disposed) return;
      unawaited(() async {
        await _refreshAuth();
        await refresh();
        _attachRealtime(force: true);
      }());
    });
  }

  void _syncPollTimer() {
    _pollTimer?.cancel();
    if (_disposed || _socketConnected) return;
    // Socket is down: keep orders fresh over HTTP every ~20s.
    _pollTimer = Timer.periodic(disconnectedPollInterval, (_) {
      if (_disposed || _socketConnected) return;
      unawaited(refresh());
    });
  }

  Future<void> _refreshAuth() async {
    try {
      if (onReconnect != null) {
        await onReconnect!();
      } else {
        await ensureRealtimeAuth();
      }
    } catch (error) {
      debugPrint('LiveQuery auth refresh skipped: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _lifecycle?.dispose();
    unawaited(_visibility?.cancel() ?? Future<void>.value());
    _cancelSubscription?.call();
    _cancelSubscription = null;
    super.dispose();
  }
}
