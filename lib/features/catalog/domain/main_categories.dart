import 'package:flutter/painting.dart';

/// A shopper-facing group of raw `products.category` values.
class MainCategory {
  const MainCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subCategories,
    this.pastel = const Color(0xFFF3F7FC),
  });

  /// Stable slug, used in the route.
  final String id;
  final String name;

  /// Cover photo for the home card, drawer and category header.
  /// Local asset path (`assets/...`) or an https URL.
  final String imageUrl;

  /// Soft studio tint behind the cover on home tiles.
  final Color pastel;

  /// Exact `products.category` values, in tab order.
  final List<String> subCategories;

  bool get isAssetImage => imageUrl.startsWith('assets/');
}

/// The fixed home/drawer categories. Every sellable `products.category` value
/// belongs to exactly one of them; [unlisted] are deliberately left out.
abstract final class MainCategories {
  static const all = [
    MainCategory(
      id: 'dairy',
      name: 'ألبان وبيض',
      imageUrl: 'assets/images/categories/dairy.jpeg',
      pastel: Color(0xFFE8F6F1),
      subCategories: [
        'جبن تترباك و مثلثات و كوب',
        'اجبان معبأ ولبنة و كريمة وسمنة',
        'أجبان وزن',
        'جبن موزاريلا',
        'زبادي وارز باللبن',
        'البان طويلة الاجل',
        'زبدة معبأ',
        'بيض مغلف',
      ],
    ),
    MainCategory(
      id: 'sweets',
      name: 'حلويات وتسالي',
      imageUrl: 'assets/images/categories/sweets.jpeg',
      pastel: Color(0xFFFFF0E8),
      subCategories: [
        'شيكولاتة',
        'بسكويت',
        'حلويات',
        'مقرمشات و محمصات',
        'حلاوة وزبدة',
      ],
    ),
    MainCategory(
      id: 'drinks',
      name: 'مشروبات وعصائر',
      imageUrl: 'assets/images/categories/drinks.jpeg',
      pastel: Color(0xFFE8F2FC),
      subCategories: [
        'مياه ومشروبات و عصائر و ايس كريم',
        'مشروبات',
        'عصائر',
        'عصائر بودر',
      ],
    ),
    MainCategory(
      id: 'meat',
      name: 'لحوم ومجمدات',
      imageUrl: 'assets/images/categories/meat.jpeg',
      pastel: Color(0xFFEEF2F6),
      subCategories: [
        'دواجن مجمدة ومصنعات دوراجن',
        'لحوم مجمدة',
        'مصنعات لحوم',
        'أسماك مجمدة',
        'اسماك مدخنة',
        'خضروات وفاكهه مجمدة',
        'معجنات مجمدة',
      ],
    ),
    MainCategory(
      id: 'bakery',
      name: 'مخبوزات وفطار',
      imageUrl: 'assets/images/categories/bakery.jpeg',
      pastel: Color(0xFFF8F1E6),
      subCategories: [
        'مخبوزات',
        'باتيه و وتش',
        'كورن فليكس و موسلي وشوفان',
      ],
    ),
    MainCategory(
      id: 'pasta-rice',
      name: 'مكرونة وأرز',
      imageUrl: 'assets/images/categories/pasta-rice.jpeg',
      pastel: Color(0xFFEEF6EA),
      subCategories: [
        'مكرونه',
        'ارز',
        'بقوليات وعطارة وبقسماط معبأة',
        'شوربات ومرقات و خلطات',
      ],
    ),
    MainCategory(
      id: 'pantry',
      name: 'بقالة وزيوت',
      imageUrl: 'assets/images/categories/pantry.jpeg',
      pastel: Color(0xFFFFF6E0),
      subCategories: [
        'زيوت',
        'سمن',
        'سكر ودقيق',
        'معلبات',
        'مشهيات',
        'زيتون ومخللات',
        'زيتون ومخلل معبأ',
        'سلاطات أنواع وزن',
      ],
    ),
    MainCategory(
      id: 'attara',
      name: 'عطارة',
      imageUrl: 'assets/images/categories/attara.jpeg',
      pastel: Color(0xFFF6EDE2),
      subCategories: [
        'عطارة وزن',
        'علافة وزن',
        'مستلزمات حلويات وبودر',
        'تسالي و مكسرات وزن',
        'ياميش رمضان',
      ],
    ),
    MainCategory(
      id: 'cleaning',
      name: 'منظفات وعناية',
      imageUrl: 'assets/images/categories/cleaning.jpeg',
      pastel: Color(0xFFE6F7F5),
      subCategories: [
        'مساحيق ومنعمات',
        'صابون سائل ومزيلات بقع',
        'كلور ومطهرات',
        'ملمعات',
        'مبيدات ومعطرات',
        'مناديل و ورق تواليت',
        'سلك وليف',
        'أسفنج و سلك',
        'مسلكات بلوعات',
        'بخور',
      ],
    ),
    MainCategory(
      id: 'personal-care',
      name: 'عناية شخصية',
      imageUrl: 'assets/images/categories/personal-care.jpeg',
      pastel: Color(0xFFF3ECF8),
      subCategories: [
        'شامبو وبلسم',
        'شاور جل وهاند ووش',
        'صابون',
        'برفانات ومزيلات عرق',
        'كريمات وسيرم',
        'مستلزمات أسنان',
        'مستلزمات حلاقة',
        'صبغات وحنة',
        'مستلزمات عناية شخصية',
        'حافضات و فوط صحية',
      ],
    ),
    MainCategory(
      id: 'baby',
      name: 'عالم الطفل',
      imageUrl: 'assets/images/categories/baby.jpeg',
      pastel: Color(0xFFFCECF2),
      subCategories: [
        'اكل اطفال',
        'مستلزمات اطفال',
      ],
    ),
    MainCategory(
      id: 'home',
      name: 'أدوات منزلية',
      imageUrl: 'assets/images/categories/home.jpeg',
      pastel: Color(0xFFF4EFE7),
      subCategories: [
        'ادوات منزلية',
        'ادوات كهربية',
        'مستلزمات كهربائية',
        'بلاستيكات وأكياس',
        'فويل',
        'خردوات',
        'بطاريات وحجاره',
        'كبريت و ولاعات',
        'مستلزمات حيوانات',
        'مستلزمات رمضان',
      ],
    ),
  ];

  /// Raw categories that aren't products for sale.
  static const unlisted = [
    'اصناف لا تتم بيعها',
    'خدمة توصيل',
    'خدمة فوري',
    'كروت وكتب',
  ];

  /// Alternate spellings found in POS / imports → canonical subcategory.
  static const spellingAliases = <String, String>{
    'تسالي ومكسرات وزن': 'تسالي و مكسرات وزن',
    'حفاضات و فوط صحية': 'حافضات و فوط صحية',
    'حفاضات وفوط صحية': 'حافضات و فوط صحية',
    'حافضات وفوط صحية': 'حافضات و فوط صحية',
    // Attara / spices — POS often stores the main title or misspellings.
    'عطارة': 'عطارة وزن',
    'عطاره': 'عطارة وزن',
    'العطارة': 'عطارة وزن',
    'العطاره': 'عطارة وزن',
    'عطاره وزن': 'عطارة وزن',
    'العطارة وزن': 'عطارة وزن',
    'علافه وزن': 'علافة وزن',
  };

  /// Every spelling the catalog should query for a list of canonical names
  /// (canonical + trailing-space + known aliases that map into them).
  static List<String> querySpellingsFor(Iterable<String> categories) {
    final wanted = {for (final name in categories) name.trim()};
    final out = <String>{};
    for (final name in wanted) {
      if (name.isEmpty) continue;
      out
        ..add(name)
        ..add('$name ');
    }
    for (final entry in spellingAliases.entries) {
      if (wanted.contains(entry.value) || wanted.contains(entry.key)) {
        out
          ..add(entry.key)
          ..add('${entry.key} ')
          ..add(entry.value)
          ..add('${entry.value} ');
      }
    }
    return out.toList(growable: false);
  }

  static MainCategory? byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Shopper-facing group for a raw `products.category` value.
  static MainCategory? byProductCategory(String? raw) {
    final name = raw?.trim();
    if (name == null || name.isEmpty) return null;
    return _byProductCategory[name] ??
        _byProductCategory[spellingAliases[name]];
  }

  static final Map<String, MainCategory> _byProductCategory = {
    for (final category in all)
      for (final key in [category.id, category.name, ...category.subCategories])
        key.trim(): category,
  };
}
