/// Supabase project URL (no `/rest/v1` suffix — the Flutter SDK appends it).
/// Override with `--dart-define=SUPABASE_URL=...` if needed.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jugdxfhmjakmzjvfltjv.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_sG4TQm_Y90WEVVha9zC8hQ_aGM0C0ia',
  );

  /// OAuth "Web application" client ID from Google Cloud — the same one set
  /// as the Google provider's Client ID in Supabase Auth. Android needs it as
  /// the server client ID to receive an ID token Supabase accepts.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// OAuth "iOS" client ID from Google Cloud (iOS only).
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Deep link Supabase sends the app back to after browser sign-in. Must be
  /// in Supabase → Authentication → URL Configuration → Redirect URLs, and
  /// match the intent filter in AndroidManifest.xml / URL type in Info.plist.
  static const authRedirectUrl = 'io.supabase.safeermarket://login-callback/';

  /// Key for Google Places API (New), used by the map's place search
  /// (`--dart-define=GOOGLE_PLACES_API_KEY=...`). Enable "Places API (New)"
  /// for it in Google Cloud. Without it, search falls back to the device's
  /// geocoder.
  static const googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
  );

  /// Phone (SMS code) sign-in. Off until an SMS provider such as Twilio is
  /// linked in Supabase → Authentication → Providers → Phone; turn on with
  /// `--dart-define=PHONE_AUTH_ENABLED=true`.
  static const phoneAuthEnabled = bool.fromEnvironment('PHONE_AUTH_ENABLED');
}
