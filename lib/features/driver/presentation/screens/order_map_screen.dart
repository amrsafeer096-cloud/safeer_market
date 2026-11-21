import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/store_location.dart';
import '../../../../core/services/external_url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';

export '../../../../core/services/external_url_launcher.dart';

/// True when an order has a real GPS pin from the app's map picker: both
/// coordinates present, finite, non-zero and on the globe. Legacy imported
/// customers and phone orders only have a written address (building /
/// apartment numbers), so they get no map navigation.
bool hasValidDeliveryCoordinates(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return false;
  if (!latitude.isFinite || !longitude.isFinite) return false;
  if (latitude == 0 || longitude == 0) return false;
  return latitude.abs() <= 90 && longitude.abs() <= 180;
}

/// A saved Google Maps pin link (`https://maps.app.goo.gl/…`,
/// `https://www.google.com/maps/…`, `geo:…`), or null when [value] isn't one.
Uri? savedMapPinUri(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  if (uri.scheme == 'geo') return uri;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  final host = uri.host.toLowerCase();
  final mapsPath = uri.path.startsWith('/maps');
  final isMaps = host == 'maps.app.goo.gl' ||
      host == 'maps.google.com' ||
      (host == 'goo.gl' && mapsPath) ||
      ((host == 'google.com' || host.startsWith('www.google.')) && mapsPath);
  return isMaps ? uri : null;
}

/// «التوجه عبر الخريطة»: Google Maps turn-by-turn directions to the
/// customer's pin, else a saved map pin link. Callers should hide the button
/// when neither exists (see [hasValidDeliveryCoordinates], [savedMapPinUri]).
Future<void> openCustomerInGoogleMaps(
  BuildContext context,
  WidgetRef ref, {
  double? latitude,
  double? longitude,
  String? address,
  Uri? mapPinUri,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  final written = address?.trim();
  final Uri uri;
  if (hasValidDeliveryCoordinates(latitude, longitude)) {
    uri = OrderMapScreen.directionsUri(latitude!, longitude!);
  } else if (mapPinUri != null) {
    uri = mapPinUri;
  } else if (written != null && written.isNotEmpty) {
    uri = OrderMapScreen.addressDirectionsUri(written);
  } else {
    messenger.showSnackBar(SnackBar(content: Text(l10n.noLocationForOrder)));
    return;
  }
  if (!await ref.read(externalUrlLauncherProvider)(uri)) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.secondary,
      content: Text(l10n.driverOpenGoogleMapsFailed),
    ));
  }
}

/// Google map for one delivery: the store pin and the customer's pin.
class OrderMapScreen extends ConsumerWidget {
  const OrderMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double? latitude;
  final double? longitude;

  static const storePoint =
      LatLng(StoreLocation.latitude, StoreLocation.longitude);

  /// Google Maps turn-by-turn; Android only.
  static Uri navigationUri(double latitude, double longitude) =>
      Uri.parse('google.navigation:q=$latitude,$longitude');

  /// Directions in Google Maps on any platform, or in the browser.
  static Uri directionsUri(double latitude, double longitude) => Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude',
      );

  /// Directions to an address typed by the customer, for orders placed
  /// without a map pin.
  static Uri addressDirectionsUri(String address) => Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${Uri.encodeComponent(address)}',
      );

  Future<void> _startNavigation(
    BuildContext context,
    WidgetRef ref,
    double latitude,
    double longitude,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final launch = ref.read(externalUrlLauncherProvider);
    if (await launch(navigationUri(latitude, longitude))) return;
    if (await launch(directionsUri(latitude, longitude))) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(l10n.driverOpenGoogleMapsFailed),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasPin = hasValidDeliveryCoordinates(this.latitude, this.longitude);
    final latitude = hasPin ? this.latitude : null;
    final longitude = hasPin ? this.longitude : null;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.driverMapAndLocationTitle)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: latitude != null && longitude != null
            ? SizedBox(
                height: 56,
                child: FloatingActionButton.extended(
                  onPressed: () =>
                      _startNavigation(context, ref, latitude, longitude),
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text(
                    l10n.driverStartNavigation,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : null,
        body: latitude != null && longitude != null
            ? _DeliveryMap(
                customer: LatLng(latitude, longitude),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.noLocationForOrder,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DeliveryMap extends StatelessWidget {
  const _DeliveryMap({required this.customer});

  final LatLng customer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: customer,
            initialZoom: 14,
            initialCameraFit: CameraFit.coordinates(
              coordinates: [OrderMapScreen.storePoint, customer],
              padding: const EdgeInsets.fromLTRB(48, 100, 48, 110),
              maxZoom: 16,
            ),
            minZoom: 5,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              // Google roadmap tiles. Markers below are the store and customer.
              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
              userAgentPackageName: 'com.example.safeer_market',
              maxZoom: 20,
            ),
            MarkerLayer(
              markers: [
                const Marker(
                  key: Key('store-marker'),
                  point: OrderMapScreen.storePoint,
                  width: 46,
                  height: 46,
                  alignment: Alignment.bottomCenter,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 42,
                    color: AppColors.primary,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Marker(
                  key: const Key('customer-marker'),
                  point: customer,
                  width: 48,
                  height: 48,
                  alignment: Alignment.bottomCenter,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 46,
                    color: AppColors.secondary,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const PositionedDirectional(
          start: 12,
          end: 12,
          top: 12,
          child: _MapLegend(),
        ),
      ],
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Material(
      color: palette.card,
      elevation: palette.isDark ? 0 : 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _LegendItem(
              icon: Icons.storefront_rounded,
              color: palette.accent,
              label: l10n.branch,
            ),
            const SizedBox(width: 16),
            _LegendItem(
              icon: Icons.location_on_rounded,
              color: AppColors.secondary,
              label: l10n.customer,
            ),
            const Spacer(),
            Text(
              'Google',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
