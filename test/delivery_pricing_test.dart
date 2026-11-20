import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/config/store_location.dart';
import 'package:safeer_market/features/checkout/domain/delivery_pricing.dart';

/// Kilometres per degree of latitude for R = 6371 km.
const _kmPerDegree = 111.19492664455873;

/// A point [km] due north of the store; its Haversine distance is exact.
DeliveryQuote _quoteAt(double km) => DeliveryPricing.quote(
      latitude: StoreLocation.latitude + km / _kmPerDegree,
      longitude: StoreLocation.longitude,
    );

double? _feeAt(double km) => switch (_quoteAt(km)) {
      DeliveryAvailable(:final fee) => fee,
      _ => null,
    };

void main() {
  test('store coordinates are the Nasr City branch', () {
    expect(StoreLocation.latitude, 30.040283);
    expect(StoreLocation.longitude, 31.338779);
  });

  group('Haversine distance', () {
    test('is zero at the store', () {
      expect(
        DeliveryPricing.distanceFromStoreKm(
          StoreLocation.latitude,
          StoreLocation.longitude,
        ),
        0,
      );
    });

    test('one degree along the equator is ~111.19 km', () {
      expect(
        DeliveryPricing.distanceKm(
          fromLatitude: 0,
          fromLongitude: 0,
          toLatitude: 0,
          toLongitude: 1,
        ),
        closeTo(111.195, 0.001),
      );
    });

    test('accounts for longitude shrinking with latitude', () {
      // Store to Tahrir Square: mostly east-west, ~9.93 km.
      expect(
        DeliveryPricing.distanceFromStoreKm(30.0444, 31.2357),
        closeTo(9.93, 0.02),
      );
    });

    test('is symmetric', () {
      double between(double aLat, double aLon, double bLat, double bLon) =>
          DeliveryPricing.distanceKm(
            fromLatitude: aLat,
            fromLongitude: aLon,
            toLatitude: bLat,
            toLongitude: bLon,
          );
      expect(
        between(30.040283, 31.338779, 30.0626, 31.3460),
        closeTo(between(30.0626, 31.3460, 30.040283, 31.338779), 1e-9),
      );
    });
  });

  group('fee brackets', () {
    test('match the agreed tiers', () {
      expect(
        DeliveryPricing.brackets.map((b) => (b.maxKm, b.fee)),
        [(1.0, 25.0), (2.0, 30.0), (3.5, 35.0), (5.0, 40.0), (6.5, 45.0)],
      );
    });

    test('each bracket is inclusive of its upper bound', () {
      expect(_feeAt(0), 25);
      expect(_feeAt(0.99), 25);
      expect(_feeAt(1.01), 30);
      expect(_feeAt(1.99), 30);
      expect(_feeAt(2.01), 35);
      expect(_feeAt(3.49), 35);
      expect(_feeAt(3.51), 40);
      expect(_feeAt(4.99), 40);
      expect(_feeAt(5.01), 45);
      expect(_feeAt(6.49), 45);
    });

    test('beyond 6.5 km is out of range', () {
      final quote = _quoteAt(6.51);
      expect(quote, isA<DeliveryOutOfRange>());
      expect((quote as DeliveryOutOfRange).distanceKm, closeTo(6.51, 1e-6));
      expect(_quoteAt(25), isA<DeliveryOutOfRange>());
    });

    test('an address without a pin cannot be priced', () {
      expect(DeliveryPricing.quote(), isA<DeliveryLocationMissing>());
      expect(
        DeliveryPricing.quote(latitude: 30.05),
        isA<DeliveryLocationMissing>(),
      );
    });
  });

  test('shown distance rounds up so it never undercuts the bracket', () {
    expect(DeliveryPricing.formatDistance(0), '0.0 كم');
    expect(DeliveryPricing.formatDistance(0.96), '1.0 كم');
    expect(DeliveryPricing.formatDistance(1.0), '1.0 كم');
    expect(DeliveryPricing.formatDistance(1.04), '1.1 كم');
    expect(DeliveryPricing.formatDistance(6.5), '6.5 كم');
  });
}
