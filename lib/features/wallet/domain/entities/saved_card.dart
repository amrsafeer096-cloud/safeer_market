import '../../../../core/l10n/l10n.dart';

enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  meeza('Meeza'),
  unknown(null);

  const CardBrand(this._name);

  final String? _name;

  String get label => _name ?? L10n.current.bankCard;

  static CardBrand fromNumber(String digits) {
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) {
      return CardBrand.mastercard;
    }
    if (digits.startsWith('507803') || digits.startsWith('507808')) {
      return CardBrand.meeza;
    }
    return CardBrand.unknown;
  }

  static CardBrand fromName(String? name) {
    switch (name?.toLowerCase()) {
      case 'visa':
        return CardBrand.visa;
      case 'mastercard':
        return CardBrand.mastercard;
      case 'meeza':
        return CardBrand.meeza;
      default:
        return CardBrand.unknown;
    }
  }
}

/// A card as the app is allowed to remember it: never the full number or CVV.
class SavedCard {
  const SavedCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.holderName,
    required this.expiry,
    this.token,
  });

  /// Stable local / remote id for this saved card.
  final String id;

  /// Last 4 digits only (masked display).
  final String last4;
  final CardBrand brand;
  final String holderName;

  /// `MM/YY` as shown on the card.
  final String expiry;

  /// Gateway token or opaque payment id — never the PAN or CVV.
  final String? token;

  String get maskedLabel => '${brand.label} •••• $last4';

  Map<String, dynamic> toJson() => {
        'id': id,
        'last4': last4,
        'brand': brand.name,
        'holderName': holderName,
        'expiry': expiry,
        if (token != null) 'token': token,
      };

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ??
        json['token']?.toString() ??
        '${json['last4']}_${json['expiry']}';
    return SavedCard(
      id: id,
      last4: json['last4']?.toString() ?? '••••',
      brand: CardBrand.fromName(json['brand']?.toString()),
      holderName: json['holderName']?.toString() ??
          json['holder_name']?.toString() ??
          '',
      expiry: json['expiry']?.toString() ?? '',
      token: json['token']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SavedCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
