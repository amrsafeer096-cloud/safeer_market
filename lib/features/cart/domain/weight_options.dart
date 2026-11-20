import '../../../core/l10n/l10n.dart';

/// Weights offered for products sold by the kilo.
abstract final class WeightOptions {
  static const presetsInGrams = [100, 200, 250, 500, 750, 1000];
  static const defaultGrams = 250;

  /// Above the largest preset the cart steps by half a kilo.
  static const _bulkStep = 500;
  static const maxGrams = 10000;

  static int next(int grams) {
    for (final preset in presetsInGrams) {
      if (preset > grams) return preset;
    }
    final stepped = grams + _bulkStep;
    return stepped > maxGrams ? grams : stepped;
  }

  /// Returns 0 below the smallest preset, which removes the item.
  static int previous(int grams) {
    if (grams > presetsInGrams.last) {
      return grams - _bulkStep < presetsInGrams.last
          ? presetsInGrams.last
          : grams - _bulkStep;
    }
    for (final preset in presetsInGrams.reversed) {
      if (preset < grams) return preset;
    }
    return 0;
  }

  /// Price for [grams] of a product costing [pricePerKilo], rounded to piasters.
  static double priceFor(double pricePerKilo, int grams) =>
      (pricePerKilo * grams / 10).round() / 100;

  static String label(int grams) {
    final l10n = L10n.current;
    if (grams < 1000) return l10n.gramsValue('$grams');
    final kilos = grams / 1000;
    final text = kilos == kilos.truncateToDouble()
        ? kilos.toInt().toString()
        : kilos.toString();
    return l10n.kilosValue(text);
  }

  /// Phone-order chips: fractions of a kilo written out in Arabic.
  static String phoneOrderLabel(int grams) => switch (grams) {
        100 => '100 جرام',
        200 => '200 جرام',
        250 => '250 جرام (ربع كيلو)',
        500 => '500 جرام (نصف كيلو)',
        750 => '750 جرام (ثلاثة أرباع كيلو)',
        1000 => '1 كيلو',
        _ => label(grams),
      };
}
