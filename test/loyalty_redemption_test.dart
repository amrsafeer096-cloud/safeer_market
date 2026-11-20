import 'dart:async';
import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/core/routing/app_router.dart';
import 'package:safeer_market/core/routing/app_routes.dart';
import 'package:safeer_market/features/profile/domain/entities/user_role.dart';
import 'package:safeer_market/features/rewards/domain/loyalty_redemption.dart';
import 'package:safeer_market/features/rewards/domain/repositories/loyalty_redemption_repository.dart';
import 'package:safeer_market/features/rewards/domain/repositories/loyalty_repository.dart';
import 'package:safeer_market/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:safeer_market/features/rewards/presentation/screens/cashier_redemption_screen.dart';
import 'package:safeer_market/features/rewards/presentation/screens/cashier_scan_screen.dart';
import 'package:safeer_market/features/rewards/presentation/widgets/redeem_points_dialog.dart';

import 'test_helpers.dart';

const _customerId = '6f1c2a9e-3b7d-4e21-9a55-0c8d7e6f5a41';

class _FakeRedemptions implements LoyaltyRedemptionRepository {
  _FakeRedemptions({this.customerPoints = 175, this.failure});

  int customerPoints;
  final LoyaltyFailure? failure;
  final events = StreamController<void>.broadcast();
  final redeemed = <({String userId, int discountEgp})>[];
  final watched = <String>[];

  @override
  Future<LoyaltyCustomer> fetchCustomer(String userId) async => LoyaltyCustomer(
        userId: userId,
        points: customerPoints,
        fullName: 'منى أحمد',
      );

  @override
  Future<LoyaltyRedemption> redeem({
    required String userId,
    required int discountEgp,
  }) async {
    if (failure != null) throw failure!;
    redeemed.add((userId: userId, discountEgp: discountEgp));
    final deducted = discountEgp * RedemptionQuote.pointsPerEgp;
    customerPoints -= deducted;
    return LoyaltyRedemption(
      pointsRedeemed: deducted,
      discountEgp: discountEgp,
      remainingPoints: customerPoints,
    );
  }

  @override
  Stream<void> watchRedemptions(String userId) {
    watched.add(userId);
    return events.stream;
  }
}

/// Stands in for the camera: a button per code it can "see".
Widget Function(ValueChanged<String>) _fakeScanner(List<String> codes) =>
    (onScan) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, code) in codes.indexed)
              TextButton(
                key: Key('fake-scan-$i'),
                onPressed: () => onScan(code),
                child: Text('scan $i'),
              ),
          ],
        );

Future<void> _openRewards(WidgetTester tester) async {
  await tester.tap(find.text('المزيد'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('نقاط الولاء'));
  await tester.pumpAndSettle();
}

void main() {
  group('RedemptionQuote', () {
    test('every 50 points is 1 EGP; the rest stays', () {
      final quote = RedemptionQuote.forPoints(175);
      expect(quote.discountEgp, 3);
      expect(quote.pointsToDeduct, 150);
      expect(quote.remainingPoints, 25);
      expect(quote.canRedeem, isTrue);
      expect(quote.barcodeData, 'SAFEER-003');
    });

    test('under 50 points is not enough', () {
      for (final points in [0, 1, 49, -5]) {
        expect(RedemptionQuote.forPoints(points).canRedeem, isFalse,
            reason: '$points');
      }
      expect(RedemptionQuote.forPoints(50).barcodeData, 'SAFEER-001');
    });

    test('the barcode pads to three digits and never truncates', () {
      expect(RedemptionQuote.forPoints(12345).barcodeData, 'SAFEER-246');
      expect(RedemptionQuote.forPoints(50000).barcodeData, 'SAFEER-1000');
    });
  });

  group('customer code', () {
    test('is {"user_id": ...} and reads back', () {
      final code = CustomerLoyaltyCode.encode(_customerId);
      expect(jsonDecode(code), {'user_id': _customerId});
      expect(CustomerLoyaltyCode.decode(code), _customerId);
    });

    test('anything else is not a customer code', () {
      for (final raw in [
        null,
        '',
        'SAFEER-003',
        '{"user_id": 5}',
        '{"user_id": "not-a-uuid"}',
        '["$_customerId"]',
        '{"id": "$_customerId"}',
      ]) {
        expect(CustomerLoyaltyCode.decode(raw), isNull, reason: raw);
      }
    });
  });

  test('only cashiers and admins reach the scanner', () {
    expect(UserRole.fromValue('cashier'), UserRole.cashier);
    expect(roleRedirect(AppRoutes.cashierScan, UserRole.cashier), isNull);
    expect(roleRedirect(AppRoutes.cashierScan, UserRole.admin), isNull);
    for (final role in [UserRole.customer, UserRole.driver, null]) {
      expect(roleRedirect(AppRoutes.cashierScan, role), AppRoutes.home,
          reason: '$role');
    }
  });

  group('customer', () {
    testWidgets('the QR dialog closes when the redemption arrives', (
      tester,
    ) async {
      final redemptions = _FakeRedemptions();
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        loyaltyRepository: FakeLoyaltyRepository(points: 175),
        overrides: [
          loyaltyRedemptionRepositoryProvider.overrideWithValue(redemptions),
          redemptionPollIntervalProvider
              .overrideWithValue(const Duration(hours: 1)),
        ],
      );
      await skipSplash(tester);
      await _openRewards(tester);

      await tester.tap(find.byKey(const Key('redeem-points')));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemPointsDialog), findsOneWidget);
      expect(find.byKey(const Key('redeem-qr')), findsOneWidget);
      expect(redemptions.watched, [testUser.id]);

      redemptions.events.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(RedeemPointsDialog), findsNothing);
      expect(find.text('تم تطبيق الخصم بنجاح'), findsOneWidget);
    });

    testWidgets('without the Realtime event, a lower balance closes it too', (
      tester,
    ) async {
      final loyalty = FakeLoyaltyRepository(points: 175);
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        loyaltyRepository: loyalty,
        overrides: [
          loyaltyRedemptionRepositoryProvider
              .overrideWithValue(_FakeRedemptions()),
          redemptionPollIntervalProvider
              .overrideWithValue(const Duration(seconds: 4)),
        ],
      );
      await skipSplash(tester);
      await _openRewards(tester);
      await tester.tap(find.byKey(const Key('redeem-points')));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(RedeemPointsDialog), findsOneWidget,
          reason: 'same balance: still waiting');

      loyalty.points = 25;
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(RedeemPointsDialog), findsNothing);
      expect(find.text('تم تطبيق الخصم بنجاح'), findsOneWidget);
    });

    testWidgets('customers get no scanner button', (tester) async {
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
      );
      await skipSplash(tester);
      await _openRewards(tester);

      expect(find.byKey(const Key('redeem-points')), findsOneWidget);
      expect(find.byKey(const Key('scan-customer-code')), findsNothing);
    });
  });

  group('cashier', () {
    Future<_FakeRedemptions> openScanner(
      WidgetTester tester, {
      int customerPoints = 175,
      List<String>? codes,
      LoyaltyFailure? failure,
    }) async {
      final redemptions =
          _FakeRedemptions(customerPoints: customerPoints, failure: failure);
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        profileRepository: FakeProfileRepository(null, UserRole.cashier),
        overrides: [
          loyaltyRedemptionRepositoryProvider.overrideWithValue(redemptions),
          customerCodeScannerProvider.overrideWithValue(_fakeScanner(
            codes ?? [CustomerLoyaltyCode.encode(_customerId)],
          )),
        ],
      );
      await skipSplash(tester);
      await _openRewards(tester);
      await tester.tap(find.byKey(const Key('scan-customer-code')));
      await tester.pumpAndSettle();
      expect(find.byType(CashierScanScreen), findsOneWidget);
      return redemptions;
    }

    testWidgets('scan, show SAFEER-003 for 175 points, confirm', (
      tester,
    ) async {
      final redemptions = await openScanner(tester);

      await tester.tap(find.byKey(const Key('fake-scan-0')));
      await tester.pumpAndSettle();

      expect(find.byType(CashierRedemptionScreen), findsOneWidget);
      expect(find.text('منى أحمد'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('cashier-points-to-deduct')))
            .data,
        '150 نقطة',
      );
      final barcode = tester.widget<BarcodeWidget>(find.byType(BarcodeWidget));
      expect(String.fromCharCodes(barcode.data), 'SAFEER-003');
      expect(barcode.barcode, isA<Barcode>());
      expect(barcode.barcode.name, Barcode.code128().name);
      expect(barcode.backgroundColor, Colors.white);
      final frame =
          tester.widget<Container>(find.byKey(const Key('cashier-barcode')));
      expect(frame.color, Colors.white);

      final confirm = find.byKey(const Key('confirm-points-deduction'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(redemptions.redeemed, [(userId: _customerId, discountEgp: 3)]);
      expect(find.byType(CashierRedemptionScreen), findsNothing);
      expect(find.byType(CashierScanScreen), findsOneWidget,
          reason: 'ready for the next customer');
      expect(find.textContaining('150'), findsWidgets);
    });

    testWidgets('a refused confirmation stays on screen and says why', (
      tester,
    ) async {
      await openScanner(
        tester,
        failure: const LoyaltyFailure('الرصيد لا يكفي لخصم 1 جنيه'),
      );
      await tester.tap(find.byKey(const Key('fake-scan-0')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const Key('confirm-points-deduction'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(CashierRedemptionScreen), findsOneWidget);
      expect(find.text('الرصيد لا يكفي لخصم 1 جنيه'), findsOneWidget);
    });

    testWidgets('under 50 points says the balance is too low', (tester) async {
      final redemptions = await openScanner(tester, customerPoints: 49);

      await tester.tap(find.byKey(const Key('fake-scan-0')));
      await tester.pumpAndSettle();

      expect(find.byType(CashierRedemptionScreen), findsNothing);
      expect(find.text('الرصيد لا يكفي لخصم 1 جنيه'), findsOneWidget);
      expect(redemptions.redeemed, isEmpty);
    });

    testWidgets('a code that is not a customer code is refused', (
      tester,
    ) async {
      await openScanner(tester, codes: ['https://example.com']);

      await tester.tap(find.byKey(const Key('fake-scan-0')));
      await tester.pumpAndSettle();

      expect(find.byType(CashierRedemptionScreen), findsNothing);
      expect(find.text('هذا ليس كود عميل من سفير ماركت'), findsOneWidget);
    });
  });
}
