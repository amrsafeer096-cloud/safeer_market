import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/egyptian_phone.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

/// Whether "Continue with phone number" is offered ([AppConfig.phoneAuthEnabled]).
final phoneAuthEnabledProvider = Provider<bool>(
  (ref) => AppConfig.phoneAuthEnabled,
);

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user, or null for guests. Falls back to the cached session
/// until the auth stream emits its first event.
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.hasValue) return authState.value;
  return ref.watch(authRepositoryProvider).currentUser;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(
  AuthController.new,
);

class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  /// Returns null when sign-up failed; the error is exposed through [state].
  Future<SignUpResult?> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    SignUpResult? result;
    state = await AsyncValue.guard(() async {
      result = await _repository.signUp(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
    });
    return result;
  }

  /// True once signed in; false on failure (see [state]), when the user
  /// closed Google's picker, or while the web redirect is under way.
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    var signedIn = false;
    state = await AsyncValue.guard(() async {
      signedIn = await _repository.signInWithGoogle();
    });
    return signedIn;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.signOut);
  }

  /// Deletes the account remotely, then clears local prefs / secure storage.
  Future<bool> deleteAccount({
    Future<void> Function()? clearLocalData,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteAccount();
      if (clearLocalData != null) await clearLocalData();
    });
    return !state.hasError;
  }
}

enum PhoneAuthStep { enterPhone, enterCode }

/// Phone + SMS code sign-in. [phone] is the local `01xxxxxxxxx` number the
/// code was sent to, once on [PhoneAuthStep.enterCode].
class PhoneAuthState {
  const PhoneAuthState({
    this.step = PhoneAuthStep.enterPhone,
    this.phone,
    this.isLoading = false,
    this.error,
    this.codeSentAt,
  });

  final PhoneAuthStep step;
  final String? phone;
  final bool isLoading;
  final String? error;
  final DateTime? codeSentAt;

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    String? phone,
    bool? isLoading,
    String? error,
    DateTime? codeSentAt,
  }) {
    return PhoneAuthState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      codeSentAt: codeSentAt ?? this.codeSentAt,
    );
  }
}

final phoneAuthControllerProvider =
    NotifierProvider.autoDispose<PhoneAuthController, PhoneAuthState>(
  PhoneAuthController.new,
);

class PhoneAuthController extends AutoDisposeNotifier<PhoneAuthState> {
  @override
  PhoneAuthState build() => const PhoneAuthState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// [phone] is the local number; returns true once the SMS is on its way.
  Future<bool> sendCode(String phone) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signInWithPhone(EgyptianPhone.toE164(phone));
      state = state.copyWith(
        step: PhoneAuthStep.enterCode,
        phone: phone,
        isLoading: false,
        codeSentAt: DateTime.now(),
      );
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _message(error));
      return false;
    }
  }

  Future<bool> resendCode() async {
    final phone = state.phone;
    return phone != null && await sendCode(phone);
  }

  Future<bool> verify(String code) async {
    final phone = state.phone;
    if (phone == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.verifyPhoneOtp(EgyptianPhone.toE164(phone), code);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _message(error));
      return false;
    }
  }

  void changeNumber() => state = PhoneAuthState(phone: state.phone);

  static String _message(Object error) =>
      error is AuthFailure ? error.message : L10n.current.unexpectedError;
}
