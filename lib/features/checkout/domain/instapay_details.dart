/// Official Safeer Market InstaPay transfer details shown at checkout.
abstract final class InstaPayDetails {
  /// Exact signed deep link — do not alter `ISIGN` (character-accurate).
  static const deepLink =
      'https://ipn.eg/C/Q/amradelfathy0/instapay?ISIGN=23052602MEQCIDxEHKUP7BiAxBOnN2Tb32qaEpp15rLXEUeaJkLQ9hqrAiAC6GYEayf4Qh64nu0nvDnydM6tl3c4GL3Kl09IK70Jmg==';

  static const logoAsset = 'assets/images/instapay_logo.webp';
  static const ipa = 'amradelfathy0@instapay';
  static const phone = '01067244277';
}
