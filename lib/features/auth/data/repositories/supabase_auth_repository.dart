import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/egyptian_phone.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  static const _googleScopes = ['email', 'profile'];

  /// [GoogleSignIn.initialize] must run exactly once per app launch.
  static Future<void>? _googleInit;

  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    return _client.auth.onAuthStateChange
        .map((state) => _toAppUser(state.session?.user));
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _client.auth.signInWithPassword(email: email, password: password),
    );
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _guard(() async {
      // The metadata feeds the `handle_new_user` trigger, which creates the
      // profile even when email confirmation leaves us without a session.
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      final user = response.user;
      // With confirmation enabled, Supabase returns a user without identities
      // instead of an error when the email is already registered.
      if (user == null || (user.identities?.isEmpty ?? false)) {
        throw AuthFailure(L10n.current.authEmailAlreadyRegistered);
      }
      if (response.session == null) return SignUpResult.confirmationRequired;

      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'phone': phone,
        });
      } on PostgrestException catch (e) {
        throw AuthFailure(
            L10n.current.authAccountCreatedProfileSaveFailed(e.message));
      }
      return SignUpResult.signedIn;
    });
  }

  @override
  Future<bool> signInWithGoogle() {
    return _guard(() async {
      // google_sign_in has no programmatic sign-in on the web, so the browser
      // goes through Supabase's OAuth redirect and comes back signed in.
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
        return false;
      }
      if (!_nativeGoogleConfigured) return _signInWithGoogleInBrowser();

      final GoogleSignInAccount account;
      final GoogleSignInClientAuthorization authorization;
      try {
        await (_googleInit ??= GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS &&
                  AppConfig.googleIosClientId.isNotEmpty
              ? AppConfig.googleIosClientId
              : null,
          serverClientId: AppConfig.googleWebClientId.isEmpty
              ? null
              : AppConfig.googleWebClientId,
        ));
        account = await GoogleSignIn.instance.authenticate(
          scopeHint: _googleScopes,
        );
        final client = account.authorizationClient;
        authorization = await client.authorizationForScopes(_googleScopes) ??
            await client.authorizeScopes(_googleScopes);
      } on GoogleSignInException catch (e) {
        debugPrint('Google sign-in (native): ${e.code.name} ${e.description}');
        switch (e.code) {
          case GoogleSignInExceptionCode.canceled:
          case GoogleSignInExceptionCode.interrupted:
            return false;
          case GoogleSignInExceptionCode.clientConfigurationError:
          case GoogleSignInExceptionCode.providerConfigurationError:
            // e.g. the app's SHA-1 isn't registered: the browser still works.
            return _signInWithGoogleInBrowser();
          default:
            throw AuthFailure(L10n.current.authGoogleFailed);
        }
      }

      final idToken = account.authentication.idToken;
      if (idToken == null) throw AuthFailure(L10n.current.authGoogleFailed);

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      await _ensureProfileForCurrentUser();
      return true;
    });
  }

  /// Creates / refreshes `profiles` for OAuth users (first Google sign-in).
  Future<void> _ensureProfileForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final fullName = (meta['full_name'] ?? meta['name'] ?? meta['fullName'])
        ?.toString()
        .trim();
    final phone = (meta['phone'] ?? meta['phone_number'])?.toString().trim();
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (e, st) {
      debugPrint('Google profile upsert failed: $e\n$st');
    }
  }

  /// The native account picker needs the OAuth client IDs passed with
  /// `--dart-define`; without them Google sign-in goes through the browser.
  static bool get _nativeGoogleConfigured => switch (defaultTargetPlatform) {
        TargetPlatform.android => AppConfig.googleWebClientId.isNotEmpty,
        TargetPlatform.iOS => AppConfig.googleIosClientId.isNotEmpty,
        _ => false,
      };

  /// Supabase's Google OAuth in the external browser, which hands the session
  /// back through the [AppConfig.authRedirectUrl] deep link. Only needs the
  /// Google provider enabled in Supabase and that URL in its redirect list.
  Future<bool> _signInWithGoogleInBrowser() async {
    final opened = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.authRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!opened) {
      debugPrint('Google sign-in: could not open the browser');
      throw AuthFailure(L10n.current.authGoogleFailed);
    }
    return false;
  }

  @override
  Future<void> signInWithPhone(String phone) {
    return _guard(() => _client.auth.signInWithOtp(phone: phone));
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String token) {
    return _guard(
      () => _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      ),
    );
  }

  @override
  Future<void> signOut() {
    return _guard(() async {
      await _client.auth.signOut();
      // Otherwise the next "Continue with Google" silently reuses the account.
      if (_googleInit != null) {
        unawaited(GoogleSignIn.instance.signOut().catchError((Object _) {}));
      }
    });
  }

  @override
  Future<void> deleteAccount() {
    return _guard(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw AuthFailure(L10n.current.serverConnectionError);
      }

      try {
        await _client.rpc('delete_user_account');
      } on PostgrestException catch (e, st) {
        debugPrint('delete_user_account RPC failed: ${e.message}\n$st');
        // Fallback when the migration isn't applied yet: wipe profile PII.
        try {
          await _client.from('profiles').update({
            'full_name': 'Deleted User',
            'phone': null,
            'loyalty_points': 0,
            'saved_cards': <dynamic>[],
          }).eq('id', uid);
        } catch (profileError, profileStack) {
          debugPrint(
            'Profile anonymize failed: $profileError\n$profileStack',
          );
        }
        try {
          await _client.from('addresses').delete().eq('user_id', uid);
        } catch (_) {}
      }

      await _client.auth.signOut();
      if (_googleInit != null) {
        unawaited(GoogleSignIn.instance.signOut().catchError((Object _) {}));
      }
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.statusCode} ${e.code} ${e.message}');
      throw AuthFailure(_messageFor(e));
    } catch (error, stack) {
      debugPrint('Auth error: $error\n$stack');
      throw AuthFailure(L10n.current.serverConnectionError);
    }
  }

  static String _messageFor(AuthException e) {
    final l10n = L10n.current;
    // No SMS gateway (e.g. Twilio) linked in Supabase.
    if (e.message.toLowerCase().contains('unsupported phone provider')) {
      return l10n.authPhoneLoginDisabled;
    }
    switch (e.code) {
      case 'invalid_credentials':
        return l10n.authInvalidCredentials;
      case 'email_not_confirmed':
        return l10n.authEmailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return l10n.authEmailAlreadyRegistered;
      case 'weak_password':
        return l10n.authWeakPassword;
      case 'otp_expired':
        return l10n.authOtpInvalid;
      case 'sms_send_failed':
        return l10n.authSmsSendFailed;
      case 'phone_provider_disabled':
        return l10n.authPhoneLoginDisabled;
      case 'provider_disabled':
        return l10n.authProviderUnavailable;
      case 'over_email_send_rate_limit':
      case 'over_sms_send_rate_limit':
      case 'over_request_rate_limit':
        return l10n.authTooManyAttempts;
      default:
        return e.message;
    }
  }

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const {};
    final authPhone = user.phone;
    return AppUser(
      id: user.id,
      email: (user.email?.isEmpty ?? true) ? null : user.email,
      // Google fills `full_name`/`name` and `avatar_url`/`picture`.
      fullName: (metadata['full_name'] ?? metadata['name']) as String?,
      phone: metadata['phone'] as String? ??
          (authPhone == null || authPhone.isEmpty
              ? null
              : EgyptianPhone.toLocal(authPhone)),
      avatarUrl: (metadata['avatar_url'] ?? metadata['picture']) as String?,
    );
  }
}
