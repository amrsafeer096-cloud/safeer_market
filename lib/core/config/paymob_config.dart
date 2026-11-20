/// Paymob Accept credentials used for in-app card checkout
/// (auth → order → payment key → iframe). No Edge Function involved.
///
/// Optional overrides at build time:
/// `--dart-define=PAYMOB_API_KEY=...` etc.
abstract final class PaymobConfig {
  static const apiKey = String.fromEnvironment(
    'PAYMOB_API_KEY',
    defaultValue:
        'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRJMU5EWTJOeXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS4wOFFrdnJQRklhc2twMENNbDZUZVo2dlBqemxTNFBpM1hSUm51NGdlZk9xTGdJUUkzR2hFUXE0N0o1RUFCTDdKclJkZGh0MW9HUHlQMXJVU1ZyUVRQdw==',
  );

  static const integrationId = String.fromEnvironment(
    'PAYMOB_INTEGRATION_ID',
    defaultValue: '6048858',
  );

  static const iframeId = String.fromEnvironment(
    'PAYMOB_IFRAME_ID',
    defaultValue: '1095533',
  );

  static const baseUrl = String.fromEnvironment(
    'PAYMOB_BASE_URL',
    defaultValue: 'https://accept.paymob.com',
  );

  /// Deep link after card payment (Android / iOS URL scheme).
  static const redirectUrl = 'io.supabase.safeermarket://payment-result';
}
