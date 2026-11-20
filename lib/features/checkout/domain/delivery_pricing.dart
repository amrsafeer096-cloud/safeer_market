import 'dart:math' as math;

import '../../../core/config/store_location.dart';
import '../../../core/l10n/l10n.dart';

class DeliveryBracket {
  const DeliveryBracket({required this.maxKm, required this.fee});

  /// Inclusive upper bound of the distance from the store.
  final double maxKm;

  /// Delivery fee in EGP.
  final double fee;
}

sealed class DeliveryQuote {
  const DeliveryQuote();
}

/// The address has no map pin, so its distance can't be measured.
final class DeliveryLocationMissing extends DeliveryQuote {
  const DeliveryLocationMissing();
}

final class DeliveryAvailable extends DeliveryQuote {
  const DeliveryAvailable({required this.distanceKm, required this.fee});

  final double distanceKm;
  final double fee;
}

/// Farther than the last bracket; checkout is blocked.
final class DeliveryOutOfRange extends DeliveryQuote {
  const DeliveryOutOfRange(this.distanceKm);

  final double distanceKm;
}

abstract final class DeliveryPricing {
  static const brackets = <DeliveryBracket>[
    DeliveryBracket(maxKm: 1, fee: 25),
    DeliveryBracket(maxKm: 2, fee: 30),
    DeliveryBracket(maxKm: 3.5, fee: 35),
    DeliveryBracket(maxKm: 5, fee: 40),
    DeliveryBracket(maxKm: 6.5, fee: 45),
  ];

  static double get maxDistanceKm => brackets.last.maxKm;

  static const _earthRadiusKm = 6371.0;

  /// Great-circle distance between two points (Haversine formula).
  static double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    double radians(double degrees) => degrees * math.pi / 180;

    final dLat = radians(toLatitude - fromLatitude);
    final dLon = radians(toLongitude - fromLongitude);
    final sinLat = math.sin(dLat / 2);
    final sinLon = math.sin(dLon / 2);
    final a = sinLat * sinLat +
        math.cos(radians(fromLatitude)) *
            math.cos(radians(toLatitude)) *
            sinLon *
            sinLon;
    return 2 * _earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  static double distanceFromStoreKm(double latitude, double longitude) =>
      distanceKm(
        fromLatitude: StoreLocation.latitude,
        fromLongitude: StoreLocation.longitude,
        toLatitude: latitude,
        toLongitude: longitude,
      );

  /// [freeDelivery] (subscribers) makes the fee 0; the address must still be
  /// pinned and within range.
  static DeliveryQuote quote({
    double? latitude,
    double? longitude,
    bool freeDelivery = false,
  }) {
    if (latitude == null || longitude == null) {
      return const DeliveryLocationMissing();
    }
    final distance = distanceFromStoreKm(latitude, longitude);
    for (final bracket in brackets) {
      if (distance <= bracket.maxKm) {
        return DeliveryAvailable(
          distanceKm: distance,
          fee: freeDelivery ? 0 : bracket.fee,
        );
      }
    }
    return DeliveryOutOfRange(distance);
  }

  /// e.g. "2.4 كم". Rounds up so the shown distance never sits below the
  /// bracket that was charged (1.04 km shows as 1.1, not 1.0).
  static String formatDistance(double km) {
    final tenths = math.max(0, (km * 10 - 1e-9).ceil());
    return L10n.current.kmValue((tenths / 10).toStringAsFixed(1));
  }
}
