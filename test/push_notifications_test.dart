import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('saves the token on app start with a saved session', (
    tester,
  ) async {
    final profiles = FakeProfileRepository();
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: profiles,
      pushNotificationService: FakePushNotificationService(token: 'tok-1'),
    );
    await skipSplash(tester);

    expect(profiles.savedTokens, [(userId: testUser.id, token: 'tok-1')]);
  });

  testWidgets('guests save nothing until they sign in', (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    await pumpApp(
      tester,
      authRepository: auth,
      profileRepository: profiles,
      pushNotificationService: FakePushNotificationService(token: 'tok-1'),
    );
    await skipSplash(tester);
    expect(profiles.savedTokens, isEmpty);

    await auth.signIn(email: 'amr@example.com', password: 'secret123');
    await tester.pumpAndSettle();

    expect(profiles.savedTokens, [(userId: 'user-1', token: 'tok-1')]);
  });

  testWidgets('a refreshed token replaces the old one', (tester) async {
    final profiles = FakeProfileRepository();
    final push = FakePushNotificationService(token: 'tok-1');
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: profiles,
      pushNotificationService: push,
    );
    await skipSplash(tester);

    push.refreshes.add('tok-2');
    await tester.pumpAndSettle();

    expect(
        profiles.savedTokens.map((saved) => saved.token), ['tok-1', 'tok-2']);
  });

  testWidgets('no token is saved when push is unavailable', (tester) async {
    final profiles = FakeProfileRepository();
    await pumpApp(
      tester,
      authRepository: FakeAuthRepository(user: testUser),
      profileRepository: profiles,
    );
    await skipSplash(tester);

    expect(profiles.savedTokens, isEmpty);
  });
}
