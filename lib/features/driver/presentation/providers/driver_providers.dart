// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../data/repositories/supabase_driver_orders_repository.dart';
import '../../data/services/geolocator_driver_location_service.dart';
import '../../domain/entities/driver_order.dart';
import '../../domain/repositories/driver_orders_repository.dart';
import '../../domain/services/driver_location_service.dart';

final driverOrdersRepositoryProvider = Provider<DriverOrdersRepository>((ref) {
  return SupabaseDriverOrdersRepository(ref.watch(supabaseClientProvider));
});

final driverLocationServiceProvider = Provider<DriverLocationService>(
  (ref) => const GeolocatorDriverLocationService(),
);

final availableOrdersProvider =
    FutureProvider.autoDispose<List<DriverOrder>>((ref) {
  return ref.watch(driverOrdersRepositoryProvider).fetchAvailableOrders();
});

final myDeliveriesProvider =
    FutureProvider.autoDispose<List<DriverOrder>>((ref) {
  return ref.watch(driverOrdersRepositoryProvider).fetchMyDeliveries();
});

final driverLocationTrackerProvider =
    ChangeNotifierProvider(DriverLocationTracker.new);

final driverActionsProvider = Provider(DriverActions.new);

enum TrackingStatus { idle, starting, streaming }

/// Streams the driver's GPS into every order they are delivering, so the
/// customers' tracking maps follow them. A single GPS subscription serves all
/// of them and is cancelled as soon as none are left.
class DriverLocationTracker extends ChangeNotifier {
  DriverLocationTracker(this._ref);

  final Ref _ref;
  final _orderIds = <String>{};

  /// Orders started by the driver that no deliveries list has confirmed yet;
  /// kept so a list fetched before the accept doesn't stop their stream.
  final _startedOrderIds = <String>{};
  StreamSubscription<DriverPosition>? _subscription;

  /// Told about every failure (permission, GPS, Supabase), at most once per
  /// message until tracking restarts, so the driver isn't flooded every 10 m.
  void Function(String message)? onFailure;
  final _reportedFailures = <String>{};

  TrackingStatus _status = TrackingStatus.idle;
  TrackingStatus get status => _status;

  /// When Supabase last accepted a position.
  DateTime? get lastSentAt => _lastSentAt;
  DateTime? _lastSentAt;

  bool get isTracking => _subscription != null;
  Set<String> get trackedOrderIds => Set.unmodifiable(_orderIds);

  /// Whether the GPS is live and feeding [orderId].
  bool isSharing(String orderId) =>
      _status == TrackingStatus.streaming && _orderIds.contains(orderId);

  /// Shares the driver's position on exactly [orderIds]; an empty set stops
  /// the GPS. Throws [DriverLocationFailure] when location access is refused.
  Future<void> track(Set<String> orderIds) {
    _startedOrderIds.removeAll(orderIds);
    _orderIds
      ..clear()
      ..addAll(orderIds)
      ..addAll(_startedOrderIds);
    return _ensureStreaming();
  }

  /// Adds [orderId] to the orders being fed and starts the GPS if needed.
  Future<void> start(String orderId) {
    _startedOrderIds.add(orderId);
    _orderIds.add(orderId);
    return _ensureStreaming();
  }

  Future<void> _ensureStreaming() async {
    if (_orderIds.isEmpty) {
      stop();
      return;
    }
    if (_status != TrackingStatus.idle) return;

    _setStatus(TrackingStatus.starting);
    print('[Tracking] requesting location permission for orders $_orderIds');
    final location = _ref.read(driverLocationServiceProvider);
    try {
      await location.ensurePermission();
    } catch (error) {
      print('[Tracking] location permission FAILED: $error');
      _setStatus(TrackingStatus.idle);
      rethrow;
    }
    // The orders may have been delivered while the permission dialog was up.
    if (_orderIds.isEmpty) {
      _setStatus(TrackingStatus.idle);
      return;
    }
    print('[Tracking] GPS stream started for orders $_orderIds');
    _reportedFailures.clear();
    _subscription = location.positions().listen(
      _publish,
      onError: (Object error) {
        print('[Tracking] GPS stream error: $error');
        _report(L10n.current.driverLocationReadFailed('$error'));
      },
      onDone: () {
        print('[Tracking] GPS stream closed');
        _subscription = null;
        _setStatus(TrackingStatus.idle);
        _report(L10n.current.driverLocationSharingStopped);
      },
    );
    _setStatus(TrackingStatus.streaming);
  }

  /// Stops sharing the position on [orderId], and the GPS if it was the last.
  void untrack(String orderId) {
    _startedOrderIds.remove(orderId);
    _orderIds.remove(orderId);
    if (_orderIds.isEmpty) stop();
  }

  void stop() {
    if (_subscription != null) print('[Tracking] GPS stream stopped');
    _orderIds.clear();
    _subscription?.cancel();
    _subscription = null;
    _setStatus(TrackingStatus.idle);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  void _setStatus(TrackingStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  void _publish(DriverPosition position) {
    final repository = _ref.read(driverOrdersRepositoryProvider);
    for (final orderId in [..._orderIds]) {
      print(
        '[Tracking] sending ${position.latitude}, ${position.longitude} '
        'to order $orderId',
      );
      repository
          .updateDriverLocation(
        orderId,
        latitude: position.latitude,
        longitude: position.longitude,
      )
          .then((_) {
        print('[Tracking] order $orderId updated');
        if (_subscription == null) return;
        _lastSentAt = DateTime.now();
        notifyListeners();
      }).catchError((Object error) {
        print('[Tracking] order $orderId update FAILED: $error');
        _report(error.toString());
      });
    }
  }

  void _report(String message) {
    if (_reportedFailures.add(message)) onFailure?.call(message);
  }
}

class DriverActions {
  const DriverActions(this._ref);

  final Ref _ref;

  Future<void> accept(DriverOrder order) async {
    try {
      await _ref.read(driverOrdersRepositoryProvider).acceptOrder(order.id);
    } finally {
      // Refresh either way: on failure the order was probably taken.
      _refresh();
    }
  }

  Future<void> markDelivered(DriverOrder order) async {
    // Stop the GPS first; if the update fails, the refresh resumes tracking.
    _ref.read(driverLocationTrackerProvider).untrack(order.id);
    try {
      await _ref.read(driverOrdersRepositoryProvider).markDelivered(order.id);
    } finally {
      _refresh();
    }
  }

  void _refresh() {
    _ref
      ..invalidate(availableOrdersProvider)
      ..invalidate(myDeliveriesProvider);
  }
}
