typedef RoutePoint = ({double latitude, double longitude});

abstract interface class DeliveryRouteService {
  /// Road route from [origin] to [destination], or an empty list when no
  /// route could be fetched.
  Future<List<RoutePoint>> route(RoutePoint origin, RoutePoint destination);
}
