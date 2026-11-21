import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/store_location.dart';
import '../../../../core/network/realtime_session.dart';
import '../../../../core/network/resilient_realtime_stream.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer_order.dart';
import '../providers/orders_providers.dart';
import '../widgets/rate_order_dialog.dart';

/// Live tracking for an order that is out for delivery: follows the order's
/// row in realtime and puts the driver marker at the latest position.
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.latitude,
    this.longitude,
    this.driverPhone,
  });

  final String orderId;

  /// Delivery pin from the orders list, shown until the live row arrives.
  final double? latitude;
  final double? longitude;

  /// From the out-for-delivery push payload, until the live row loads.
  final String? driverPhone;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  static const _store =
      gmaps.LatLng(StoreLocation.latitude, StoreLocation.longitude);

  static const _driverIconAsset = 'assets/images/motorcycle.png';
  static const _routeColor = Color(0xFF1E88E5);

  late final Stream<CustomerOrder?> _order;
  gmaps.GoogleMapController? _map;
  gmaps.LatLng? _framedDriver;

  /// Orange pin until the motorcycle image has loaded.
  gmaps.BitmapDescriptor _driverIcon =
      gmaps.BitmapDescriptor.defaultMarkerWithHue(
    gmaps.BitmapDescriptor.hueOrange,
  );

  String get _shortId => widget.orderId.length > 8
      ? widget.orderId.substring(0, 8)
      : widget.orderId;

  @override
  void initState() {
    super.initState();
    final override =
        ref.read(trackedOrderStreamOverrideProvider(widget.orderId));
    if (override != null) {
      _order = override;
    } else {
      final client = Supabase.instance.client;
      final orderId = widget.orderId;
      CustomerOrder? fromRows(List<Map<String, dynamic>> rows) =>
          rows.isEmpty ? null : CustomerOrder.fromRow(rows.first);
      _order = resilientRealtimeStream<CustomerOrder?>(
        fetch: () async {
          final row = await client
              .from('orders')
              .select()
              .eq('id', orderId)
              .maybeSingle();
          return row == null ? null : CustomerOrder.fromRow(row);
        },
        create: () => client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('id', orderId)
            .map(fromRows),
        onReconnect: () => ensureRealtimeAuth(client),
      ).map((order) {
        debugPrint(
          '[Tracking] order ${order?.status ?? 'not found'}, '
          'driver_lat: ${order?.driverLatitude}, '
          'driver_lng: ${order?.driverLongitude}',
        );
        return order;
      });
    }
    _loadDriverIcon();
  }

  Future<void> _loadDriverIcon() async {
    try {
      final icon = await gmaps.BitmapDescriptor.asset(
        const ImageConfiguration(),
        _driverIconAsset,
        width: 48,
      );
      if (!mounted) return;
      setState(() => _driverIcon = icon);
    } catch (error) {
      debugPrint('[Tracking] motorcycle icon failed to load: $error');
    }
  }

  gmaps.LatLng? _destinationOf(CustomerOrder? order) {
    final latitude = order?.deliveryLatitude ?? widget.latitude;
    final longitude = order?.deliveryLongitude ?? widget.longitude;
    return latitude != null && longitude != null
        ? gmaps.LatLng(latitude, longitude)
        : null;
  }

  static gmaps.LatLng? _driverOf(CustomerOrder? order) {
    if (order == null || order.isDelivered) return null;
    final latitude = order.driverLatitude;
    final longitude = order.driverLongitude;
    return latitude != null && longitude != null
        ? gmaps.LatLng(latitude, longitude)
        : null;
  }

  /// Re-frames the camera whenever the driver moves, keeping both the
  /// driver and the customer on screen.
  void _scheduleFraming(gmaps.LatLng? driver, gmaps.LatLng? destination) {
    if (driver == null || driver == _framedDriver) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _frame(driver, destination);
    });
  }

  Future<void> _frame(gmaps.LatLng driver, gmaps.LatLng? destination) async {
    final map = _map;
    if (map == null) return;
    _framedDriver = driver;
    final other = destination ?? _store;
    final south = math.min(driver.latitude, other.latitude);
    final north = math.max(driver.latitude, other.latitude);
    final west = math.min(driver.longitude, other.longitude);
    final east = math.max(driver.longitude, other.longitude);
    // Bounds around (almost) a single point would zoom in to street level.
    final update = north - south < 0.002 && east - west < 0.002
        ? gmaps.CameraUpdate.newLatLngZoom(driver, 16)
        : gmaps.CameraUpdate.newLatLngBounds(
            gmaps.LatLngBounds(
              southwest: gmaps.LatLng(south, west),
              northeast: gmaps.LatLng(north, east),
            ),
            72,
          );
    try {
      await map.animateCamera(update);
    } catch (_) {
      // The map can still be laying out; the next GPS fix retries.
      _framedDriver = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(title: Text(l10n.trackingTitle(_shortId))),
        body: StreamBuilder<CustomerOrder?>(
          stream: _order,
          builder: (context, snapshot) {
            final order = snapshot.data;
            final destination = _destinationOf(order);
            final driver = _driverOf(order);
            _scheduleFraming(driver, destination);

            return Column(
              children: [
                Expanded(
                  child: gmaps.GoogleMap(
                    key: const Key('order-tracking-map'),
                    initialCameraPosition: gmaps.CameraPosition(
                      target: driver ?? destination ?? _store,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _map = controller;
                      _scheduleFraming(driver, destination);
                    },
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId('store'),
                        position: _store,
                        infoWindow: gmaps.InfoWindow(title: l10n.branch),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueAzure,
                        ),
                      ),
                      if (destination != null)
                        gmaps.Marker(
                          markerId: const gmaps.MarkerId('destination'),
                          position: destination,
                          infoWindow: gmaps.InfoWindow(
                              title: l10n.trackingYourAddressMarker),
                        ),
                      if (driver != null)
                        gmaps.Marker(
                          markerId: const gmaps.MarkerId('driver'),
                          position: driver,
                          infoWindow: gmaps.InfoWindow(
                              title: l10n.trackingDriverMarker),
                          icon: _driverIcon,
                          anchor: const Offset(0.5, 0.5),
                        ),
                    },
                    polylines: {
                      if (driver != null && destination != null)
                        gmaps.Polyline(
                          polylineId: const gmaps.PolylineId('route'),
                          points: [driver, destination],
                          color: _routeColor,
                          width: 5,
                        ),
                    },
                  ),
                ),
                _TrackingPanel(
                  state: switch (order) {
                    CustomerOrder(isDelivered: true) =>
                      _TrackingState.delivered,
                    _ when driver != null => _TrackingState.live,
                    _ => _TrackingState.locating,
                  },
                  orderId: widget.orderId,
                  driverName: order?.driverName,
                  driverPhone: order?.driverPhone ?? widget.driverPhone,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _TrackingState { locating, live, delivered }

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({
    required this.state,
    required this.orderId,
    this.driverName,
    this.driverPhone,
  });

  final _TrackingState state;
  final String orderId;
  final String? driverName;
  final String? driverPhone;

  Future<void> _callDriver(BuildContext context) async {
    final raw = driverPhone?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    if (raw.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: raw);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعذر فتح تطبيق الاتصال'
                : 'Could not open the phone dialer',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final (title, icon, color) = switch (state) {
      _TrackingState.delivered => (
          l10n.trackingOrderDelivered,
          Icons.task_alt_rounded,
          AppColors.success,
        ),
      _ => (
          l10n.orderOnTheWayToYou,
          Icons.delivery_dining_rounded,
          const Color(0xFF1565C0),
        ),
    };
    final phone = driverPhone?.trim();

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (driverName != null && driverName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                arabic
                    ? 'المندوب: $driverName'
                    : 'Driver: $driverName',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ],
            if (state != _TrackingState.delivered) ...[
              const SizedBox(height: 12),
              state == _TrackingState.live
                  ? _StatusNote(
                      key: const Key('driver-location-live'),
                      icon: Icons.gps_fixed_rounded,
                      color: AppColors.success,
                      text: l10n.trackingDriverLocationLive,
                    )
                  : _StatusNote(
                      key: const Key('driver-location-placeholder'),
                      icon: Icons.gps_not_fixed_rounded,
                      color: palette.muted,
                      text: l10n.trackingDriverLocating,
                    ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('call-driver'),
                  onPressed: () => _callDriver(context),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(arabic ? 'اتصال بالمندوب' : 'Call driver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('rate-order-from-tracking'),
                onPressed: () =>
                    showRateOrderDialog(context, orderId: orderId),
                icon: const Icon(Icons.star_rounded),
                label: Text(arabic ? 'تقييم الطلب' : 'Rate order'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
