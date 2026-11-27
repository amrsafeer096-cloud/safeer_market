import '../../../../core/l10n/l10n.dart';

/// A row of the Supabase `products` table.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.unit = defaultUnit,
    this.description,
    this.categoryId,
    this.category,
    this.subCategory,
    this.stockQuantity = defaultStockQuantity,
    this.barcode,
    this.discountPrice,
    this.isActive = true,
    this.createdAt,
    this.pieces = 1,
    bool isWeightBased = false,
  }) : _isWeightBased = isWeightBased;

  /// For products built in code. Rows read from the database always use
  /// their `stock_quantity`, where a missing value counts as 0.
  static const defaultStockQuantity = 100;
  static const defaultUnit = 'قطعة';
  static const weightUnit = 'وزن';

  final String id;
  final String name;

  /// Regular price (`price`): per kilo when [isWeightBased], otherwise per
  /// [unit]. Charge [effectivePrice], which accounts for [discountPrice].
  final double price;
  final String? imageUrl;

  /// Unit of sale as named in the POS, e.g. 'قطعة', 'وزن', 'كرتونة'. Shown
  /// through [displayUnit].
  final String unit;
  final String? description;

  /// `category_id`: the `categories` row (UUID) this product belongs to.
  final String? categoryId;

  /// `category`: the product's group, e.g. 'جبن تترباك' or 'منظفات'. Drives
  /// the home categories grid, the categories drawer and category pages.
  final String? category;

  /// `sub_category`: an optional finer group within [categoryId], e.g.
  /// 'معلبات'.
  final String? subCategory;

  /// `stock_quantity`: units on hand. Zero or less means out of stock.
  final int stockQuantity;

  final String? barcode;

  /// `discount_price`: the sale price while discounted, else null.
  final double? discountPrice;

  /// `is_active`: manual on/off switch, independent of [stockQuantity].
  final bool isActive;

  /// `created_at`: when the row was added, or null if the database didn't
  /// say.
  final DateTime? createdAt;

  /// Fujitsu `v_hd_items.Pieces` for this barcode (1 = loose/weight unit,
  /// >1 = sealed pack/sack sold by integer quantity).
  final int pieces;

  final bool _isWeightBased;

  /// Effective pack size: `products.pieces` when >1, else ERP «ك * N» in
  /// [unit].
  int get effectivePieces {
    if (pieces > 1) return pieces;
    return piecesPerCarton ?? 1;
  }

  /// Sold by decimal kg **only** when pack size is 1. Any barcode with
  /// `pieces > 1` (or unit `ك * N`) is a pack — never the weight picker —
  /// even if the name contains «وزن».
  bool get isWeightBased {
    if (effectivePieces > 1) return false;
    return _isWeightBased ||
        unit.trim() == weightUnit ||
        name.contains(weightUnit) ||
        canonicalUnit(unit) == 'كيلو';
  }

  /// Box / pack / carton packaging (`علبة`, `كرتونة`, ERP `ك * N`, pieces>1).
  bool get isBoxUnit {
    if (effectivePieces > 1) return true;
    if (piecesPerCarton != null) return true;
    final c = canonicalUnit(unit);
    if (c == 'علبة' || c == 'كرتونة' || c == 'باكو') return true;
    final raw = unit.trim().toLowerCase();
    return raw.contains('علبة') ||
        raw.contains('علبه') ||
        raw.contains('كرتون') ||
        raw.contains('باكت') ||
        raw.contains('باكو') ||
        raw.contains('pack') ||
        raw.contains('box') ||
        raw.contains('carton');
  }

  /// Single-piece sale unit (not weight, not box/carton).
  bool get isPieceUnit => !isWeightBased && !isBoxUnit;

  /// What to show after the price («/ علبة»), in the app language. Weight
  /// items are priced per kilo; a unit the app doesn't know shows as stored.
  String get displayUnit {
    final l10n = L10n.current;
    if (isWeightBased) return l10n.unitKilo;
    final stored = unit.trim();
    final pack = effectivePieces > 1 ? effectivePieces : null;
    if (pack != null) return l10n.unitBoxOf('$pack');
    return switch (canonicalUnit(stored)) {
      'قطعة' => l10n.unitPiece,
      'كيلو' => l10n.unitKilo,
      'كرتونة' => l10n.unitCarton,
      'علبة' => l10n.unitBox,
      'كيس' => l10n.unitBag,
      'باكو' => l10n.unitPack,
      'طقم' => l10n.unitSet,
      _ => stored.isEmpty ? l10n.unitPiece : stored,
    };
  }

  /// The ERP's carton code: «ك * 36» (spaces optional) is a carton of 36.
  static final _cartonCode = RegExp(r'^ك\s*[*×xX]\s*(\d+)$');

  /// Pieces in a carton when [unit] is the ERP's «ك * N» code, else null.
  int? get piecesPerCarton {
    final match = _cartonCode.firstMatch(unit.trim());
    final count = match == null ? null : int.tryParse(match.group(1)!);
    return count == null || count <= 0 ? null : count;
  }

  /// Spellings and codes a POS or import may use, by the POS's Arabic name.
  static const _unitAliases = <String, String>{
    'قطعة': 'قطعة',
    'قطعه': 'قطعة',
    'piece': 'قطعة',
    'pcs': 'قطعة',
    'pc': 'قطعة',
    'ea': 'قطعة',
    'كيلو': 'كيلو',
    'كجم': 'كيلو',
    'كيلوجرام': 'كيلو',
    'kg': 'كيلو',
    'kilo': 'كيلو',
    'كرتونة': 'كرتونة',
    'كرتونه': 'كرتونة',
    'كرتون': 'كرتونة',
    'carton': 'كرتونة',
    'ctn': 'كرتونة',
    'علبة': 'علبة',
    'علبه': 'علبة',
    'box': 'علبة',
    'كيس': 'كيس',
    'bag': 'كيس',
    'باكو': 'باكو',
    'باكت': 'باكو',
    'pack': 'باكو',
    'packet': 'باكو',
    'طقم': 'طقم',
    'set': 'طقم',
  };

  /// [raw]'s unit in the POS's Arabic spelling (e.g. 'box' → 'علبة'), or
  /// null when it isn't a known unit.
  static String? canonicalUnit(String raw) =>
      _unitAliases[raw.trim().toLowerCase()];

  /// For a row with no unit: one named as a whole word in [name] (e.g.
  /// «تونة صن شاين علبة»). Whole words only, so «كيلوجز» isn't read as a kilo.
  /// Otherwise a piece.
  static String unitFromName(String name) {
    if (name.contains(weightUnit)) return weightUnit;
    final words = name.split(RegExp(r'[\s\-*/,.()]+'));
    for (final unit in const ['علبة', 'كرتونة', 'طقم', 'كيلو']) {
      if (words.any((word) => canonicalUnit(word) == unit)) return unit;
    }
    return defaultUnit;
  }

  /// Offers live on the product itself as `discount_price` (no separate
  /// offers table or date range). One only counts when it's above zero and
  /// below the regular price, so a bad import can't make an item free.
  bool get hasActiveOffer {
    final discount = discountPrice;
    return discount != null && discount > 0 && discount < price;
  }

  /// What is charged: the offer price while [hasActiveOffer], else [price].
  double get effectivePrice => hasActiveOffer ? discountPrice! : price;

  /// The regular price to strike through while [hasActiveOffer].
  double? get oldPrice => hasActiveOffer ? price : null;

  /// Rounded saving for the offer badge, e.g. 15 for 15% off.
  int get discountPercentage => hasActiveOffer && price > 0
      ? ((1 - discountPrice! / price) * 100).round()
      : 0;

  bool get inStock => isActive && stockQuantity > 0;

  /// Whether `image_url` is a usable http(s) link. Only admins are shown
  /// products without one, so they can spot what still needs a photo. A link
  /// can still fail to load (e.g. the Storage file is gone); the UI handles
  /// that at runtime.
  bool get hasValidImageUrl => isValidImageUrl(imageUrl);

  /// This product with no image link, for when its link is known to be dead.
  Product withoutImage() => Product(
        id: id,
        name: name,
        price: price,
        unit: unit,
        description: description,
        categoryId: categoryId,
        category: category,
        subCategory: subCategory,
        stockQuantity: stockQuantity,
        barcode: barcode,
        discountPrice: discountPrice,
        isActive: isActive,
        createdAt: createdAt,
        pieces: pieces,
        isWeightBased: _isWeightBased,
      );

  /// Text that importers have left in `image_url` instead of leaving it empty.
  static const _missingImageValues = {'null', 'undefined', 'none', 'n/a'};

  static bool isValidImageUrl(String? value) {
    final url = value?.trim();
    if (url == null ||
        url.isEmpty ||
        _missingImageValues.contains(url.toLowerCase())) {
      return false;
    }
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

extension AvailableProducts on Iterable<Product> {
  /// Drops inactive products and those with no `stock_quantity` left.
  List<Product> get available => [
        for (final product in this)
          if (product.inStock) product,
      ];

  /// [available], also dropping products without a valid image link unless
  /// [includeWithoutImage] (admins).
  List<Product> availableFor({required bool includeWithoutImage}) => [
        for (final product in this)
          if (product.inStock &&
              (includeWithoutImage || product.hasValidImageUrl))
            product,
      ];

  /// Drops products without a valid image link unless [includeWithoutImage].
  List<Product> withImageUnless(bool includeWithoutImage) => [
        for (final product in this)
          if (includeWithoutImage || product.hasValidImageUrl) product,
      ];
}
