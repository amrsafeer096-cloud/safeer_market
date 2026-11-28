import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/features/admin/domain/fujitsu_address_composer.dart';

void main() {
  test('Fujitsu formula matches TrustyDelivery example', () {
    expect(
      composeFujitsuAddress(
        building: '5',
        street: 'الجرجاني',
        floor: '5',
        apartment: '2',
        zone: 'حى السفارات',
        city: 'مدينة نصر',
        governorate: 'القاهرة',
      ),
      '5 - ش الجرجاني - الدور 5 - شقة 2 - حى السفارات - مدينة نصر - القاهرة',
    );
  });

  test('does not duplicate ش prefix or empty landmark', () {
    expect(
      composeFujitsuAddress(
        building: '5',
        street: 'ش الجرجاني',
        landmark: 'كوبري',
        city: 'مدينة نصر',
        governorate: 'القاهرة',
      ),
      '5 - ش الجرجاني - ع.م كوبري - مدينة نصر - القاهرة',
    );
  });
}
