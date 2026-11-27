import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/features/cart/domain/weight_options.dart';

void main() {
  group('WeightOptions custom parse', () {
    test('kilo decimals map to exact grams', () {
      expect(
        WeightOptions.parseCustomGrams('1.3', inKilos: true),
        1300,
      );
      expect(
        WeightOptions.parseCustomGrams('0.125', inKilos: true),
        125,
      );
      expect(
        WeightOptions.parseCustomGrams('1.25', inKilos: true),
        1250,
      );
    });

    test('normalizes Arabic digits and decimals', () {
      expect(
        WeightOptions.parseCustomGrams('١٫٣', inKilos: true),
        1300,
      );
      expect(
        WeightOptions.parseCustomGrams('1,25', inKilos: true),
        1250,
      );
    });

    test('gram mode', () {
      expect(
        WeightOptions.parseCustomGrams('125', inKilos: false),
        125,
      );
      expect(
        WeightOptions.parseCustomGrams('1300', inKilos: false),
        1300,
      );
    });

    test('rejects empty / non-positive', () {
      expect(WeightOptions.parseCustomGrams('', inKilos: true), isNull);
      expect(WeightOptions.parseCustomGrams('0', inKilos: true), isNull);
      expect(WeightOptions.parseCustomGrams('-1', inKilos: true), isNull);
    });

    test('customer default rejects above 50 kg; admin allows 20–999 kg', () {
      // 20 kg used to be blocked by the old 10 kg ceiling — now allowed.
      expect(
        WeightOptions.parseCustomGrams(
          '20',
          inKilos: true,
          maxGramsLimit: WeightOptions.adminMaxGrams,
        ),
        20000,
      );
      expect(
        WeightOptions.parseCustomGrams(
          '50',
          inKilos: true,
          maxGramsLimit: WeightOptions.customerMaxGrams,
        ),
        50000,
      );
      expect(
        WeightOptions.parseCustomGrams(
          '51',
          inKilos: true,
          maxGramsLimit: WeightOptions.customerMaxGrams,
        ),
        isNull,
      );
      expect(
        WeightOptions.parseCustomGrams(
          '999',
          inKilos: true,
          maxGramsLimit: WeightOptions.adminMaxGrams,
        ),
        999000,
      );
      expect(
        WeightOptions.parseCustomGrams(
          '1000',
          inKilos: true,
          maxGramsLimit: WeightOptions.adminMaxGrams,
        ),
        isNull,
      );
    });

    test('kgOf preserves three decimals', () {
      expect(WeightOptions.kgOf(125), 0.125);
      expect(WeightOptions.kgOf(1300), 1.3);
      expect(WeightOptions.kgOf(1200), 1.2);
    });

    test('compactLabel keeps decimals', () {
      expect(WeightOptions.compactLabel(125), '125 جم');
      expect(WeightOptions.compactLabel(1300), '1.3 كجم');
      expect(WeightOptions.compactLabel(1000), '1 كجم');
    });
  });
}
