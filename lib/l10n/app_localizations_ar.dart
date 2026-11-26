// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get bannerShopBrandProducts => 'تسوق منتجات الشركة';

  @override
  String get bannerAdd => 'إضافة إعلان شركة';

  @override
  String get bannerTitleLabel => 'اسم الشركة / عنوان الإعلان';

  @override
  String get bannerKeywordLabel => 'كلمة البحث عن منتجات الشركة';

  @override
  String get bannerKeywordHint => 'مثال: جهينة';

  @override
  String get bannerChooseImage => 'اختيار صورة الإعلان';

  @override
  String get bannerChangeImage => 'تغيير الصورة';

  @override
  String get bannerImageRequired => 'اختر صورة الإعلان أولاً';

  @override
  String get bannerKeywordRequired => 'اكتب كلمة البحث التي تفتح منتجات الشركة';

  @override
  String get bannerSaved => 'تمت إضافة الإعلان بنجاح';

  @override
  String bannerSaveFailed(String error) {
    return 'تعذر حفظ الإعلان: $error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return 'هل تريد حذف إعلان «$title»؟';
  }

  @override
  String get bannerExistingHeader => 'الإعلانات الحالية';

  @override
  String get appTitle => 'سفير ماركت';

  @override
  String get home => 'الرئيسية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get save => 'حفظ';

  @override
  String get search => 'البحث';

  @override
  String get cart => 'السلة';

  @override
  String get wallet => 'المحفظة';

  @override
  String get more => 'المزيد';

  @override
  String get exitHint => 'اضغط مرة أخرى للخروج من التطبيق';

  @override
  String get newProducts => 'منتجات جديدة';

  @override
  String get trendingOffers => 'عروض رائجة';

  @override
  String get noNewNotifications => 'لا توجد إشعارات جديدة';

  @override
  String get loadingLatestProducts => 'جاري تحميل أحدث المنتجات...';

  @override
  String get noNewProductsLast3Days => 'لا توجد منتجات جديدة خلال آخر 3 أيام';

  @override
  String get loadingOffers => 'جاري تحميل العروض...';

  @override
  String get noOffersCurrently => 'لا توجد عروض حالياً';

  @override
  String get subscribersExclusiveFeature => 'ميزة حصرية للمشتركين 👑';

  @override
  String get playAndWinPaywallBody =>
      'لعبة \"العب واكسب\" والهدايا الأسبوعية متاحة فقط لمشتركي باقات سفير برايم وسفير برو. رقي حسابك واستمتع بالمميزات!';

  @override
  String get upgradeAccountNow => 'رقي حسابك الآن';

  @override
  String get exploreSafeer => 'استكشف سفير';

  @override
  String get featuredProducts => 'منتجات مختارة';

  @override
  String get failedToLoadProducts => 'تعذر تحميل المنتجات';

  @override
  String get noProductsCurrently => 'لا توجد منتجات حالياً';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loyaltyPoints => 'نقاط الولاء';

  @override
  String get spinWheelCollectPoints => 'لف العجلة واجمع النقاط';

  @override
  String get favoriteProducts => 'المنتجات المفضلة';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get contactUs => 'تحدث معنا';

  @override
  String get help => 'المساعدة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signIn => 'سجل دخولك';

  @override
  String get signOutConfirmMessage => 'هل تريد تسجيل الخروج من حسابك؟';

  @override
  String get signedOut => 'تم تسجيل الخروج';

  @override
  String get adminDashboard => 'لوحة تحكم الإدارة';

  @override
  String get adminDashboardSubtitle => 'إدارة طلبات العملاء وتحديث حالتها';

  @override
  String get guestName => 'ضيفنا';

  @override
  String welcomeUser(String name) {
    return 'أهلاً بك يا $name';
  }

  @override
  String get guestSubtitle => 'سجّل دخولك لتتابع طلباتك ومفضلتك';

  @override
  String get personalData => 'البيانات الشخصية';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get savedAddresses => 'العناوين المحفوظة';

  @override
  String get savedCards => 'البطاقات المحفوظة';

  @override
  String get messageAndSmsAlerts => 'تنبيهات الرسائل والرسائل النصية';

  @override
  String get privacyAndTerms => 'سياسة الخصوصية والشروط';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirmMessage =>
      'سيتم حذف حسابك وجميع بياناتك نهائياً. هل أنت متأكد؟';

  @override
  String get deleteAccountSuccess => 'تم حذف حسابك بنجاح';

  @override
  String get passwordRequirementsTitle => 'يجب أن تحتوي كلمة المرور على:';

  @override
  String get passwordRuleMinLength => '8 حروف على الأقل';

  @override
  String get passwordRuleUppercase => 'حرف كبير واحد على الأقل';

  @override
  String get passwordRuleLowercase => 'حرف صغير واحد على الأقل';

  @override
  String get passwordRuleDigit => 'رقم واحد على الأقل';

  @override
  String get talkToUs => 'تحدث معنا';

  @override
  String get supportWhatsApp => 'واتساب';

  @override
  String get supportLiveChat => 'محادثة فورية مع خدمة العملاء';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count نقطة • استبدال';
  }

  @override
  String get loyaltyPointsEarnNow => 'نقاط الولاء • اكسب الآن 🎁';

  @override
  String get ok => 'حسناً';

  @override
  String get noEmail => 'لا يوجد بريد إلكتروني';

  @override
  String get changeEmailContactSupport =>
      'لتغيير البريد الإلكتروني يرجى التواصل مع الدعم';

  @override
  String get privacyPolicyBody =>
      'نحن في سفير ماركت نحترم خصوصيتك. نستخدم بياناتك مثل الاسم ورقم الهاتف والعنوان فقط لتوصيل طلباتك وتحسين خدماتنا، ولا نشاركها مع أي طرف ثالث دون موافقتك.\n\nباستخدامك للتطبيق فإنك توافق على شروط الاستخدام، بما في ذلك سياسات الطلب والتوصيل والاسترجاع. سيتم نشر النسخة الكاملة من السياسة قريباً.';

  @override
  String get helpTitle => 'كيف يمكننا مساعدتك؟';

  @override
  String get helpBody =>
      'فريق سفير ماركت جاهز دائماً لخدمتك.\nإذا واجهتك أي مشكلة في طلبك أو لديك استفسار، تواصل معنا وسنرد عليك في أسرع وقت.';

  @override
  String get callUs => 'الاتصال بنا';

  @override
  String get callUsSubtitle => 'تحدث مع خدمة العملاء مباشرة';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get whatsappSubtitle => 'راسلنا وسنرد عليك سريعاً';

  @override
  String get messageAlerts => 'تنبيهات الرسائل';

  @override
  String get appNotifications => 'إشعارات التطبيق';

  @override
  String get appNotificationsSubtitle => 'العروض وتحديثات حالة الطلب';

  @override
  String get smsMessages => 'رسائل SMS';

  @override
  String get smsMessagesSubtitle => 'رسائل نصية بتأكيد الطلب والتوصيل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get close => 'إغلاق';

  @override
  String get refresh => 'تحديث';

  @override
  String get all => 'الكل';

  @override
  String get shopNow => 'تسوق الآن';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get categories => 'الأقسام';

  @override
  String get magazines => 'المجلات';

  @override
  String get addMagazine => 'إضافة مجلة';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get networkError => 'تعذر الاتصال بالشبكة';

  @override
  String get serverError => 'حدث خطأ في الخادم';

  @override
  String get serverConnectionError => 'تعذر الاتصال بالخادم، حاول مرة أخرى';

  @override
  String get pleaseSignInFirst => 'يرجى تسجيل الدخول أولاً';

  @override
  String get noPermissionToEditOrder => 'لا تملك صلاحية تعديل هذا الطلب';

  @override
  String orderUpdateFailed(String error) {
    return 'تعذر تحديث الطلب: $error';
  }

  @override
  String ordersLoadFailed(String error) {
    return 'تعذر تحميل الطلبات\n$error';
  }

  @override
  String orderNumber(String id) {
    return 'طلب #$id';
  }

  @override
  String get deletedProduct => 'منتج محذوف';

  @override
  String get product => 'منتج';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get manageAddresses => 'إدارة العناوين';

  @override
  String get editLocation => 'تعديل الموقع';

  @override
  String helloName(String name) {
    return 'أهلاً يا $name';
  }

  @override
  String get cardNumber => 'رقم البطاقة';

  @override
  String get cardholderName => 'اسم حامل البطاقة';

  @override
  String get asWrittenOnCard => 'كما هو مكتوب على البطاقة';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get addBankCard => 'إضافة بطاقة بنكية';

  @override
  String get bankCard => 'بطاقة بنكية';

  @override
  String get adminPaidByVisa => 'مدفوع بالفيزا';

  @override
  String get cameraOpenFailed => 'تعذر فتح الكاميرا، تحقق من صلاحية الكاميرا';

  @override
  String get addressLabelHome => 'المنزل';

  @override
  String get addressLabelWork => 'العمل';

  @override
  String get puzzleGame => 'لعبة البازل';

  @override
  String get luckyWheel => 'عجلة الحظ';

  @override
  String get awesome => 'رائع!';

  @override
  String get customer => 'العميل';

  @override
  String get noLocationForOrder => 'لا يتوفر موقع لهذا الطلب';

  @override
  String get branch => 'الفرع';

  @override
  String get safeerCustomer => 'عميل سفير';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get cashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get orderStatusPending => 'قيد الانتظار';

  @override
  String get orderStatusPreparing => 'جاري التجهيز';

  @override
  String get orderStatusReadyForDelivery => 'جاهز للتوصيل';

  @override
  String get orderStatusOutForDelivery => 'في الطريق';

  @override
  String get orderStatusDelivered => 'تم التوصيل';

  @override
  String get orderStatusCancelled => 'ملغي';

  @override
  String get statusNew => 'جديد';

  @override
  String get startPreparing => 'بدء التجهيز';

  @override
  String get total => 'الإجمالي';

  @override
  String get inStock => 'متوفر';

  @override
  String get outOfStock => 'غير متوفر';

  @override
  String get decreaseQuantity => 'تقليل الكمية';

  @override
  String get increaseQuantity => 'زيادة الكمية';

  @override
  String get decreaseWeight => 'تقليل الوزن';

  @override
  String get increaseWeight => 'زيادة الوزن';

  @override
  String get addToCart => 'أضف للسلة';

  @override
  String get cartEmpty => 'سلتك فارغة';

  @override
  String get productUnavailableNow => 'هذا المنتج غير متوفر حالياً';

  @override
  String distanceFromBranch(String distance) {
    return 'يبعد $distance عن الفرع';
  }

  @override
  String get invoiceNumberRequired => 'رقم الفاتورة مطلوب';

  @override
  String get addAtLeastOneItem => 'أضف صنفاً واحداً على الأقل';

  @override
  String get orderOnTheWayToYou => 'الطلب في الطريق إليك!';

  @override
  String get deliveryFee => 'رسوم التوصيل';

  @override
  String get currencySymbol => 'ج.م';

  @override
  String get unitPiece => 'قطعة';

  @override
  String get unitKilo => 'كيلو';

  @override
  String gramsValue(String value) {
    return '$value جرام';
  }

  @override
  String kilosValue(String value) {
    return '$value كيلو';
  }

  @override
  String kmValue(String value) {
    return '$value كم';
  }

  @override
  String get sessionExpired => 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'تعذر تحديث الحالة: $error';
  }

  @override
  String get adminDeleteMagazineTitle => 'حذف المجلة';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return 'هل تريد حذف «$title»؟';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return 'تعذر حذف المجلة: $error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return 'خطأ: $error';
  }

  @override
  String get adminNoMagazinesYet =>
      'لا توجد مجلات بعد. اضغط «إضافة مجلة» لرفع أول مجلة.';

  @override
  String get adminMagazineExpired => 'منتهية';

  @override
  String get adminMagazineUpcoming => 'قادمة';

  @override
  String get adminMagazineActive => 'نشطة';

  @override
  String adminMagazineDateRange(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get adminPickMagazinePdfTitle => 'اختر ملف المجلة (PDF)';

  @override
  String get adminMagazineStartDate => 'تاريخ البداية';

  @override
  String get adminMagazineEndDate => 'تاريخ النهاية';

  @override
  String get adminMagazineTitleRequired => 'اكتب عنوان المجلة';

  @override
  String get adminMagazineCoverRequired => 'اختر صورة الغلاف';

  @override
  String get adminMagazinePdfRequired => 'اختر ملف PDF للمجلة';

  @override
  String get adminMagazineEndBeforeStart =>
      'تاريخ النهاية يجب أن يكون بعد تاريخ البداية';

  @override
  String get adminMagazineAdded => 'تمت إضافة المجلة بنجاح';

  @override
  String adminMagazineSaveFailed(String error) {
    return 'تعذر حفظ المجلة: $error';
  }

  @override
  String get adminAddNewMagazine => 'إضافة مجلة جديدة';

  @override
  String get adminMagazineTitleLabel => 'عنوان المجلة';

  @override
  String get adminPickCoverImage => 'اختيار صورة الغلاف';

  @override
  String get adminChangeCover => 'تغيير الغلاف';

  @override
  String get adminPickPdfFile => 'اختيار ملف PDF';

  @override
  String get adminUploading => 'جارٍ الرفع...';

  @override
  String get adminSupervisorPermissions => 'صلاحيات المشرف';

  @override
  String get adminEnterPinHint => 'أدخل PIN (1234)';

  @override
  String get adminSupervisorModeEnabled => 'تم تفعيل وضع المشرف';

  @override
  String get adminInvalidPin => 'PIN غير صحيح';

  @override
  String get adminActivate => 'تفعيل';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - الإدارة';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - لوحة العمل';
  }

  @override
  String get adminCloseManagement => 'إغلاق الإدارة';

  @override
  String get adminEnableManagement => 'تفعيل الإدارة';

  @override
  String get adminExitToStore => 'خروج للمتجر';

  @override
  String get adminMenuOrders => 'الطلبات';

  @override
  String get adminMenuProducts => 'المنتجات';

  @override
  String get adminMenuStaff => 'طاقم العمل';

  @override
  String get adminMenuReports => 'التقارير واليومية';

  @override
  String get adminStatusPreparingShort => 'تحضير';

  @override
  String get adminStatusReadyForDriverShort => 'للطيار';

  @override
  String get adminStatusDeliveryShort => 'توصيل';

  @override
  String get adminStatusCompletedShort => 'مكتمل';

  @override
  String get adminStatusUnknown => 'غير معروف';

  @override
  String get adminNoOrders => 'لا توجد طلبات';

  @override
  String get adminSelectOrderFromList => 'اختر طلب من القائمة';

  @override
  String get adminItemsToPrepare => 'المنتجات المطلوبة للتجهيز:';

  @override
  String get adminNoItemsInOrder => 'لا توجد منتجات مسجلة';

  @override
  String get adminAvailableActions => 'الإجراءات المتاحة';

  @override
  String get adminOrderAwaitingPreparer => 'الطلب بانتظار محضر';

  @override
  String adminPreparerName(String name) {
    return 'المحضر: $name';
  }

  @override
  String get adminAwaitingDriverAssignment => 'بانتظار المشرف لتحديد الطيار';

  @override
  String get adminPickUpAndStartRoute => 'استلام وبدء التوجه 🗺️';

  @override
  String adminDriverName(String name) {
    return 'الطيار: $name';
  }

  @override
  String get adminOrderReadyAwaitingDriver =>
      'تم تجهيز الطلب بنجاح. في انتظار استلام الطيار.';

  @override
  String get adminMarkDelivered => 'تم التوصيل بنجاح 💵';

  @override
  String get adminCloseOrderPermanently => 'إنهاء الطلب نهائياً';

  @override
  String get adminOrderWithDriverOnTheWay =>
      'الطلب الآن مع الطيار في الطريق للعميل.';

  @override
  String get adminOrderDeliveredAndClosed =>
      'تم توصيل هذا الطلب وإغلاقه بنجاح.';

  @override
  String get adminWhoAreYouPickName => 'أنت مين؟ (اختر اسمك للبدء)';

  @override
  String get adminNoPreparers => 'لا يوجد محضرين';

  @override
  String get adminFinishOrderPreparation => 'إتمام تجهيز الطلب';

  @override
  String get adminCheckAllItemsFirst =>
      '⚠️ عذراً، يجب تحديد جميع المنتجات بعلامة (صح) أولاً.';

  @override
  String get adminPreparationFinished => 'تم إنهاء التجهيز بنجاح.';

  @override
  String get adminAssignDriverTitle => 'تحديد الطيار (صلاحية المشرف)';

  @override
  String get adminSelectDriver => 'اختر الطيار';

  @override
  String get adminOrderAssignedToDriver => 'تم إسناد الطلب للطيار بنجاح';

  @override
  String get adminAssignToSelectedDriver => 'إسناد للطيار المختار';

  @override
  String get adminCallFailed => 'تعذر الاتصال';

  @override
  String get adminNoPhoneNumber => 'بدون رقم';

  @override
  String get adminNoName => 'بدون اسم';

  @override
  String get adminAddressNotSet => 'لم يتم التحديد';

  @override
  String get adminCustomerInfo => 'بيانات العميل';

  @override
  String get adminManageProducts => 'إدارة المنتجات';

  @override
  String get adminActiveProducts => 'المنتجات المفعلة';

  @override
  String get adminInactiveProducts => 'غير مفعلة';

  @override
  String get adminSearchProductByName => 'ابحث عن منتج بالاسم...';

  @override
  String adminErrorOccurred(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get adminNoProducts => 'لا توجد منتجات';

  @override
  String get adminCopyProductName => 'نسخ اسم المنتج';

  @override
  String get adminCopied => 'تم النسخ';

  @override
  String get adminCopyBarcode => 'نسخ الباركود';

  @override
  String adminBarcodeValue(String barcode) {
    return 'باركود: $barcode';
  }

  @override
  String get adminUpdateErrorOccurred => 'حدث خطأ أثناء التحديث';

  @override
  String get adminManageStaff => 'إدارة طاقم العاملين';

  @override
  String get adminAddEmployee => 'إضافة موظف';

  @override
  String get adminNoStaff => 'لا يوجد موظفين مسجلين';

  @override
  String get adminRoleTaker => 'تيكر';

  @override
  String get adminRolePreparer => 'محضر';

  @override
  String get adminRoleDriver => 'طيار';

  @override
  String get adminNoPhone => 'بدون هاتف';

  @override
  String get adminReportsTitle => 'لوحة التقارير واليومية المجمعة';

  @override
  String get adminTotalSalesCollected => 'إجمالي المبيعات (المحصلة)';

  @override
  String get adminDeliveredOrdersTitle => 'طلبات مكتملة وتم توصيلها';

  @override
  String get adminOrdersInPreparationTitle => 'طلبات قيد التحضير حالياً';

  @override
  String get adminCancelledOrdersTitle => 'طلبات ملغاة';

  @override
  String get adminTotalOrdersCumulative => 'إجمالي الطلبات (التراكمي)';

  @override
  String adminOrdersCount(String count) {
    return '$count طلب';
  }

  @override
  String get adminRecentOrdersLog => 'سجل الطلبات الأخير';

  @override
  String get adminOrderNumberColumn => 'رقم الطلب';

  @override
  String get adminCustomerNameColumn => 'اسم العميل';

  @override
  String get adminStatusColumn => 'الحالة';

  @override
  String get paymentMethodCashLabel => 'كاش عند الاستلام';

  @override
  String get paymentMethodCardLabel => 'بطاقة بنكية (فيزا/ماستركارد)';

  @override
  String get paymentMethodInstaPayLabel => 'إنستا باي (InstaPay)';

  @override
  String get paymentMethodInstaPaySubtitle => 'تحويل فوري عبر تطبيق InstaPay';

  @override
  String get instaPayOpenApp => 'افتح تطبيق InstaPay للدفع الآن';

  @override
  String get instaPayIpaLabel => 'عنوان الدفع اللحظي IPA';

  @override
  String get instaPayPhoneLabel => 'أو التحويل برقم الهاتف';

  @override
  String get instaPayCopy => 'نسخ';

  @override
  String get instaPayCopied => 'تم النسخ';

  @override
  String get instaPayConfirmHint =>
      'بعد إتمام التحويل بقيمة الطلب عبر إنستا باي، اضغط على تأكيد الطلب بالأسفل.';

  @override
  String get instaPayReceiptTitle => 'إيصال التحويل البنكي (سكرين شوت)';

  @override
  String get instaPayReceiptHint =>
      'يجب إرفاق لقطة شاشة لنجاح عملية التحويل من تطبيق إنستا باي لتأكيد الطلب';

  @override
  String get instaPayReceiptPick => 'اختر صورة الإيصال أو التقاط صورة';

  @override
  String get instaPayReceiptRequired => 'يرجى إرفاق صورة إيصال التحويل أولاً';

  @override
  String get adminViewTransferReceipt => 'عرض إيصال التحويل';

  @override
  String get adminCopyReceiptImage => 'نسخ الصورة';

  @override
  String get adminShareReceipt => 'مشاركة الإيصال';

  @override
  String get adminReceiptImageCopied => 'تم نسخ صورة الإيصال';

  @override
  String get adminReceiptActionFailed => 'تعذر تنفيذ العملية على صورة الإيصال';

  @override
  String get subscriptionConfirmInstaPay => 'تأكيد الاشتراك';

  @override
  String get subscriptionPendingSuccessTitle => 'تم استلام طلب الترقية';

  @override
  String get subscriptionPendingSuccessBody =>
      'تم استلام طلب الترقية وإيصال الدفع. سيتم تفعيل حسابك (Pro) فور مراجعة الإدارة.';

  @override
  String get adminMenuPendingSubscriptions => 'طلبات الترقية المعلقة';

  @override
  String get adminActivateAccount => 'تفعيل الحساب';

  @override
  String get adminSubscriptionApproved => 'تم تفعيل الاشتراك';

  @override
  String get adminNoPendingSubscriptions => 'لا توجد طلبات ترقية معلقة';

  @override
  String get adminPendingSubscriptionTier => 'الباقة المطلوبة';

  @override
  String get paymentCopyCardNumber => 'نسخ رقم البطاقة';

  @override
  String get paymentCardNumberCopied => 'تم نسخ رقم البطاقة';

  @override
  String get checkoutAddressOutOfRange => 'العنوان خارج نطاق التوصيل';

  @override
  String get checkoutPinAddressFirst => 'حدد موقع العنوان على الخريطة أولاً';

  @override
  String checkoutOrderFailed(String error) {
    return 'تعذر إتمام الطلب: $error';
  }

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get checkoutDeliveryAddress => 'عنوان التوصيل';

  @override
  String get checkoutPaymentMethod => 'طريقة الدفع';

  @override
  String get checkoutOrderSummary => 'ملخص الطلب';

  @override
  String get checkoutSelectAddressFirst =>
      'اختر عنوان التوصيل أولاً لإتمام طلبك';

  @override
  String get checkoutPinLocationForFee =>
      'حدد موقع العنوان على الخريطة لحساب مصاريف التوصيل';

  @override
  String checkoutOrderPlaced(String id) {
    return 'تم استلام طلبك بنجاح • رقم الطلب #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return 'عذراً، العنوان يبعد $distance وخارج نطاق التوصيل (حتى $maxDistance)';
  }

  @override
  String get checkoutSignInToChooseAddress =>
      'سجّل دخولك لاختيار عنوان التوصيل';

  @override
  String get checkoutPinThisAddressForFee =>
      'حدد موقع هذا العنوان على الخريطة لحساب مصاريف التوصيل';

  @override
  String get checkoutPinLocation => 'حدد الموقع';

  @override
  String get checkoutChangeAddress => 'تغيير';

  @override
  String get checkoutAddDeliveryAddress => 'أضف عنوان التوصيل لإتمام طلبك';

  @override
  String get checkoutAddAddress => 'إضافة عنوان';

  @override
  String get checkoutNoAddressChosen => 'لم تختر عنوان التوصيل بعد';

  @override
  String get checkoutChooseAddress => 'اختر العنوان';

  @override
  String get checkoutEstimatedArrival => 'وقت الوصول المتوقع:';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return 'رسوم التوصيل ($distance)';
  }

  @override
  String get checkoutOutOfDeliveryRange => 'خارج نطاق التوصيل';

  @override
  String get checkoutItemCount => 'عدد المنتجات';

  @override
  String get checkoutSubtotal => 'المجموع';

  @override
  String get checkoutGrandTotal => 'الإجمالي النهائي';

  @override
  String get checkoutConfirmOrder => 'تأكيد الطلب';

  @override
  String get paymentCardScanUnsupported =>
      'مسح البطاقة غير مدعوم على هذا الجهاز';

  @override
  String get paymentCardScanFailed =>
      'لم نتمكن من قراءة البطاقة، أدخل البيانات يدويًا';

  @override
  String get paymentCardScanned =>
      'تمت قراءة البطاقة، راجع البيانات وأدخل رمز CVV';

  @override
  String get paymentCardTitle => 'الدفع بالبطاقة';

  @override
  String get paymentSecureNotice => 'عملية دفع آمنة ومشفرة';

  @override
  String paymentPayNow(String amount) {
    return 'ادفع الآن • $amount';
  }

  @override
  String get paymentScanCardTooltip => 'مسح البطاقة بالكاميرا';

  @override
  String get paymentAmountDue => 'المبلغ المطلوب';

  @override
  String get cardNumberRequired => 'أدخل رقم البطاقة';

  @override
  String get cardNumberInvalid => 'رقم البطاقة غير صحيح';

  @override
  String get cardExpiryRequired => 'أدخل التاريخ MM/YY';

  @override
  String get cardExpiryInvalidMonth => 'شهر غير صحيح';

  @override
  String get cardExpired => 'البطاقة منتهية';

  @override
  String get cardCvvInvalid => 'رمز غير صحيح';

  @override
  String get cardHolderNameRequired => 'أدخل الاسم كما هو على البطاقة';

  @override
  String get walletCardSaved => 'تم حفظ البطاقة بنجاح';

  @override
  String get walletCardDataProtected => 'بياناتك محمية ولن نحتفظ برمز CVV';

  @override
  String get walletSaveCard => 'حفظ البطاقة';

  @override
  String get walletAddCardHint =>
      'أضف بطاقتك للدفع بشكل أسرع في طلباتك القادمة';

  @override
  String get walletInAppBalance => 'رصيد محفظتك في التطبيق';

  @override
  String get walletBalanceLoadFailed => 'تعذر تحميل الرصيد';

  @override
  String get walletBalanceAutoApplied => 'يُستخدم رصيدك تلقائياً عند الدفع';

  @override
  String get walletSignInToViewBalance => 'سجل دخولك لعرض رصيدك';

  @override
  String walletCardExpires(String expiry) {
    return 'تنتهي $expiry';
  }

  @override
  String get walletDeleteCard => 'حذف البطاقة';

  @override
  String get checkoutUseOrAddNewCard => '+ استخدام أو إضافة بطاقة جديدة';

  @override
  String get checkoutSavedCards => 'بطاقاتك المحفوظة';

  @override
  String get paywallUpgradeAccount => 'ترقية الحساب';

  @override
  String get paywallDiscoverSafeer => 'اكتشف عالم سفير 👑';

  @override
  String get paywallChoosePlan =>
      'اختر الباقة التي تناسب احتياجاتك ووفر أكثر مع كل طلب.';

  @override
  String get paywallProTitle => 'سفير برو (VIP)';

  @override
  String get paywallPerMonth => '/ شهرياً';

  @override
  String get paywallProUnlimitedFreeDelivery => 'توصيل مجاني غير محدود 🚀';

  @override
  String get paywallProExpressDelivery => 'توصيل إكسبريس (أولوية التجهيز)';

  @override
  String get paywallProWholesalePrices => 'أسعار الجملة الحصرية 💰';

  @override
  String get paywallProNoMinimumOrder => 'بدون حد أدنى للطلب';

  @override
  String get paywallProUnlimitedGiveaways => 'دخول غير محدود لسحوبات الهدايا';

  @override
  String get paywallPrimeTitle => 'سفير برايم';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders => 'توصيل مجاني لـ 5 طلبات';

  @override
  String get paywallPrimeOffersPriority => 'أولوية حجز العروض الكبرى';

  @override
  String get paywallPrimeWeeklyPlayAndWin => 'لعبة العب واكسب أسبوعياً 🎁';

  @override
  String get paywallFreeTitle => 'حساب عادي';

  @override
  String get paywallFreePrice => 'مجاناً';

  @override
  String get paywallFreeStandardDelivery => 'توصيل عادي بتكلفة قياسية';

  @override
  String get paywallFreePublicAccess => 'الوصول للمنتجات والعروض العامة';

  @override
  String get paywallBestSeller => 'الأكثر مبيعاً';

  @override
  String get paywallPaymentComingSoon => 'سيتم ربط الدفع قريباً';

  @override
  String get paywallSubscribeNow => 'اشترك الآن';

  @override
  String get catDairyEggs => 'ألبان وبيض';

  @override
  String get subcatTetraPakCheese => 'جبن تترباك و مثلثات و كوب';

  @override
  String get subcatPackagedCheeseLabneh => 'اجبان معبأ ولبنة و كريمة وسمنة';

  @override
  String get subcatCheeseByWeight => 'أجبان وزن';

  @override
  String get subcatMozzarella => 'جبن موزاريلا';

  @override
  String get subcatYogurtRicePudding => 'زبادي وارز باللبن';

  @override
  String get subcatLongLifeDairy => 'البان طويلة الاجل';

  @override
  String get subcatPackagedButter => 'زبدة معبأ';

  @override
  String get subcatPackagedEggs => 'بيض مغلف';

  @override
  String get catSweetsSnacks => 'حلويات وتسالي';

  @override
  String get subcatChocolate => 'شيكولاتة';

  @override
  String get subcatBiscuits => 'بسكويت';

  @override
  String get subcatSweets => 'حلويات';

  @override
  String get subcatChipsRoasted => 'مقرمشات و محمصات';

  @override
  String get subcatNutsByWeight => 'تسالي و مكسرات وزن';

  @override
  String get subcatHalawaSpreads => 'حلاوة وزبدة';

  @override
  String get subcatRamadanYamish => 'ياميش رمضان';

  @override
  String get catDrinksJuices => 'مشروبات وعصائر';

  @override
  String get subcatWaterDrinksIceCream => 'مياه ومشروبات و عصائر و ايس كريم';

  @override
  String get subcatDrinks => 'مشروبات';

  @override
  String get subcatJuices => 'عصائر';

  @override
  String get subcatPowderedJuices => 'عصائر بودر';

  @override
  String get catMeatFrozen => 'لحوم ومجمدات';

  @override
  String get subcatFrozenPoultry => 'دواجن مجمدة ومصنعات دوراجن';

  @override
  String get subcatFrozenMeat => 'لحوم مجمدة';

  @override
  String get subcatProcessedMeat => 'مصنعات لحوم';

  @override
  String get subcatFrozenFish => 'أسماك مجمدة';

  @override
  String get subcatSmokedFish => 'اسماك مدخنة';

  @override
  String get subcatFrozenVegFruit => 'خضروات وفاكهه مجمدة';

  @override
  String get subcatFrozenPastries => 'معجنات مجمدة';

  @override
  String get catBakeryBreakfast => 'مخبوزات وفطار';

  @override
  String get subcatBakery => 'مخبوزات';

  @override
  String get subcatPatisserie => 'باتيه و وتش';

  @override
  String get subcatCerealsOats => 'كورن فليكس و موسلي وشوفان';

  @override
  String get catPastaRice => 'مكرونة وأرز';

  @override
  String get subcatPasta => 'مكرونه';

  @override
  String get subcatRice => 'ارز';

  @override
  String get subcatLegumesSpicesBreadcrumbs => 'بقوليات وعطارة وبقسماط معبأة';

  @override
  String get subcatSoupsStocksMixes => 'شوربات ومرقات و خلطات';

  @override
  String get catPantryOils => 'بقالة وزيوت';

  @override
  String get subcatOils => 'زيوت';

  @override
  String get subcatGhee => 'سمن';

  @override
  String get subcatSugarFlour => 'سكر ودقيق';

  @override
  String get subcatCannedFood => 'معلبات';

  @override
  String get subcatCondiments => 'مشهيات';

  @override
  String get subcatOlivesPickles => 'زيتون ومخللات';

  @override
  String get subcatPackagedOlivesPickles => 'زيتون ومخلل معبأ';

  @override
  String get subcatSpicesByWeight => 'عطارة وزن';

  @override
  String get subcatGrainsByWeight => 'علافة وزن';

  @override
  String get subcatBakingSupplies => 'مستلزمات حلويات وبودر';

  @override
  String get subcatSaladsByWeight => 'سلاطات أنواع وزن';

  @override
  String get catCleaningCare => 'منظفات وعناية';

  @override
  String get subcatDetergentsSofteners => 'مساحيق ومنعمات';

  @override
  String get subcatLiquidSoapStainRemovers => 'صابون سائل ومزيلات بقع';

  @override
  String get subcatBleachDisinfectants => 'كلور ومطهرات';

  @override
  String get subcatPolishes => 'ملمعات';

  @override
  String get subcatInsecticidesFresheners => 'مبيدات ومعطرات';

  @override
  String get subcatTissuesToiletPaper => 'مناديل و ورق تواليت';

  @override
  String get subcatSteelWoolScrubbers => 'سلك وليف';

  @override
  String get subcatSpongesSteelWool => 'أسفنج و سلك';

  @override
  String get subcatDrainCleaners => 'مسلكات بلوعات';

  @override
  String get subcatIncense => 'بخور';

  @override
  String get catPersonalCare => 'عناية شخصية';

  @override
  String get subcatShampooConditioner => 'شامبو وبلسم';

  @override
  String get subcatShowerGelHandWash => 'شاور جل وهاند ووش';

  @override
  String get subcatSoap => 'صابون';

  @override
  String get subcatPerfumesDeodorants => 'برفانات ومزيلات عرق';

  @override
  String get subcatCreamsSerums => 'كريمات وسيرم';

  @override
  String get subcatOralCare => 'مستلزمات أسنان';

  @override
  String get subcatShavingSupplies => 'مستلزمات حلاقة';

  @override
  String get subcatHairDyeHenna => 'صبغات وحنة';

  @override
  String get subcatPersonalCareSupplies => 'مستلزمات عناية شخصية';

  @override
  String get catBabyWorld => 'عالم الطفل';

  @override
  String get subcatDiapersPads => 'حافضات و فوط صحية';

  @override
  String get subcatBabyFood => 'اكل اطفال';

  @override
  String get subcatBabySupplies => 'مستلزمات اطفال';

  @override
  String get catHomeSupplies => 'أدوات منزلية';

  @override
  String get subcatHousewares => 'ادوات منزلية';

  @override
  String get subcatElectricalTools => 'ادوات كهربية';

  @override
  String get subcatElectricalSupplies => 'مستلزمات كهربائية';

  @override
  String get subcatPlasticsBags => 'بلاستيكات وأكياس';

  @override
  String get subcatFoil => 'فويل';

  @override
  String get subcatHardware => 'خردوات';

  @override
  String get subcatBatteries => 'بطاريات وحجاره';

  @override
  String get subcatMatchesLighters => 'كبريت و ولاعات';

  @override
  String get subcatPetSupplies => 'مستلزمات حيوانات';

  @override
  String get subcatRamadanSupplies => 'مستلزمات رمضان';

  @override
  String get categoryTitle => 'القسم';

  @override
  String get categoryNotFound => 'هذا القسم غير موجود';

  @override
  String get categoryNoProductsNow => 'لا توجد منتجات في هذا القسم حالياً';

  @override
  String get shopFromHome => 'تسوق من الرئيسية';

  @override
  String categoryProductCount(String count) {
    return '$count منتج';
  }

  @override
  String get loadMoreFailedRetry => 'تعذر تحميل المزيد، إعادة المحاولة';

  @override
  String get categoriesDrawerTagline => 'كل اللي محتاجه في مكان واحد';

  @override
  String get productDetailsTitle => 'تفاصيل المنتج';

  @override
  String get productNotAvailable => 'هذا المنتج غير متاح';

  @override
  String get productLoadFailed => 'تعذر تحميل المنتج';

  @override
  String get productImageUpdated => 'تم تحديث صورة المنتج بنجاح!';

  @override
  String productImageUploadFailed(String error) {
    return 'حدث خطأ أثناء الرفع: $error';
  }

  @override
  String get updateProductImage => 'تحديث صورة المنتج';

  @override
  String get takePhotoWithCamera => 'التقاط صورة بالكاميرا';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get changeProductImage => 'تغيير الصورة';

  @override
  String get pricePerKiloChooseWeight => 'السعر للكيلو، اختر الوزن عند الإضافة';

  @override
  String get productDescription => 'الوصف';

  @override
  String get addToCartButton => 'إضافة للسلة';

  @override
  String get productCurrentlyUnavailable => 'غير متوفر حالياً';

  @override
  String get productDetailsInCart => 'في السلة';

  @override
  String get imageLinkCopied => 'تم نسخ رابط الصورة بنجاح';

  @override
  String get copyImageLink => 'نسخ رابط الصورة';

  @override
  String get similarProducts => 'منتجات مشابهة';

  @override
  String get searchInSafeer => 'ابحث في سفير';

  @override
  String get searchProductHint => 'ابحث عن منتج، مثل: لبن، جبنة...';

  @override
  String get clearSearch => 'مسح';

  @override
  String get barcodeScanUnsupported => 'مسح الباركود غير مدعوم على هذا الجهاز';

  @override
  String get searchFailedCheckConnection => 'تعذر البحث، تحقق من اتصالك';

  @override
  String get scanAnotherProduct => 'امسح منتجًا آخر';

  @override
  String noProductWithBarcode(String barcode) {
    return 'لا يوجد منتج بالباركود «$barcode»';
  }

  @override
  String get productMayBeUnavailable => 'قد يكون المنتج غير متوفر حاليًا';

  @override
  String get scanAgain => 'امسح مرة أخرى';

  @override
  String noSearchResultsFor(String query) {
    return 'لا توجد نتائج لـ «$query»';
  }

  @override
  String get searchTryAnotherWord => 'جرّب كلمة أخرى أو تأكد من الإملاء';

  @override
  String searchResultsCount(String count, String query) {
    return '$count نتيجة لـ «$query»';
  }

  @override
  String get popularSearches => 'عمليات بحث شائعة';

  @override
  String get searchIntroSubtitle => 'ابحث بين آلاف المنتجات واطلبها في دقائق';

  @override
  String get searchSuggestionMilk => 'لبن';

  @override
  String get searchSuggestionCheese => 'جبنة';

  @override
  String get searchSuggestionRice => 'أرز';

  @override
  String get searchSuggestionOil => 'زيت';

  @override
  String get searchSuggestionSugar => 'سكر';

  @override
  String get searchSuggestionTea => 'شاي';

  @override
  String get receiptTypeReceive => 'استلام';

  @override
  String get receiptTypeSupplierReturn => 'استرجاع';

  @override
  String get warehouseGoodsReceiptTitle => 'استلام بضاعة';

  @override
  String get warehouseGoodsReturnTitle => 'استرجاع بضاعة';

  @override
  String get warehouseReceiptSaved => 'تم حفظ أمر الاستلام';

  @override
  String get warehouseReturnSaved => 'تم حفظ أمر الاسترجاع';

  @override
  String get warehouseSubmitReceipt => 'إرسال أمر الاستلام';

  @override
  String get warehouseSubmitReturn => 'إرسال أمر الاسترجاع';

  @override
  String get warehouseInvoiceDate => 'تاريخ الفاتورة';

  @override
  String get warehouseScanOrEnterBarcode => 'امسح الباركود أو اكتبه';

  @override
  String get warehouseEnterQuantityAboveZero => 'أدخل كمية أكبر من صفر';

  @override
  String get warehouseCompleteRequiredFields => 'أكمل الحقول المطلوبة أولاً';

  @override
  String get warehouseNoItemsYet => 'لم تُضف أصناف بعد';

  @override
  String get warehouseDocumentDetails => 'بيانات المستند';

  @override
  String get warehouseInvoiceNumberRequiredLabel => 'رقم الفاتورة *';

  @override
  String get warehouseInvoiceDateRequiredLabel => 'تاريخ الفاتورة *';

  @override
  String get warehouseInvoiceDateRequired => 'تاريخ الفاتورة مطلوب';

  @override
  String get warehouseItems => 'الأصناف';

  @override
  String get warehouseBarcode => 'الباركود';

  @override
  String get warehouseQuantity => 'الكمية';

  @override
  String get warehouseAdd => 'إضافة';

  @override
  String get warehouseReloadSuppliers => 'إعادة تحميل الموردين';

  @override
  String get warehouseSupplierRequiredLabel => 'المورد *';

  @override
  String get warehouseSupplierHint => 'ابحث أو اكتب رقم المورد';

  @override
  String get warehouseSuppliersEmpty => 'قائمة الموردين فارغة';

  @override
  String get warehouseSelectSupplier => 'اختر المورد';

  @override
  String get warehouseSelectSupplierFromList => 'اختر المورد من القائمة';

  @override
  String get warehouseFetchingProductName => 'جارٍ جلب اسم المنتج…';

  @override
  String get warehouseUnregisteredProduct => 'منتج غير مسجل';

  @override
  String warehouseQuantityValue(String quantity) {
    return 'الكمية: $quantity';
  }

  @override
  String get warehouseSelectDate => 'اختر التاريخ';

  @override
  String get warehouseClearDate => 'مسح التاريخ';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return 'تعذر تحميل الموردين: $error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return 'تعذر حفظ المستند: $error';
  }

  @override
  String get warehouseOrderAlreadyUpdated =>
      'تعذر تحديث الطلب، ربما تم تحديثه بالفعل';

  @override
  String get warehouseSignOutConfirm => 'هل تريد تسجيل الخروج من حساب المخزن؟';

  @override
  String get warehouseDashboardTitle => 'لوحة المخزن';

  @override
  String get warehouseNewOrdersTab => 'طلبات جديدة';

  @override
  String get warehousePreparingTab => 'قيد التجهيز';

  @override
  String get warehouseItemInquiry => 'استعلام عن صنف';

  @override
  String warehouseItemInquiryFailed(String error) {
    return 'تعذر الاستعلام عن الصنف\n$error';
  }

  @override
  String get warehouseItemNotRegistered => 'الصنف غير مسجل في قاعدة البيانات';

  @override
  String warehouseBarcodeValue(String barcode) {
    return 'الباركود: $barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return 'الكمية المتاحة: $quantity';
  }

  @override
  String get warehouseNoNewOrders => 'لا توجد طلبات جديدة\nاسحب للتحديث';

  @override
  String get warehouseNoPreparingOrders => 'لا توجد طلبات قيد التجهيز';

  @override
  String warehousePreparingStarted(String id) {
    return 'بدأ تجهيز الطلب #$id، تجده في «قيد التجهيز»';
  }

  @override
  String warehouseOrderReady(String id) {
    return 'الطلب #$id جاهز، تم إشعار مناديب التوصيل';
  }

  @override
  String warehouseProductsCount(String count) {
    return 'المنتجات ($count)';
  }

  @override
  String warehouseCustomerValue(String name) {
    return 'العميل: $name';
  }

  @override
  String warehouseAddressValue(String address) {
    return 'العنوان: $address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String get driverNewOrderAvailable => 'طلب جديد متاح للتوصيل!';

  @override
  String driverLocationSharingStartFailed(String error) {
    return 'تعذر بدء مشاركة موقعك: $error';
  }

  @override
  String get driverSignOutConfirm => 'هل تريد تسجيل الخروج من حساب السائق؟';

  @override
  String get driverDashboardTitle => 'لوحة السائق';

  @override
  String get driverAvailableOrdersTab => 'طلبات متاحة';

  @override
  String get driverNoAvailableOrders =>
      'لا توجد طلبات متاحة الآن\nاسحب للتحديث';

  @override
  String get driverNoActiveDeliveries => 'لا توجد طلبات قيد التوصيل';

  @override
  String driverOrderAccepted(String id) {
    return 'تم قبول الطلب #$id، تجده في «طلباتي»';
  }

  @override
  String driverOrderDelivered(String id) {
    return 'تم توصيل الطلب #$id';
  }

  @override
  String get driverPhoneLabel => 'الهاتف';

  @override
  String get driverAddressLabel => 'العنوان';

  @override
  String get driverDistanceLabel => 'المسافة';

  @override
  String get driverDistanceNotSpecified => 'غير محددة';

  @override
  String driverDistanceFromBranch(String distance) {
    return '$distance من الفرع';
  }

  @override
  String get driverTotalToCollect => 'الإجمالي (تحصيل)';

  @override
  String get driverViewMapAndLocation => 'عرض الخريطة والموقع';

  @override
  String get driverAcceptOrder => 'قبول الطلب';

  @override
  String get driverBroadcastingLocation => 'جاري بث الموقع...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return 'جاري بث الموقع... آخر إرسال $time';
  }

  @override
  String get driverRequestingLocationPermission => 'جاري طلب إذن الموقع...';

  @override
  String get driverStartLocationSharing => 'بدء بث الموقع';

  @override
  String driverCopyLabel(String label) {
    return 'نسخ $label';
  }

  @override
  String driverCopiedLabel(String label) {
    return 'تم نسخ $label';
  }

  @override
  String driverLocationReadFailed(String error) {
    return 'تعذر قراءة موقعك: $error';
  }

  @override
  String get driverLocationSharingStopped =>
      'توقف بث الموقع، اضغط «بدء بث الموقع» للمتابعة';

  @override
  String get driverOrderTakenByAnother =>
      'عذراً، تم قبول هذا الطلب من سائق آخر';

  @override
  String driverAcceptOrderFailed(String error) {
    return 'تعذر قبول الطلب: $error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return 'تعذر إرسال موقعك للعميل: $error (code: $code)';
  }

  @override
  String get driverLocationSendNotAssigned =>
      'تعذر إرسال موقعك للعميل: الطلب غير مُسند إليك أو لم يعد قيد التوصيل';

  @override
  String get driverGpsDisabled =>
      'خدمة الموقع (GPS) متوقفة، فعّلها ليتمكن العميل من تتبعك';

  @override
  String get driverLocationPermissionDeniedForever =>
      'إذن الموقع مرفوض، فعّله من إعدادات التطبيق ليتمكن العميل من تتبعك';

  @override
  String get driverLocationPermissionDenied =>
      'لم يتم السماح بالوصول لموقعك، لن يتمكن العميل من تتبع الطلب';

  @override
  String get driverOpenGoogleMapsFailed => 'تعذر فتح خرائط جوجل على هذا الجهاز';

  @override
  String get driverMapAndLocationTitle => 'الخريطة والموقع';

  @override
  String get driverStartNavigation => 'ابدأ التوجيه';

  @override
  String get listSeparator => '، ';

  @override
  String get storeCityName => 'مدينة نصر';

  @override
  String get addressDefaultTitle => 'عنوان';

  @override
  String get addressLabelOther => 'أخرى';

  @override
  String addressBuildingLine(String building) {
    return 'عمارة $building';
  }

  @override
  String addressFloorAptLine(String floor) {
    return 'الدور/الشقة $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return 'علامة مميزة: $landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return 'تعذر حفظ العنوان: $error';
  }

  @override
  String get addressLocationSaveFailed => 'تعذر حفظ موقع العنوان';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return 'تعذر حفظ موقع العنوان: $error';
  }

  @override
  String get locationServiceDisabled =>
      'خدمة الموقع (GPS) متوقفة، فعّلها وحاول مرة أخرى';

  @override
  String get locationPermissionDenied =>
      'لم يتم السماح بالوصول لموقعك، يمكنك تحريك الخريطة يدوياً';

  @override
  String get locationPermissionDeniedForever =>
      'إذن الموقع مرفوض، فعّله من إعدادات التطبيق';

  @override
  String get currentLocationUnavailable =>
      'تعذر تحديد موقعك الحالي، حاول مرة أخرى';

  @override
  String get mapAddressReadFailed => 'تعذر قراءة العنوان من الخريطة';

  @override
  String get addressesEmptyTitle => 'لا توجد عناوين محفوظة بعد';

  @override
  String get addressesEmptyHint => 'أضف عنوانك لتوصيل طلباتك بسرعة';

  @override
  String get addressesLoadFailed => 'تعذر تحميل العناوين';

  @override
  String get signInToManageAddresses => 'سجّل دخولك لإدارة عناوينك';

  @override
  String get addressDeleteTitle => 'حذف العنوان';

  @override
  String addressDeleteConfirm(String title) {
    return 'هل تريد حذف عنوان «$title»؟';
  }

  @override
  String get addressDeleteFailed => 'تعذر حذف العنوان';

  @override
  String addressSaved(String title) {
    return 'تم حفظ عنوان «$title»';
  }

  @override
  String get addressPickerTitle => 'اختر عنوان التوصيل';

  @override
  String get addressPickerEmpty => 'لا توجد عناوين محفوظة، أضف عنوانك الأول';

  @override
  String get addressDetailsTitle => 'تفاصيل العنوان';

  @override
  String get addressTitleLabel => 'اسم العنوان';

  @override
  String get addressTitleHint => 'مثال: المنزل، العمل';

  @override
  String get addressAreaLabel => 'المنطقة';

  @override
  String get addressAreaHint => 'مثال: مدينة نصر، الحي السادس';

  @override
  String get addressStreetLabel => 'الشارع';

  @override
  String get addressBuildingNumberLabel => 'رقم العمارة';

  @override
  String get addressFloorAptLabel => 'الدور / الشقة';

  @override
  String get addressLandmarkLabel => 'علامة مميزة';

  @override
  String get addressLandmarkHint => 'مثال: بجوار مسجد...';

  @override
  String get addressSaveButton => 'حفظ العنوان';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label (اختياري)';
  }

  @override
  String get addressFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get addressReviewAndComplete => 'راجع العنوان وأكمل باقي البيانات.';

  @override
  String get mapAddressReadFailedFillManually =>
      'تعذر قراءة العنوان من الخريطة، أكمل البيانات يدوياً.';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return 'يبعد $distance عن الفرع · التوصيل $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return 'هذا الموقع يبعد $distance، خارج نطاق التوصيل (حتى $maxDistance).';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return 'يبعد $distance، خارج نطاق التوصيل';
  }

  @override
  String get mapPinHint => 'حرّك الخريطة لوضع الدبوس على مكان التوصيل بالضبط';

  @override
  String get mapMyCurrentLocation => 'موقعي الحالي';

  @override
  String get mapConfirmLocation => 'تأكيد الموقع';

  @override
  String get mapSetDeliveryLocation => 'حدد موقع التوصيل';

  @override
  String get myOrdersLoadFailed => 'تعذر تحميل طلباتك';

  @override
  String get myOrdersEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get myOrdersEmptySubtitle => 'ابدأ التسوق وستظهر طلباتك هنا';

  @override
  String get orderStatusReceivedLong => 'تم استلام الطلب';

  @override
  String get orderStatusPreparingInWarehouse => 'جاري التجهيز في المخزن';

  @override
  String get orderStatusAwaitingDriver => 'في انتظار مندوب التوصيل';

  @override
  String get orderStatusReadyShort => 'جاهز';

  @override
  String get orderStepReceived => 'تم الاستلام';

  @override
  String get orderStepPreparing => 'التجهيز';

  @override
  String orderCardStatusLine(String status) {
    return 'حالة الطلب: $status';
  }

  @override
  String get orderCardTrackOnMap => 'تتبع الطلب على الخريطة';

  @override
  String trackingTitle(String id) {
    return 'تتبع الطلب #$id';
  }

  @override
  String get trackingYourAddressMarker => 'عنوانك';

  @override
  String get trackingDriverMarker => 'مندوب التوصيل';

  @override
  String get trackingOrderDelivered => 'تم توصيل طلبك، بالهناء والشفاء!';

  @override
  String get trackingDriverLocationLive =>
      'يتم تحديث موقع المندوب على الخريطة مباشرة';

  @override
  String get trackingDriverLocating =>
      'جاري تحديد موقع المندوب… سيظهر على الخريطة قريباً';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return 'تم إنشاء حسابك! أرسلنا رابط التأكيد إلى $email، أكّد بريدك ثم سجّل الدخول.';
  }

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authEnterFullName => 'أدخل اسمك الكامل';

  @override
  String get authEnterValidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get authEnterValidEgyptianPhone =>
      'أدخل رقم هاتف مصري صحيح (11 رقماً)';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authPasswordMinLength => 'كلمة المرور 6 أحرف على الأقل';

  @override
  String get authSignInButton => 'تسجيل الدخول';

  @override
  String get authCreateAccountButton => 'إنشاء الحساب';

  @override
  String get authNoAccountPrompt => 'ليس لديك حساب؟ ';

  @override
  String get authHaveAccountPrompt => 'لديك حساب بالفعل؟ ';

  @override
  String get authCreateNewAccountLink => 'أنشئ حساباً جديداً';

  @override
  String get authSignInLink => 'سجّل الدخول';

  @override
  String get authWelcomeBack => 'أهلاً بعودتك!';

  @override
  String get authJoinSafeerMarket => 'انضم إلى سفير ماركت';

  @override
  String get authSignInSubtitle => 'سجّل دخولك لإتمام طلبك';

  @override
  String get authSignUpSubtitle => 'أنشئ حسابك واستمتع بعروض سفير';

  @override
  String get authNewAccountTab => 'حساب جديد';

  @override
  String get authEmailAlreadyRegistered => 'هذا البريد الإلكتروني مسجل بالفعل';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return 'تم إنشاء الحساب لكن تعذر حفظ البيانات: $error';
  }

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get authEmailNotConfirmed =>
      'يرجى تأكيد بريدك الإلكتروني أولاً من الرسالة المرسلة إليك';

  @override
  String get authWeakPassword => 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';

  @override
  String get authTooManyAttempts => 'محاولات كثيرة، يرجى المحاولة بعد قليل';

  @override
  String get editProfileSignInPrompt => 'سجل دخولك لتعديل بياناتك';

  @override
  String get profileSavedSuccessfully => 'تم حفظ بياناتك بنجاح';

  @override
  String get profileFullNameLabel => 'الاسم بالكامل';

  @override
  String get profileEnterFullName => 'أدخل اسمك بالكامل';

  @override
  String get profileEnterValidPhone => 'أدخل رقم هاتف مصري صحيح';

  @override
  String get profileSaveChanges => 'حفظ التغييرات';

  @override
  String profileSaveFailed(String error) {
    return 'تعذر حفظ البيانات: $error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return 'تعذر حفظ رمز الإشعارات: $error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature متاح قريباً';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نقطة',
      few: '$count نقاط',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => 'الألعاب';

  @override
  String get rewardsGamesSubtitle => 'العب واجمع نقاط الولاء';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return 'متاح مرة أخرى بعد $countdown';
  }

  @override
  String get scratchCardTitle => 'بطاقة الخدش - امسح واربح';

  @override
  String get scratchCardSubtitle => 'امسح الطبقة واربح نقاطاً فورية';

  @override
  String get scratchCardHint => 'امسح الطبقة الفضية لكشف جائزتك';

  @override
  String scratchWonPoints(String points) {
    return 'ربحت $points نقطة!';
  }

  @override
  String get scratchBetterLuck => 'حظ أوفر';

  @override
  String get luckyChestTitle => 'صندوق الحظ اليومي - افتح صندوقك';

  @override
  String get luckyChestSubtitle => 'افتح الصندوق واربح حتى 10 نقاط';

  @override
  String get luckyChestHint => 'اضغط على الصندوق لفتحه وكشف جائزتك';

  @override
  String get luckyChestTapToOpen => 'اضغط لفتح الصندوق';

  @override
  String get luckyChestOpened => 'تم فتح الصندوق لهذا اليوم';

  @override
  String luckyChestWonPoints(String points) {
    return 'ربحت $points نقطة من الصندوق!';
  }

  @override
  String get rewardsWheelCardSubtitle => 'لف العجلة واربح حتى 100 نقطة';

  @override
  String get rewardsPuzzleCardSubtitle => 'رتّب الشعار واربح 50 نقطة';

  @override
  String get loyaltyCurrentBalance => 'رصيدك الحالي';

  @override
  String get loyaltySignInToSeePoints => 'سجّل دخولك لترى نقاطك';

  @override
  String get loyaltyLoadFailedRetry => 'تعذر التحميل — إعادة المحاولة';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return 'تعذر تحميل نقاط الولاء: $error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return 'تعذر تحديث نقاط الولاء: $error';
  }

  @override
  String get wheelPrizeTryAgain => 'حاول مجدداً';

  @override
  String get wheelSpinCollectLoyaltyPoints => 'لف العجلة واجمع نقاط الولاء';

  @override
  String get wheelSignInToPlay => 'سجل دخولك لتلعب';

  @override
  String get wheelSpinning => 'العجلة تدور...';

  @override
  String get wheelSpin => 'لف العجلة';

  @override
  String get wheelCongrats => 'مبروك!';

  @override
  String get wheelTryAgainTitle => 'حاول مرة أخرى';

  @override
  String wheelWonPrize(String prize) {
    return 'ربحت $prize ولاء وأُضيفت إلى رصيدك.';
  }

  @override
  String get wheelNoPointsThisTime =>
      'لم تربح نقاطاً هذه المرة. حظاً أوفر في اللفة القادمة!';

  @override
  String puzzleMoves(String moves) {
    return 'الحركات: $moves';
  }

  @override
  String puzzlePrize(String points) {
    return 'الجائزة: $points نقطة';
  }

  @override
  String puzzleSavePoints(String points) {
    return 'احفظ $points نقطة';
  }

  @override
  String get puzzleShuffle => 'خلط القطع';

  @override
  String get puzzleOutOfMoves =>
      'حظ أوفر المرة القادمة! لقد استنفدت عدد الحركات المتاحة.';

  @override
  String get puzzleCongrats => 'مبرووك!';

  @override
  String puzzleEarnedPoints(String points) {
    return 'كسبت $points نقطة 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance => 'أُضيفت النقاط إلى رصيد الولاء.';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return 'مبرووك! كسبت $points نقطة 🎉';
  }

  @override
  String get puzzleSignInToAddPoints => 'سجّل دخولك لنضيفها إلى رصيدك.';

  @override
  String get puzzleGoalTitle => 'رتّب الشعار';

  @override
  String get puzzleGoalDescription =>
      'حرّك القطع المجاورة للفراغ حتى يعود الشعار كما في الصورة';

  @override
  String get unitCarton => 'كرتونة';

  @override
  String get unitBox => 'علبة';

  @override
  String get unitBag => 'كيس';

  @override
  String get unitPack => 'باكو';

  @override
  String get cartTitle => 'سلة التسوق';

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String cartSubtotalWithCount(String count) {
    return 'المجموع ($count منتج)';
  }

  @override
  String get cartDeliveryFeeNextStep => 'رسوم التوصيل تُحسب في الخطوة التالية';

  @override
  String get cartContinueOrder => 'متابعة الطلب';

  @override
  String get cartEmptySubtitle => 'أضف منتجاتك المفضلة وابدأ التسوق';

  @override
  String get cartSaveDeliveryFeesTitle => 'وفر رسوم التوصيل! 💡';

  @override
  String get cartPrimeUpsellSubtitle => 'اشترك في سفير برايم بـ 90 ج.م فقط.';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return 'تمت إضافة $weight من $product إلى السلة';
  }

  @override
  String cartAddedProduct(String product) {
    return 'تمت إضافة $product إلى السلة';
  }

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get removeFromCart => 'حذف من السلة';

  @override
  String get chooseWeight => 'اختر الوزن';

  @override
  String pricePerKilo(String price) {
    return '$price للكيلو';
  }

  @override
  String get weightPickerPrice => 'السعر';

  @override
  String get updateWeight => 'تحديث الوزن';

  @override
  String get homeNotificationsTooltip => 'الإشعارات';

  @override
  String get homeSearchHint => 'ابحث عن منتج أو ماركة';

  @override
  String homeDeliveringTo(String city) {
    return 'التوصيل إلى · $city';
  }

  @override
  String get homeChooseYourAddress => 'اختر عنوانك';

  @override
  String get homeMyAccountTooltip => 'حسابي';

  @override
  String get homeSignedInSuccessfully => 'تم تسجيل الدخول بنجاح';

  @override
  String get homeDeliveryEta => 'توصيل خلال 30 - 45 دقيقة';

  @override
  String get quickActionLatestProducts => 'أحدث المنتجات';

  @override
  String get quickActionOffers => 'العروض';

  @override
  String get quickActionPlayAndWin => 'العب واكسب';

  @override
  String get promoEndlessOffersTitle => 'عروض سفير ما بتنتهيش';

  @override
  String get promoEndlessOffersSubtitle => 'خصومات يومية على مئات المنتجات';

  @override
  String get promoSavingsStoreTitle => 'سفير... محل التوفير';

  @override
  String get promoSavingsStoreSubtitle => 'أسعار أقل كل يوم لكل البيت';

  @override
  String get promoOpeningDiscountsTitle => 'خصومات الافتتاح';

  @override
  String get promoOpeningDiscountsSubtitle => 'حتى 30% على أول طلب';

  @override
  String get promoFreeDeliveryTitle => 'توصيل مجاني';

  @override
  String get promoFreeDeliverySubtitle => 'على الطلبات فوق 300 ج.م';

  @override
  String offerDiscountPercent(String percent) {
    return 'خصم $percent%';
  }

  @override
  String get offerBadge => 'عرض';

  @override
  String get favoritesSignInPrompt => 'سجّل دخولك لحفظ منتجاتك المفضلة';

  @override
  String get favoritesLoadFailed => 'تعذر تحميل المفضلة';

  @override
  String get favoritesEmptyTitle => 'لا توجد منتجات مفضلة بعد';

  @override
  String get favoritesEmptySubtitle => 'اضغط على ♡ في أي منتج لحفظه هنا';

  @override
  String get favoritesUpdateFailed => 'تعذر تحديث المفضلة، حاول مرة أخرى';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get addToFavorites => 'أضف للمفضلة';

  @override
  String get magazinesLoadFailed => 'تعذر تحميل المجلات';

  @override
  String get noMagazinesCurrently => 'لا توجد مجلات حالياً';

  @override
  String get magazineNoPdf => 'لا يوجد ملف PDF لهذه المجلة';

  @override
  String get magazineOpenFailed => 'تعذر فتح المجلة. حاول مرة أخرى لاحقاً.';

  @override
  String get magazinePreviousPage => 'الصفحة السابقة';

  @override
  String get magazineNextPage => 'الصفحة التالية';

  @override
  String magazinePageOf(String page, String count) {
    return 'صفحة $page من $count';
  }

  @override
  String get authWelcomeTitle => 'أهلاً بك في سفير ماركت';

  @override
  String get authWelcomeSubtitle => 'سجّل دخولك أو أنشئ حساباً في ثوانٍ';

  @override
  String get authContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get authContinueWithPhone => 'المتابعة برقم الهاتف';

  @override
  String get authContinueWithEmail => 'المتابعة بالبريد الإلكتروني';

  @override
  String get authOr => 'أو';

  @override
  String get authOtherSignInOptions => 'طرق دخول أخرى';

  @override
  String get authTermsNotice =>
      'بالمتابعة، أنت توافق على سياسة الخصوصية والشروط';

  @override
  String get authGoogleFailed =>
      'تعذر تسجيل الدخول بحساب Google، حاول مرة أخرى';

  @override
  String get authProviderUnavailable =>
      'طريقة تسجيل الدخول هذه غير متاحة حالياً';

  @override
  String get authOtpInvalid => 'الرمز غير صحيح أو انتهت صلاحيته';

  @override
  String get authSmsSendFailed =>
      'تعذر إرسال رسالة التحقق، تأكد من الرقم وحاول مرة أخرى';

  @override
  String get authPhoneSheetTitle => 'الدخول برقم الهاتف';

  @override
  String get authPhoneSheetSubtitle =>
      'سنرسل لك رمز تحقق مكوّناً من 6 أرقام في رسالة نصية';

  @override
  String get authSendCode => 'إرسال الرمز';

  @override
  String get authEnterCodeTitle => 'أدخل رمز التحقق';

  @override
  String authCodeSentTo(String phone) {
    return 'أرسلنا الرمز في رسالة نصية إلى $phone';
  }

  @override
  String get authVerifyCode => 'تأكيد الرمز';

  @override
  String get authEnterSixDigitCode => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get authResendCode => 'إعادة إرسال الرمز';

  @override
  String authResendCodeIn(String seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get authChangeNumber => 'تغيير الرقم';

  @override
  String get authCodeResent => 'تم إرسال رمز جديد';

  @override
  String get productNoImageBadge => 'بدون صورة';

  @override
  String newProductsMissingImageCount(String count) {
    return 'منتجات جديدة (بدون صورة: $count)';
  }

  @override
  String missingImageCountBadge(String count) {
    return 'بدون صورة: $count';
  }

  @override
  String get productImageSaveBlocked =>
      'تم رفع الصورة لكن لم يتم حفظها على المنتج: صلاحية تعديل المنتجات مرفوضة. راجع صلاحيات المسؤول في Supabase.';

  @override
  String get authPhoneLoginDisabled =>
      'تسجيل الدخول برقم الهاتف غير مفعّل حالياً، استخدم Google أو البريد الإلكتروني';

  @override
  String get onboardingLanguageTitle => 'اختر لغتك';

  @override
  String get onboardingLanguageSubtitle =>
      'يمكنك تغييرها في أي وقت من الإعدادات';

  @override
  String get onboardingAppearanceTitle => 'اختر مظهر التطبيق';

  @override
  String get onboardingAppearanceSubtitle =>
      'فاتح أو داكن، أو حسب إعدادات جهازك';

  @override
  String get onboardingAccountTitle => 'سجّل دخولك لتجربة كاملة';

  @override
  String get onboardingAccountSubtitle =>
      'اطلب منتجاتك، تابع طلباتك، واحفظ عناوينك ومفضلتك';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingSignInOrRegister => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get onboardingBrowseFirst => 'تصفح التطبيق أولاً';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String get settingsAccountSection => 'الحساب';

  @override
  String get guestSignInTitle => 'سجّل دخولك للمتابعة';

  @override
  String get guestCartMessage =>
      'أنشئ حساباً أو سجّل دخولك لإضافة المنتجات إلى السلة وإتمام طلبك.';

  @override
  String get guestProfileMessage =>
      'سجّل دخولك لعرض بياناتك وطلباتك وعناوينك ومفضلتك.';

  @override
  String get notNow => 'لاحقاً';

  @override
  String get unitSet => 'طقم';

  @override
  String unitBoxOf(String count) {
    return 'علبة $count قطعة';
  }

  @override
  String get paywallSignInToSubscribe => 'سجّل دخولك للاشتراك في باقات سفير';

  @override
  String get paymentChooseMethod => 'اختر طريقة الدفع';

  @override
  String get paymentMethodCard => 'بطاقة بنكية (فيزا / ماستركارد / ميزة)';

  @override
  String get paymentMethodWallet => 'محفظة إلكترونية (فودافون كاش وغيرها)';

  @override
  String get paymentWalletPhoneLabel => 'رقم المحفظة';

  @override
  String get paymentWalletPhoneInvalid => 'أدخل رقم محفظة صحيحاً يبدأ بـ 01';

  @override
  String get paymentContinue => 'متابعة';

  @override
  String get paymentStartFailed => 'تعذّر بدء الدفع، حاول مرة أخرى';

  @override
  String get paymentMethodUnavailable => 'طريقة الدفع هذه غير متاحة حالياً';

  @override
  String get paymentPageOpenFailed => 'تعذّر فتح صفحة الدفع';

  @override
  String get paymentVerifying => 'جارٍ التحقق من الدفع…';

  @override
  String get paymentFailedMessage =>
      'لم تكتمل عملية الدفع أو تم رفض البطاقة من البنك. يرجى المحاولة مرة أخرى.';

  @override
  String get paymentStillProcessing =>
      'لم يكتمل تأكيد الدفع بعد. يمكنك مراجعة حالة طلبك من طلباتي.';

  @override
  String get subscriptionActivatedTitle => 'تم تفعيل الاشتراك بنجاح 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return 'باقة $plan فعّالة حتى $date';
  }

  @override
  String get subscriptionContinueShopping => 'متابعة التسوق';

  @override
  String get redeemPoints => 'تبديل النقاط';

  @override
  String get redeemQrTitle => 'اعرض الكود على الكاشير';

  @override
  String get redeemQrSubtitle =>
      'كل 50 نقطة = 1 جنيه خصم. يُغلق الكود تلقائياً بعد تطبيق الخصم.';

  @override
  String get redeemSuccess => 'تم تطبيق الخصم بنجاح';

  @override
  String get scanCustomerCode => 'مسح كود العميل';

  @override
  String get scanCustomerHint => 'وجّه الكاميرا إلى كود العميل';

  @override
  String get scanInvalidCode => 'هذا ليس كود عميل من سفير ماركت';

  @override
  String scanCameraFailed(String error) {
    return 'تعذّر تشغيل الكاميرا: $error';
  }

  @override
  String get redeemInsufficientPoints => 'الرصيد لا يكفي لخصم 1 جنيه';

  @override
  String get redeemNotAllowed => 'هذا الحساب غير مصرّح له بخصم النقاط';

  @override
  String get redeemCustomerNotFound => 'لم يتم العثور على العميل';

  @override
  String redeemFailed(String error) {
    return 'تعذّر خصم النقاط: $error';
  }

  @override
  String get cashierRedeemTitle => 'خصم نقاط الولاء';

  @override
  String get cashierCustomer => 'العميل';

  @override
  String get cashierCurrentBalance => 'الرصيد الحالي';

  @override
  String get cashierPointsToDeduct => 'النقاط المخصومة';

  @override
  String get cashierDiscount => 'قيمة الخصم';

  @override
  String get cashierRemainingPoints => 'الرصيد بعد الخصم';

  @override
  String get cashierBarcodeHint =>
      'امسح هذا الباركود بجهاز الكاشير، ثم اضغط تأكيد';

  @override
  String get confirmPointsDeduction => 'تأكيد خصم النقاط';

  @override
  String cashierRedeemDone(String points, String amount) {
    return 'تم خصم $points نقطة (خصم $amount) بنجاح';
  }

  @override
  String get phoneOrdersTitle => 'طلبات التليفون / بحث العملاء';

  @override
  String get phoneOrderOpen => 'طلب تليفون';

  @override
  String get phoneOrderSearchHint => 'ابحث برقم الهاتف أو اسم العميل...';

  @override
  String get phoneOrderNewCustomer => '+ عميل جديد';

  @override
  String get phoneOrderTypeToSearch => 'اكتب رقم الهاتف أو الاسم للبحث';

  @override
  String get phoneOrderNoCustomers => 'لا يوجد عميل مطابق. أضفه كعميل جديد.';

  @override
  String get phoneOrderAppCustomer => 'مسجل بالتطبيق';

  @override
  String get phoneOrderPosCustomer => 'عميل الكاشير';

  @override
  String get phoneOrderNoAddress => 'لا يوجد عنوان محفوظ';

  @override
  String get phoneOrderChangeCustomer => 'تغيير العميل';

  @override
  String get phoneOrderCustomerName => 'اسم العميل';

  @override
  String get phoneOrderCustomerPhone => 'رقم الهاتف';

  @override
  String get phoneOrderCustomerAddress => 'العنوان';

  @override
  String get phoneOrderCustomerZone => 'المنطقة';

  @override
  String get phoneOrderSaveCustomer => 'حفظ العميل';

  @override
  String get phoneOrderNameRequired => 'اكتب اسم العميل';

  @override
  String get phoneOrderPhoneInvalid =>
      'اكتب رقم موبايل (01…) أو أرضي مصري صحيح';

  @override
  String get phoneOrderProductSearchHint => 'ابحث باسم المنتج أو الباركود...';

  @override
  String get phoneOrderSearchProductsPrompt =>
      'ابحث عن منتج بالاسم أو الباركود';

  @override
  String get phoneOrderNoProducts => 'لا توجد منتجات مطابقة';

  @override
  String get phoneOrderCartTitle => 'سلة العميل';

  @override
  String get phoneOrderCartEmpty => 'لم تتم إضافة منتجات بعد';

  @override
  String get phoneOrderItemsTotal => 'إجمالي المنتجات';

  @override
  String get phoneOrderTotal => 'الإجمالي';

  @override
  String get phoneOrderFreeDelivery => 'مجاني';

  @override
  String get phoneOrderConfirm => 'إتمام وتسجيل الطلب';

  @override
  String phoneOrderPlaced(String id) {
    return 'تم تسجيل الطلب #$id';
  }

  @override
  String phoneOrderFailed(String error) {
    return 'تعذّر تسجيل الطلب: $error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return 'تعذّر البحث: $error';
  }

  @override
  String get phoneOrderNotAllowed =>
      'هذا الحساب غير مصرّح له بتسجيل طلبات التليفون';

  @override
  String get phoneOrderBadge => 'تليفون';

  @override
  String phoneOrderSetupMissing(String function) {
    return 'الدالة $function غير موجودة في قاعدة البيانات. شغّل ملف supabase/migrations/20261111010000_phone_orders.sql من Supabase SQL Editor.';
  }

  @override
  String get adminToggleMenu => 'إظهار/إخفاء القائمة';

  @override
  String get adminResizeColumn => 'اسحب لتغيير عرض العمود';

  @override
  String get phoneOrderShowCart => 'عرض السلة والتوصيل';

  @override
  String get phoneOrderHideCart => 'إخفاء السلة';

  @override
  String get driverDeliveryAddress => 'عنوان التوصيل';

  @override
  String get driverNavigateViaMap => 'التوجه عبر الخريطة';

  @override
  String get mapSearchHint => 'ابحث عن منطقة أو شارع...';

  @override
  String get mapSearchNoResults => 'لا توجد نتائج لهذا البحث';

  @override
  String mapSearchFailed(String error) {
    return 'تعذّر البحث عن المكان: $error';
  }

  @override
  String get mapSearchClear => 'مسح البحث';

  @override
  String get supportLiveChatSubtitle =>
      'اكتب لنا من داخل التطبيق وسيرد عليك فريقنا مباشرة';

  @override
  String get supportSignInMessage => 'سجّل دخولك لتبدأ محادثة مع خدمة العملاء.';

  @override
  String supportLaunchFailed(String phone) {
    return 'تعذر فتح التطبيق، يمكنك الاتصال بنا على $phone';
  }

  @override
  String get supportChatTitle => 'خدمة العملاء';

  @override
  String get supportChatSubtitle => 'فريق سفير ماركت يرد عليك هنا';

  @override
  String get supportChatWelcome =>
      'أهلاً بك! اكتب سؤالك أو مشكلتك وسيرد عليك فريق خدمة العملاء في أقرب وقت.';

  @override
  String get supportMessageHint => 'اكتب رسالتك...';

  @override
  String supportLoadFailed(String error) {
    return 'تعذر تحميل المحادثة: $error';
  }

  @override
  String get supportSetupMissing =>
      'خدمة المحادثة غير مفعلة بعد. شغّل supabase/migrations/20261114210000_support_chat.sql في Supabase SQL Editor.';

  @override
  String get supportNotAllowed => 'لا تملك صلاحية الوصول إلى هذه المحادثة';

  @override
  String supportRequestFailed(String error) {
    return 'تعذر إتمام العملية: $error';
  }

  @override
  String get supportCenterTitle => 'الشكاوى والمحادثات';

  @override
  String get supportNoChats => 'لا توجد محادثات مفتوحة حالياً';

  @override
  String get supportSelectChat => 'اختر محادثة من القائمة للرد على العميل';

  @override
  String get supportNoMessagesYet => 'لا توجد رسائل في هذه المحادثة بعد';

  @override
  String get supportReplyHint => 'اكتب ردك على العميل...';

  @override
  String get supportLatestOrders => 'آخر الطلبات';

  @override
  String supportLatestOrdersTitle(String name) {
    return 'آخر طلبات $name';
  }

  @override
  String get supportNoOrders => 'لا توجد طلبات لهذا العميل';

  @override
  String supportNewMessageToast(String name, String message) {
    return 'رسالة جديدة من $name: $message';
  }

  @override
  String get supportOpenChat => 'فتح المحادثة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmptySubtitle =>
      'سنقوم بإشعارك فور توفر عروض أو مجلات جديدة من سفير ماركت';

  @override
  String notificationsLoadFailed(String error) {
    return 'تعذر تحميل الإشعارات: $error';
  }

  @override
  String get notificationsSetupMissing =>
      'الإشعارات غير مفعلة بعد. شغّل supabase/migrations/20261114220000_app_notifications.sql في Supabase SQL Editor.';

  @override
  String get notificationsNotAllowed =>
      'إرسال الإشعارات وحذفها متاح لحساب المدير فقط';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوماً',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => 'عام';

  @override
  String get notificationTypePromo => 'عروض وخصومات';

  @override
  String get notificationTypeMagazine => 'مجلة جديدة';

  @override
  String get notificationTypeOrder => 'طلباتك';

  @override
  String get notificationTypeSupportChat => 'خدمة العملاء';

  @override
  String get adminSendNotifications => 'إرسال إشعارات';

  @override
  String get adminNotificationFormSubtitle =>
      'يظهر الإشعار فوراً في تطبيق جميع العملاء';

  @override
  String get adminNotificationTitleLabel => 'عنوان الإشعار';

  @override
  String get adminNotificationTitleHint =>
      'مثال: مجلة عروض الشهر نزلت الآن! 🔥';

  @override
  String get adminNotificationTitleRequired => 'اكتب عنوان الإشعار';

  @override
  String get adminNotificationBodyLabel => 'نص الإشعار';

  @override
  String get adminNotificationBodyHint =>
      'مثال: تصفح أحدث العروض والخصومات الحصرية في سفير ماركت';

  @override
  String get adminNotificationBodyRequired => 'اكتب نص الإشعار';

  @override
  String get adminNotificationTypeLabel => 'نوع الإشعار';

  @override
  String get adminNotificationImageLabel => 'رابط صورة العرض - اختياري';

  @override
  String get adminNotificationImageInvalid =>
      'أدخل رابطاً صحيحاً يبدأ بـ https://';

  @override
  String get adminSendNotificationButton => 'إرسال الإشعار لجميع العملاء';

  @override
  String get adminNotificationSent => 'تم إرسال الإشعار لجميع العملاء';

  @override
  String adminNotificationSendFailed(String error) {
    return 'تعذر إرسال الإشعار: $error';
  }

  @override
  String get adminNotificationsHistory => 'الإشعارات المرسلة';

  @override
  String get adminNoNotificationsSent => 'لم يتم إرسال أي إشعارات بعد';

  @override
  String get adminDeleteNotificationTitle => 'حذف الإشعار';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return 'هل تريد حذف الإشعار «$title»؟ سيختفي من تطبيق العملاء.';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return 'تعذر حذف الإشعار: $error';
  }

  @override
  String get orderCardShowDetails => 'عرض التفاصيل';

  @override
  String get orderCardHideDetails => 'إخفاء التفاصيل';

  @override
  String get orderCardItemsTitle => 'منتجات الطلب';

  @override
  String get orderCardItemsFailed => 'تعذر تحميل منتجات الطلب';

  @override
  String get orderCardNoItems => 'لا توجد منتجات مسجلة لهذا الطلب';

  @override
  String get orderCardCancelledNote => 'تم إلغاء هذا الطلب';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderConfirmTitle => 'هل أنت متأكد من إلغاء الطلب؟';

  @override
  String get cancelOrderReasonPrompt => 'اختر سبب الإلغاء:';

  @override
  String get cancelOrderDismiss => 'تراجع';

  @override
  String get cancelOrderConfirm => 'تأكيد الإلغاء';

  @override
  String get cancelReasonDeliveryDelay => 'تأخير في التوصيل';

  @override
  String get cancelReasonOrderedByMistake => 'طلبت بالخطأ';

  @override
  String get cancelReasonChangedMind => 'تغيير رأيي';

  @override
  String get cancelReasonOther => 'سبب آخر';

  @override
  String cancellationReasonLine(String reason) {
    return 'سبب الإلغاء: $reason';
  }

  @override
  String get orderCancelledSuccess => 'تم إلغاء الطلب بنجاح';

  @override
  String get orderCancelTooLate =>
      'تعذر إلغاء الطلب لأن تجهيزه اكتمل أو خرج للتوصيل';

  @override
  String get orderCancelSetupMissing =>
      'إلغاء الطلب غير مفعّل بعد. شغّل supabase/migrations/20261114240000_customer_cancel_order.sql في Supabase SQL Editor.';

  @override
  String orderCancelFailed(String error) {
    return 'تعذر إلغاء الطلب: $error';
  }

  @override
  String get adminMenuReceiveOrders => 'تلقي الطلبات';

  @override
  String get adminMenuOrderStatus => 'حالة الطلب';

  @override
  String get adminStatusDelayedShort => 'متأخر';

  @override
  String get adminStatusCancelledShort => 'ملغي';

  @override
  String get adminResendNotification => 'إعادة إرسال';

  @override
  String get adminResendFillForm => 'تعبئة النموذج';

  @override
  String get adminResendNotificationTitle => 'إعادة إرسال الإشعار؟';

  @override
  String adminResendNotificationConfirm(String title) {
    return 'سيتم إرسال الإشعار «$title» لجميع العملاء مرة أخرى.';
  }

  @override
  String get adminNotificationSearchHint => 'بحث بالاسم أو العنوان';

  @override
  String get adminNotificationFilterByDate => 'فلترة بالتاريخ';

  @override
  String get adminNotificationFilterByType => 'فلترة بالسبب/النوع';

  @override
  String get adminNotificationClearDateFilter => 'مسح فلتر التاريخ';

  @override
  String get adminSelectCustomerFirst => 'اختر عميلاً لبدء الطلب';
}
