import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/features/admin/presentation/widgets/order_detail_panels.dart';
import 'package:safeer_market/features/driver/presentation/screens/order_map_screen.dart';

void main() {
  group('hasValidDeliveryCoordinates', () {
    test('accepts a GPS pin', () {
      expect(hasValidDeliveryCoordinates(30.0561, 31.3301), isTrue);
    });

    test('rejects missing, zero, non-finite and out-of-range values', () {
      expect(hasValidDeliveryCoordinates(null, 31.3), isFalse);
      expect(hasValidDeliveryCoordinates(30.0, null), isFalse);
      expect(hasValidDeliveryCoordinates(0, 0), isFalse);
      expect(hasValidDeliveryCoordinates(30.0, 0), isFalse);
      expect(hasValidDeliveryCoordinates(0, 31.3), isFalse);
      expect(hasValidDeliveryCoordinates(double.nan, 31.3), isFalse);
      expect(hasValidDeliveryCoordinates(95, 31.3), isFalse);
      expect(hasValidDeliveryCoordinates(30.0, 190), isFalse);
    });
  });

  group('orderHasMapPin', () {
    test('legacy orders with only a written address get no map button', () {
      expect(
        orderHasMapPin({
          'address_details': 'عمارة 12 شقة 4',
          'delivery_latitude': null,
          'delivery_longitude': null,
        }),
        isFalse,
      );
      expect(
        orderHasMapPin({
          'address_details': 'عمارة 12 شقة 4',
          'delivery_latitude': '0',
          'delivery_longitude': '0',
        }),
        isFalse,
      );
    });

    test('coordinates stored as text count', () {
      expect(
        orderHasMapPin({
          'delivery_latitude': '30.0561',
          'delivery_longitude': '31.3301',
        }),
        isTrue,
      );
    });

    test('a saved Google Maps link counts, other links do not', () {
      expect(
        orderHasMapPin({'delivery_map_url': 'https://maps.app.goo.gl/abc123'}),
        isTrue,
      );
      expect(
        orderHasMapPin({
          'delivery_map_url': 'https://www.google.com/maps?q=30.05,31.33',
        }),
        isTrue,
      );
      expect(
        orderHasMapPin({'delivery_map_url': 'https://example.com/maps'}),
        isFalse,
      );
      expect(orderHasMapPin({'delivery_map_url': 'عمارة 12'}), isFalse);
    });
  });
}
