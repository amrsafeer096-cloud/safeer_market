import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../../domain/services/delivery_route_service.dart';

/// Routes from the Google Maps Directions API.
class DirectionsRouteService implements DeliveryRouteService {
  DirectionsRouteService(String apiKey)
      : _polylinePoints = PolylinePoints.legacy(apiKey);

  final PolylinePoints _polylinePoints;

  @override
  Future<List<RoutePoint>> route(
    RoutePoint origin,
    RoutePoint destination,
  ) async {
    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        // ignore: deprecated_member_use
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );
      if (result.points.isEmpty) {
        debugPrint(
          '[Tracking] Directions API returned no route. '
          'status: ${result.status}, errorMessage: ${result.errorMessage}',
        );
      }
      return [
        for (final point in result.points)
          (latitude: point.latitude, longitude: point.longitude),
      ];
    } catch (error, stackTrace) {
      debugPrint('[Tracking] Directions API request failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
      return const [];
    }
  }
}

DeliveryRouteService createPlatformRouteService(String apiKey) =>
    DirectionsRouteService(apiKey);
