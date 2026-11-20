import '../entities/app_user.dart';

enum SignUpResult { signedIn, confirmationRequired }

abstract class AuthRepository {
  AppUser? get currentUser;

  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  /// Returns true once signed in, false when the user dismissed Google's
  /// account picker or (on web) the browser is redirecting to Google; the
  /// session then arrives through [authStateChanges].
  Future<bool> signInWithGoogle();

  /// Texts a one-time code to [phone] (E.164, e.g. `+201012345678`),
  /// creating the account on first use.
  Future<void> signInWithPhone(String phone);

  /// Signs in with the code sent by [signInWithPhone].
  Future<void> verifyPhoneOtp(String phone, String token);

  Future<void> signOut();

  /// Deletes the signed-in account (RPC + local cleanup handled by callers).
  Future<void> deleteAccount();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
