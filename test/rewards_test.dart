import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safeer_market/features/auth/presentation/screens/auth_screen.dart';
import 'package:safeer_market/features/rewards/presentation/providers/rewards_providers.dart';
import 'package:safeer_market/features/rewards/presentation/screens/rewards_screen.dart';
import 'package:safeer_market/features/rewards/presentation/wheel_prizes.dart';
import 'package:safeer_market/features/subscriptions/presentation/providers/subscription_providers.dart';
import 'package:safeer_market/features/subscriptions/presentation/screens/subscription_success_screen.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('home card and المزيد menu open the rewards screen', (
    tester,
  ) async {
    final loyalty = FakeLoyaltyRepository(points: 80);
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      paymobService: FakePaymobService(subscription: FakePaymobService.pro),
      loyaltyRepository: loyalty,
    );
    await skipSplash(tester);

    await tester.tap(find.text('العب واكسب'));
    await tester.pumpAndSettle();

    expect(find.byType(RewardsScreen), findsOneWidget);
    expect(find.text('80 نقطة'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نقاط الولاء'));
    await tester.pumpAndSettle();

    expect(find.byType(RewardsScreen), findsOneWidget);
    expect(find.text('80 نقطة'), findsOneWidget);
  });

  testWidgets('a winning spin adds the prize to loyalty points', (
    tester,
  ) async {
    final loyalty = FakeLoyaltyRepository(points: 80);
    final prize = wheelPrizes.first;
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      paymobService: FakePaymobService(subscription: FakePaymobService.pro),
      loyaltyRepository: loyalty,
      overrides: [
        wheelRollProvider.overrideWithValue((_) => 0),
      ],
    );
    await skipSplash(tester);

    await tester.tap(find.text('العب واكسب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عجلة الحظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'لف العجلة'));
    await tester.pumpAndSettle();

    expect(find.text('مبروك!'), findsOneWidget);
    expect(find.textContaining(prize.label), findsWidgets);
    expect(loyalty.added, [(userId: testUser.id, amount: prize.points)]);
    expect(loyalty.points, 80 + prize.points);

    await tester.tap(find.widgetWithText(FilledButton, 'رائع!'));
    await tester.pumpAndSettle();
    expect(find.text('${loyalty.points} نقطة'), findsOneWidget);
  });

  testWidgets('try again leaves the balance unchanged', (tester) async {
    final loyalty = FakeLoyaltyRepository(points: 80);
    final miss = wheelPrizes.indexWhere((prize) => !prize.isWin);
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      paymobService: FakePaymobService(subscription: FakePaymobService.pro),
      loyaltyRepository: loyalty,
      overrides: [
        wheelRollProvider.overrideWithValue((_) => miss),
      ],
    );
    await skipSplash(tester);

    await tester.tap(find.text('العب واكسب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عجلة الحظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'لف العجلة'));
    await tester.pumpAndSettle();

    expect(find.text('حاول مرة أخرى'), findsWidgets);
    expect(loyalty.added, isEmpty);
    expect(loyalty.points, 80);
  });

  testWidgets('guests are asked to sign in before spinning', (tester) async {
    await pumpApp(tester);
    await skipSplash(tester);

    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نقاط الولاء'));
    await tester.pumpAndSettle();

    expect(find.text('سجّل دخولك لترى نقاطك'), findsOneWidget);
    await tester.tap(find.text('عجلة الحظ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'سجل دخولك لتلعب'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  group('العب واكسب and the plan', () {
    testWidgets('free users get the upgrade sheet, not the game', (
      tester,
    ) async {
      final plans = FakePaymobService();
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        paymobService: plans,
      );
      await skipSplash(tester);

      await tester.tap(find.text('العب واكسب'));
      await tester.pumpAndSettle();

      expect(find.byType(RewardsScreen), findsNothing);
      expect(find.text('رقي حسابك الآن'), findsOneWidget);
      expect(plans.subscriptionReads, 2,
          reason: 'a free plan in memory is read once more before refusing');
    });

    testWidgets('a plan the webhook set since start opens the game at once', (
      tester,
    ) async {
      final plans = FakePaymobService();
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        paymobService: plans,
      );
      await skipSplash(tester);
      expect(plans.subscriptionReads, 1, reason: 'read on start');

      // The payment webhook makes the profile pro behind the app's back.
      plans.subscription = FakePaymobService.pro;
      await tester.tap(find.text('العب واكسب'));
      await tester.pumpAndSettle();

      expect(find.byType(RewardsScreen), findsOneWidget);
    });

    testWidgets('«متابعة التسوق» reloads the plan before leaving', (
      tester,
    ) async {
      final plans = FakePaymobService();
      await pumpApp(
        tester,
        authRepository: FakeAuthRepository(user: testUser),
        paymobService: plans,
      );
      await skipSplash(tester);

      plans.subscription = FakePaymobService.pro;
      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      unawaited(navigator.push(MaterialPageRoute<void>(
        builder: (_) => const SubscriptionSuccessScreen(),
      )));
      await tester.pumpAndSettle();
      final readsBefore = plans.subscriptionReads;

      await tester.tap(find.byKey(const Key('continue-shopping')));
      await tester.pumpAndSettle();

      expect(plans.subscriptionReads, readsBefore + 1);
      expect(find.byType(SubscriptionSuccessScreen), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.text('العب واكسب')),
      );
      expect(
          container.read(subscriptionProvider).valueOrNull?.isFree(), isFalse);

      await tester.tap(find.text('العب واكسب'));
      await tester.pumpAndSettle();
      expect(find.byType(RewardsScreen), findsOneWidget);
      expect(plans.subscriptionReads, readsBefore + 1,
          reason: 'the plan in memory is already pro');
    });
  });
}
