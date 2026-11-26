import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/features/admin/domain/prep_receipt.dart';

void main() {
  test('weighted line: per-kg price, grams label, no false discount', () {
    final item = PrepReceiptItem.fromJson({
      'product_name': 'امنتال مستورد وزن',
      'quantity': 1,
      'price_at_time': 400.0,
      'weight_in_grams': 500,
      'list_price': 800.0,
      'discount_price': null,
      'category_name': 'جبن',
    });
    expect(item.isWeightBased, isTrue);
    expect(item.quantityLabel, '500 جم');
    expect(item.unitPrice, closeTo(800.0, 0.01));
    expect(item.lineTotal, closeTo(400.0, 0.01));
    expect(item.hasDiscount, isFalse);
  });

  test('weighted RPC shape: unit per kg + explicit line_total', () {
    final item = PrepReceiptItem.fromJson({
      'product_name': 'حلواني روست رومي مدور وزن',
      'quantity': 1,
      'is_weight_based': true,
      'weight_in_grams': 750,
      'unit_price': 720.0,
      'line_total': 540.0,
      'list_price': 720.0,
      'category_name': 'لحوم',
    });
    expect(item.quantityLabel, '750 جم');
    expect(item.unitPrice, closeTo(720.0, 0.01));
    expect(item.lineTotal, closeTo(540.0, 0.01));
    expect(item.hasDiscount, isFalse);
  });

  test('piece line keeps unit × qty and real discount', () {
    final item = PrepReceiptItem.fromJson({
      'product_name': 'جهينة زبادي 5+1',
      'quantity': 5,
      'unit_price': 50.0,
      'line_total': 250.0,
      'list_price': 60.0,
      'discount_price': 50.0,
      'category_name': 'ألبان',
    });
    expect(item.isWeightBased, isFalse);
    expect(item.quantityLabel, '5 قطعة');
    expect(item.unitPrice, 50.0);
    expect(item.lineTotal, 250.0);
    expect(item.hasDiscount, isTrue);
  });

  test('1 kg label', () {
    final item = PrepReceiptItem.fromJson({
      'product_name': 'وزن',
      'quantity': 1,
      'price_at_time': 800.0,
      'weight_in_grams': 1000,
      'list_price': 800.0,
    });
    expect(item.quantityLabel, '1 كجم');
    expect(item.unitPrice, closeTo(800.0, 0.01));
    expect(item.lineTotal, closeTo(800.0, 0.01));
  });

  test('custom 1.3 kg label and math', () {
    final item = PrepReceiptItem.fromJson({
      'product_name': 'وزن مخصص',
      'quantity': 1,
      'price_at_time': 1040.0,
      'weight_in_grams': 1300,
      'list_price': 800.0,
    });
    expect(item.quantityLabel, '1.3 كجم');
    expect(item.unitPrice, closeTo(800.0, 0.01));
    expect(item.lineTotal, closeTo(1040.0, 0.01));
    expect(item.hasDiscount, isFalse);
  });
}
