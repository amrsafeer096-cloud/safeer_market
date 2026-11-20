import 'package:latlong2/latlong.dart';

/// A point chosen on the map plus whatever address could be read from it.
class PickedLocation {
  const PickedLocation({required this.point, this.area, this.street});

  final LatLng point;
  final String? area;
  final String? street;

  bool get hasAddress => area != null || street != null;
}

enum LocationFailureReason {
  serviceDisabled,
  denied,
  deniedForever,
  unavailable
}

class LocationFailure implements Exception {
  const LocationFailure(this.reason, this.message);

  final LocationFailureReason reason;
  final String message;

  /// Whether the user can fix this from the system settings.
  bool get isFixableInSettings =>
      reason == LocationFailureReason.serviceDisabled ||
      reason == LocationFailureReason.deniedForever;

  @override
  String toString() => message;
}

abstract interface class LocationService {
  /// Asks for permission when needed; throws [LocationFailure].
  Future<LatLng> currentPosition();

  /// Throws [LocationFailure] when no address can be resolved.
  Future<PickedLocation> reverseGeocode(LatLng point);

  /// Opens the screen that resolves [failure]; false when unsupported.
  Future<bool> openSettingsFor(LocationFailure failure);
}
