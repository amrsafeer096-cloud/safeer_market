/// Safeer Market's customer service line, on WhatsApp too.
abstract final class SupportContact {
  static const phone = '01066208383';

  /// [phone] without the leading 0, after Egypt's country code.
  static const internationalPhone = '201066208383';

  static const whatsappGreeting = 'مرحباً سفير ماركت، أحتاج إلى مساعدة بخصوص...';

  static Uri get callUri => Uri.parse('tel:$phone');

  static Uri get whatsappUri => Uri.parse(
        'https://wa.me/$internationalPhone'
        '?text=${Uri.encodeComponent(whatsappGreeting)}',
      );
}
