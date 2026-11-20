// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get bannerShopBrandProducts => 'Bu brend mahsulotlari';

  @override
  String get bannerAdd => 'Kompaniya bannerini qo\'shish';

  @override
  String get bannerTitleLabel => 'Kompaniya / banner sarlavhasi';

  @override
  String get bannerKeywordLabel => 'Kompaniya mahsulotlari uchun kalit so\'z';

  @override
  String get bannerKeywordHint => 'mas.: Juhayna';

  @override
  String get bannerChooseImage => 'Banner rasmini tanlash';

  @override
  String get bannerChangeImage => 'Rasmni o\'zgartirish';

  @override
  String get bannerImageRequired => 'Avval banner rasmini tanlang';

  @override
  String get bannerKeywordRequired =>
      'Kompaniya mahsulotlarini ochadigan kalit so\'zni kiriting';

  @override
  String get bannerSaved => 'Banner muvaffaqiyatli qo\'shildi';

  @override
  String bannerSaveFailed(String error) {
    return 'Banner saqlanmadi: $error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return '«$title» bannerini o\'chirasizmi?';
  }

  @override
  String get bannerExistingHeader => 'Joriy bannerlar';

  @override
  String get appTitle => 'Safeer Market';

  @override
  String get home => 'Bosh sahifa';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get language => 'Til';

  @override
  String get save => 'Saqlash';

  @override
  String get search => 'Qidiruv';

  @override
  String get cart => 'Savat';

  @override
  String get wallet => 'Hamyon';

  @override
  String get more => 'Ko‘proq';

  @override
  String get exitHint => 'Chiqish uchun orqaga tugmasini yana bir marta bosing';

  @override
  String get newProducts => 'Yangi mahsulotlar';

  @override
  String get trendingOffers => 'Mashhur takliflar';

  @override
  String get noNewNotifications => 'Yangi bildirishnomalar yo‘q';

  @override
  String get loadingLatestProducts => 'Eng so‘nggi mahsulotlar yuklanmoqda...';

  @override
  String get noNewProductsLast3Days => 'So‘nggi 3 kunda yangi mahsulotlar yo‘q';

  @override
  String get loadingOffers => 'Takliflar yuklanmoqda...';

  @override
  String get noOffersCurrently => 'Hozircha takliflar yo‘q';

  @override
  String get subscribersExclusiveFeature =>
      'Obunachilar uchun maxsus imkoniyat 👑';

  @override
  String get playAndWinPaywallBody =>
      '«O‘yna va yut» o‘yini va haftalik sovg‘alar faqat Safeer Prime va Safeer Pro obunachilari uchun. Hisobingizni yangilang va imkoniyatlardan foydalaning!';

  @override
  String get upgradeAccountNow => 'Hisobni hozir yangilash';

  @override
  String get exploreSafeer => 'Safeerni kashf eting';

  @override
  String get featuredProducts => 'Tanlangan mahsulotlar';

  @override
  String get failedToLoadProducts => 'Mahsulotlarni yuklab bo‘lmadi';

  @override
  String get noProductsCurrently => 'Hozircha mahsulotlar yo‘q';

  @override
  String get seeAll => 'Barchasini ko‘rish';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get loyaltyPoints => 'Sodiqlik ballari';

  @override
  String get spinWheelCollectPoints =>
      'G‘ildirakni aylantiring va ball to‘plang';

  @override
  String get favoriteProducts => 'Sevimli mahsulotlar';

  @override
  String get myOrders => 'Buyurtmalarim';

  @override
  String get contactUs => 'Biz bilan bog‘laning';

  @override
  String get help => 'Yordam';

  @override
  String get signOut => 'Chiqish';

  @override
  String get signIn => 'Hisobga kirish';

  @override
  String get signOutConfirmMessage => 'Hisobingizdan chiqmoqchimisiz?';

  @override
  String get signedOut => 'Hisobdan chiqdingiz';

  @override
  String get adminDashboard => 'Administrator paneli';

  @override
  String get adminDashboardSubtitle =>
      'Mijoz buyurtmalarini boshqaring va holatini yangilang';

  @override
  String get guestName => 'Mehmon';

  @override
  String welcomeUser(String name) {
    return 'Xush kelibsiz, $name';
  }

  @override
  String get guestSubtitle =>
      'Buyurtmalar va sevimlilarni kuzatish uchun kiring';

  @override
  String get personalData => 'Shaxsiy ma’lumotlar';

  @override
  String get email => 'Elektron pochta';

  @override
  String get savedAddresses => 'Saqlangan manzillar';

  @override
  String get savedCards => 'Saqlangan kartalar';

  @override
  String get messageAndSmsAlerts => 'Ilova va SMS ogohlantirishlari';

  @override
  String get privacyAndTerms => 'Maxfiylik siyosati va shartlar';

  @override
  String get deleteAccount => 'Hisobni o‘chirish';

  @override
  String get deleteAccountConfirmMessage =>
      'Hisobingiz va barcha ma’lumotlaringiz butunlay o‘chiriladi. Ishonchingiz komilmi?';

  @override
  String get deleteAccountSuccess => 'Hisobingiz muvaffaqiyatli o‘chirildi';

  @override
  String get passwordRequirementsTitle => 'Parolda bo‘lishi kerak:';

  @override
  String get passwordRuleMinLength => 'Kamida 8 ta belgi';

  @override
  String get passwordRuleUppercase => 'Kamida 1 ta katta harf';

  @override
  String get passwordRuleLowercase => 'Kamida 1 ta kichik harf';

  @override
  String get passwordRuleDigit => 'Kamida 1 ta raqam';

  @override
  String get talkToUs => 'Biz bilan gaplashing';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportLiveChat => 'Mijozlarga xizmat bilan jonli chat';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count ball • Ayirboshlash';
  }

  @override
  String get loyaltyPointsEarnNow => 'Sodiqlik ballari • Hozir to‘plang 🎁';

  @override
  String get ok => 'OK';

  @override
  String get noEmail => 'Elektron pochta yo‘q';

  @override
  String get changeEmailContactSupport =>
      'Elektron pochtani o‘zgartirish uchun qo‘llab-quvvatlash xizmatiga murojaat qiling';

  @override
  String get privacyPolicyBody =>
      'Safeer Marketda maxfiyligingizni hurmat qilamiz. Ism, telefon raqami va manzil kabi ma’lumotlaringizdan faqat buyurtmalarni yetkazish va xizmatlarni yaxshilash uchun foydalanamiz va ularni sizning roziligingizsiz uchinchi tomonga bermaymiz.\n\nIlovadan foydalanish orqali siz foydalanish shartlariga, jumladan buyurtma, yetkazib berish va qaytarish qoidalariga rozilik bildirasiz. To‘liq siyosat tez orada e’lon qilinadi.';

  @override
  String get helpTitle => 'Qanday yordam bera olamiz?';

  @override
  String get helpBody =>
      'Safeer Market jamoasi har doim xizmatingizda.\nBuyurtmangizda muammo bo‘lsa yoki savolingiz bo‘lsa, biz bilan bog‘laning — imkon qadar tez javob beramiz.';

  @override
  String get callUs => 'Qo‘ng‘iroq qilish';

  @override
  String get callUsSubtitle =>
      'Mijozlarni qo‘llab-quvvatlash xizmati bilan to‘g‘ridan-to‘g‘ri gaplashing';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whatsappSubtitle => 'Yozing, tez orada javob beramiz';

  @override
  String get messageAlerts => 'Xabar ogohlantirishlari';

  @override
  String get appNotifications => 'Ilova bildirishnomalari';

  @override
  String get appNotificationsSubtitle =>
      'Takliflar va buyurtma holati yangilanishlari';

  @override
  String get smsMessages => 'SMS xabarlar';

  @override
  String get smsMessagesSubtitle =>
      'Buyurtmani tasdiqlash va yetkazib berish haqidagi SMS';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get delete => 'O‘chirish';

  @override
  String get close => 'Yopish';

  @override
  String get refresh => 'Yangilash';

  @override
  String get all => 'Hammasi';

  @override
  String get shopNow => 'Hozir xarid qiling';

  @override
  String get scanBarcode => 'Shtrix-kodni skanerlash';

  @override
  String get phoneNumber => 'Telefon raqami';

  @override
  String get categories => 'Kategoriyalar';

  @override
  String get magazines => 'Jurnallar';

  @override
  String get addMagazine => 'Jurnal qo‘shish';

  @override
  String get unexpectedError => 'Kutilmagan xatolik yuz berdi';

  @override
  String get networkError => 'Tarmoqqa ulanib bo‘lmadi';

  @override
  String get serverError => 'Serverda xatolik yuz berdi';

  @override
  String get serverConnectionError =>
      'Serverga ulanib bo‘lmadi, qayta urinib ko‘ring';

  @override
  String get pleaseSignInFirst => 'Iltimos, avval hisobga kiring';

  @override
  String get noPermissionToEditOrder =>
      'Bu buyurtmani tahrirlashga ruxsatingiz yo‘q';

  @override
  String orderUpdateFailed(String error) {
    return 'Buyurtmani yangilab bo‘lmadi: $error';
  }

  @override
  String ordersLoadFailed(String error) {
    return 'Buyurtmalarni yuklab bo‘lmadi\n$error';
  }

  @override
  String orderNumber(String id) {
    return 'Buyurtma #$id';
  }

  @override
  String get deletedProduct => 'O‘chirilgan mahsulot';

  @override
  String get product => 'Mahsulot';

  @override
  String get addNewAddress => 'Yangi manzil qo‘shish';

  @override
  String get manageAddresses => 'Manzillarni boshqarish';

  @override
  String get editLocation => 'Joylashuvni tahrirlash';

  @override
  String helloName(String name) {
    return 'Salom, $name';
  }

  @override
  String get cardNumber => 'Karta raqami';

  @override
  String get cardholderName => 'Karta egasining ismi';

  @override
  String get asWrittenOnCard => 'Kartada yozilganidek';

  @override
  String get expiryDate => 'Amal qilish muddati';

  @override
  String get addBankCard => 'Bank kartasini qo‘shish';

  @override
  String get bankCard => 'Bank kartasi';

  @override
  String get adminPaidByVisa => 'Visa orqali to‘langan';

  @override
  String get cameraOpenFailed =>
      'Kamerani ochib bo‘lmadi, kamera ruxsatini tekshiring';

  @override
  String get addressLabelHome => 'Uy';

  @override
  String get addressLabelWork => 'Ish';

  @override
  String get puzzleGame => 'Boshqotirma o‘yini';

  @override
  String get luckyWheel => 'Omad g‘ildiragi';

  @override
  String get awesome => 'Ajoyib!';

  @override
  String get customer => 'Mijoz';

  @override
  String get noLocationForOrder => 'Bu buyurtma uchun joylashuv mavjud emas';

  @override
  String get branch => 'Filial';

  @override
  String get safeerCustomer => 'Safeer mijozi';

  @override
  String get notSpecified => 'Ko‘rsatilmagan';

  @override
  String get cashOnDelivery => 'Yetkazib berilganda naqd to‘lov';

  @override
  String get orderStatusPending => 'Kutilmoqda';

  @override
  String get orderStatusPreparing => 'Tayyorlanmoqda';

  @override
  String get orderStatusReadyForDelivery => 'Yetkazishga tayyor';

  @override
  String get orderStatusOutForDelivery => 'Yo‘lda';

  @override
  String get orderStatusDelivered => 'Yetkazildi';

  @override
  String get orderStatusCancelled => 'Bekor qilindi';

  @override
  String get statusNew => 'Yangi';

  @override
  String get startPreparing => 'Tayyorlashni boshlash';

  @override
  String get total => 'Jami';

  @override
  String get inStock => 'Mavjud';

  @override
  String get outOfStock => 'Mavjud emas';

  @override
  String get decreaseQuantity => 'Miqdorni kamaytirish';

  @override
  String get increaseQuantity => 'Miqdorni oshirish';

  @override
  String get decreaseWeight => 'Vaznni kamaytirish';

  @override
  String get increaseWeight => 'Vaznni oshirish';

  @override
  String get addToCart => 'Savatga qo‘shish';

  @override
  String get cartEmpty => 'Savatingiz bo‘sh';

  @override
  String get productUnavailableNow => 'Bu mahsulot hozircha mavjud emas';

  @override
  String distanceFromBranch(String distance) {
    return 'Filialdan $distance uzoqlikda';
  }

  @override
  String get invoiceNumberRequired => 'Hisob-faktura raqami majburiy';

  @override
  String get addAtLeastOneItem => 'Kamida bitta mahsulot qo‘shing';

  @override
  String get orderOnTheWayToYou => 'Buyurtmangiz yo‘lda!';

  @override
  String get deliveryFee => 'Yetkazib berish narxi';

  @override
  String get currencySymbol => 'EGP';

  @override
  String get unitPiece => 'dona';

  @override
  String get unitKilo => 'kg';

  @override
  String gramsValue(String value) {
    return '$value g';
  }

  @override
  String kilosValue(String value) {
    return '$value kg';
  }

  @override
  String kmValue(String value) {
    return '$value km';
  }

  @override
  String get sessionExpired => 'Seans muddati tugadi, iltimos, qayta kiring';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'Holatni yangilab bo‘lmadi: $error';
  }

  @override
  String get adminDeleteMagazineTitle => 'Jurnalni o‘chirish';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return '«$title» o‘chirilsinmi?';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return 'Jurnalni o‘chirib bo‘lmadi: $error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return 'Xato: $error';
  }

  @override
  String get adminNoMagazinesYet =>
      'Hozircha jurnallar yo‘q. Birinchisini yuklash uchun «Jurnal qo‘shish» tugmasini bosing.';

  @override
  String get adminMagazineExpired => 'Muddati o‘tgan';

  @override
  String get adminMagazineUpcoming => 'Yaqinda';

  @override
  String get adminMagazineActive => 'Faol';

  @override
  String adminMagazineDateRange(String start, String end) {
    return '$start dan $end gacha';
  }

  @override
  String get adminPickMagazinePdfTitle => 'Jurnal faylini tanlang (PDF)';

  @override
  String get adminMagazineStartDate => 'Boshlanish sanasi';

  @override
  String get adminMagazineEndDate => 'Tugash sanasi';

  @override
  String get adminMagazineTitleRequired => 'Jurnal nomini kiriting';

  @override
  String get adminMagazineCoverRequired => 'Muqova rasmini tanlang';

  @override
  String get adminMagazinePdfRequired => 'Jurnal uchun PDF faylni tanlang';

  @override
  String get adminMagazineEndBeforeStart =>
      'Tugash sanasi boshlanish sanasidan keyin bo‘lishi kerak';

  @override
  String get adminMagazineAdded => 'Jurnal muvaffaqiyatli qo‘shildi';

  @override
  String adminMagazineSaveFailed(String error) {
    return 'Jurnalni saqlab bo‘lmadi: $error';
  }

  @override
  String get adminAddNewMagazine => 'Yangi jurnal qo‘shish';

  @override
  String get adminMagazineTitleLabel => 'Jurnal nomi';

  @override
  String get adminPickCoverImage => 'Muqova rasmini tanlash';

  @override
  String get adminChangeCover => 'Muqovani o‘zgartirish';

  @override
  String get adminPickPdfFile => 'PDF faylni tanlash';

  @override
  String get adminUploading => 'Yuklanmoqda...';

  @override
  String get adminSupervisorPermissions => 'Nazoratchi huquqlari';

  @override
  String get adminEnterPinHint => 'PIN kodni kiriting (1234)';

  @override
  String get adminSupervisorModeEnabled => 'Nazoratchi rejimi yoqildi';

  @override
  String get adminInvalidPin => 'PIN kod noto‘g‘ri';

  @override
  String get adminActivate => 'Faollashtirish';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - Boshqaruv';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - Ish paneli';
  }

  @override
  String get adminCloseManagement => 'Boshqaruvni yopish';

  @override
  String get adminEnableManagement => 'Boshqaruvni yoqish';

  @override
  String get adminExitToStore => 'Do‘konga qaytish';

  @override
  String get adminMenuOrders => 'Buyurtmalar';

  @override
  String get adminMenuProducts => 'Mahsulotlar';

  @override
  String get adminMenuStaff => 'Xodimlar';

  @override
  String get adminMenuReports => 'Hisobotlar va kundalik jurnal';

  @override
  String get adminStatusPreparingShort => 'Tayyorlash';

  @override
  String get adminStatusReadyForDriverShort => 'Kuryer uchun';

  @override
  String get adminStatusDeliveryShort => 'Yetkazish';

  @override
  String get adminStatusCompletedShort => 'Yakunlangan';

  @override
  String get adminStatusUnknown => 'Noma’lum';

  @override
  String get adminNoOrders => 'Buyurtmalar yo‘q';

  @override
  String get adminSelectOrderFromList => 'Ro‘yxatdan buyurtmani tanlang';

  @override
  String get adminItemsToPrepare => 'Tayyorlanadigan mahsulotlar:';

  @override
  String get adminNoItemsInOrder => 'Qayd etilgan mahsulotlar yo‘q';

  @override
  String get adminAvailableActions => 'Mavjud amallar';

  @override
  String get adminOrderAwaitingPreparer => 'Buyurtma tayyorlovchini kutmoqda';

  @override
  String adminPreparerName(String name) {
    return 'Tayyorlovchi: $name';
  }

  @override
  String get adminAwaitingDriverAssignment =>
      'Nazoratchi kuryerni tayinlashi kutilmoqda';

  @override
  String get adminPickUpAndStartRoute => 'Olish va yo‘lga chiqish 🗺️';

  @override
  String adminDriverName(String name) {
    return 'Kuryer: $name';
  }

  @override
  String get adminOrderReadyAwaitingDriver =>
      'Buyurtma muvaffaqiyatli tayyorlandi. Kuryer olib ketishi kutilmoqda.';

  @override
  String get adminMarkDelivered => 'Muvaffaqiyatli yetkazildi 💵';

  @override
  String get adminCloseOrderPermanently => 'Buyurtmani butunlay yopish';

  @override
  String get adminOrderWithDriverOnTheWay =>
      'Buyurtma hozir kuryerda, mijozga yo‘lda.';

  @override
  String get adminOrderDeliveredAndClosed =>
      'Bu buyurtma muvaffaqiyatli yetkazildi va yopildi.';

  @override
  String get adminWhoAreYouPickName =>
      'Siz kimsiz? (Boshlash uchun ismingizni tanlang)';

  @override
  String get adminNoPreparers => 'Tayyorlovchilar yo‘q';

  @override
  String get adminFinishOrderPreparation => 'Buyurtmani tayyorlashni yakunlash';

  @override
  String get adminCheckAllItemsFirst =>
      '⚠️ Kechirasiz, avval barcha mahsulotlarni belgilashingiz kerak.';

  @override
  String get adminPreparationFinished =>
      'Tayyorlash muvaffaqiyatli yakunlandi.';

  @override
  String get adminAssignDriverTitle => 'Kuryerni tayinlash (faqat nazoratchi)';

  @override
  String get adminSelectDriver => 'Kuryerni tanlang';

  @override
  String get adminOrderAssignedToDriver => 'Buyurtma kuryerga biriktirildi';

  @override
  String get adminAssignToSelectedDriver => 'Tanlangan kuryerga biriktirish';

  @override
  String get adminCallFailed => 'Qo‘ng‘iroq qilib bo‘lmadi';

  @override
  String get adminNoPhoneNumber => 'Raqam yo‘q';

  @override
  String get adminNoName => 'Ism yo‘q';

  @override
  String get adminAddressNotSet => 'Ko‘rsatilmagan';

  @override
  String get adminCustomerInfo => 'Mijoz ma’lumotlari';

  @override
  String get adminManageProducts => 'Mahsulotlarni boshqarish';

  @override
  String get adminActiveProducts => 'Faol mahsulotlar';

  @override
  String get adminInactiveProducts => 'Nofaol';

  @override
  String get adminSearchProductByName => 'Mahsulotni nomi bo‘yicha qidiring...';

  @override
  String adminErrorOccurred(String error) {
    return 'Xatolik yuz berdi: $error';
  }

  @override
  String get adminNoProducts => 'Mahsulotlar yo‘q';

  @override
  String get adminCopyProductName => 'Mahsulot nomini nusxalash';

  @override
  String get adminCopied => 'Nusxalandi';

  @override
  String get adminCopyBarcode => 'Shtrix-kodni nusxalash';

  @override
  String adminBarcodeValue(String barcode) {
    return 'Shtrix-kod: $barcode';
  }

  @override
  String get adminUpdateErrorOccurred => 'Yangilashda xatolik yuz berdi';

  @override
  String get adminManageStaff => 'Xodimlarni boshqarish';

  @override
  String get adminAddEmployee => 'Xodim qo‘shish';

  @override
  String get adminNoStaff => 'Ro‘yxatdan o‘tgan xodimlar yo‘q';

  @override
  String get adminRoleTaker => 'Buyurtma qabul qiluvchi';

  @override
  String get adminRolePreparer => 'Tayyorlovchi';

  @override
  String get adminRoleDriver => 'Kuryer';

  @override
  String get adminNoPhone => 'Telefon yo‘q';

  @override
  String get adminReportsTitle => 'Hisobotlar va umumiy kundalik jurnal';

  @override
  String get adminTotalSalesCollected => 'Jami savdo (undirilgan)';

  @override
  String get adminDeliveredOrdersTitle =>
      'Yakunlangan va yetkazilgan buyurtmalar';

  @override
  String get adminOrdersInPreparationTitle =>
      'Hozir tayyorlanayotgan buyurtmalar';

  @override
  String get adminCancelledOrdersTitle => 'Bekor qilingan buyurtmalar';

  @override
  String get adminTotalOrdersCumulative => 'Jami buyurtmalar (umumiy)';

  @override
  String adminOrdersCount(String count) {
    return '$count ta buyurtma';
  }

  @override
  String get adminRecentOrdersLog => 'So‘nggi buyurtmalar jurnali';

  @override
  String get adminOrderNumberColumn => 'Buyurtma №';

  @override
  String get adminCustomerNameColumn => 'Mijoz ismi';

  @override
  String get adminStatusColumn => 'Holat';

  @override
  String get paymentMethodCashLabel => 'Yetkazib berilganda naqd pul';

  @override
  String get paymentMethodCardLabel => 'Bank kartasi (Visa/Mastercard)';

  @override
  String get paymentMethodInstaPayLabel => 'InstaPay';

  @override
  String get paymentMethodInstaPaySubtitle =>
      'InstaPay ilovasi orqali tezkor o‘tkazma';

  @override
  String get instaPayOpenApp => 'To‘lash uchun InstaPay’ni oching';

  @override
  String get instaPayIpaLabel => 'Tezkor to‘lov manzili (IPA)';

  @override
  String get instaPayPhoneLabel => 'Yoki telefon raqami orqali';

  @override
  String get instaPayCopy => 'Nusxa';

  @override
  String get instaPayCopied => 'Nusxa olindi';

  @override
  String get instaPayConfirmHint =>
      'InstaPay orqali buyurtma summasini o‘tkazgach, pastdagi Buyurtmani tasdiqlash tugmasini bosing.';

  @override
  String get instaPayReceiptTitle => 'Bank o‘tkazmasi cheki (skrinshot)';

  @override
  String get instaPayReceiptHint =>
      'Buyurtmani tasdiqlash uchun InstaPay’dan muvaffaqiyatli o‘tkazma skrinshotini biriktiring';

  @override
  String get instaPayReceiptPick => 'Chek rasmini tanlang yoki suratga oling';

  @override
  String get instaPayReceiptRequired =>
      'Avval o‘tkazma cheki rasmini biriktiring';

  @override
  String get adminViewTransferReceipt => 'O‘tkazma chekini ko‘rish';

  @override
  String get adminCopyReceiptImage => 'Rasmni nusxalash';

  @override
  String get adminShareReceipt => 'Chekni ulashish';

  @override
  String get adminReceiptImageCopied => 'Chek rasmi nusxalandi';

  @override
  String get adminReceiptActionFailed => 'Chek rasmini qayta ishlab bo‘lmadi';

  @override
  String get subscriptionConfirmInstaPay => 'Obunani tasdiqlash';

  @override
  String get subscriptionPendingSuccessTitle =>
      'Yangilash so‘rovi qabul qilindi';

  @override
  String get subscriptionPendingSuccessBody =>
      'Yangilash so‘rovingiz va to‘lov cheki qabul qilindi. Admin ko‘rib chiqqach Pro hisobingiz faollashtiriladi.';

  @override
  String get adminMenuPendingSubscriptions => 'Kutilayotgan obunalar';

  @override
  String get adminActivateAccount => 'Hisobni faollashtirish';

  @override
  String get adminSubscriptionApproved => 'Obuna faollashtirildi';

  @override
  String get adminNoPendingSubscriptions =>
      'Kutilayotgan obuna so‘rovlari yo‘q';

  @override
  String get adminPendingSubscriptionTier => 'So‘ralgan reja';

  @override
  String get paymentCopyCardNumber => 'Karta raqamini nusxalash';

  @override
  String get paymentCardNumberCopied => 'Karta raqami nusxa olindi';

  @override
  String get checkoutAddressOutOfRange =>
      'Manzil yetkazib berish hududidan tashqarida';

  @override
  String get checkoutPinAddressFirst => 'Avval manzilni xaritada belgilang';

  @override
  String checkoutOrderFailed(String error) {
    return 'Buyurtma berib bo‘lmadi: $error';
  }

  @override
  String get checkoutTitle => 'Buyurtmani rasmiylashtirish';

  @override
  String get checkoutDeliveryAddress => 'Yetkazib berish manzili';

  @override
  String get checkoutPaymentMethod => 'To‘lov usuli';

  @override
  String get checkoutOrderSummary => 'Buyurtma xulosasi';

  @override
  String get checkoutSelectAddressFirst =>
      'Buyurtma berish uchun avval yetkazib berish manzilini tanlang';

  @override
  String get checkoutPinLocationForFee =>
      'Yetkazib berish narxini hisoblash uchun manzilni xaritada belgilang';

  @override
  String checkoutOrderPlaced(String id) {
    return 'Buyurtmangiz qabul qilindi • Buyurtma #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return 'Kechirasiz, manzil $distance uzoqlikda, yetkazib berish hududidan tashqarida ($maxDistance gacha)';
  }

  @override
  String get checkoutSignInToChooseAddress =>
      'Yetkazib berish manzilini tanlash uchun hisobga kiring';

  @override
  String get checkoutPinThisAddressForFee =>
      'Yetkazib berish narxini hisoblash uchun bu manzilni xaritada belgilang';

  @override
  String get checkoutPinLocation => 'Joylashuvni belgilash';

  @override
  String get checkoutChangeAddress => 'O‘zgartirish';

  @override
  String get checkoutAddDeliveryAddress =>
      'Buyurtma berish uchun yetkazib berish manzilini qo‘shing';

  @override
  String get checkoutAddAddress => 'Manzil qo‘shish';

  @override
  String get checkoutNoAddressChosen =>
      'Siz hali yetkazib berish manzilini tanlamadingiz';

  @override
  String get checkoutChooseAddress => 'Manzilni tanlash';

  @override
  String get checkoutEstimatedArrival => 'Taxminiy yetib kelish vaqti:';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return 'Yetkazib berish narxi ($distance)';
  }

  @override
  String get checkoutOutOfDeliveryRange =>
      'Yetkazib berish hududidan tashqarida';

  @override
  String get checkoutItemCount => 'Mahsulotlar soni';

  @override
  String get checkoutSubtotal => 'Oraliq jami';

  @override
  String get checkoutGrandTotal => 'Umumiy jami';

  @override
  String get checkoutConfirmOrder => 'Buyurtmani tasdiqlash';

  @override
  String get paymentCardScanUnsupported =>
      'Bu qurilmada kartani skanerlash qo‘llab-quvvatlanmaydi';

  @override
  String get paymentCardScanFailed =>
      'Kartani o‘qib bo‘lmadi, iltimos, ma’lumotlarni qo‘lda kiriting';

  @override
  String get paymentCardScanned =>
      'Karta skanerlandi, ma’lumotlarni tekshiring va CVV kodini kiriting';

  @override
  String get paymentCardTitle => 'Karta orqali to‘lov';

  @override
  String get paymentSecureNotice => 'Xavfsiz, shifrlangan to‘lov';

  @override
  String paymentPayNow(String amount) {
    return 'Hozir to‘lash • $amount';
  }

  @override
  String get paymentScanCardTooltip => 'Kartani kamera bilan skanerlash';

  @override
  String get paymentAmountDue => 'To‘lanadigan summa';

  @override
  String get cardNumberRequired => 'Karta raqamini kiriting';

  @override
  String get cardNumberInvalid => 'Karta raqami noto‘g‘ri';

  @override
  String get cardExpiryRequired => 'Sanani MM/YY formatida kiriting';

  @override
  String get cardExpiryInvalidMonth => 'Oy noto‘g‘ri';

  @override
  String get cardExpired => 'Karta muddati tugagan';

  @override
  String get cardCvvInvalid => 'Kod noto‘g‘ri';

  @override
  String get cardHolderNameRequired =>
      'Ismni kartada ko‘rsatilganidek kiriting';

  @override
  String get walletCardSaved => 'Karta muvaffaqiyatli saqlandi';

  @override
  String get walletCardDataProtected =>
      'Ma’lumotlaringiz himoyalangan, biz CVV kodini hech qachon saqlamaymiz';

  @override
  String get walletSaveCard => 'Kartani saqlash';

  @override
  String get walletAddCardHint =>
      'Keyingi buyurtmalarda tezroq to‘lash uchun kartangizni qo‘shing';

  @override
  String get walletInAppBalance => 'Ilovadagi hamyoningiz balansi';

  @override
  String get walletBalanceLoadFailed => 'Balansni yuklab bo‘lmadi';

  @override
  String get walletBalanceAutoApplied =>
      'Balansingiz to‘lov vaqtida avtomatik qo‘llaniladi';

  @override
  String get walletSignInToViewBalance =>
      'Balansingizni ko‘rish uchun hisobga kiring';

  @override
  String walletCardExpires(String expiry) {
    return 'Amal qilish muddati: $expiry';
  }

  @override
  String get walletDeleteCard => 'Kartani o‘chirish';

  @override
  String get checkoutUseOrAddNewCard =>
      '+ Yangi kartadan foydalanish yoki qo‘shish';

  @override
  String get checkoutSavedCards => 'Saqlangan kartalaringiz';

  @override
  String get paywallUpgradeAccount => 'Hisobni yangilash';

  @override
  String get paywallDiscoverSafeer => 'Safeer olamini kashf eting 👑';

  @override
  String get paywallChoosePlan =>
      'Ehtiyojlaringizga mos tarifni tanlang va har bir buyurtmada ko‘proq tejang.';

  @override
  String get paywallProTitle => 'Safeer Pro (VIP)';

  @override
  String get paywallPerMonth => '/ oyiga';

  @override
  String get paywallProUnlimitedFreeDelivery =>
      'Cheksiz bepul yetkazib berish 🚀';

  @override
  String get paywallProExpressDelivery =>
      'Ekspress yetkazib berish (ustuvor tayyorlash)';

  @override
  String get paywallProWholesalePrices => 'Eksklyuziv ulgurji narxlar 💰';

  @override
  String get paywallProNoMinimumOrder => 'Minimal buyurtma summasi yo‘q';

  @override
  String get paywallProUnlimitedGiveaways =>
      'Sovg‘alar o‘yinlarida cheksiz ishtirok';

  @override
  String get paywallPrimeTitle => 'Safeer Prime';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders =>
      '5 ta buyurtmaga bepul yetkazib berish';

  @override
  String get paywallPrimeOffersPriority =>
      'Katta takliflardan ustuvor foydalanish';

  @override
  String get paywallPrimeWeeklyPlayAndWin =>
      'Haftalik «O‘yna va yut» o‘yini 🎁';

  @override
  String get paywallFreeTitle => 'Standart hisob';

  @override
  String get paywallFreePrice => 'Bepul';

  @override
  String get paywallFreeStandardDelivery =>
      'Standart narxda oddiy yetkazib berish';

  @override
  String get paywallFreePublicAccess =>
      'Mahsulotlar va ommaviy takliflardan foydalanish';

  @override
  String get paywallBestSeller => 'Eng ko‘p sotilgan';

  @override
  String get paywallPaymentComingSoon => 'To‘lov tez orada ishga tushiriladi';

  @override
  String get paywallSubscribeNow => 'Hozir obuna bo‘lish';

  @override
  String get catDairyEggs => 'Sut mahsulotlari va tuxum';

  @override
  String get subcatTetraPakCheese =>
      'Tetra Pak, uchburchak va stakandagi pishloq';

  @override
  String get subcatPackagedCheeseLabneh =>
      'Qadoqlangan pishloq, labne, qaymoq va eritilgan sariyog‘';

  @override
  String get subcatCheeseByWeight => 'Vaznli pishloq';

  @override
  String get subcatMozzarella => 'Mozzarella pishlog‘i';

  @override
  String get subcatYogurtRicePudding => 'Yogurt va sutli guruch';

  @override
  String get subcatLongLifeDairy => 'Uzoq saqlanadigan sut mahsulotlari';

  @override
  String get subcatPackagedButter => 'Qadoqlangan sariyog‘';

  @override
  String get subcatPackagedEggs => 'Qadoqlangan tuxum';

  @override
  String get catSweetsSnacks => 'Shirinliklar va gazaklar';

  @override
  String get subcatChocolate => 'Shokolad';

  @override
  String get subcatBiscuits => 'Pechene';

  @override
  String get subcatSweets => 'Shirinliklar';

  @override
  String get subcatChipsRoasted => 'Chipslar va qovurilgan gazaklar';

  @override
  String get subcatNutsByWeight => 'Vaznli gazaklar va yong‘oqlar';

  @override
  String get subcatHalawaSpreads => 'Holva va surtma pastalar';

  @override
  String get subcatRamadanYamish => 'Ramazon uchun quruq mevalar va yong‘oqlar';

  @override
  String get catDrinksJuices => 'Ichimliklar va sharbatlar';

  @override
  String get subcatWaterDrinksIceCream =>
      'Suv, ichimliklar, sharbatlar va muzqaymoq';

  @override
  String get subcatDrinks => 'Ichimliklar';

  @override
  String get subcatJuices => 'Sharbatlar';

  @override
  String get subcatPowderedJuices => 'Kukunli sharbatlar';

  @override
  String get catMeatFrozen => 'Go‘sht va muzlatilgan mahsulotlar';

  @override
  String get subcatFrozenPoultry =>
      'Muzlatilgan va qayta ishlangan parranda go‘shti';

  @override
  String get subcatFrozenMeat => 'Muzlatilgan go‘sht';

  @override
  String get subcatProcessedMeat => 'Go‘sht mahsulotlari';

  @override
  String get subcatFrozenFish => 'Muzlatilgan baliq';

  @override
  String get subcatSmokedFish => 'Dudlangan baliq';

  @override
  String get subcatFrozenVegFruit => 'Muzlatilgan sabzavot va mevalar';

  @override
  String get subcatFrozenPastries => 'Muzlatilgan xamir mahsulotlari';

  @override
  String get catBakeryBreakfast => 'Non mahsulotlari va nonushta';

  @override
  String get subcatBakery => 'Non mahsulotlari';

  @override
  String get subcatPatisserie => 'Pishiriqlar va keksler';

  @override
  String get subcatCerealsOats => 'Makkajo‘xori yormasi, myusli va suli';

  @override
  String get catPastaRice => 'Makaron va guruch';

  @override
  String get subcatPasta => 'Makaron';

  @override
  String get subcatRice => 'Guruch';

  @override
  String get subcatLegumesSpicesBreadcrumbs =>
      'Qadoqlangan dukkaklilar, ziravorlar va non ushog‘i';

  @override
  String get subcatSoupsStocksMixes =>
      'Sho‘rvalar, bulyonlar va ziravor aralashmalari';

  @override
  String get catPantryOils => 'Oziq-ovqat va yog‘lar';

  @override
  String get subcatOils => 'Yog‘lar';

  @override
  String get subcatGhee => 'Eritilgan sariyog‘';

  @override
  String get subcatSugarFlour => 'Shakar va un';

  @override
  String get subcatCannedFood => 'Konservalar';

  @override
  String get subcatCondiments => 'Souslar va gazaklar';

  @override
  String get subcatOlivesPickles => 'Zaytun va tuzlamalar';

  @override
  String get subcatPackagedOlivesPickles => 'Qadoqlangan zaytun va tuzlamalar';

  @override
  String get subcatSpicesByWeight => 'Vaznli ziravorlar';

  @override
  String get subcatGrainsByWeight => 'Vaznli don va urug‘lar';

  @override
  String get subcatBakingSupplies =>
      'Qandolatchilik uchun mahsulotlar va kukunlar';

  @override
  String get subcatSaladsByWeight => 'Vaznli salatlar';

  @override
  String get catCleaningCare => 'Tozalash va uy-ro‘zg‘or';

  @override
  String get subcatDetergentsSofteners =>
      'Kir yuvish kukunlari va yumshatgichlar';

  @override
  String get subcatLiquidSoapStainRemovers =>
      'Suyuq sovun va dog‘ ketkazgichlar';

  @override
  String get subcatBleachDisinfectants =>
      'Oqartirgichlar va dezinfeksiya vositalari';

  @override
  String get subcatPolishes => 'Yaltiratish vositalari';

  @override
  String get subcatInsecticidesFresheners =>
      'Hasharotlarga qarshi vositalar va xushbo‘ylagichlar';

  @override
  String get subcatTissuesToiletPaper => 'Salfetkalar va hojatxona qog‘ozi';

  @override
  String get subcatSteelWoolScrubbers => 'Metall mochalkalar va ishqalagichlar';

  @override
  String get subcatSpongesSteelWool => 'Gubkalar va metall mochalkalar';

  @override
  String get subcatDrainCleaners => 'Quvur tozalash vositalari';

  @override
  String get subcatIncense => 'Tutatqilar';

  @override
  String get catPersonalCare => 'Shaxsiy gigiyena';

  @override
  String get subcatShampooConditioner => 'Shampun va balzam';

  @override
  String get subcatShowerGelHandWash => 'Dush geli va qo‘l yuvish vositalari';

  @override
  String get subcatSoap => 'Sovun';

  @override
  String get subcatPerfumesDeodorants => 'Atirlar va dezodorantlar';

  @override
  String get subcatCreamsSerums => 'Kremlar va serumlar';

  @override
  String get subcatOralCare => 'Og‘iz bo‘shlig‘i gigiyenasi';

  @override
  String get subcatShavingSupplies => 'Soqol olish vositalari';

  @override
  String get subcatHairDyeHenna => 'Soch bo‘yoqlari va xina';

  @override
  String get subcatPersonalCareSupplies => 'Shaxsiy gigiyena vositalari';

  @override
  String get catBabyWorld => 'Bolalar olami';

  @override
  String get subcatDiapersPads => 'Tagliklar va gigiyenik prokladkalar';

  @override
  String get subcatBabyFood => 'Bolalar ovqati';

  @override
  String get subcatBabySupplies => 'Bolalar uchun mahsulotlar';

  @override
  String get catHomeSupplies => 'Uy-ro‘zg‘or buyumlari';

  @override
  String get subcatHousewares => 'Uy-ro‘zg‘or anjomlari';

  @override
  String get subcatElectricalTools => 'Elektr asboblari';

  @override
  String get subcatElectricalSupplies => 'Elektr jihozlari';

  @override
  String get subcatPlasticsBags => 'Plastik buyumlar va paketlar';

  @override
  String get subcatFoil => 'Folga';

  @override
  String get subcatHardware => 'Xo‘jalik mollari';

  @override
  String get subcatBatteries => 'Batareyalar';

  @override
  String get subcatMatchesLighters => 'Gugurt va zajigalkalar';

  @override
  String get subcatPetSupplies => 'Uy hayvonlari uchun mahsulotlar';

  @override
  String get subcatRamadanSupplies => 'Ramazon uchun mahsulotlar';

  @override
  String get categoryTitle => 'Kategoriya';

  @override
  String get categoryNotFound => 'Bunday kategoriya mavjud emas';

  @override
  String get categoryNoProductsNow =>
      'Hozircha bu kategoriyada mahsulotlar yo‘q';

  @override
  String get shopFromHome => 'Bosh sahifadan xarid qiling';

  @override
  String categoryProductCount(String count) {
    return '$count ta mahsulot';
  }

  @override
  String get loadMoreFailedRetry => 'Ko‘proq yuklab bo‘lmadi, qayta urinish';

  @override
  String get categoriesDrawerTagline => 'Kerakli hamma narsa bir joyda';

  @override
  String get productDetailsTitle => 'Mahsulot tafsilotlari';

  @override
  String get productNotAvailable => 'Bu mahsulot mavjud emas';

  @override
  String get productLoadFailed => 'Mahsulotni yuklab bo‘lmadi';

  @override
  String get productImageUpdated => 'Mahsulot rasmi muvaffaqiyatli yangilandi!';

  @override
  String productImageUploadFailed(String error) {
    return 'Yuklashda xatolik: $error';
  }

  @override
  String get updateProductImage => 'Mahsulot rasmini yangilash';

  @override
  String get takePhotoWithCamera => 'Rasmga olish';

  @override
  String get chooseFromGallery => 'Galereyadan tanlash';

  @override
  String get changeProductImage => 'Rasmni o‘zgartirish';

  @override
  String get pricePerKiloChooseWeight =>
      'Narx 1 kg uchun, qo‘shishda vaznni tanlang';

  @override
  String get productDescription => 'Tavsif';

  @override
  String get addToCartButton => 'Savatga qo‘shish';

  @override
  String get productCurrentlyUnavailable => 'Hozircha mavjud emas';

  @override
  String get productDetailsInCart => 'Savatda';

  @override
  String get imageLinkCopied => 'Rasm havolasi nusxalandi';

  @override
  String get copyImageLink => 'Rasm havolasini nusxalash';

  @override
  String get similarProducts => 'O‘xshash mahsulotlar';

  @override
  String get searchInSafeer => 'Safeerda qidirish';

  @override
  String get searchProductHint =>
      'Mahsulotni qidiring, masalan: sut, pishloq...';

  @override
  String get clearSearch => 'Tozalash';

  @override
  String get barcodeScanUnsupported =>
      'Bu qurilmada shtrix-kodni skanerlash qo‘llab-quvvatlanmaydi';

  @override
  String get searchFailedCheckConnection =>
      'Qidiruv amalga oshmadi, internet aloqasini tekshiring';

  @override
  String get scanAnotherProduct => 'Boshqa mahsulotni skanerlash';

  @override
  String noProductWithBarcode(String barcode) {
    return '«$barcode» shtrix-kodli mahsulot yo‘q';
  }

  @override
  String get productMayBeUnavailable =>
      'Mahsulot hozircha mavjud bo‘lmasligi mumkin';

  @override
  String get scanAgain => 'Qayta skanerlash';

  @override
  String noSearchResultsFor(String query) {
    return '«$query» bo‘yicha natija topilmadi';
  }

  @override
  String get searchTryAnotherWord =>
      'Boshqa so‘zni sinab ko‘ring yoki imloni tekshiring';

  @override
  String searchResultsCount(String count, String query) {
    return '«$query» bo‘yicha $count ta natija';
  }

  @override
  String get popularSearches => 'Ommabop qidiruvlar';

  @override
  String get searchIntroSubtitle =>
      'Minglab mahsulotlar orasidan qidiring va bir necha daqiqada buyurtma bering';

  @override
  String get searchSuggestionMilk => 'Sut';

  @override
  String get searchSuggestionCheese => 'Pishloq';

  @override
  String get searchSuggestionRice => 'Guruch';

  @override
  String get searchSuggestionOil => 'Yog‘';

  @override
  String get searchSuggestionSugar => 'Shakar';

  @override
  String get searchSuggestionTea => 'Choy';

  @override
  String get receiptTypeReceive => 'Qabul qilish';

  @override
  String get receiptTypeSupplierReturn => 'Qaytarish';

  @override
  String get warehouseGoodsReceiptTitle => 'Tovarni qabul qilish';

  @override
  String get warehouseGoodsReturnTitle => 'Tovarni qaytarish';

  @override
  String get warehouseReceiptSaved => 'Qabul qilish hujjati saqlandi';

  @override
  String get warehouseReturnSaved => 'Qaytarish hujjati saqlandi';

  @override
  String get warehouseSubmitReceipt => 'Qabul qilish hujjatini yuborish';

  @override
  String get warehouseSubmitReturn => 'Qaytarish hujjatini yuborish';

  @override
  String get warehouseInvoiceDate => 'Hisob-faktura sanasi';

  @override
  String get warehouseScanOrEnterBarcode =>
      'Shtrix-kodni skanerlang yoki kiriting';

  @override
  String get warehouseEnterQuantityAboveZero =>
      'Noldan katta miqdorni kiriting';

  @override
  String get warehouseCompleteRequiredFields =>
      'Avval majburiy maydonlarni to‘ldiring';

  @override
  String get warehouseNoItemsYet => 'Hali mahsulot qo‘shilmagan';

  @override
  String get warehouseDocumentDetails => 'Hujjat ma’lumotlari';

  @override
  String get warehouseInvoiceNumberRequiredLabel => 'Hisob-faktura raqami *';

  @override
  String get warehouseInvoiceDateRequiredLabel => 'Hisob-faktura sanasi *';

  @override
  String get warehouseInvoiceDateRequired => 'Hisob-faktura sanasi majburiy';

  @override
  String get warehouseItems => 'Mahsulotlar';

  @override
  String get warehouseBarcode => 'Shtrix-kod';

  @override
  String get warehouseQuantity => 'Miqdor';

  @override
  String get warehouseAdd => 'Qo‘shish';

  @override
  String get warehouseReloadSuppliers => 'Yetkazib beruvchilarni qayta yuklash';

  @override
  String get warehouseSupplierRequiredLabel => 'Yetkazib beruvchi *';

  @override
  String get warehouseSupplierHint =>
      'Yetkazib beruvchi raqamini qidiring yoki kiriting';

  @override
  String get warehouseSuppliersEmpty => 'Yetkazib beruvchilar ro‘yxati bo‘sh';

  @override
  String get warehouseSelectSupplier => 'Yetkazib beruvchini tanlang';

  @override
  String get warehouseSelectSupplierFromList =>
      'Yetkazib beruvchini ro‘yxatdan tanlang';

  @override
  String get warehouseFetchingProductName => 'Mahsulot nomi olinmoqda…';

  @override
  String get warehouseUnregisteredProduct => 'Ro‘yxatdan o‘tmagan mahsulot';

  @override
  String warehouseQuantityValue(String quantity) {
    return 'Miqdor: $quantity';
  }

  @override
  String get warehouseSelectDate => 'Sanani tanlang';

  @override
  String get warehouseClearDate => 'Sanani tozalash';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return 'Yetkazib beruvchilarni yuklab bo‘lmadi: $error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return 'Hujjatni saqlab bo‘lmadi: $error';
  }

  @override
  String get warehouseOrderAlreadyUpdated =>
      'Buyurtmani yangilab bo‘lmadi, u allaqachon yangilangan bo‘lishi mumkin';

  @override
  String get warehouseSignOutConfirm => 'Ombor hisobidan chiqmoqchimisiz?';

  @override
  String get warehouseDashboardTitle => 'Ombor paneli';

  @override
  String get warehouseNewOrdersTab => 'Yangi buyurtmalar';

  @override
  String get warehousePreparingTab => 'Tayyorlanmoqda';

  @override
  String get warehouseItemInquiry => 'Mahsulot haqida so‘rov';

  @override
  String warehouseItemInquiryFailed(String error) {
    return 'Mahsulot haqida ma’lumot olib bo‘lmadi\n$error';
  }

  @override
  String get warehouseItemNotRegistered =>
      'Bu mahsulot ma’lumotlar bazasida ro‘yxatdan o‘tmagan';

  @override
  String warehouseBarcodeValue(String barcode) {
    return 'Shtrix-kod: $barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return 'Mavjud miqdor: $quantity';
  }

  @override
  String get warehouseNoNewOrders =>
      'Yangi buyurtmalar yo‘q\nYangilash uchun pastga torting';

  @override
  String get warehouseNoPreparingOrders => 'Tayyorlanayotgan buyurtmalar yo‘q';

  @override
  String warehousePreparingStarted(String id) {
    return '#$id buyurtmani tayyorlash boshlandi, uni «Tayyorlanmoqda» bo‘limida toping';
  }

  @override
  String warehouseOrderReady(String id) {
    return '#$id buyurtma tayyor, kuryerlarga xabar berildi';
  }

  @override
  String warehouseProductsCount(String count) {
    return 'Mahsulotlar ($count)';
  }

  @override
  String warehouseCustomerValue(String name) {
    return 'Mijoz: $name';
  }

  @override
  String warehouseAddressValue(String address) {
    return 'Manzil: $address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return 'Jami: $amount';
  }

  @override
  String get driverNewOrderAvailable =>
      'Yetkazish uchun yangi buyurtma mavjud!';

  @override
  String driverLocationSharingStartFailed(String error) {
    return 'Joylashuvni ulashishni boshlab bo‘lmadi: $error';
  }

  @override
  String get driverSignOutConfirm => 'Kuryer hisobidan chiqmoqchimisiz?';

  @override
  String get driverDashboardTitle => 'Kuryer paneli';

  @override
  String get driverAvailableOrdersTab => 'Mavjud buyurtmalar';

  @override
  String get driverNoAvailableOrders =>
      'Hozircha mavjud buyurtmalar yo‘q\nYangilash uchun pastga torting';

  @override
  String get driverNoActiveDeliveries => 'Yetkazilayotgan buyurtmalar yo‘q';

  @override
  String driverOrderAccepted(String id) {
    return '#$id buyurtma qabul qilindi, uni «Buyurtmalarim» bo‘limida toping';
  }

  @override
  String driverOrderDelivered(String id) {
    return '#$id buyurtma yetkazildi';
  }

  @override
  String get driverPhoneLabel => 'Telefon';

  @override
  String get driverAddressLabel => 'Manzil';

  @override
  String get driverDistanceLabel => 'Masofa';

  @override
  String get driverDistanceNotSpecified => 'Ko‘rsatilmagan';

  @override
  String driverDistanceFromBranch(String distance) {
    return 'Filialdan $distance';
  }

  @override
  String get driverTotalToCollect => 'Jami (undiriladigan)';

  @override
  String get driverViewMapAndLocation => 'Xarita va joylashuvni ko‘rish';

  @override
  String get driverAcceptOrder => 'Buyurtmani qabul qilish';

  @override
  String get driverBroadcastingLocation => 'Joylashuv ulashilmoqda...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return 'Joylashuv ulashilmoqda... oxirgi yuborilgan: $time';
  }

  @override
  String get driverRequestingLocationPermission =>
      'Joylashuv ruxsati so‘ralmoqda...';

  @override
  String get driverStartLocationSharing => 'Joylashuvni ulashishni boshlash';

  @override
  String driverCopyLabel(String label) {
    return 'Nusxalash: $label';
  }

  @override
  String driverCopiedLabel(String label) {
    return '$label nusxalandi';
  }

  @override
  String driverLocationReadFailed(String error) {
    return 'Joylashuvingizni aniqlab bo‘lmadi: $error';
  }

  @override
  String get driverLocationSharingStopped =>
      'Joylashuvni ulashish to‘xtadi, davom etish uchun «Joylashuvni ulashishni boshlash» tugmasini bosing';

  @override
  String get driverOrderTakenByAnother =>
      'Kechirasiz, bu buyurtmani boshqa kuryer allaqachon qabul qilgan';

  @override
  String driverAcceptOrderFailed(String error) {
    return 'Buyurtmani qabul qilib bo‘lmadi: $error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return 'Joylashuvingizni mijozga yuborib bo‘lmadi: $error (kod: $code)';
  }

  @override
  String get driverLocationSendNotAssigned =>
      'Joylashuvingizni mijozga yuborib bo‘lmadi: buyurtma sizga biriktirilmagan yoki endi yetkazilmayapti';

  @override
  String get driverGpsDisabled =>
      'Joylashuv xizmati (GPS) o‘chirilgan, mijoz sizni kuzata olishi uchun uni yoqing';

  @override
  String get driverLocationPermissionDeniedForever =>
      'Joylashuv ruxsati rad etilgan, mijoz sizni kuzata olishi uchun uni ilova sozlamalarida yoqing';

  @override
  String get driverLocationPermissionDenied =>
      'Joylashuvga ruxsat berilmadi, mijoz buyurtmani kuzata olmaydi';

  @override
  String get driverOpenGoogleMapsFailed =>
      'Bu qurilmada Google Xaritalarni ochib bo‘lmadi';

  @override
  String get driverMapAndLocationTitle => 'Xarita va joylashuv';

  @override
  String get driverStartNavigation => 'Navigatsiyani boshlash';

  @override
  String get listSeparator => ', ';

  @override
  String get storeCityName => 'Nasr Siti';

  @override
  String get addressDefaultTitle => 'Manzil';

  @override
  String get addressLabelOther => 'Boshqa';

  @override
  String addressBuildingLine(String building) {
    return '$building-bino';
  }

  @override
  String addressFloorAptLine(String floor) {
    return 'Qavat/xonadon $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return 'Mo‘ljal: $landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return 'Manzilni saqlab bo‘lmadi: $error';
  }

  @override
  String get addressLocationSaveFailed => 'Manzil joylashuvini saqlab bo‘lmadi';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return 'Manzil joylashuvini saqlab bo‘lmadi: $error';
  }

  @override
  String get locationServiceDisabled =>
      'Joylashuv xizmati (GPS) o‘chirilgan. Uni yoqing va qayta urinib ko‘ring';

  @override
  String get locationPermissionDenied =>
      'Joylashuvga ruxsat berilmadi. Xaritani qo‘lda surishingiz mumkin';

  @override
  String get locationPermissionDeniedForever =>
      'Joylashuv ruxsati rad etilgan. Uni ilova sozlamalarida yoqing';

  @override
  String get currentLocationUnavailable =>
      'Joriy joylashuvingizni aniqlab bo‘lmadi, qayta urinib ko‘ring';

  @override
  String get mapAddressReadFailed => 'Xaritadan manzilni aniqlab bo‘lmadi';

  @override
  String get addressesEmptyTitle => 'Hali saqlangan manzillar yo‘q';

  @override
  String get addressesEmptyHint =>
      'Buyurtmalaringiz tez yetkazilishi uchun manzilingizni qo‘shing';

  @override
  String get addressesLoadFailed => 'Manzillarni yuklab bo‘lmadi';

  @override
  String get signInToManageAddresses =>
      'Manzillaringizni boshqarish uchun hisobga kiring';

  @override
  String get addressDeleteTitle => 'Manzilni o‘chirish';

  @override
  String addressDeleteConfirm(String title) {
    return '«$title» manzili o‘chirilsinmi?';
  }

  @override
  String get addressDeleteFailed => 'Manzilni o‘chirib bo‘lmadi';

  @override
  String addressSaved(String title) {
    return '«$title» manzili saqlandi';
  }

  @override
  String get addressPickerTitle => 'Yetkazib berish manzilini tanlang';

  @override
  String get addressPickerEmpty =>
      'Saqlangan manzillar yo‘q. Birinchi manzilingizni qo‘shing';

  @override
  String get addressDetailsTitle => 'Manzil tafsilotlari';

  @override
  String get addressTitleLabel => 'Manzil nomi';

  @override
  String get addressTitleHint => 'Masalan: Uy, Ish';

  @override
  String get addressAreaLabel => 'Hudud';

  @override
  String get addressAreaHint => 'Masalan: Nasr Siti, 6-mavze';

  @override
  String get addressStreetLabel => 'Ko‘cha';

  @override
  String get addressBuildingNumberLabel => 'Bino raqami';

  @override
  String get addressFloorAptLabel => 'Qavat / xonadon';

  @override
  String get addressLandmarkLabel => 'Mo‘ljal';

  @override
  String get addressLandmarkHint => 'Masalan: masjid yonida...';

  @override
  String get addressSaveButton => 'Manzilni saqlash';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label (ixtiyoriy)';
  }

  @override
  String get addressFieldRequired => 'Bu maydon majburiy';

  @override
  String get addressReviewAndComplete =>
      'Manzilni tekshiring va qolgan ma’lumotlarni to‘ldiring.';

  @override
  String get mapAddressReadFailedFillManually =>
      'Xaritadan manzilni aniqlab bo‘lmadi. Iltimos, ma’lumotlarni qo‘lda to‘ldiring.';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return 'Filialdan $distance · Yetkazib berish $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return 'Bu joy $distance uzoqlikda, yetkazib berish hududidan tashqarida ($maxDistance gacha).';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return '$distance uzoqlikda, yetkazib berish hududidan tashqarida';
  }

  @override
  String get mapPinHint =>
      'Belgini aynan yetkazib berish joyiga qo‘yish uchun xaritani suring';

  @override
  String get mapMyCurrentLocation => 'Joriy joylashuvim';

  @override
  String get mapConfirmLocation => 'Joylashuvni tasdiqlash';

  @override
  String get mapSetDeliveryLocation => 'Yetkazib berish joyini belgilang';

  @override
  String get myOrdersLoadFailed => 'Buyurtmalaringizni yuklab bo‘lmadi';

  @override
  String get myOrdersEmptyTitle => 'Hali buyurtmalar yo‘q';

  @override
  String get myOrdersEmptySubtitle =>
      'Xarid qilishni boshlang, buyurtmalaringiz shu yerda ko‘rinadi';

  @override
  String get orderStatusReceivedLong => 'Buyurtma qabul qilindi';

  @override
  String get orderStatusPreparingInWarehouse => 'Omborda tayyorlanmoqda';

  @override
  String get orderStatusAwaitingDriver => 'Kuryer kutilmoqda';

  @override
  String get orderStatusReadyShort => 'Tayyor';

  @override
  String get orderStepReceived => 'Qabul qilindi';

  @override
  String get orderStepPreparing => 'Tayyorlanmoqda';

  @override
  String orderCardStatusLine(String status) {
    return 'Buyurtma holati: $status';
  }

  @override
  String get orderCardTrackOnMap => 'Buyurtmani xaritada kuzatish';

  @override
  String trackingTitle(String id) {
    return '#$id buyurtmani kuzatish';
  }

  @override
  String get trackingYourAddressMarker => 'Manzilingiz';

  @override
  String get trackingDriverMarker => 'Kuryer';

  @override
  String get trackingOrderDelivered =>
      'Buyurtmangiz yetkazildi. Yoqimli ishtaha!';

  @override
  String get trackingDriverLocationLive =>
      'Kuryer joylashuvi xaritada jonli yangilanadi';

  @override
  String get trackingDriverLocating =>
      'Kuryer joylashuvi aniqlanmoqda… u tez orada xaritada paydo bo‘ladi';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return 'Hisobingiz yaratildi! $email manziliga tasdiqlash havolasini yubordik. Elektron pochtangizni tasdiqlang, so‘ng hisobga kiring.';
  }

  @override
  String get authFullNameLabel => 'To‘liq ism';

  @override
  String get authEnterFullName => 'To‘liq ismingizni kiriting';

  @override
  String get authEnterValidEmail =>
      'To‘g‘ri elektron pochta manzilini kiriting';

  @override
  String get authEnterValidEgyptianPhone =>
      'To‘g‘ri Misr telefon raqamini kiriting (11 ta raqam)';

  @override
  String get authPassword => 'Parol';

  @override
  String get authShowPassword => 'Parolni ko‘rsatish';

  @override
  String get authHidePassword => 'Parolni yashirish';

  @override
  String get authPasswordMinLength =>
      'Parol kamida 6 ta belgidan iborat bo‘lishi kerak';

  @override
  String get authSignInButton => 'Kirish';

  @override
  String get authCreateAccountButton => 'Hisob yaratish';

  @override
  String get authNoAccountPrompt => 'Hisobingiz yo‘qmi? ';

  @override
  String get authHaveAccountPrompt => 'Hisobingiz bormi? ';

  @override
  String get authCreateNewAccountLink => 'Yangi hisob yarating';

  @override
  String get authSignInLink => 'Kirish';

  @override
  String get authWelcomeBack => 'Qaytganingizdan xursandmiz!';

  @override
  String get authJoinSafeerMarket => 'Safeer Marketga qo‘shiling';

  @override
  String get authSignInSubtitle =>
      'Buyurtmangizni yakunlash uchun hisobga kiring';

  @override
  String get authSignUpSubtitle =>
      'Hisob yarating va Safeer takliflaridan bahramand bo‘ling';

  @override
  String get authNewAccountTab => 'Yangi hisob';

  @override
  String get authEmailAlreadyRegistered =>
      'Bu elektron pochta allaqachon ro‘yxatdan o‘tgan';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return 'Hisobingiz yaratildi, lekin ma’lumotlaringizni saqlab bo‘lmadi: $error';
  }

  @override
  String get authInvalidCredentials => 'Elektron pochta yoki parol noto‘g‘ri';

  @override
  String get authEmailNotConfirmed =>
      'Iltimos, avval sizga yuborilgan xabar orqali elektron pochtangizni tasdiqlang';

  @override
  String get authWeakPassword =>
      'Parol juda oddiy, kamida 6 ta belgidan foydalaning';

  @override
  String get authTooManyAttempts =>
      'Urinishlar juda ko‘p, birozdan so‘ng qayta urinib ko‘ring';

  @override
  String get editProfileSignInPrompt =>
      'Ma’lumotlaringizni tahrirlash uchun hisobga kiring';

  @override
  String get profileSavedSuccessfully =>
      'Ma’lumotlaringiz muvaffaqiyatli saqlandi';

  @override
  String get profileFullNameLabel => 'To‘liq ism';

  @override
  String get profileEnterFullName => 'To‘liq ismingizni kiriting';

  @override
  String get profileEnterValidPhone => 'To‘g‘ri Misr telefon raqamini kiriting';

  @override
  String get profileSaveChanges => 'O‘zgarishlarni saqlash';

  @override
  String profileSaveFailed(String error) {
    return 'Ma’lumotlaringizni saqlab bo‘lmadi: $error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return 'Bildirishnoma tokenini saqlab bo‘lmadi: $error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature tez orada ishga tushadi';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ball',
      one: '$count ball',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => 'O‘yinlar';

  @override
  String get rewardsGamesSubtitle => 'O‘ynang va sodiqlik ballarini to‘plang';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return 'Yana $countdown dan keyin ochiladi';
  }

  @override
  String get scratchCardTitle => 'Scratch karta — artib yuting';

  @override
  String get scratchCardSubtitle => 'Qoplamani artib ball yuting';

  @override
  String get scratchCardHint =>
      'Mukofotingizni ko‘rish uchun kulrang qatlamni artíng';

  @override
  String scratchWonPoints(String points) {
    return '$points ball yutdingiz!';
  }

  @override
  String get scratchBetterLuck => 'Keyingi safar omad';

  @override
  String get luckyChestTitle => 'Kundalik omad sandig‘i — oching';

  @override
  String get luckyChestSubtitle => 'Sandiqni ochib 10 ballgacha yuting';

  @override
  String get luckyChestHint => 'Mukofotni ko‘rish uchun sandiqni bosing';

  @override
  String get luckyChestTapToOpen => 'Ochish uchun bosing';

  @override
  String get luckyChestOpened => 'Bugungi sandiq ochilgan';

  @override
  String luckyChestWonPoints(String points) {
    return 'Sandiqdan $points ball yutdingiz!';
  }

  @override
  String get rewardsWheelCardSubtitle =>
      'G‘ildirakni aylantiring va 100 ballgacha yutib oling';

  @override
  String get rewardsPuzzleCardSubtitle =>
      'Logotipni qayta yig‘ing va 50 ball yutib oling';

  @override
  String get loyaltyCurrentBalance => 'Joriy balansingiz';

  @override
  String get loyaltySignInToSeePoints =>
      'Ballaringizni ko‘rish uchun hisobga kiring';

  @override
  String get loyaltyLoadFailedRetry => 'Yuklab bo‘lmadi — Qayta urinish';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return 'Sodiqlik ballarini yuklab bo‘lmadi: $error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return 'Sodiqlik ballarini yangilab bo‘lmadi: $error';
  }

  @override
  String get wheelPrizeTryAgain => 'Yana urinib ko‘ring';

  @override
  String get wheelSpinCollectLoyaltyPoints =>
      'G‘ildirakni aylantiring va sodiqlik ballarini to‘plang';

  @override
  String get wheelSignInToPlay => 'O‘ynash uchun hisobga kiring';

  @override
  String get wheelSpinning => 'Aylanmoqda...';

  @override
  String get wheelSpin => 'G‘ildirakni aylantirish';

  @override
  String get wheelCongrats => 'Tabriklaymiz!';

  @override
  String get wheelTryAgainTitle => 'Yana urinib ko‘ring';

  @override
  String wheelWonPrize(String prize) {
    return 'Siz $prize yutdingiz, u sodiqlik balansingizga qo‘shildi.';
  }

  @override
  String get wheelNoPointsThisTime =>
      'Bu safar ball yo‘q. Keyingi aylantirishda omad tilaymiz!';

  @override
  String puzzleMoves(String moves) {
    return 'Yurishlar: $moves';
  }

  @override
  String puzzlePrize(String points) {
    return 'Sovrin: $points ball';
  }

  @override
  String puzzleSavePoints(String points) {
    return '$points ballni saqlash';
  }

  @override
  String get puzzleShuffle => 'Bo‘laklarni aralashtirish';

  @override
  String get puzzleOutOfMoves =>
      'Keyingi safar omad! Barcha harakatlaringiz tugadi.';

  @override
  String get puzzleCongrats => 'Tabriklaymiz!';

  @override
  String puzzleEarnedPoints(String points) {
    return 'Siz $points ball yutdingiz 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance =>
      'Ballar sodiqlik balansingizga qo‘shildi.';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return 'Tabriklaymiz! Siz $points ball yutdingiz 🎉';
  }

  @override
  String get puzzleSignInToAddPoints =>
      'Ularni balansingizga qo‘shishimiz uchun hisobga kiring.';

  @override
  String get puzzleGoalTitle => 'Logotipni qayta yig‘ing';

  @override
  String get puzzleGoalDescription =>
      'Logotip rasmdagidek bo‘lguncha bo‘sh joy yonidagi bo‘laklarni suring';

  @override
  String get unitCarton => 'karton';

  @override
  String get unitBox => 'quti';

  @override
  String get unitBag => 'xalta';

  @override
  String get unitPack => 'pachka';

  @override
  String get cartTitle => 'Xarid savati';

  @override
  String get clearCart => 'Savatni bo‘shatish';

  @override
  String cartSubtotalWithCount(String count) {
    return 'Oraliq jami ($count ta mahsulot)';
  }

  @override
  String get cartDeliveryFeeNextStep =>
      'Yetkazib berish narxi keyingi bosqichda hisoblanadi';

  @override
  String get cartContinueOrder => 'Rasmiylashtirishga o‘tish';

  @override
  String get cartEmptySubtitle =>
      'Sevimli mahsulotlaringizni qo‘shing va xarid qilishni boshlang';

  @override
  String get cartSaveDeliveryFeesTitle => 'Yetkazib berishda tejang! 💡';

  @override
  String get cartPrimeUpsellSubtitle =>
      'Safeer Prime obunasini atigi 90 EGP ga oling.';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return '$weight $product savatga qo‘shildi';
  }

  @override
  String cartAddedProduct(String product) {
    return '$product savatga qo‘shildi';
  }

  @override
  String get viewCart => 'Savatni ko‘rish';

  @override
  String get removeFromCart => 'Savatdan olib tashlash';

  @override
  String get chooseWeight => 'Vaznni tanlang';

  @override
  String pricePerKilo(String price) {
    return '1 kg uchun $price';
  }

  @override
  String get weightPickerPrice => 'Narx';

  @override
  String get updateWeight => 'Vaznni yangilash';

  @override
  String get homeNotificationsTooltip => 'Bildirishnomalar';

  @override
  String get homeSearchHint => 'Mahsulot yoki brendni qidiring';

  @override
  String homeDeliveringTo(String city) {
    return 'Yetkazib berish · $city';
  }

  @override
  String get homeChooseYourAddress => 'Manzilingizni tanlang';

  @override
  String get homeMyAccountTooltip => 'Mening hisobim';

  @override
  String get homeSignedInSuccessfully => 'Hisobga muvaffaqiyatli kirdingiz';

  @override
  String get homeDeliveryEta => '30 - 45 daqiqada yetkazib berish';

  @override
  String get quickActionLatestProducts => 'Eng yangi mahsulotlar';

  @override
  String get quickActionOffers => 'Takliflar';

  @override
  String get quickActionPlayAndWin => 'O‘yna va yut';

  @override
  String get promoEndlessOffersTitle => 'Safeer takliflari tugamaydi';

  @override
  String get promoEndlessOffersSubtitle =>
      'Yuzlab mahsulotlarga kundalik chegirmalar';

  @override
  String get promoSavingsStoreTitle => 'Safeer... tejamkorlik do‘koni';

  @override
  String get promoSavingsStoreSubtitle =>
      'Butun uy uchun har kuni arzonroq narxlar';

  @override
  String get promoOpeningDiscountsTitle => 'Ochilish chegirmalari';

  @override
  String get promoOpeningDiscountsSubtitle =>
      'Birinchi buyurtmaga 30% gacha chegirma';

  @override
  String get promoFreeDeliveryTitle => 'Bepul yetkazib berish';

  @override
  String get promoFreeDeliverySubtitle => '300 EGP dan ortiq buyurtmalarga';

  @override
  String offerDiscountPercent(String percent) {
    return '$percent% chegirma';
  }

  @override
  String get offerBadge => 'Aksiya';

  @override
  String get favoritesSignInPrompt =>
      'Sevimli mahsulotlaringizni saqlash uchun hisobga kiring';

  @override
  String get favoritesLoadFailed => 'Sevimlilarni yuklab bo‘lmadi';

  @override
  String get favoritesEmptyTitle => 'Hali sevimli mahsulotlar yo‘q';

  @override
  String get favoritesEmptySubtitle =>
      'Mahsulotni shu yerda saqlash uchun undagi ♡ belgisini bosing';

  @override
  String get favoritesUpdateFailed =>
      'Sevimlilarni yangilab bo‘lmadi, qayta urinib ko‘ring';

  @override
  String get removeFromFavorites => 'Sevimlilardan olib tashlash';

  @override
  String get addToFavorites => 'Sevimlilarga qo‘shish';

  @override
  String get magazinesLoadFailed => 'Jurnallarni yuklab bo‘lmadi';

  @override
  String get noMagazinesCurrently => 'Hozircha jurnallar yo‘q';

  @override
  String get magazineNoPdf => 'Bu jurnalda PDF fayl yo‘q';

  @override
  String get magazineOpenFailed =>
      'Jurnalni ochib bo‘lmadi. Keyinroq qayta urinib ko‘ring.';

  @override
  String get magazinePreviousPage => 'Oldingi sahifa';

  @override
  String get magazineNextPage => 'Keyingi sahifa';

  @override
  String magazinePageOf(String page, String count) {
    return '$page/$count-sahifa';
  }

  @override
  String get authWelcomeTitle => 'Safeer Marketga xush kelibsiz';

  @override
  String get authWelcomeSubtitle =>
      'Bir necha soniyada kiring yoki hisob yarating';

  @override
  String get authContinueWithGoogle => 'Google orqali davom etish';

  @override
  String get authContinueWithPhone => 'Telefon raqami orqali davom etish';

  @override
  String get authContinueWithEmail => 'Elektron pochta orqali davom etish';

  @override
  String get authOr => 'yoki';

  @override
  String get authOtherSignInOptions => 'Kirishning boshqa usullari';

  @override
  String get authTermsNotice =>
      'Davom etish orqali siz maxfiylik siyosati va shartlarga rozilik bildirasiz';

  @override
  String get authGoogleFailed =>
      'Google orqali kirib bo‘lmadi, qayta urinib ko‘ring';

  @override
  String get authProviderUnavailable => 'Bu kirish usuli hozircha mavjud emas';

  @override
  String get authOtpInvalid => 'Kod noto‘g‘ri yoki muddati tugagan';

  @override
  String get authSmsSendFailed =>
      'Tasdiqlash SMS yuborilmadi, raqamni tekshirib qayta urinib ko‘ring';

  @override
  String get authPhoneSheetTitle => 'Telefon orqali kirish';

  @override
  String get authPhoneSheetSubtitle =>
      'Sizga 6 xonali tasdiqlash kodini SMS orqali yuboramiz';

  @override
  String get authSendCode => 'Kodni yuborish';

  @override
  String get authEnterCodeTitle => 'Tasdiqlash kodini kiriting';

  @override
  String authCodeSentTo(String phone) {
    return 'Kodni $phone raqamiga SMS orqali yubordik';
  }

  @override
  String get authVerifyCode => 'Kodni tasdiqlash';

  @override
  String get authEnterSixDigitCode => '6 xonali kodni kiriting';

  @override
  String get authResendCode => 'Kodni qayta yuborish';

  @override
  String authResendCodeIn(String seconds) {
    return '$seconds soniyadan keyin qayta yuborish';
  }

  @override
  String get authChangeNumber => 'Raqamni o‘zgartirish';

  @override
  String get authCodeResent => 'Yangi kod yuborildi';

  @override
  String get productNoImageBadge => 'Rasmsiz';

  @override
  String newProductsMissingImageCount(String count) {
    return 'Yangi mahsulotlar (rasmsiz: $count)';
  }

  @override
  String missingImageCountBadge(String count) {
    return 'Rasmsiz: $count';
  }

  @override
  String get productImageSaveBlocked =>
      'Rasm yuklandi, lekin mahsulotga saqlanmadi: mahsulotlarni tahrirlashga ruxsat berilmadi. Supabase’dagi administrator ruxsatlarini tekshiring.';

  @override
  String get authPhoneLoginDisabled =>
      'Telefon orqali kirish hozircha mavjud emas, Google yoki elektron pochtadan foydalaning';

  @override
  String get onboardingLanguageTitle => 'Tilni tanlang';

  @override
  String get onboardingLanguageSubtitle =>
      'Uni istalgan vaqtda Sozlamalarda o‘zgartirishingiz mumkin';

  @override
  String get onboardingAppearanceTitle => 'Ilova ko‘rinishini tanlang';

  @override
  String get onboardingAppearanceSubtitle =>
      'Yorug‘, qorong‘i yoki qurilmangizga mos';

  @override
  String get onboardingAccountTitle => 'To‘liq imkoniyatlar uchun kiring';

  @override
  String get onboardingAccountSubtitle =>
      'Buyurtma bering, buyurtmalarni kuzating, manzil va sevimlilarni saqlang';

  @override
  String get onboardingNext => 'Keyingi';

  @override
  String get onboardingSignInOrRegister => 'Kirish yoki hisob yaratish';

  @override
  String get onboardingBrowseFirst => 'Avval ilovani ko‘rib chiqish';

  @override
  String get appearance => 'Ko‘rinish';

  @override
  String get themeSystem => 'Tizim';

  @override
  String get themeDark => 'Qorong‘i';

  @override
  String get themeLight => 'Yorug‘';

  @override
  String get settingsAccountSection => 'Hisob';

  @override
  String get guestSignInTitle => 'Davom etish uchun kiring';

  @override
  String get guestCartMessage =>
      'Savatga mahsulot qo‘shish va buyurtma berish uchun kiring yoki hisob yarating.';

  @override
  String get guestProfileMessage =>
      'Ma’lumotlaringiz, buyurtmalaringiz, manzillaringiz va sevimlilaringizni ko‘rish uchun kiring.';

  @override
  String get notNow => 'Hozir emas';

  @override
  String get unitSet => 'to‘plam';

  @override
  String unitBoxOf(String count) {
    return '$count donalik quti';
  }

  @override
  String get paywallSignInToSubscribe =>
      'Safeer tarifiga obuna bo‘lish uchun kiring';

  @override
  String get paymentChooseMethod => 'To‘lov usulini tanlang';

  @override
  String get paymentMethodCard => 'Bank kartasi (Visa / Mastercard / Meeza)';

  @override
  String get paymentMethodWallet => 'Mobil hamyon (Vodafone Cash va boshqalar)';

  @override
  String get paymentWalletPhoneLabel => 'Hamyon raqami';

  @override
  String get paymentWalletPhoneInvalid =>
      '01 bilan boshlanadigan to‘g‘ri hamyon raqamini kiriting';

  @override
  String get paymentContinue => 'Davom etish';

  @override
  String get paymentStartFailed =>
      'To‘lovni boshlab bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get paymentMethodUnavailable => 'Bu to‘lov usuli hozircha mavjud emas';

  @override
  String get paymentPageOpenFailed => 'To‘lov sahifasini ochib bo‘lmadi';

  @override
  String get paymentVerifying => 'To‘lov tekshirilmoqda…';

  @override
  String get paymentFailedMessage =>
      'To‘lov amalga oshmadi. Qayta urinib ko‘rishingiz mumkin.';

  @override
  String get paymentStillProcessing =>
      'To‘lov tasdig‘i hali yakunlanmadi. Buyurtma holatini Buyurtmalarimdan tekshirishingiz mumkin.';

  @override
  String get subscriptionActivatedTitle =>
      'Obuna muvaffaqiyatli faollashtirildi 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return '$plan tarifi $date gacha faol';
  }

  @override
  String get subscriptionContinueShopping => 'Xaridni davom ettirish';

  @override
  String get redeemPoints => 'Ballarni almashtirish';

  @override
  String get redeemQrTitle => 'Ushbu kodni kassirga ko‘rsating';

  @override
  String get redeemQrSubtitle =>
      'Har 50 ball = 1 EGP chegirma. Chegirma qo‘llangach kod o‘zi yopiladi.';

  @override
  String get redeemSuccess => 'Chegirma muvaffaqiyatli qo‘llandi';

  @override
  String get scanCustomerCode => 'Mijoz kodini skanerlash';

  @override
  String get scanCustomerHint => 'Kamerani mijoz kodiga qarating';

  @override
  String get scanInvalidCode => 'Bu Safeer Market mijoz kodi emas';

  @override
  String scanCameraFailed(String error) {
    return 'Kamerani ishga tushirib bo‘lmadi: $error';
  }

  @override
  String get redeemInsufficientPoints =>
      '1 EGP chegirma uchun ball yetarli emas';

  @override
  String get redeemNotAllowed =>
      'Bu hisobga ballarni almashtirishga ruxsat yo‘q';

  @override
  String get redeemCustomerNotFound => 'Mijoz topilmadi';

  @override
  String redeemFailed(String error) {
    return 'Ballarni almashtirib bo‘lmadi: $error';
  }

  @override
  String get cashierRedeemTitle => 'Sodiqlik ballarini almashtirish';

  @override
  String get cashierCustomer => 'Mijoz';

  @override
  String get cashierCurrentBalance => 'Joriy balans';

  @override
  String get cashierPointsToDeduct => 'Ayiriladigan ballar';

  @override
  String get cashierDiscount => 'Chegirma';

  @override
  String get cashierRemainingPoints => 'Keyingi balans';

  @override
  String get cashierBarcodeHint =>
      'Bu shtrix-kodni kassada skanerlang, so‘ng tasdiqlang';

  @override
  String get confirmPointsDeduction => 'Ballarni ayirishni tasdiqlash';

  @override
  String cashierRedeemDone(String points, String amount) {
    return '$points ball almashtirildi ($amount chegirma)';
  }

  @override
  String get phoneOrdersTitle => 'Telefon buyurtmalari / Mijoz qidiruvi';

  @override
  String get phoneOrderOpen => 'Telefon buyurtmasi';

  @override
  String get phoneOrderSearchHint =>
      'Telefon raqami yoki mijoz ismi bo‘yicha qidirish...';

  @override
  String get phoneOrderNewCustomer => '+ Yangi mijoz';

  @override
  String get phoneOrderTypeToSearch =>
      'Qidirish uchun telefon raqami yoki ismni yozing';

  @override
  String get phoneOrderNoCustomers =>
      'Mos mijoz yo‘q. Uni yangi mijoz sifatida qo‘shing.';

  @override
  String get phoneOrderAppCustomer => 'Ilova foydalanuvchisi';

  @override
  String get phoneOrderPosCustomer => 'Kassa mijozi';

  @override
  String get phoneOrderNoAddress => 'Saqlangan manzil yo‘q';

  @override
  String get phoneOrderChangeCustomer => 'Mijozni almashtirish';

  @override
  String get phoneOrderCustomerName => 'Mijoz ismi';

  @override
  String get phoneOrderCustomerPhone => 'Telefon raqami';

  @override
  String get phoneOrderCustomerAddress => 'Manzil';

  @override
  String get phoneOrderCustomerZone => 'Hudud';

  @override
  String get phoneOrderSaveCustomer => 'Mijozni saqlash';

  @override
  String get phoneOrderNameRequired => 'Mijoz ismini kiriting';

  @override
  String get phoneOrderPhoneInvalid =>
      'To‘g‘ri Misr mobil raqamini kiriting (01XXXXXXXXX)';

  @override
  String get phoneOrderProductSearchHint =>
      'Mahsulot nomi yoki shtrix-kod bo‘yicha qidirish...';

  @override
  String get phoneOrderSearchProductsPrompt =>
      'Mahsulotni nomi yoki shtrix-kodi bo‘yicha qidiring';

  @override
  String get phoneOrderNoProducts => 'Mos mahsulotlar yo‘q';

  @override
  String get phoneOrderCartTitle => 'Mijoz savati';

  @override
  String get phoneOrderCartEmpty => 'Hali mahsulot qo‘shilmagan';

  @override
  String get phoneOrderItemsTotal => 'Mahsulotlar jami';

  @override
  String get phoneOrderTotal => 'Jami';

  @override
  String get phoneOrderFreeDelivery => 'Bepul';

  @override
  String get phoneOrderConfirm => 'Tasdiqlash va buyurtma berish';

  @override
  String phoneOrderPlaced(String id) {
    return '#$id buyurtma qayd etildi';
  }

  @override
  String phoneOrderFailed(String error) {
    return 'Buyurtmani qayd etib bo‘lmadi: $error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return 'Qidiruv amalga oshmadi: $error';
  }

  @override
  String get phoneOrderNotAllowed =>
      'Bu hisobga telefon buyurtmalarini qabul qilishga ruxsat yo‘q';

  @override
  String get phoneOrderBadge => 'Telefon';

  @override
  String phoneOrderSetupMissing(String function) {
    return '$function funksiyasi maʼlumotlar bazasida yo‘q. Supabase SQL Editor’da supabase/migrations/20261111010000_phone_orders.sql faylini ishga tushiring.';
  }

  @override
  String get adminToggleMenu => 'Menyuni ko‘rsatish/yashirish';

  @override
  String get adminResizeColumn => 'Ustun kengligini o‘zgartirish uchun torting';

  @override
  String get phoneOrderShowCart => 'Savat va yetkazishni ko‘rsatish';

  @override
  String get phoneOrderHideCart => 'Savatni yashirish';

  @override
  String get driverDeliveryAddress => 'Yetkazib berish manzili';

  @override
  String get driverNavigateViaMap => 'Xarita orqali yo‘nalish';

  @override
  String get mapSearchHint => 'Hudud yoki ko‘chani qidiring...';

  @override
  String get mapSearchNoResults => 'Hech narsa topilmadi';

  @override
  String mapSearchFailed(String error) {
    return 'Joyni qidirib bo‘lmadi: $error';
  }

  @override
  String get mapSearchClear => 'Qidiruvni tozalash';

  @override
  String get supportLiveChatSubtitle =>
      'Ilovada bizga yozing, jamoamiz darhol javob beradi';

  @override
  String get supportSignInMessage =>
      'Mijozlarga xizmat bilan chat boshlash uchun tizimga kiring.';

  @override
  String supportLaunchFailed(String phone) {
    return 'Ilovani ochib bo‘lmadi. Bizga $phone raqamiga qo‘ng‘iroq qilishingiz mumkin';
  }

  @override
  String get supportChatTitle => 'Mijozlarga xizmat';

  @override
  String get supportChatSubtitle =>
      'Safeer Market jamoasi shu yerda javob beradi';

  @override
  String get supportChatWelcome =>
      'Xush kelibsiz! Savolingiz yoki muammoingizni yozing, mijozlarga xizmat jamoasi imkon qadar tez javob beradi.';

  @override
  String get supportMessageHint => 'Xabaringizni yozing...';

  @override
  String supportLoadFailed(String error) {
    return 'Chatni yuklab bo‘lmadi: $error';
  }

  @override
  String get supportSetupMissing =>
      'Jonli chat hali sozlanmagan. Supabase SQL Editor’da supabase/migrations/20261114210000_support_chat.sql faylini ishga tushiring.';

  @override
  String get supportNotAllowed => 'Bu chatga kirish huquqingiz yo‘q';

  @override
  String supportRequestFailed(String error) {
    return 'So‘rovni bajarib bo‘lmadi: $error';
  }

  @override
  String get supportCenterTitle => 'Shikoyatlar va chatlar';

  @override
  String get supportNoChats => 'Hozircha ochiq chatlar yo‘q';

  @override
  String get supportSelectChat =>
      'Mijozga javob berish uchun ro‘yxatdan chat tanlang';

  @override
  String get supportNoMessagesYet => 'Bu chatda hali xabarlar yo‘q';

  @override
  String get supportReplyHint => 'Mijozga javobingizni yozing...';

  @override
  String get supportLatestOrders => 'So‘nggi buyurtmalar';

  @override
  String supportLatestOrdersTitle(String name) {
    return '${name}ning so‘nggi buyurtmalari';
  }

  @override
  String get supportNoOrders => 'Bu mijozning buyurtmalari yo‘q';

  @override
  String supportNewMessageToast(String name, String message) {
    return '${name}dan yangi xabar: $message';
  }

  @override
  String get supportOpenChat => 'Chatni ochish';

  @override
  String get notificationsTitle => 'Bildirishnomalar';

  @override
  String get notificationsEmptySubtitle =>
      'Safeer Market’da yangi aksiyalar yoki jurnallar chiqishi bilan sizga xabar beramiz';

  @override
  String notificationsLoadFailed(String error) {
    return 'Bildirishnomalarni yuklab bo‘lmadi: $error';
  }

  @override
  String get notificationsSetupMissing =>
      'Bildirishnomalar hali sozlanmagan. Supabase SQL Editor’da supabase/migrations/20261114220000_app_notifications.sql faylini ishga tushiring.';

  @override
  String get notificationsNotAllowed =>
      'Bildirishnomalarni yuborish va o‘chirish faqat administrator uchun';

  @override
  String get timeJustNow => 'Hozirgina';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daqiqa oldin',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soat oldin',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun oldin',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => 'Umumiy';

  @override
  String get notificationTypePromo => 'Aksiya va chegirmalar';

  @override
  String get notificationTypeMagazine => 'Yangi jurnal';

  @override
  String get notificationTypeOrder => 'Buyurtmalaringiz';

  @override
  String get notificationTypeSupportChat => 'Mijozlar xizmati';

  @override
  String get adminSendNotifications => 'Bildirishnoma yuborish';

  @override
  String get adminNotificationFormSubtitle =>
      'Barcha mijozlar ilovasida darhol ko‘rinadi';

  @override
  String get adminNotificationTitleLabel => 'Bildirishnoma sarlavhasi';

  @override
  String get adminNotificationTitleHint =>
      'Masalan: Oyning aksiyalar jurnali chiqdi! 🔥';

  @override
  String get adminNotificationTitleRequired =>
      'Bildirishnoma sarlavhasini yozing';

  @override
  String get adminNotificationBodyLabel => 'Bildirishnoma matni';

  @override
  String get adminNotificationBodyHint =>
      'Masalan: Safeer Market’dagi eng so‘nggi eksklyuziv chegirmalarni ko‘ring';

  @override
  String get adminNotificationBodyRequired => 'Bildirishnoma matnini yozing';

  @override
  String get adminNotificationTypeLabel => 'Bildirishnoma turi';

  @override
  String get adminNotificationImageLabel => 'Rasm havolasi - ixtiyoriy';

  @override
  String get adminNotificationImageInvalid =>
      'https:// bilan boshlanadigan to‘g‘ri havola kiriting';

  @override
  String get adminSendNotificationButton => 'Barcha mijozlarga yuborish';

  @override
  String get adminNotificationSent =>
      'Bildirishnoma barcha mijozlarga yuborildi';

  @override
  String adminNotificationSendFailed(String error) {
    return 'Bildirishnomani yuborib bo‘lmadi: $error';
  }

  @override
  String get adminNotificationsHistory => 'Yuborilgan bildirishnomalar';

  @override
  String get adminNoNotificationsSent => 'Hali bildirishnoma yuborilmagan';

  @override
  String get adminDeleteNotificationTitle => 'Bildirishnomani o‘chirish';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return '«$title» bildirishnomasini o‘chirasizmi? U mijozlar ilovasidan yo‘qoladi.';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return 'Bildirishnomani o‘chirib bo‘lmadi: $error';
  }

  @override
  String get orderCardShowDetails => 'Batafsil';

  @override
  String get orderCardHideDetails => 'Yashirish';

  @override
  String get orderCardItemsTitle => 'Buyurtma mahsulotlari';

  @override
  String get orderCardItemsFailed => 'Buyurtma mahsulotlarini yuklab bo‘lmadi';

  @override
  String get orderCardNoItems => 'Bu buyurtmada mahsulotlar yo‘q';

  @override
  String get orderCardCancelledNote => 'Bu buyurtma bekor qilindi';

  @override
  String get cancelOrder => 'Buyurtmani bekor qilish';

  @override
  String get cancelOrderConfirmTitle =>
      'Buyurtmani bekor qilishni xohlaysizmi?';

  @override
  String get cancelOrderReasonPrompt => 'Bekor qilish sababini tanlang:';

  @override
  String get cancelOrderDismiss => 'Orqaga';

  @override
  String get cancelOrderConfirm => 'Bekor qilishni tasdiqlash';

  @override
  String get cancelReasonDeliveryDelay => 'Yetkazib berish kechikdi';

  @override
  String get cancelReasonOrderedByMistake => 'Xato buyurtma berdim';

  @override
  String get cancelReasonChangedMind => 'Fikrim o‘zgardi';

  @override
  String get cancelReasonOther => 'Boshqa sabab';

  @override
  String cancellationReasonLine(String reason) {
    return 'Bekor qilish sababi: $reason';
  }

  @override
  String get orderCancelledSuccess => 'Buyurtma muvaffaqiyatli bekor qilindi';

  @override
  String get orderCancelTooLate =>
      'Buyurtma tayyor yoki yo‘lda bo‘lgani uchun bekor qilib bo‘lmaydi';

  @override
  String get orderCancelSetupMissing =>
      'Buyurtmani bekor qilish hali sozlanmagan. Supabase SQL Editor’da supabase/migrations/20261114240000_customer_cancel_order.sql faylini ishga tushiring.';

  @override
  String orderCancelFailed(String error) {
    return 'Buyurtmani bekor qilib bo‘lmadi: $error';
  }

  @override
  String get adminMenuReceiveOrders => 'Buyurtmalarni qabul qilish';

  @override
  String get adminMenuOrderStatus => 'Buyurtma holati';

  @override
  String get adminStatusDelayedShort => 'Kechikkan';

  @override
  String get adminStatusCancelledShort => 'Bekor qilingan';

  @override
  String get adminResendNotification => 'Qayta yuborish';

  @override
  String get adminResendFillForm => 'Formani to‘ldirish';

  @override
  String get adminResendNotificationTitle =>
      'Bu bildirishnomani qayta yuborasizmi?';

  @override
  String adminResendNotificationConfirm(String title) {
    return '«$title» bildirishnomasi yana barcha mijozlarga yuboriladi.';
  }

  @override
  String get adminNotificationSearchHint => 'Sarlavha boyicha qidirish';

  @override
  String get adminNotificationFilterByDate => 'Sana boyicha filtrlash';

  @override
  String get adminNotificationFilterByType => 'Tur boyicha filtrlash';

  @override
  String get adminNotificationClearDateFilter => 'Sana filtrini tozalash';

  @override
  String get adminSelectCustomerFirst =>
      'Buyurtmani boshlash uchun mijozni tanlang';
}
