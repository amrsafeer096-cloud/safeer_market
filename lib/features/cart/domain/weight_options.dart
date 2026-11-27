import '../../../core/l10n/l10n.dart';

/// Result of «اختر الوزن المطلوب», including an optional item note.
class WeightSelection {
  const WeightSelection({required this.grams, this.notes});

  final int grams;
  final String? notes;
}

/// Weights offered for products sold by the kilo.
abstract final class WeightOptions {
  static const presetsInGrams = [100, 200, 250, 500, 750, 1000];
  static const defaultGrams = 250;

  /// Admin dashboard («تلقي الطلبات» / «تعديل الطلب») quick-picks.
  static const adminQuickPicksInGrams = [125, 250, 500, 1000];

  /// Above the largest preset the cart steps by half a kilo.
  static const _bulkStep = 500;

  /// Customer app: generous bulk limit (50 kg).
  static const customerMaxGrams = 50000;

  /// Admin dashboard: bulk orders up to 999 kg (e.g. 20 / 25 / 50 kg rice).
  static const adminMaxGrams = 999000;

  /// Default parse/step ceiling — customer-facing unless overridden.
  static const maxGrams = customerMaxGrams;

  /// Customer app piece-item quantity ceiling.
  static const customerMaxQuantity = 99;

  static double get customerMaxKg => customerMaxGrams / 1000.0;
  static double get adminMaxKg => adminMaxGrams / 1000.0;

  /// Max fractional digits when entering kilos (0.001 kg = 1 g).
  static const maxKgDecimals = 3;

  static int next(int grams, {int maxGramsLimit = maxGrams}) {
    for (final preset in presetsInGrams) {
      if (preset > grams) return preset;
    }
    final stepped = grams + _bulkStep;
    return stepped > maxGramsLimit ? grams : stepped;
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

  /// Exact kg for storage/sync (3 decimal places = whole grams).
  static double kgOf(int grams) => grams / 1000.0;

  static String label(int grams) {
    final l10n = L10n.current;
    if (grams < 1000) return l10n.gramsValue('$grams');
    final kilos = grams / 1000;
    final text = kilos == kilos.truncateToDouble()
        ? kilos.toInt().toString()
        : _trimKgText(kilos);
    return l10n.kilosValue(text);
  }

  /// Compact Arabic label for receipts / admin chips (preserves decimals).
  static String compactLabel(int grams) {
    if (grams <= 0) return '0';
    if (grams % 1000 == 0) {
      final kg = grams ~/ 1000;
      return kg == 1 ? '1 كجم' : '$kg كجم';
    }
    if (grams > 1000) {
      return '${_trimKgText(grams / 1000.0)} كجم';
    }
    return '$grams جم';
  }

  /// Phone-order chips: fractions of a kilo written out in Arabic.
  static String phoneOrderLabel(int grams) => switch (grams) {
        100 => '100 جرام',
        200 => '200 جرام',
        250 => '250 جرام (ربع كيلو)',
        500 => '500 جرام (نصف كيلو)',
        750 => '750 جرام (ثلاثة أرباع كيلو)',
        1000 => '1 كيلو',
        _ => compactLabel(grams),
      };

  /// Compact admin quick-pick labels (125g / ربع / نص / 1 كيلو).
  static String adminQuickPickLabel(int grams) => switch (grams) {
        125 => '125 جرام',
        250 => 'ربع كيلو',
        500 => 'نص كيلو',
        1000 => '1 كيلو',
        _ => phoneOrderLabel(grams),
      };

  /// Normalize Eastern/Arabic digits and decimal separators to ASCII.
  static String normalizeDecimalInput(String raw) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      final e = eastern.indexOf(ch);
      if (e >= 0) {
        buffer.write(e);
        continue;
      }
      final p = persian.indexOf(ch);
      if (p >= 0) {
        buffer.write(p);
        continue;
      }
      if (ch == ',' || ch == '٫' || ch == '،') {
        buffer.write('.');
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString().trim();
  }

  /// Parse a custom weight field into grams (1…[maxGramsLimit]), or null if invalid.
  ///
  /// [inKilos] true → value is kilograms (up to 3 decimals);
  /// false → value is grams (decimals round to nearest gram).
  /// Defaults to [maxGrams] (customer 50 kg); pass [adminMaxGrams] for staff.
  static int? parseCustomGrams(
    String raw, {
    required bool inKilos,
    int maxGramsLimit = maxGrams,
  }) {
    final normalized = normalizeDecimalInput(raw);
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;

    final grams = inKilos
        ? (value * 1000).round() // 1.3 → 1300, 0.125 → 125, 20 → 20000
        : value.round();
    if (grams < 1 || grams > maxGramsLimit) return null;
    return grams;
  }

  static String _trimKgText(double kilos) {
    var text = kilos.toStringAsFixed(maxKgDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
