typedef DriverPosition = ({double latitude, double longitude});

abstract interface class DriverLocationService {
  /// Asks for location access. Throws [DriverLocationFailure] when GPS is off
  /// or the driver refuses.
  Future<void> ensurePermission();

  /// Live GPS fixes, emitted only after the driver moved a meaningful
  /// distance. Cancelling the subscription stops the GPS.
  Stream<DriverPosition> positions();
}

class DriverLocationFailure implements Exception {
  const DriverLocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
