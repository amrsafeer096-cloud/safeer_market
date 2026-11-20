import '../../domain/services/delivery_route_service.dart';
import 'directions_route_service.dart'
    if (dart.library.js_interop) 'web_directions_route_service.dart'
    as platform;

/// The Directions web service on Android and iOS, the Maps JavaScript API's
/// DirectionsService on web.
DeliveryRouteService createDeliveryRouteService(String apiKey) =>
    platform.createPlatformRouteService(apiKey);
