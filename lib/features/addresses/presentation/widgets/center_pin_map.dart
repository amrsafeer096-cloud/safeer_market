import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

abstract interface class CenterPinMapController {
  Future<void> moveTo(LatLng point, {double zoom});
}

class CenterPinMapConfig {
  const CenterPinMapConfig({
    required this.initialCenter,
    required this.initialZoom,
    required this.onCenterChanged,
    required this.onCreated,
  });

  final LatLng initialCenter;
  final double initialZoom;

  /// Fires continuously while the user drags the map under the fixed pin.
  final ValueChanged<LatLng> onCenterChanged;
  final ValueChanged<CenterPinMapController> onCreated;
}

typedef CenterPinMapBuilder = Widget Function(CenterPinMapConfig config);

/// Overridden in widget tests, where native Google Maps views can't render.
final centerPinMapBuilderProvider = Provider<CenterPinMapBuilder>(
  (ref) => (config) => GoogleCenterPinMap(config: config),
);

class GoogleCenterPinMap extends StatelessWidget {
  const GoogleCenterPinMap({super.key, required this.config});

  final CenterPinMapConfig config;

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: _toGoogle(config.initialCenter),
        zoom: config.initialZoom,
      ),
      onMapCreated: (controller) =>
          config.onCreated(_GoogleCenterPinMapController(controller)),
      onCameraMove: (position) =>
          config.onCenterChanged(_fromGoogle(position.target)),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}

class _GoogleCenterPinMapController implements CenterPinMapController {
  const _GoogleCenterPinMapController(this._controller);

  final gmaps.GoogleMapController _controller;

  @override
  Future<void> moveTo(LatLng point, {double zoom = 17}) {
    return _controller.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_toGoogle(point), zoom),
    );
  }
}

gmaps.LatLng _toGoogle(LatLng point) =>
    gmaps.LatLng(point.latitude, point.longitude);

LatLng _fromGoogle(gmaps.LatLng point) =>
    LatLng(point.latitude, point.longitude);
