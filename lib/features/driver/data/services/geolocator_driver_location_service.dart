// ignore_for_file: avoid_print

import 'package:geolocator/geolocator.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/services/driver_location_service.dart';

class GeolocatorDriverLocationService implements DriverLocationService {
  const GeolocatorDriverLocationService();

  /// Metres the driver must move before a new fix is emitted.
  static const distanceFilterMeters = 10;

  @override
  Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      print('[Tracking] location services are off');
      throw DriverLocationFailure(L10n.current.driverGpsDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    print('[Tracking] location permission: ${permission.name}');
    switch (permission) {
      case LocationPermission.whileInUse || LocationPermission.always:
        return;
      case LocationPermission.deniedForever:
        throw DriverLocationFailure(
          L10n.current.driverLocationPermissionDeniedForever,
        );
      case LocationPermission.denied || LocationPermission.unableToDetermine:
        throw DriverLocationFailure(
          L10n.current.driverLocationPermissionDenied,
        );
    }
  }

  @override
  Stream<DriverPosition> positions() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((position) {
      print(
        '[Tracking] GPS fix: ${position.latitude}, ${position.longitude} '
        '(±${position.accuracy.toStringAsFixed(0)} m)',
      );
      return (latitude: position.latitude, longitude: position.longitude);
    });
  }
}
