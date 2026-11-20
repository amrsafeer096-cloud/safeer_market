import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps/google_maps.dart' as js;

import '../../domain/services/delivery_route_service.dart';

/// Routes from the Maps JavaScript API's DirectionsService. Browsers block
/// direct calls to the Directions web service (no CORS headers), so on web
/// the request goes through the Maps script loaded in `web/index.html`, with
/// that script's key.
class WebDirectionsRouteService implements DeliveryRouteService {
  const WebDirectionsRouteService();

  @override
  Future<List<RoutePoint>> route(
    RoutePoint origin,
    RoutePoint destination,
  ) async {
    try {
      final result = await js.DirectionsService().route(
        js.DirectionsRequest(
          origin: js.LatLng(origin.latitude, origin.longitude),
          destination: js.LatLng(destination.latitude, destination.longitude),
          travelMode: js.TravelMode.DRIVING,
        ),
      );
      final routes = result.routes;
      if (routes.isEmpty) {
        debugPrint('[Tracking] Maps JS DirectionsService returned no route');
        return const [];
      }
      return [
        for (final point
            in PolylinePoints.decodePolyline(routes.first.overviewPolyline))
          (latitude: point.latitude, longitude: point.longitude),
      ];
    } catch (error) {
      // A rejected key shows up here as REQUEST_DENIED.
      debugPrint('[Tracking] Maps JS DirectionsService failed: $error');
      return const [];
    }
  }
}

DeliveryRouteService createPlatformRouteService(String apiKey) =>
    const WebDirectionsRouteService();
