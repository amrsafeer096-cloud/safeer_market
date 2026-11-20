// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kirghiz Kyrgyz (`ky`).
class AppLocalizationsKy extends AppLocalizations {
  AppLocalizationsKy([String locale = 'ky']) : super(locale);

  @override
  String get bannerShopBrandProducts => 'Бул бренддин товарлары';

  @override
  String get bannerAdd => 'Компания баннерин кошуу';

  @override
  String get bannerTitleLabel => 'Компания / баннер аталышы';

  @override
  String get bannerKeywordLabel => 'Компаниянын товарлары үчүн ачкыч сөз';

  @override
  String get bannerKeywordHint => 'мис.: Juhayna';

  @override
  String get bannerChooseImage => 'Баннер сүрөтүн тандоо';

  @override
  String get bannerChangeImage => 'Сүрөтту өзгөртүү';

  @override
  String get bannerImageRequired => 'Адегенде баннер сүрөтүн тандаңыз';

  @override
  String get bannerKeywordRequired =>
      'Компаниянын товарларын ачкан ачкыч сөздү жазыңыз';

  @override
  String get bannerSaved => 'Баннер ийгиликтүү кошулду';

  @override
  String bannerSaveFailed(String error) {
    return 'Баннер сакталган жок: $error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return '«$title» баннерин өчүрөсүзбү?';
  }

  @override
  String get bannerExistingHeader => 'Учурдагы баннерлер';

  @override
  String get appTitle => 'Safeer Market';

  @override
  String get home => 'Башкы бет';

  @override
  String get settings => 'Жөндөөлөр';

  @override
  String get language => 'Тил';

  @override
  String get save => 'Сактоо';

  @override
  String get search => 'Издөө';

  @override
  String get cart => 'Себет';

  @override
  String get wallet => 'Капчык';

  @override
  String get more => 'Дагы';

  @override
  String get exitHint => 'Чыгуу үчүн артка баскычын дагы бир жолу басыңыз';

  @override
  String get newProducts => 'Жаңы товарлар';

  @override
  String get trendingOffers => 'Популярдуу сунуштар';

  @override
  String get noNewNotifications => 'Жаңы билдирмелер жок';

  @override
  String get loadingLatestProducts => 'Эң жаңы товарлар жүктөлүүдө...';

  @override
  String get noNewProductsLast3Days => 'Акыркы 3 күндө жаңы товарлар жок';

  @override
  String get loadingOffers => 'Сунуштар жүктөлүүдө...';

  @override
  String get noOffersCurrently => 'Азырынча сунуштар жок';

  @override
  String get subscribersExclusiveFeature => 'Жазылуучуларга гана 👑';

  @override
  String get playAndWinPaywallBody =>
      '«Ойно жана ут» оюну жана жумалык белектер Safeer Prime жана Safeer Pro жазылуучуларына гана жеткиликтүү. Аккаунтуңузду жаңыртып, мүмкүнчүлүктөрдөн пайдаланыңыз!';

  @override
  String get upgradeAccountNow => 'Аккаунтту азыр жаңыртуу';

  @override
  String get exploreSafeer => 'Safeerди изилдеңиз';

  @override
  String get featuredProducts => 'Тандалган товарлар';

  @override
  String get failedToLoadProducts => 'Товарларды жүктөө мүмкүн болбоду';

  @override
  String get noProductsCurrently => 'Азырынча товарлар жок';

  @override
  String get seeAll => 'Баарын көрүү';

  @override
  String get retry => 'Кайталоо';

  @override
  String get loyaltyPoints => 'Берилгендик упайлары';

  @override
  String get spinWheelCollectPoints => 'Дөңгөлөктү айлантып, упай топтоңуз';

  @override
  String get favoriteProducts => 'Сүйүктүү товарлар';

  @override
  String get myOrders => 'Буйрутмаларым';

  @override
  String get contactUs => 'Биз менен байланышыңыз';

  @override
  String get help => 'Жардам';

  @override
  String get signOut => 'Чыгуу';

  @override
  String get signIn => 'Кирүү';

  @override
  String get signOutConfirmMessage => 'Аккаунтуңуздан чыгасызбы?';

  @override
  String get signedOut => 'Сиз чыктыңыз';

  @override
  String get adminDashboard => 'Админ панели';

  @override
  String get adminDashboardSubtitle =>
      'Кардар буйрутмаларын башкарып, абалын жаңыртыңыз';

  @override
  String get guestName => 'Конок';

  @override
  String welcomeUser(String name) {
    return 'Кош келиңиз, $name';
  }

  @override
  String get guestSubtitle =>
      'Буйрутмалар менен сүйүктүүлөрдү көзөмөлдөө үчүн кириңиз';

  @override
  String get personalData => 'Жеке маалымат';

  @override
  String get email => 'Электрондук почта';

  @override
  String get savedAddresses => 'Сакталган даректер';

  @override
  String get savedCards => 'Сакталган карталар';

  @override
  String get messageAndSmsAlerts => 'Колдонмо жана SMS эскертмелери';

  @override
  String get privacyAndTerms => 'Купуялык саясаты жана шарттар';

  @override
  String get deleteAccount => 'Аккаунтту өчүрүү';

  @override
  String get deleteAccountConfirmMessage =>
      'Аккаунтуңуз жана бардык дайындарыңыз биротоло өчүрүлөт. Ишенесизби?';

  @override
  String get deleteAccountSuccess => 'Аккаунтуңуз ийгиликтүү өчүрүлдү';

  @override
  String get passwordRequirementsTitle => 'Сырсөздө болушу керек:';

  @override
  String get passwordRuleMinLength => 'Кеминде 8 белги';

  @override
  String get passwordRuleUppercase => 'Кеминде 1 баш тамга';

  @override
  String get passwordRuleLowercase => 'Кеминде 1 кичине тамга';

  @override
  String get passwordRuleDigit => 'Кеминде 1 сан';

  @override
  String get talkToUs => 'Биз менен сүйлөшүңүз';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportLiveChat => 'Кардарларды тейлөө менен түз чат';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count упай • Алмаштыруу';
  }

  @override
  String get loyaltyPointsEarnNow => 'Берилгендик упайлары • Азыр топтоңуз 🎁';

  @override
  String get ok => 'Жарайт';

  @override
  String get noEmail => 'Электрондук почта жок';

  @override
  String get changeEmailContactSupport =>
      'Электрондук почтаны өзгөртүү үчүн колдоо кызматына кайрылыңыз';

  @override
  String get privacyPolicyBody =>
      'Safeer Marketте купуялыгыңызды урматтайбыз. Аты-жөнү, телефон номери жана дарек сыяктуу дайындарыңызды буйрутмаларды жеткирүү жана кызматтарды жакшыртуу үчүн гана колдонобуз жана сиздин макулдугуңузсуз үчүнчү тарапка бербейбиз.\n\nКолдонмону колдонуу менен сиз колдонуу шарттарына, анын ичинде буйрутма, жеткирүү жана кайтаруу эрежелерине макул болосуз. Толук саясат жакында жарыяланат.';

  @override
  String get helpTitle => 'Кантип жардам бере алабыз?';

  @override
  String get helpBody =>
      'Safeer Market командасы ар дайым кызматыңызда.\nБуйрутмаңызда көйгөй же суроо болсо, биз менен байланышыңыз — мүмкүн болушунча тезирээк жооп беребиз.';

  @override
  String get callUs => 'Чалуу';

  @override
  String get callUsSubtitle =>
      'Кардарларды колдоо кызматы менен түздөн-түз сүйлөшүңүз';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whatsappSubtitle => 'Жазыңыз, тез жооп беребиз';

  @override
  String get messageAlerts => 'Билдирме эскертмелери';

  @override
  String get appNotifications => 'Колдонмо билдирмелери';

  @override
  String get appNotificationsSubtitle =>
      'Сунуштар жана буйрутма абалынын жаңыртуулары';

  @override
  String get smsMessages => 'SMS билдирүүлөр';

  @override
  String get smsMessagesSubtitle =>
      'Буйрутманы ырастоо жана жеткирүү боюнча SMS';

  @override
  String get cancel => 'Жокко чыгаруу';

  @override
  String get delete => 'Өчүрүү';

  @override
  String get close => 'Жабуу';

  @override
  String get refresh => 'Жаңылоо';

  @override
  String get all => 'Баары';

  @override
  String get shopNow => 'Азыр сатып алуу';

  @override
  String get scanBarcode => 'Штрих-кодду скандоо';

  @override
  String get phoneNumber => 'Телефон номери';

  @override
  String get categories => 'Категориялар';

  @override
  String get magazines => 'Журналдар';

  @override
  String get addMagazine => 'Журнал кошуу';

  @override
  String get unexpectedError => 'Күтүлбөгөн ката кетти';

  @override
  String get networkError => 'Тармакка туташуу мүмкүн болбоду';

  @override
  String get serverError => 'Серверде ката кетти';

  @override
  String get serverConnectionError =>
      'Серверге туташуу мүмкүн болбоду, кайра аракет кылыңыз';

  @override
  String get pleaseSignInFirst => 'Адегенде кириңиз';

  @override
  String get noPermissionToEditOrder =>
      'Бул буйрутманы өзгөртүүгө укугуңуз жок';

  @override
  String orderUpdateFailed(String error) {
    return 'Буйрутманы жаңыртуу мүмкүн болбоду: $error';
  }

  @override
  String ordersLoadFailed(String error) {
    return 'Буйрутмаларды жүктөө мүмкүн болбоду\n$error';
  }

  @override
  String orderNumber(String id) {
    return 'Буйрутма #$id';
  }

  @override
  String get deletedProduct => 'Өчүрүлгөн товар';

  @override
  String get product => 'Товар';

  @override
  String get addNewAddress => 'Жаңы дарек кошуу';

  @override
  String get manageAddresses => 'Даректерди башкаруу';

  @override
  String get editLocation => 'Жайгашкан жерди өзгөртүү';

  @override
  String helloName(String name) {
    return 'Салам, $name';
  }

  @override
  String get cardNumber => 'Карта номери';

  @override
  String get cardholderName => 'Карта ээсинин аты';

  @override
  String get asWrittenOnCard => 'Картада жазылгандай';

  @override
  String get expiryDate => 'Жарактуулук мөөнөтү';

  @override
  String get addBankCard => 'Банк картасын кошуу';

  @override
  String get bankCard => 'Банк картасы';

  @override
  String get adminPaidByVisa => 'Visa менен төлөнгөн';

  @override
  String get cameraOpenFailed =>
      'Камераны ачуу мүмкүн болбоду, камерага уруксатты текшериңиз';

  @override
  String get addressLabelHome => 'Үй';

  @override
  String get addressLabelWork => 'Жумуш';

  @override
  String get puzzleGame => 'Пазл оюну';

  @override
  String get luckyWheel => 'Бакыт дөңгөлөгү';

  @override
  String get awesome => 'Сонун!';

  @override
  String get customer => 'Кардар';

  @override
  String get noLocationForOrder => 'Бул буйрутма үчүн жайгашкан жер жок';

  @override
  String get branch => 'Филиал';

  @override
  String get safeerCustomer => 'Safeer кардары';

  @override
  String get notSpecified => 'Көрсөтүлгөн эмес';

  @override
  String get cashOnDelivery => 'Алганда накталай төлөө';

  @override
  String get orderStatusPending => 'Күтүүдө';

  @override
  String get orderStatusPreparing => 'Даярдалууда';

  @override
  String get orderStatusReadyForDelivery => 'Жеткирүүгө даяр';

  @override
  String get orderStatusOutForDelivery => 'Жолдо';

  @override
  String get orderStatusDelivered => 'Жеткирилди';

  @override
  String get orderStatusCancelled => 'Жокко чыгарылды';

  @override
  String get statusNew => 'Жаңы';

  @override
  String get startPreparing => 'Даярдоону баштоо';

  @override
  String get total => 'Жалпы';

  @override
  String get inStock => 'Бар';

  @override
  String get outOfStock => 'Түгөндү';

  @override
  String get decreaseQuantity => 'Санын азайтуу';

  @override
  String get increaseQuantity => 'Санын көбөйтүү';

  @override
  String get decreaseWeight => 'Салмагын азайтуу';

  @override
  String get increaseWeight => 'Салмагын көбөйтүү';

  @override
  String get addToCart => 'Себетке кошуу';

  @override
  String get cartEmpty => 'Себетиңиз бош';

  @override
  String get productUnavailableNow => 'Бул товар азыр жеткиликсиз';

  @override
  String distanceFromBranch(String distance) {
    return 'Филиалдан $distance';
  }

  @override
  String get invoiceNumberRequired => 'Эсеп-фактуранын номери милдеттүү';

  @override
  String get addAtLeastOneItem => 'Жок дегенде бир товар кошуңуз';

  @override
  String get orderOnTheWayToYou => 'Буйрутмаңыз жолдо!';

  @override
  String get deliveryFee => 'Жеткирүү акысы';

  @override
  String get currencySymbol => 'EGP';

  @override
  String get unitPiece => 'даана';

  @override
  String get unitKilo => 'кг';

  @override
  String gramsValue(String value) {
    return '$value г';
  }

  @override
  String kilosValue(String value) {
    return '$value кг';
  }

  @override
  String kmValue(String value) {
    return '$value км';
  }

  @override
  String get sessionExpired => 'Сессияңыз бүттү, кайра кириңиз';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'Абалды жаңыртуу мүмкүн болбоду: $error';
  }

  @override
  String get adminDeleteMagazineTitle => 'Журналды өчүрүү';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return '«$title» өчүрүлсүнбү?';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return 'Журналды өчүрүү мүмкүн болбоду: $error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return 'Ката: $error';
  }

  @override
  String get adminNoMagazinesYet =>
      'Азырынча журналдар жок. Биринчисин жүктөө үчүн «Журнал кошуу» баскычын басыңыз.';

  @override
  String get adminMagazineExpired => 'Мөөнөтү бүткөн';

  @override
  String get adminMagazineUpcoming => 'Алдыда';

  @override
  String get adminMagazineActive => 'Активдүү';

  @override
  String adminMagazineDateRange(String start, String end) {
    return '$start — $end';
  }

  @override
  String get adminPickMagazinePdfTitle => 'Журнал файлын тандаңыз (PDF)';

  @override
  String get adminMagazineStartDate => 'Башталыш күнү';

  @override
  String get adminMagazineEndDate => 'Аяктоо күнү';

  @override
  String get adminMagazineTitleRequired => 'Журналдын аталышын жазыңыз';

  @override
  String get adminMagazineCoverRequired => 'Мукаба сүрөтүн тандаңыз';

  @override
  String get adminMagazinePdfRequired => 'Журнал үчүн PDF файлын тандаңыз';

  @override
  String get adminMagazineEndBeforeStart =>
      'Аяктоо күнү башталыш күнүнөн кийин болушу керек';

  @override
  String get adminMagazineAdded => 'Журнал ийгиликтүү кошулду';

  @override
  String adminMagazineSaveFailed(String error) {
    return 'Журналды сактоо мүмкүн болбоду: $error';
  }

  @override
  String get adminAddNewMagazine => 'Жаңы журнал кошуу';

  @override
  String get adminMagazineTitleLabel => 'Журналдын аталышы';

  @override
  String get adminPickCoverImage => 'Мукаба сүрөтүн тандоо';

  @override
  String get adminChangeCover => 'Мукабаны алмаштыруу';

  @override
  String get adminPickPdfFile => 'PDF файлын тандоо';

  @override
  String get adminUploading => 'Жүктөлүүдө...';

  @override
  String get adminSupervisorPermissions => 'Супервайзердин укуктары';

  @override
  String get adminEnterPinHint => 'PIN киргизиңиз (1234)';

  @override
  String get adminSupervisorModeEnabled => 'Супервайзер режими күйгүзүлдү';

  @override
  String get adminInvalidPin => 'PIN туура эмес';

  @override
  String get adminActivate => 'Активдештирүү';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - Башкаруу';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - Иш мейкиндиги';
  }

  @override
  String get adminCloseManagement => 'Админди кулпулоо';

  @override
  String get adminEnableManagement => 'Админди ачуу';

  @override
  String get adminExitToStore => 'Дүкөнгө кайтуу';

  @override
  String get adminMenuOrders => 'Буйрутмалар';

  @override
  String get adminMenuProducts => 'Товарлар';

  @override
  String get adminMenuStaff => 'Кызматкерлер';

  @override
  String get adminMenuReports => 'Отчеттор жана күндөлүк журнал';

  @override
  String get adminStatusPreparingShort => 'Даярдоо';

  @override
  String get adminStatusReadyForDriverShort => 'Айдоочуга';

  @override
  String get adminStatusDeliveryShort => 'Жеткирүү';

  @override
  String get adminStatusCompletedShort => 'Аякталды';

  @override
  String get adminStatusUnknown => 'Белгисиз';

  @override
  String get adminNoOrders => 'Буйрутмалар жок';

  @override
  String get adminSelectOrderFromList => 'Тизмеден буйрутма тандаңыз';

  @override
  String get adminItemsToPrepare => 'Даярдала турган товарлар:';

  @override
  String get adminNoItemsInOrder => 'Катталган товарлар жок';

  @override
  String get adminAvailableActions => 'Жеткиликтүү аракеттер';

  @override
  String get adminOrderAwaitingPreparer => 'Буйрутма даярдоочуну күтүүдө';

  @override
  String adminPreparerName(String name) {
    return 'Даярдоочу: $name';
  }

  @override
  String get adminAwaitingDriverAssignment =>
      'Супервайзердин айдоочу дайындашы күтүлүүдө';

  @override
  String get adminPickUpAndStartRoute => 'Алып, жолго чыгуу 🗺️';

  @override
  String adminDriverName(String name) {
    return 'Айдоочу: $name';
  }

  @override
  String get adminOrderReadyAwaitingDriver =>
      'Буйрутма ийгиликтүү даярдалды. Айдоочунун алып кетиши күтүлүүдө.';

  @override
  String get adminMarkDelivered => 'Ийгиликтүү жеткирилди 💵';

  @override
  String get adminCloseOrderPermanently => 'Буйрутманы биротоло жабуу';

  @override
  String get adminOrderWithDriverOnTheWay =>
      'Буйрутма азыр айдоочуда, кардарга бара жатат.';

  @override
  String get adminOrderDeliveredAndClosed =>
      'Бул буйрутма ийгиликтүү жеткирилип, жабылды.';

  @override
  String get adminWhoAreYouPickName =>
      'Сиз кимсиз? (Баштоо үчүн атыңызды тандаңыз)';

  @override
  String get adminNoPreparers => 'Даярдоочулар жок';

  @override
  String get adminFinishOrderPreparation => 'Буйрутманы даярдоону аяктоо';

  @override
  String get adminCheckAllItemsFirst =>
      '⚠️ Кечиресиз, адегенде бардык товарларды белгилешиңиз керек.';

  @override
  String get adminPreparationFinished => 'Даярдоо ийгиликтүү аяктады.';

  @override
  String get adminAssignDriverTitle => 'Айдоочу дайындоо (супервайзер гана)';

  @override
  String get adminSelectDriver => 'Айдоочу тандаңыз';

  @override
  String get adminOrderAssignedToDriver => 'Буйрутма айдоочуга дайындалды';

  @override
  String get adminAssignToSelectedDriver => 'Тандалган айдоочуга дайындоо';

  @override
  String get adminCallFailed => 'Чалуу мүмкүн болбоду';

  @override
  String get adminNoPhoneNumber => 'Номер жок';

  @override
  String get adminNoName => 'Аты жок';

  @override
  String get adminAddressNotSet => 'Көрсөтүлгөн эмес';

  @override
  String get adminCustomerInfo => 'Кардардын маалыматы';

  @override
  String get adminManageProducts => 'Товарларды башкаруу';

  @override
  String get adminActiveProducts => 'Активдүү товарлар';

  @override
  String get adminInactiveProducts => 'Активдүү эмес';

  @override
  String get adminSearchProductByName => 'Товарды аты боюнча издөө...';

  @override
  String adminErrorOccurred(String error) {
    return 'Ката кетти: $error';
  }

  @override
  String get adminNoProducts => 'Товарлар жок';

  @override
  String get adminCopyProductName => 'Товардын атын көчүрүү';

  @override
  String get adminCopied => 'Көчүрүлдү';

  @override
  String get adminCopyBarcode => 'Штрих-кодду көчүрүү';

  @override
  String adminBarcodeValue(String barcode) {
    return 'Штрих-код: $barcode';
  }

  @override
  String get adminUpdateErrorOccurred => 'Жаңыртууда ката кетти';

  @override
  String get adminManageStaff => 'Кызматкерлерди башкаруу';

  @override
  String get adminAddEmployee => 'Кызматкер кошуу';

  @override
  String get adminNoStaff => 'Катталган кызматкерлер жок';

  @override
  String get adminRoleTaker => 'Буйрутма кабыл алуучу';

  @override
  String get adminRolePreparer => 'Даярдоочу';

  @override
  String get adminRoleDriver => 'Айдоочу';

  @override
  String get adminNoPhone => 'Телефон жок';

  @override
  String get adminReportsTitle => 'Отчеттор жана жалпы күндөлүк журнал';

  @override
  String get adminTotalSalesCollected => 'Жалпы сатуу (чогултулган)';

  @override
  String get adminDeliveredOrdersTitle =>
      'Аякталган жана жеткирилген буйрутмалар';

  @override
  String get adminOrdersInPreparationTitle =>
      'Азыр даярдалып жаткан буйрутмалар';

  @override
  String get adminCancelledOrdersTitle => 'Жокко чыгарылган буйрутмалар';

  @override
  String get adminTotalOrdersCumulative => 'Жалпы буйрутмалар (топтолгон)';

  @override
  String adminOrdersCount(String count) {
    return '$count буйрутма';
  }

  @override
  String get adminRecentOrdersLog => 'Акыркы буйрутмалар журналы';

  @override
  String get adminOrderNumberColumn => 'Буйрутма №';

  @override
  String get adminCustomerNameColumn => 'Кардардын аты';

  @override
  String get adminStatusColumn => 'Абалы';

  @override
  String get paymentMethodCashLabel => 'Алганда накталай';

  @override
  String get paymentMethodCardLabel => 'Банк картасы (Visa/Mastercard)';

  @override
  String get paymentMethodInstaPayLabel => 'InstaPay';

  @override
  String get paymentMethodInstaPaySubtitle =>
      'InstaPay колдонмосу аркылуу тез которуу';

  @override
  String get instaPayOpenApp => 'Төлөө үчүн InstaPay’ди ачыңыз';

  @override
  String get instaPayIpaLabel => 'Тез төлөм дареги (IPA)';

  @override
  String get instaPayPhoneLabel => 'Же телефон номери аркылуу';

  @override
  String get instaPayCopy => 'Көчүрүү';

  @override
  String get instaPayCopied => 'Көчүрүлдү';

  @override
  String get instaPayConfirmHint =>
      'InstaPay аркылуу заказ суммасын которгондон кийин, төмөнкү Заказды ырастоо баскычын басыңыз.';

  @override
  String get instaPayReceiptTitle => 'Банк которуу дүмүрчөгү (скриншот)';

  @override
  String get instaPayReceiptHint =>
      'Заказды ырастоо үчүн InstaPay ийгиликтүү которуу скриншотун тиркеңиз';

  @override
  String get instaPayReceiptPick =>
      'Дүмүрчөк сүрөтүн тандаңыз же сүрөткө тартыңыз';

  @override
  String get instaPayReceiptRequired =>
      'Адегенде которуу дүмүрчөгүнүн сүрөтүн тиркеңиз';

  @override
  String get adminViewTransferReceipt => 'Которуу дүмүрчөгүн көрүү';

  @override
  String get adminCopyReceiptImage => 'Сүрөттү көчүрүү';

  @override
  String get adminShareReceipt => 'Дүмүрчөктү бөлүшүү';

  @override
  String get adminReceiptImageCopied => 'Дүмүрчөк сүрөтү көчүрүлдү';

  @override
  String get adminReceiptActionFailed =>
      'Дүмүрчөк сүрөтүн иштетүү мүмкүн болбоду';

  @override
  String get subscriptionConfirmInstaPay => 'Жазылууну ырастоо';

  @override
  String get subscriptionPendingSuccessTitle =>
      'Жогорулатуу өтүнүчү кабыл алынды';

  @override
  String get subscriptionPendingSuccessBody =>
      'Жогорулатуу өтүнүчүңүз жана төлөм дүмүрчөгү кабыл алынды. Админ текшергенден кийин Pro аккаунтуңуз активдештирилет.';

  @override
  String get adminMenuPendingSubscriptions => 'Күтүүдөгү жазылуулар';

  @override
  String get adminActivateAccount => 'Аккаунтту активдештирүү';

  @override
  String get adminSubscriptionApproved => 'Жазылуу активдештирилди';

  @override
  String get adminNoPendingSubscriptions => 'Күтүүдөгү жазылуу өтүнүчтөрү жок';

  @override
  String get adminPendingSubscriptionTier => 'Суралган план';

  @override
  String get paymentCopyCardNumber => 'Карта номерин көчүрүү';

  @override
  String get paymentCardNumberCopied => 'Карта номери көчүрүлдү';

  @override
  String get checkoutAddressOutOfRange => 'Дарек жеткирүү аймагынан тышкары';

  @override
  String get checkoutPinAddressFirst => 'Адегенде даректи картадан белгилеңиз';

  @override
  String checkoutOrderFailed(String error) {
    return 'Буйрутма берүү мүмкүн болбоду: $error';
  }

  @override
  String get checkoutTitle => 'Буйрутманы тариздөө';

  @override
  String get checkoutDeliveryAddress => 'Жеткирүү дареги';

  @override
  String get checkoutPaymentMethod => 'Төлөм ыкмасы';

  @override
  String get checkoutOrderSummary => 'Буйрутманын жыйынтыгы';

  @override
  String get checkoutSelectAddressFirst =>
      'Буйрутма берүү үчүн адегенде жеткирүү дарегин тандаңыз';

  @override
  String get checkoutPinLocationForFee =>
      'Жеткирүү акысын эсептөө үчүн даректи картадан белгилеңиз';

  @override
  String checkoutOrderPlaced(String id) {
    return 'Буйрутмаңыз кабыл алынды • Буйрутма #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return 'Кечиресиз, дарек $distance алыстыкта, жеткирүү аймагынан тышкары ($maxDistance чейин)';
  }

  @override
  String get checkoutSignInToChooseAddress =>
      'Жеткирүү дарегин тандоо үчүн кириңиз';

  @override
  String get checkoutPinThisAddressForFee =>
      'Жеткирүү акысын эсептөө үчүн бул даректи картадан белгилеңиз';

  @override
  String get checkoutPinLocation => 'Жерди белгилөө';

  @override
  String get checkoutChangeAddress => 'Өзгөртүү';

  @override
  String get checkoutAddDeliveryAddress =>
      'Буйрутма берүү үчүн жеткирүү дарегин кошуңуз';

  @override
  String get checkoutAddAddress => 'Дарек кошуу';

  @override
  String get checkoutNoAddressChosen => 'Жеткирүү дареги али тандала элек';

  @override
  String get checkoutChooseAddress => 'Даректи тандоо';

  @override
  String get checkoutEstimatedArrival => 'Болжолдуу жетүү убактысы:';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return 'Жеткирүү акысы ($distance)';
  }

  @override
  String get checkoutOutOfDeliveryRange => 'Жеткирүү аймагынан тышкары';

  @override
  String get checkoutItemCount => 'Товарлардын саны';

  @override
  String get checkoutSubtotal => 'Аралык сумма';

  @override
  String get checkoutGrandTotal => 'Жалпы сумма';

  @override
  String get checkoutConfirmOrder => 'Буйрутманы ырастоо';

  @override
  String get paymentCardScanUnsupported =>
      'Бул түзмөктө картаны скандоо колдоого алынбайт';

  @override
  String get paymentCardScanFailed =>
      'Картаны окуй алган жокпуз, маалыматты кол менен киргизиңиз';

  @override
  String get paymentCardScanned =>
      'Карта скандалды, маалыматты текшерип, CVV киргизиңиз';

  @override
  String get paymentCardTitle => 'Карта менен төлөө';

  @override
  String get paymentSecureNotice => 'Коопсуз, шифрленген төлөм';

  @override
  String paymentPayNow(String amount) {
    return 'Азыр төлөө • $amount';
  }

  @override
  String get paymentScanCardTooltip => 'Картаны камера менен скандоо';

  @override
  String get paymentAmountDue => 'Төлөнө турган сумма';

  @override
  String get cardNumberRequired => 'Карта номерин киргизиңиз';

  @override
  String get cardNumberInvalid => 'Карта номери туура эмес';

  @override
  String get cardExpiryRequired => 'Күндү MM/YY түрүндө киргизиңиз';

  @override
  String get cardExpiryInvalidMonth => 'Ай туура эмес';

  @override
  String get cardExpired => 'Картанын мөөнөтү бүткөн';

  @override
  String get cardCvvInvalid => 'Код туура эмес';

  @override
  String get cardHolderNameRequired =>
      'Атыңызды картада жазылгандай киргизиңиз';

  @override
  String get walletCardSaved => 'Карта ийгиликтүү сакталды';

  @override
  String get walletCardDataProtected =>
      'Маалыматыңыз корголгон, биз CVV кодун эч качан сактабайбыз';

  @override
  String get walletSaveCard => 'Картаны сактоо';

  @override
  String get walletAddCardHint =>
      'Кийинки буйрутмаларда тезирээк төлөө үчүн картаңызды кошуңуз';

  @override
  String get walletInAppBalance => 'Колдонмодогу капчыгыңыздын балансы';

  @override
  String get walletBalanceLoadFailed => 'Балансты жүктөө мүмкүн болбоду';

  @override
  String get walletBalanceAutoApplied =>
      'Балансыңыз төлөөдө автоматтык түрдө колдонулат';

  @override
  String get walletSignInToViewBalance => 'Балансты көрүү үчүн кириңиз';

  @override
  String walletCardExpires(String expiry) {
    return 'Мөөнөтү: $expiry';
  }

  @override
  String get walletDeleteCard => 'Картаны өчүрүү';

  @override
  String get checkoutUseOrAddNewCard => '+ Жаңы картаны колдонуу же кошуу';

  @override
  String get checkoutSavedCards => 'Сакталган карталарыңыз';

  @override
  String get paywallUpgradeAccount => 'Аккаунтту жаңыртуу';

  @override
  String get paywallDiscoverSafeer => 'Safeer дүйнөсүн ачыңыз 👑';

  @override
  String get paywallChoosePlan =>
      'Муктаждыгыңызга ылайык планды тандап, ар бир буйрутмада көбүрөөк үнөмдөңүз.';

  @override
  String get paywallProTitle => 'Safeer Pro (VIP)';

  @override
  String get paywallPerMonth => '/ ай';

  @override
  String get paywallProUnlimitedFreeDelivery => 'Чексиз акысыз жеткирүү 🚀';

  @override
  String get paywallProExpressDelivery =>
      'Экспресс жеткирүү (артыкчылыктуу даярдоо)';

  @override
  String get paywallProWholesalePrices => 'Эксклюзивдүү дүң баалар 💰';

  @override
  String get paywallProNoMinimumOrder => 'Минималдуу буйрутма жок';

  @override
  String get paywallProUnlimitedGiveaways => 'Белек утуштарына чексиз катышуу';

  @override
  String get paywallPrimeTitle => 'Safeer Prime';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders =>
      '5 буйрутмага акысыз жеткирүү';

  @override
  String get paywallPrimeOffersPriority => 'Ири сунуштарга артыкчылыктуу жетүү';

  @override
  String get paywallPrimeWeeklyPlayAndWin => 'Жумалык «Ойно жана ут» оюну 🎁';

  @override
  String get paywallFreeTitle => 'Стандарттык аккаунт';

  @override
  String get paywallFreePrice => 'Акысыз';

  @override
  String get paywallFreeStandardDelivery =>
      'Стандарттык баадагы кадимки жеткирүү';

  @override
  String get paywallFreePublicAccess =>
      'Товарларга жана жалпы сунуштарга жетүү';

  @override
  String get paywallBestSeller => 'Эң көп сатылган';

  @override
  String get paywallPaymentComingSoon => 'Төлөм жакында жеткиликтүү болот';

  @override
  String get paywallSubscribeNow => 'Азыр жазылуу';

  @override
  String get catDairyEggs => 'Сүт азыктары жана жумуртка';

  @override
  String get subcatTetraPakCheese => 'Тетрапак, үч бурчтуу жана стакандагы сыр';

  @override
  String get subcatPackagedCheeseLabneh =>
      'Таңгакталган сыр, лабне, каймак жана эритилген май';

  @override
  String get subcatCheeseByWeight => 'Салмак менен сатылган сыр';

  @override
  String get subcatMozzarella => 'Моцарелла сыры';

  @override
  String get subcatYogurtRicePudding => 'Йогурт жана сүттүү күрүч';

  @override
  String get subcatLongLifeDairy => 'Узак сакталуучу сүт азыктары';

  @override
  String get subcatPackagedButter => 'Таңгакталган сары май';

  @override
  String get subcatPackagedEggs => 'Таңгакталган жумуртка';

  @override
  String get catSweetsSnacks => 'Таттуулар жана закускалар';

  @override
  String get subcatChocolate => 'Шоколад';

  @override
  String get subcatBiscuits => 'Печенье';

  @override
  String get subcatSweets => 'Таттуулар';

  @override
  String get subcatChipsRoasted => 'Чипстер жана куурулган закускалар';

  @override
  String get subcatNutsByWeight => 'Салмак менен закускалар жана жаңгактар';

  @override
  String get subcatHalawaSpreads => 'Халва жана пасталар';

  @override
  String get subcatRamadanYamish =>
      'Рамазан үчүн кургак жемиштер жана жаңгактар';

  @override
  String get catDrinksJuices => 'Суусундуктар жана ширелер';

  @override
  String get subcatWaterDrinksIceCream =>
      'Суу, суусундуктар, ширелер жана балмуздак';

  @override
  String get subcatDrinks => 'Суусундуктар';

  @override
  String get subcatJuices => 'Ширелер';

  @override
  String get subcatPowderedJuices => 'Порошок ширелер';

  @override
  String get catMeatFrozen => 'Эт жана тоңдурулган азыктар';

  @override
  String get subcatFrozenPoultry =>
      'Тоңдурулган жана иштетилген канаттуулар эти';

  @override
  String get subcatFrozenMeat => 'Тоңдурулган эт';

  @override
  String get subcatProcessedMeat => 'Иштетилген эт азыктары';

  @override
  String get subcatFrozenFish => 'Тоңдурулган балык';

  @override
  String get subcatSmokedFish => 'Ышталган балык';

  @override
  String get subcatFrozenVegFruit => 'Тоңдурулган жашылчалар жана жемиштер';

  @override
  String get subcatFrozenPastries => 'Тоңдурулган камыр азыктары';

  @override
  String get catBakeryBreakfast => 'Нан азыктары жана эртең мененки тамак';

  @override
  String get subcatBakery => 'Нан азыктары';

  @override
  String get subcatPatisserie => 'Пирожныйлар жана кекстер';

  @override
  String get subcatCerealsOats => 'Корнфлекс, мюсли жана сулу';

  @override
  String get catPastaRice => 'Макарон жана күрүч';

  @override
  String get subcatPasta => 'Макарон';

  @override
  String get subcatRice => 'Күрүч';

  @override
  String get subcatLegumesSpicesBreadcrumbs =>
      'Таңгакталган буурчак, татымалдар жана нан күкүмү';

  @override
  String get subcatSoupsStocksMixes =>
      'Шорполор, сорпо кубиктери жана татымал аралашмалары';

  @override
  String get catPantryOils => 'Азык-түлүк жана майлар';

  @override
  String get subcatOils => 'Майлар';

  @override
  String get subcatGhee => 'Эритилген май';

  @override
  String get subcatSugarFlour => 'Шекер жана ун';

  @override
  String get subcatCannedFood => 'Консервалар';

  @override
  String get subcatCondiments => 'Соустар жана закускалар';

  @override
  String get subcatOlivesPickles => 'Зайтун жана туздалган азыктар';

  @override
  String get subcatPackagedOlivesPickles =>
      'Таңгакталган зайтун жана туздалган азыктар';

  @override
  String get subcatSpicesByWeight => 'Салмак менен татымалдар';

  @override
  String get subcatGrainsByWeight => 'Салмак менен дан жана уруктар';

  @override
  String get subcatBakingSupplies => 'Бышыруу үчүн каражаттар жана порошоктор';

  @override
  String get subcatSaladsByWeight => 'Салмак менен салаттар';

  @override
  String get catCleaningCare => 'Тазалоо жана үй тиричилиги';

  @override
  String get subcatDetergentsSofteners =>
      'Кир жуугуч порошоктор жана жумшарткычтар';

  @override
  String get subcatLiquidSoapStainRemovers => 'Суюк самын жана так кетиргичтер';

  @override
  String get subcatBleachDisinfectants =>
      'Агартуучулар жана дезинфекциялоочу каражаттар';

  @override
  String get subcatPolishes => 'Жылтыраткычтар';

  @override
  String get subcatInsecticidesFresheners =>
      'Инсектициддер жана аба жыпарлагычтар';

  @override
  String get subcatTissuesToiletPaper => 'Салфеткалар жана даараткана кагазы';

  @override
  String get subcatSteelWoolScrubbers => 'Металл жышкычтар жана ышкылар';

  @override
  String get subcatSpongesSteelWool => 'Губкалар жана металл жышкычтар';

  @override
  String get subcatDrainCleaners => 'Түтүк тазалагычтар';

  @override
  String get subcatIncense => 'Жыпар түтөткүчтөр';

  @override
  String get catPersonalCare => 'Жеке гигиена';

  @override
  String get subcatShampooConditioner => 'Шампунь жана бальзам';

  @override
  String get subcatShowerGelHandWash => 'Душ гели жана кол жуугуч';

  @override
  String get subcatSoap => 'Самын';

  @override
  String get subcatPerfumesDeodorants => 'Атырлар жана дезодоранттар';

  @override
  String get subcatCreamsSerums => 'Кремдер жана сывороткалар';

  @override
  String get subcatOralCare => 'Ооз көңдөйүнө кам көрүү';

  @override
  String get subcatShavingSupplies => 'Сакал алуу каражаттары';

  @override
  String get subcatHairDyeHenna => 'Чач боёктору жана хна';

  @override
  String get subcatPersonalCareSupplies => 'Жеке гигиена каражаттары';

  @override
  String get catBabyWorld => 'Балдар дүйнөсү';

  @override
  String get subcatDiapersPads => 'Подгузниктер жана гигиеналык прокладкалар';

  @override
  String get subcatBabyFood => 'Балдар тамагы';

  @override
  String get subcatBabySupplies => 'Балдар үчүн буюмдар';

  @override
  String get catHomeSupplies => 'Үй буюмдары';

  @override
  String get subcatHousewares => 'Үй тиричилик буюмдары';

  @override
  String get subcatElectricalTools => 'Электр шаймандары';

  @override
  String get subcatElectricalSupplies => 'Электр буюмдары';

  @override
  String get subcatPlasticsBags => 'Пластик буюмдар жана пакеттер';

  @override
  String get subcatFoil => 'Фольга';

  @override
  String get subcatHardware => 'Майда-барат буюмдар';

  @override
  String get subcatBatteries => 'Батарейкалар';

  @override
  String get subcatMatchesLighters => 'Ширеңке жана оттуктар';

  @override
  String get subcatPetSupplies => 'Үй жаныбарлары үчүн буюмдар';

  @override
  String get subcatRamadanSupplies => 'Рамазан буюмдары';

  @override
  String get categoryTitle => 'Категория';

  @override
  String get categoryNotFound => 'Мындай категория жок';

  @override
  String get categoryNoProductsNow => 'Бул категорияда азыр товарлар жок';

  @override
  String get shopFromHome => 'Башкы беттен сатып алуу';

  @override
  String categoryProductCount(String count) {
    return '$count товар';
  }

  @override
  String get loadMoreFailedRetry => 'Дагы жүктөө мүмкүн болбоду, кайталаңыз';

  @override
  String get categoriesDrawerTagline => 'Керектүүнүн баары бир жерде';

  @override
  String get productDetailsTitle => 'Товар жөнүндө';

  @override
  String get productNotAvailable => 'Бул товар жеткиликсиз';

  @override
  String get productLoadFailed => 'Товарды жүктөө мүмкүн болбоду';

  @override
  String get productImageUpdated => 'Товардын сүрөтү ийгиликтүү жаңыртылды!';

  @override
  String productImageUploadFailed(String error) {
    return 'Жүктөө ишке ашкан жок: $error';
  }

  @override
  String get updateProductImage => 'Товардын сүрөтүн жаңыртуу';

  @override
  String get takePhotoWithCamera => 'Сүрөткө тартуу';

  @override
  String get chooseFromGallery => 'Галереядан тандоо';

  @override
  String get changeProductImage => 'Сүрөттү алмаштыруу';

  @override
  String get pricePerKiloChooseWeight =>
      'Баасы бир кило үчүн, кошкондо салмагын тандаңыз';

  @override
  String get productDescription => 'Сүрөттөмө';

  @override
  String get addToCartButton => 'Себетке кошуу';

  @override
  String get productCurrentlyUnavailable => 'Азыр жеткиликсиз';

  @override
  String get productDetailsInCart => 'Себетте';

  @override
  String get imageLinkCopied => 'Сүрөттүн шилтемеси көчүрүлдү';

  @override
  String get copyImageLink => 'Сүрөттүн шилтемесин көчүрүү';

  @override
  String get similarProducts => 'Окшош товарлар';

  @override
  String get searchInSafeer => 'Safeerден издөө';

  @override
  String get searchProductHint => 'Товар издеңиз, мисалы: сүт, сыр...';

  @override
  String get clearSearch => 'Тазалоо';

  @override
  String get barcodeScanUnsupported =>
      'Бул түзмөктө штрих-кодду скандоо колдоого алынбайт';

  @override
  String get searchFailedCheckConnection =>
      'Издөө ишке ашкан жок, туташууну текшериңиз';

  @override
  String get scanAnotherProduct => 'Башка товарды скандоо';

  @override
  String noProductWithBarcode(String barcode) {
    return '«$barcode» штрих-коду менен товар жок';
  }

  @override
  String get productMayBeUnavailable => 'Товар азыр жеткиликсиз болушу мүмкүн';

  @override
  String get scanAgain => 'Кайра скандоо';

  @override
  String noSearchResultsFor(String query) {
    return '«$query» боюнча эч нерсе табылган жок';
  }

  @override
  String get searchTryAnotherWord =>
      'Башка сөз менен аракет кылыңыз же жазылышын текшериңиз';

  @override
  String searchResultsCount(String count, String query) {
    return '«$query» боюнча $count натыйжа';
  }

  @override
  String get popularSearches => 'Популярдуу издөөлөр';

  @override
  String get searchIntroSubtitle =>
      'Миңдеген товарлардын арасынан издеп, бир нече мүнөттө буйрутма бериңиз';

  @override
  String get searchSuggestionMilk => 'Сүт';

  @override
  String get searchSuggestionCheese => 'Сыр';

  @override
  String get searchSuggestionRice => 'Күрүч';

  @override
  String get searchSuggestionOil => 'Май';

  @override
  String get searchSuggestionSugar => 'Шекер';

  @override
  String get searchSuggestionTea => 'Чай';

  @override
  String get receiptTypeReceive => 'Кабыл алуу';

  @override
  String get receiptTypeSupplierReturn => 'Кайтаруу';

  @override
  String get warehouseGoodsReceiptTitle => 'Товар кабыл алуу';

  @override
  String get warehouseGoodsReturnTitle => 'Товар кайтаруу';

  @override
  String get warehouseReceiptSaved => 'Кабыл алуу документи сакталды';

  @override
  String get warehouseReturnSaved => 'Кайтаруу документи сакталды';

  @override
  String get warehouseSubmitReceipt => 'Кабыл алуу документин жөнөтүү';

  @override
  String get warehouseSubmitReturn => 'Кайтаруу документин жөнөтүү';

  @override
  String get warehouseInvoiceDate => 'Эсеп-фактуранын күнү';

  @override
  String get warehouseScanOrEnterBarcode => 'Штрих-кодду скандаңыз же жазыңыз';

  @override
  String get warehouseEnterQuantityAboveZero => 'Нөлдөн чоң санды киргизиңиз';

  @override
  String get warehouseCompleteRequiredFields =>
      'Адегенде милдеттүү талааларды толтуруңуз';

  @override
  String get warehouseNoItemsYet => 'Азырынча товарлар кошула элек';

  @override
  String get warehouseDocumentDetails => 'Документтин маалыматы';

  @override
  String get warehouseInvoiceNumberRequiredLabel => 'Эсеп-фактуранын номери *';

  @override
  String get warehouseInvoiceDateRequiredLabel => 'Эсеп-фактуранын күнү *';

  @override
  String get warehouseInvoiceDateRequired => 'Эсеп-фактуранын күнү милдеттүү';

  @override
  String get warehouseItems => 'Товарлар';

  @override
  String get warehouseBarcode => 'Штрих-код';

  @override
  String get warehouseQuantity => 'Саны';

  @override
  String get warehouseAdd => 'Кошуу';

  @override
  String get warehouseReloadSuppliers => 'Жеткирүүчүлөрдү кайра жүктөө';

  @override
  String get warehouseSupplierRequiredLabel => 'Жеткирүүчү *';

  @override
  String get warehouseSupplierHint => 'Жеткирүүчүнү издеңиз же номерин жазыңыз';

  @override
  String get warehouseSuppliersEmpty => 'Жеткирүүчүлөр тизмеси бош';

  @override
  String get warehouseSelectSupplier => 'Жеткирүүчүнү тандаңыз';

  @override
  String get warehouseSelectSupplierFromList =>
      'Жеткирүүчүнү тизмеден тандаңыз';

  @override
  String get warehouseFetchingProductName => 'Товардын аты алынууда…';

  @override
  String get warehouseUnregisteredProduct => 'Катталбаган товар';

  @override
  String warehouseQuantityValue(String quantity) {
    return 'Саны: $quantity';
  }

  @override
  String get warehouseSelectDate => 'Күндү тандаңыз';

  @override
  String get warehouseClearDate => 'Күндү тазалоо';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return 'Жеткирүүчүлөрдү жүктөө мүмкүн болбоду: $error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return 'Документти сактоо мүмкүн болбоду: $error';
  }

  @override
  String get warehouseOrderAlreadyUpdated =>
      'Буйрутманы жаңыртуу мүмкүн болбоду, ал мурунтан эле жаңыртылган болушу мүмкүн';

  @override
  String get warehouseSignOutConfirm => 'Кампа аккаунтунан чыгасызбы?';

  @override
  String get warehouseDashboardTitle => 'Кампа панели';

  @override
  String get warehouseNewOrdersTab => 'Жаңы буйрутмалар';

  @override
  String get warehousePreparingTab => 'Даярдалууда';

  @override
  String get warehouseItemInquiry => 'Товарды текшерүү';

  @override
  String warehouseItemInquiryFailed(String error) {
    return 'Товарды текшерүү мүмкүн болбоду\n$error';
  }

  @override
  String get warehouseItemNotRegistered =>
      'Бул товар маалымат базасында катталган эмес';

  @override
  String warehouseBarcodeValue(String barcode) {
    return 'Штрих-код: $barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return 'Жеткиликтүү саны: $quantity';
  }

  @override
  String get warehouseNoNewOrders =>
      'Жаңы буйрутмалар жок\nЖаңылоо үчүн ылдый тартыңыз';

  @override
  String get warehouseNoPreparingOrders => 'Даярдалып жаткан буйрутмалар жок';

  @override
  String warehousePreparingStarted(String id) {
    return '#$id буйрутманы даярдоо башталды, аны «Даярдалууда» бөлүмүнөн табасыз';
  }

  @override
  String warehouseOrderReady(String id) {
    return '#$id буйрутма даяр, курьерлерге билдирилди';
  }

  @override
  String warehouseProductsCount(String count) {
    return 'Товарлар ($count)';
  }

  @override
  String warehouseCustomerValue(String name) {
    return 'Кардар: $name';
  }

  @override
  String warehouseAddressValue(String address) {
    return 'Дарек: $address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return 'Жалпы: $amount';
  }

  @override
  String get driverNewOrderAvailable => 'Жеткирүү үчүн жаңы буйрутма бар!';

  @override
  String driverLocationSharingStartFailed(String error) {
    return 'Жайгашкан жериңизди бөлүшүүнү баштоо мүмкүн болбоду: $error';
  }

  @override
  String get driverSignOutConfirm => 'Айдоочу аккаунтунан чыгасызбы?';

  @override
  String get driverDashboardTitle => 'Айдоочу панели';

  @override
  String get driverAvailableOrdersTab => 'Жеткиликтүү буйрутмалар';

  @override
  String get driverNoAvailableOrders =>
      'Азыр жеткиликтүү буйрутмалар жок\nЖаңылоо үчүн ылдый тартыңыз';

  @override
  String get driverNoActiveDeliveries => 'Жеткирилип жаткан буйрутмалар жок';

  @override
  String driverOrderAccepted(String id) {
    return '#$id буйрутма кабыл алынды, аны «Буйрутмаларым» бөлүмүнөн табасыз';
  }

  @override
  String driverOrderDelivered(String id) {
    return '#$id буйрутма жеткирилди';
  }

  @override
  String get driverPhoneLabel => 'Телефон';

  @override
  String get driverAddressLabel => 'Дарек';

  @override
  String get driverDistanceLabel => 'Аралык';

  @override
  String get driverDistanceNotSpecified => 'Көрсөтүлгөн эмес';

  @override
  String driverDistanceFromBranch(String distance) {
    return 'Филиалдан $distance';
  }

  @override
  String get driverTotalToCollect => 'Жалпы (алынуучу)';

  @override
  String get driverViewMapAndLocation => 'Картаны жана жайгашкан жерди көрүү';

  @override
  String get driverAcceptOrder => 'Буйрутманы кабыл алуу';

  @override
  String get driverBroadcastingLocation => 'Жайгашкан жер бөлүшүлүүдө...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return 'Жайгашкан жер бөлүшүлүүдө... акыркы жолу $time жөнөтүлдү';
  }

  @override
  String get driverRequestingLocationPermission =>
      'Жайгашкан жерге уруксат суралууда...';

  @override
  String get driverStartLocationSharing => 'Жайгашкан жерди бөлүшүүнү баштоо';

  @override
  String driverCopyLabel(String label) {
    return 'Көчүрүү: $label';
  }

  @override
  String driverCopiedLabel(String label) {
    return 'Көчүрүлдү: $label';
  }

  @override
  String driverLocationReadFailed(String error) {
    return 'Жайгашкан жериңизди аныктоо мүмкүн болбоду: $error';
  }

  @override
  String get driverLocationSharingStopped =>
      'Жайгашкан жерди бөлүшүү токтоду, улантуу үчүн «Жайгашкан жерди бөлүшүүнү баштоо» баскычын басыңыз';

  @override
  String get driverOrderTakenByAnother =>
      'Кечиресиз, бул буйрутманы башка айдоочу кабыл алып алды';

  @override
  String driverAcceptOrderFailed(String error) {
    return 'Буйрутманы кабыл алуу мүмкүн болбоду: $error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return 'Жайгашкан жериңизди кардарга жөнөтүү мүмкүн болбоду: $error (код: $code)';
  }

  @override
  String get driverLocationSendNotAssigned =>
      'Жайгашкан жериңизди кардарга жөнөтүү мүмкүн болбоду: буйрутма сизге дайындалган эмес же жеткирилүүдө эмес';

  @override
  String get driverGpsDisabled =>
      'Жайгашкан жер кызматы (GPS) өчүк, кардар сизди көзөмөлдөй алышы үчүн аны күйгүзүңүз';

  @override
  String get driverLocationPermissionDeniedForever =>
      'Жайгашкан жерге уруксат берилген жок, кардар сизди көзөмөлдөй алышы үчүн аны колдонмо жөндөөлөрүнөн күйгүзүңүз';

  @override
  String get driverLocationPermissionDenied =>
      'Жайгашкан жериңизге уруксат берилген жок, кардар буйрутманы көзөмөлдөй албайт';

  @override
  String get driverOpenGoogleMapsFailed =>
      'Бул түзмөктө Google Карталарды ачуу мүмкүн болбоду';

  @override
  String get driverMapAndLocationTitle => 'Карта жана жайгашкан жер';

  @override
  String get driverStartNavigation => 'Навигацияны баштоо';

  @override
  String get listSeparator => ', ';

  @override
  String get storeCityName => 'Наср-Сити';

  @override
  String get addressDefaultTitle => 'Дарек';

  @override
  String get addressLabelOther => 'Башка';

  @override
  String addressBuildingLine(String building) {
    return 'Имарат $building';
  }

  @override
  String addressFloorAptLine(String floor) {
    return 'Кабат/батир $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return 'Ориентир: $landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return 'Даректи сактоо мүмкүн болбоду: $error';
  }

  @override
  String get addressLocationSaveFailed =>
      'Даректин жайгашкан жерин сактоо мүмкүн болбоду';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return 'Даректин жайгашкан жерин сактоо мүмкүн болбоду: $error';
  }

  @override
  String get locationServiceDisabled =>
      'Жайгашкан жер кызматы (GPS) өчүк. Аны күйгүзүп, кайра аракет кылыңыз';

  @override
  String get locationPermissionDenied =>
      'Жайгашкан жериңизге уруксат берилген жок. Картаны кол менен жылдыра аласыз';

  @override
  String get locationPermissionDeniedForever =>
      'Жайгашкан жерге уруксат берилген жок. Аны колдонмо жөндөөлөрүнөн күйгүзүңүз';

  @override
  String get currentLocationUnavailable =>
      'Учурдагы жайгашкан жериңизди аныктоо мүмкүн болбоду, кайра аракет кылыңыз';

  @override
  String get mapAddressReadFailed => 'Даректи картадан аныктоо мүмкүн болбоду';

  @override
  String get addressesEmptyTitle => 'Азырынча сакталган даректер жок';

  @override
  String get addressesEmptyHint =>
      'Буйрутмаларыңыз тез жеткирилиши үчүн дарегиңизди кошуңуз';

  @override
  String get addressesLoadFailed => 'Даректерди жүктөө мүмкүн болбоду';

  @override
  String get signInToManageAddresses => 'Даректериңизди башкаруу үчүн кириңиз';

  @override
  String get addressDeleteTitle => 'Даректи өчүрүү';

  @override
  String addressDeleteConfirm(String title) {
    return '«$title» дареги өчүрүлсүнбү?';
  }

  @override
  String get addressDeleteFailed => 'Даректи өчүрүү мүмкүн болбоду';

  @override
  String addressSaved(String title) {
    return '«$title» дареги сакталды';
  }

  @override
  String get addressPickerTitle => 'Жеткирүү дарегин тандаңыз';

  @override
  String get addressPickerEmpty =>
      'Сакталган даректер жок. Биринчи дарегиңизди кошуңуз';

  @override
  String get addressDetailsTitle => 'Даректин маалыматы';

  @override
  String get addressTitleLabel => 'Даректин аталышы';

  @override
  String get addressTitleHint => 'Мисалы: Үй, Жумуш';

  @override
  String get addressAreaLabel => 'Район';

  @override
  String get addressAreaHint => 'Мисалы: Наср-Сити, 6-район';

  @override
  String get addressStreetLabel => 'Көчө';

  @override
  String get addressBuildingNumberLabel => 'Имарат №';

  @override
  String get addressFloorAptLabel => 'Кабат / батир';

  @override
  String get addressLandmarkLabel => 'Ориентир';

  @override
  String get addressLandmarkHint => 'Мисалы: мечиттин жанында...';

  @override
  String get addressSaveButton => 'Даректи сактоо';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label (милдеттүү эмес)';
  }

  @override
  String get addressFieldRequired => 'Бул талаа милдеттүү';

  @override
  String get addressReviewAndComplete =>
      'Даректи текшерип, калган маалыматты толтуруңуз.';

  @override
  String get mapAddressReadFailedFillManually =>
      'Даректи картадан аныктоо мүмкүн болбоду. Маалыматты кол менен толтуруңуз.';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return 'Филиалдан $distance · Жеткирүү $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return 'Бул жер $distance алыстыкта, жеткирүү аймагынан тышкары ($maxDistance чейин).';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return '$distance алыстыкта, жеткирүү аймагынан тышкары';
  }

  @override
  String get mapPinHint =>
      'Белгини так жеткирүү жерине коюу үчүн картаны жылдырыңыз';

  @override
  String get mapMyCurrentLocation => 'Учурдагы жайгашкан жерим';

  @override
  String get mapConfirmLocation => 'Жайгашкан жерди ырастоо';

  @override
  String get mapSetDeliveryLocation => 'Жеткирүү жерин белгилөө';

  @override
  String get myOrdersLoadFailed => 'Буйрутмаларыңызды жүктөө мүмкүн болбоду';

  @override
  String get myOrdersEmptyTitle => 'Азырынча буйрутмалар жок';

  @override
  String get myOrdersEmptySubtitle =>
      'Сатып алууну баштаңыз, буйрутмаларыңыз ушул жерде көрүнөт';

  @override
  String get orderStatusReceivedLong => 'Буйрутма кабыл алынды';

  @override
  String get orderStatusPreparingInWarehouse => 'Кампада даярдалууда';

  @override
  String get orderStatusAwaitingDriver => 'Курьер күтүлүүдө';

  @override
  String get orderStatusReadyShort => 'Даяр';

  @override
  String get orderStepReceived => 'Кабыл алынды';

  @override
  String get orderStepPreparing => 'Даярдоо';

  @override
  String orderCardStatusLine(String status) {
    return 'Буйрутманын абалы: $status';
  }

  @override
  String get orderCardTrackOnMap => 'Буйрутманы картадан көзөмөлдөө';

  @override
  String trackingTitle(String id) {
    return '#$id буйрутманы көзөмөлдөө';
  }

  @override
  String get trackingYourAddressMarker => 'Сиздин дарегиңиз';

  @override
  String get trackingDriverMarker => 'Курьер';

  @override
  String get trackingOrderDelivered => 'Буйрутмаңыз жеткирилди. Аш болсун!';

  @override
  String get trackingDriverLocationLive =>
      'Курьердин жайгашкан жери картада түз жаңыртылып турат';

  @override
  String get trackingDriverLocating =>
      'Курьердин жайгашкан жери аныкталууда… ал жакында картада пайда болот';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return 'Аккаунтуңуз түзүлдү! $email дарегине ырастоо шилтемесин жөнөттүк. Электрондук почтаңызды ырастап, анан кириңиз.';
  }

  @override
  String get authFullNameLabel => 'Толук аты-жөнү';

  @override
  String get authEnterFullName => 'Толук аты-жөнүңүздү киргизиңиз';

  @override
  String get authEnterValidEmail =>
      'Туура электрондук почта дарегин киргизиңиз';

  @override
  String get authEnterValidEgyptianPhone =>
      'Туура Египет телефон номерин киргизиңиз (11 сан)';

  @override
  String get authPassword => 'Сырсөз';

  @override
  String get authShowPassword => 'Сырсөздү көрсөтүү';

  @override
  String get authHidePassword => 'Сырсөздү жашыруу';

  @override
  String get authPasswordMinLength => 'Сырсөз кеминде 6 белгиден турушу керек';

  @override
  String get authSignInButton => 'Кирүү';

  @override
  String get authCreateAccountButton => 'Аккаунт түзүү';

  @override
  String get authNoAccountPrompt => 'Аккаунтуңуз жокпу? ';

  @override
  String get authHaveAccountPrompt => 'Аккаунтуңуз барбы? ';

  @override
  String get authCreateNewAccountLink => 'Жаңы аккаунт түзүү';

  @override
  String get authSignInLink => 'Кирүү';

  @override
  String get authWelcomeBack => 'Кайра кош келиңиз!';

  @override
  String get authJoinSafeerMarket => 'Safeer Marketке кошулуңуз';

  @override
  String get authSignInSubtitle => 'Буйрутмаңызды бүтүрүү үчүн кириңиз';

  @override
  String get authSignUpSubtitle =>
      'Аккаунт түзүп, Safeer сунуштарынан пайдаланыңыз';

  @override
  String get authNewAccountTab => 'Жаңы аккаунт';

  @override
  String get authEmailAlreadyRegistered =>
      'Бул электрондук почта мурунтан катталган';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return 'Аккаунтуңуз түзүлдү, бирок маалыматыңызды сактоо мүмкүн болбоду: $error';
  }

  @override
  String get authInvalidCredentials => 'Электрондук почта же сырсөз туура эмес';

  @override
  String get authEmailNotConfirmed =>
      'Адегенде биз жөнөткөн кат аркылуу электрондук почтаңызды ырастаңыз';

  @override
  String get authWeakPassword => 'Сырсөз өтө алсыз, кеминде 6 белги колдонуңуз';

  @override
  String get authTooManyAttempts =>
      'Аракеттер өтө көп, бир аздан кийин кайра аракет кылыңыз';

  @override
  String get editProfileSignInPrompt => 'Маалыматыңызды өзгөртүү үчүн кириңиз';

  @override
  String get profileSavedSuccessfully => 'Маалыматыңыз ийгиликтүү сакталды';

  @override
  String get profileFullNameLabel => 'Толук аты-жөнү';

  @override
  String get profileEnterFullName => 'Толук аты-жөнүңүздү киргизиңиз';

  @override
  String get profileEnterValidPhone =>
      'Туура Египет телефон номерин киргизиңиз';

  @override
  String get profileSaveChanges => 'Өзгөртүүлөрдү сактоо';

  @override
  String profileSaveFailed(String error) {
    return 'Маалыматыңызды сактоо мүмкүн болбоду: $error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return 'Билдирме токенин сактоо мүмкүн болбоду: $error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature жакында жеткиликтүү болот';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упай',
      one: '$count упай',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => 'Оюндар';

  @override
  String get rewardsGamesSubtitle => 'Ойноп, берилгендик упайларын топтоңуз';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return '$countdown кийин кайра ачылат';
  }

  @override
  String get scratchCardTitle => 'Скретч карта — сүртүп утуңуз';

  @override
  String get scratchCardSubtitle => 'Каптоону сүртүп упай утуңуз';

  @override
  String get scratchCardHint =>
      'Сыйлыгыңызды көрүү үчүн күмүш катмарды сүртүңүз';

  @override
  String scratchWonPoints(String points) {
    return 'Сиз $points упай уттуңуз!';
  }

  @override
  String get scratchBetterLuck => 'Кийинки жолу ийгилик';

  @override
  String get luckyChestTitle => 'Күнүмдүк бактыя куту — ачыңыз';

  @override
  String get luckyChestSubtitle => 'Кутуну ачып 10 упайга чейин утуңуз';

  @override
  String get luckyChestHint => 'Сыйлыкты көрүү үчүн кутуну басыңыз';

  @override
  String get luckyChestTapToOpen => 'Ачуу үчүн басыңыз';

  @override
  String get luckyChestOpened => 'Бүгүнкү куту ачылган';

  @override
  String luckyChestWonPoints(String points) {
    return 'Кутудан $points упай уттуңуз!';
  }

  @override
  String get rewardsWheelCardSubtitle =>
      'Дөңгөлөктү айлантып, 100 упайга чейин утуп алыңыз';

  @override
  String get rewardsPuzzleCardSubtitle =>
      'Логотипти чогултуп, 50 упай утуп алыңыз';

  @override
  String get loyaltyCurrentBalance => 'Учурдагы балансыңыз';

  @override
  String get loyaltySignInToSeePoints => 'Упайларыңызды көрүү үчүн кириңиз';

  @override
  String get loyaltyLoadFailedRetry => 'Жүктөө мүмкүн болбоду — Кайталоо';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return 'Берилгендик упайларын жүктөө мүмкүн болбоду: $error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return 'Берилгендик упайларын жаңыртуу мүмкүн болбоду: $error';
  }

  @override
  String get wheelPrizeTryAgain => 'Кайра аракет кылыңыз';

  @override
  String get wheelSpinCollectLoyaltyPoints =>
      'Дөңгөлөктү айлантып, берилгендик упайларын топтоңуз';

  @override
  String get wheelSignInToPlay => 'Ойноо үчүн кириңиз';

  @override
  String get wheelSpinning => 'Айланууда...';

  @override
  String get wheelSpin => 'Дөңгөлөктү айлантуу';

  @override
  String get wheelCongrats => 'Куттуктайбыз!';

  @override
  String get wheelTryAgainTitle => 'Кайра аракет кылыңыз';

  @override
  String wheelWonPrize(String prize) {
    return 'Сиз $prize уттуңуз, ал берилгендик балансыңызга кошулду.';
  }

  @override
  String get wheelNoPointsThisTime =>
      'Бул жолу упай жок. Кийинки айлантууда ийгилик!';

  @override
  String puzzleMoves(String moves) {
    return 'Жүрүштөр: $moves';
  }

  @override
  String puzzlePrize(String points) {
    return 'Сыйлык: $points упай';
  }

  @override
  String puzzleSavePoints(String points) {
    return '$points упайды сактоо';
  }

  @override
  String get puzzleShuffle => 'Бөлүктөрдү аралаштыруу';

  @override
  String get puzzleOutOfMoves =>
      'Кийинки жолу ийгилик! Бардык жылыштарыңыз түгөндү.';

  @override
  String get puzzleCongrats => 'Куттуктайбыз!';

  @override
  String puzzleEarnedPoints(String points) {
    return 'Сиз $points упай таптыңыз 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance =>
      'Упайлар берилгендик балансыңызга кошулду.';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return 'Куттуктайбыз! Сиз $points упай таптыңыз 🎉';
  }

  @override
  String get puzzleSignInToAddPoints =>
      'Аларды балансыңызга кошуубуз үчүн кириңиз.';

  @override
  String get puzzleGoalTitle => 'Логотипти чогултуңуз';

  @override
  String get puzzleGoalDescription =>
      'Логотип сүрөттөгүдөй болгонго чейин бош орундун жанындагы бөлүктөрдү жылдырыңыз';

  @override
  String get unitCarton => 'коробка';

  @override
  String get unitBox => 'куту';

  @override
  String get unitBag => 'баштык';

  @override
  String get unitPack => 'пачка';

  @override
  String get cartTitle => 'Сатып алуулар себети';

  @override
  String get clearCart => 'Себетти бошотуу';

  @override
  String cartSubtotalWithCount(String count) {
    return 'Аралык сумма ($count товар)';
  }

  @override
  String get cartDeliveryFeeNextStep =>
      'Жеткирүү акысы кийинки кадамда эсептелет';

  @override
  String get cartContinueOrder => 'Тариздөөгө өтүү';

  @override
  String get cartEmptySubtitle =>
      'Сүйүктүү товарларыңызды кошуп, сатып алууну баштаңыз';

  @override
  String get cartSaveDeliveryFeesTitle => 'Жеткирүү акысын үнөмдөңүз! 💡';

  @override
  String get cartPrimeUpsellSubtitle =>
      'Болгону 90 EGP төлөп, Safeer Prime жазылуусун алыңыз.';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return '$product ($weight) себетке кошулду';
  }

  @override
  String cartAddedProduct(String product) {
    return '$product себетке кошулду';
  }

  @override
  String get viewCart => 'Себетти көрүү';

  @override
  String get removeFromCart => 'Себеттен алып салуу';

  @override
  String get chooseWeight => 'Салмагын тандаңыз';

  @override
  String pricePerKilo(String price) {
    return '$price / кило';
  }

  @override
  String get weightPickerPrice => 'Баасы';

  @override
  String get updateWeight => 'Салмагын жаңыртуу';

  @override
  String get homeNotificationsTooltip => 'Билдирмелер';

  @override
  String get homeSearchHint => 'Товар же бренд издеңиз';

  @override
  String homeDeliveringTo(String city) {
    return 'Жеткирүү · $city';
  }

  @override
  String get homeChooseYourAddress => 'Дарегиңизди тандаңыз';

  @override
  String get homeMyAccountTooltip => 'Менин аккаунтум';

  @override
  String get homeSignedInSuccessfully => 'Ийгиликтүү кирдиңиз';

  @override
  String get homeDeliveryEta => '30 - 45 мүнөттө жеткирүү';

  @override
  String get quickActionLatestProducts => 'Эң жаңы товарлар';

  @override
  String get quickActionOffers => 'Сунуштар';

  @override
  String get quickActionPlayAndWin => 'Ойно жана ут';

  @override
  String get promoEndlessOffersTitle => 'Safeer сунуштары түгөнбөйт';

  @override
  String get promoEndlessOffersSubtitle =>
      'Жүздөгөн товарларга күнүмдүк арзандатуулар';

  @override
  String get promoSavingsStoreTitle => 'Safeer... үнөмдөө дүкөнү';

  @override
  String get promoSavingsStoreSubtitle => 'Бүт үй үчүн күн сайын арзан баалар';

  @override
  String get promoOpeningDiscountsTitle => 'Ачылыш арзандатуулары';

  @override
  String get promoOpeningDiscountsSubtitle =>
      'Биринчи буйрутмага 30% чейин арзандатуу';

  @override
  String get promoFreeDeliveryTitle => 'Акысыз жеткирүү';

  @override
  String get promoFreeDeliverySubtitle => '300 EGPден ашкан буйрутмаларга';

  @override
  String offerDiscountPercent(String percent) {
    return '$percent% арзандатуу';
  }

  @override
  String get offerBadge => 'Акция';

  @override
  String get favoritesSignInPrompt =>
      'Сүйүктүү товарларыңызды сактоо үчүн кириңиз';

  @override
  String get favoritesLoadFailed => 'Сүйүктүүлөрдү жүктөө мүмкүн болбоду';

  @override
  String get favoritesEmptyTitle => 'Азырынча сүйүктүү товарлар жок';

  @override
  String get favoritesEmptySubtitle =>
      'Товарды ушул жерге сактоо үчүн андагы ♡ белгисин басыңыз';

  @override
  String get favoritesUpdateFailed =>
      'Сүйүктүүлөрдү жаңыртуу мүмкүн болбоду, кайра аракет кылыңыз';

  @override
  String get removeFromFavorites => 'Сүйүктүүлөрдөн алып салуу';

  @override
  String get addToFavorites => 'Сүйүктүүлөргө кошуу';

  @override
  String get magazinesLoadFailed => 'Журналдарды жүктөө мүмкүн болбоду';

  @override
  String get noMagazinesCurrently => 'Азыр журналдар жок';

  @override
  String get magazineNoPdf => 'Бул журналдын PDF файлы жок';

  @override
  String get magazineOpenFailed =>
      'Журналды ачуу мүмкүн болбоду. Кийинчерээк кайра аракет кылыңыз.';

  @override
  String get magazinePreviousPage => 'Мурунку бет';

  @override
  String get magazineNextPage => 'Кийинки бет';

  @override
  String magazinePageOf(String page, String count) {
    return 'Бет $page / $count';
  }

  @override
  String get authWelcomeTitle => 'Safeer Marketке кош келиңиз';

  @override
  String get authWelcomeSubtitle =>
      'Бир нече секундда кириңиз же аккаунт түзүңүз';

  @override
  String get authContinueWithGoogle => 'Google менен улантуу';

  @override
  String get authContinueWithPhone => 'Телефон номери менен улантуу';

  @override
  String get authContinueWithEmail => 'Электрондук почта менен улантуу';

  @override
  String get authOr => 'же';

  @override
  String get authOtherSignInOptions => 'Кирүүнүн башка жолдору';

  @override
  String get authTermsNotice =>
      'Улантуу менен сиз купуялык саясатына жана шарттарга макул болосуз';

  @override
  String get authGoogleFailed =>
      'Google аркылуу кирүү мүмкүн болгон жок, кайра аракет кылыңыз';

  @override
  String get authProviderUnavailable => 'Бул кирүү ыкмасы азыр жеткиликсиз';

  @override
  String get authOtpInvalid => 'Код туура эмес же мөөнөтү бүткөн';

  @override
  String get authSmsSendFailed =>
      'Текшерүү SMS жөнөтүлгөн жок, номерди текшерип кайра аракет кылыңыз';

  @override
  String get authPhoneSheetTitle => 'Телефон менен кирүү';

  @override
  String get authPhoneSheetSubtitle =>
      'Сизге 6 сандан турган текшерүү кодун SMS менен жөнөтөбүз';

  @override
  String get authSendCode => 'Код жөнөтүү';

  @override
  String get authEnterCodeTitle => 'Текшерүү кодун киргизиңиз';

  @override
  String authCodeSentTo(String phone) {
    return 'Кодду $phone номерине SMS менен жөнөттүк';
  }

  @override
  String get authVerifyCode => 'Кодду ырастоо';

  @override
  String get authEnterSixDigitCode => '6 сандан турган кодду киргизиңиз';

  @override
  String get authResendCode => 'Кодду кайра жөнөтүү';

  @override
  String authResendCodeIn(String seconds) {
    return '$seconds сек кийин кайра жөнөтүү';
  }

  @override
  String get authChangeNumber => 'Номерди өзгөртүү';

  @override
  String get authCodeResent => 'Жаңы код жөнөтүлдү';

  @override
  String get productNoImageBadge => 'Сүрөтү жок';

  @override
  String newProductsMissingImageCount(String count) {
    return 'Жаңы товарлар (сүрөтү жок: $count)';
  }

  @override
  String missingImageCountBadge(String count) {
    return 'Сүрөтү жок: $count';
  }

  @override
  String get productImageSaveBlocked =>
      'Сүрөт жүктөлдү, бирок товарга сакталган жок: товарларды өзгөртүүгө уруксат жок. Supabase ичиндеги админ укуктарын текшериңиз.';

  @override
  String get authPhoneLoginDisabled =>
      'Телефон менен кирүү азырынча жеткиликсиз, Google же электрондук почтаны колдонуңуз';

  @override
  String get onboardingLanguageTitle => 'Тилди тандаңыз';

  @override
  String get onboardingLanguageSubtitle =>
      'Аны каалаган убакта Жөндөөлөрдөн өзгөртө аласыз';

  @override
  String get onboardingAppearanceTitle => 'Колдонмонун көрүнүшүн тандаңыз';

  @override
  String get onboardingAppearanceSubtitle =>
      'Ачык, караңгы же түзмөгүңүзгө жараша';

  @override
  String get onboardingAccountTitle => 'Толук мүмкүнчүлүк үчүн кириңиз';

  @override
  String get onboardingAccountSubtitle =>
      'Буйрутма бериңиз, буйрутмаларды көзөмөлдөңүз, даректерди жана тандалгандарды сактаңыз';

  @override
  String get onboardingNext => 'Кийинки';

  @override
  String get onboardingSignInOrRegister => 'Кирүү же аккаунт түзүү';

  @override
  String get onboardingBrowseFirst => 'Адегенде колдонмону карап чыгуу';

  @override
  String get appearance => 'Көрүнүш';

  @override
  String get themeSystem => 'Тутум';

  @override
  String get themeDark => 'Караңгы';

  @override
  String get themeLight => 'Ачык';

  @override
  String get settingsAccountSection => 'Аккаунт';

  @override
  String get guestSignInTitle => 'Улантуу үчүн кириңиз';

  @override
  String get guestCartMessage =>
      'Себетке товар кошуу жана буйрутма берүү үчүн кириңиз же аккаунт түзүңүз.';

  @override
  String get guestProfileMessage =>
      'Маалыматтарыңызды, буйрутмаларыңызды, даректериңизди жана тандалгандарды көрүү үчүн кириңиз.';

  @override
  String get notNow => 'Азыр эмес';

  @override
  String get unitSet => 'топтом';

  @override
  String unitBoxOf(String count) {
    return '$count даана куту';
  }

  @override
  String get paywallSignInToSubscribe => 'Safeer тарифине жазылуу үчүн кириңиз';

  @override
  String get paymentChooseMethod => 'Төлөм ыкмасын тандаңыз';

  @override
  String get paymentMethodCard => 'Банк картасы (Visa / Mastercard / Meeza)';

  @override
  String get paymentMethodWallet => 'Мобилдик капчык (Vodafone Cash ж.б.)';

  @override
  String get paymentWalletPhoneLabel => 'Капчык номери';

  @override
  String get paymentWalletPhoneInvalid =>
      '01 менен башталган туура капчык номерин киргизиңиз';

  @override
  String get paymentContinue => 'Улантуу';

  @override
  String get paymentStartFailed =>
      'Төлөмдү баштоо мүмкүн болбоду. Кайра аракет кылыңыз.';

  @override
  String get paymentMethodUnavailable => 'Бул төлөм ыкмасы азыр жеткиликсиз';

  @override
  String get paymentPageOpenFailed => 'Төлөм барагын ачуу мүмкүн болбоду';

  @override
  String get paymentVerifying => 'Төлөм текшерилүүдө…';

  @override
  String get paymentFailedMessage =>
      'Төлөм аяктаган жок. Кайра аракет кылсаңыз болот.';

  @override
  String get paymentStillProcessing =>
      'Төлөм ырастоосу али бүтө элек. Заказдын абалын Менин заказдарымдан текшере аласыз.';

  @override
  String get subscriptionActivatedTitle => 'Жазылуу ийгиликтүү иштетилди 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return '$plan тарифи $date чейин активдүү';
  }

  @override
  String get subscriptionContinueShopping => 'Соода кылууну улантуу';

  @override
  String get redeemPoints => 'Упайларды алмаштыруу';

  @override
  String get redeemQrTitle => 'Бул кодду кассирге көрсөтүңүз';

  @override
  String get redeemQrSubtitle =>
      'Ар бир 50 упай = 1 EGP арзандатуу. Арзандатуу колдонулгандан кийин код өзү жабылат.';

  @override
  String get redeemSuccess => 'Арзандатуу ийгиликтүү колдонулду';

  @override
  String get scanCustomerCode => 'Кардардын кодун сканерлөө';

  @override
  String get scanCustomerHint => 'Камераны кардардын кодуна багыттаңыз';

  @override
  String get scanInvalidCode => 'Бул Safeer Market кардарынын коду эмес';

  @override
  String scanCameraFailed(String error) {
    return 'Камераны иштетүү мүмкүн болбоду: $error';
  }

  @override
  String get redeemInsufficientPoints => '1 EGP арзандатуу үчүн упай жетишсиз';

  @override
  String get redeemNotAllowed =>
      'Бул аккаунтка упайларды алмаштырууга уруксат жок';

  @override
  String get redeemCustomerNotFound => 'Кардар табылган жок';

  @override
  String redeemFailed(String error) {
    return 'Упайларды алмаштыруу мүмкүн болбоду: $error';
  }

  @override
  String get cashierRedeemTitle => 'Упайларды алмаштыруу';

  @override
  String get cashierCustomer => 'Кардар';

  @override
  String get cashierCurrentBalance => 'Учурдагы баланс';

  @override
  String get cashierPointsToDeduct => 'Кемитилүүчү упайлар';

  @override
  String get cashierDiscount => 'Арзандатуу';

  @override
  String get cashierRemainingPoints => 'Кийинки баланс';

  @override
  String get cashierBarcodeHint =>
      'Бул штрих-кодду кассада сканерлеп, андан кийин ырастаңыз';

  @override
  String get confirmPointsDeduction => 'Упайларды кемитүүнү ырастоо';

  @override
  String cashierRedeemDone(String points, String amount) {
    return '$points упай алмаштырылды ($amount арзандатуу)';
  }

  @override
  String get phoneOrdersTitle => 'Телефон буйрутмалары / Кардар издөө';

  @override
  String get phoneOrderOpen => 'Телефон буйрутмасы';

  @override
  String get phoneOrderSearchHint =>
      'Телефон номери же кардардын аты боюнча издөө...';

  @override
  String get phoneOrderNewCustomer => '+ Жаңы кардар';

  @override
  String get phoneOrderTypeToSearch =>
      'Издөө үчүн телефон номерин же атын жазыңыз';

  @override
  String get phoneOrderNoCustomers =>
      'Дал келген кардар жок. Аны жаңы кардар катары кошуңуз.';

  @override
  String get phoneOrderAppCustomer => 'Колдонмо колдонуучусу';

  @override
  String get phoneOrderPosCustomer => 'Касса кардары';

  @override
  String get phoneOrderNoAddress => 'Сакталган дарек жок';

  @override
  String get phoneOrderChangeCustomer => 'Кардарды алмаштыруу';

  @override
  String get phoneOrderCustomerName => 'Кардардын аты';

  @override
  String get phoneOrderCustomerPhone => 'Телефон номери';

  @override
  String get phoneOrderCustomerAddress => 'Дарек';

  @override
  String get phoneOrderCustomerZone => 'Аймак';

  @override
  String get phoneOrderSaveCustomer => 'Кардарды сактоо';

  @override
  String get phoneOrderNameRequired => 'Кардардын атын жазыңыз';

  @override
  String get phoneOrderPhoneInvalid =>
      'Туура Египет мобилдик номерин жазыңыз (01XXXXXXXXX)';

  @override
  String get phoneOrderProductSearchHint =>
      'Товардын аты же штрих-коду боюнча издөө...';

  @override
  String get phoneOrderSearchProductsPrompt =>
      'Товарды аты же штрих-коду боюнча издеңиз';

  @override
  String get phoneOrderNoProducts => 'Дал келген товарлар жок';

  @override
  String get phoneOrderCartTitle => 'Кардардын себети';

  @override
  String get phoneOrderCartEmpty => 'Азырынча товар кошулган жок';

  @override
  String get phoneOrderItemsTotal => 'Товарлардын жалпы суммасы';

  @override
  String get phoneOrderTotal => 'Жалпы';

  @override
  String get phoneOrderFreeDelivery => 'Акысыз';

  @override
  String get phoneOrderConfirm => 'Буйрутманы ырастоо жана каттоо';

  @override
  String phoneOrderPlaced(String id) {
    return '#$id буйрутмасы катталды';
  }

  @override
  String phoneOrderFailed(String error) {
    return 'Буйрутманы каттоо мүмкүн болбоду: $error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return 'Издөө ишке ашкан жок: $error';
  }

  @override
  String get phoneOrderNotAllowed =>
      'Бул аккаунтка телефон буйрутмаларын кабыл алууга уруксат жок';

  @override
  String get phoneOrderBadge => 'Телефон';

  @override
  String phoneOrderSetupMissing(String function) {
    return '$function функциясы маалымат базасында жок. Supabase SQL Editor аркылуу supabase/migrations/20261111010000_phone_orders.sql файлын иштетиңиз.';
  }

  @override
  String get adminToggleMenu => 'Менюну көрсөтүү/жашыруу';

  @override
  String get adminResizeColumn => 'Мамычанын туурасын өзгөртүү үчүн сүйрөңүз';

  @override
  String get phoneOrderShowCart => 'Себетти жана жеткирүүнү көрсөтүү';

  @override
  String get phoneOrderHideCart => 'Себетти жашыруу';

  @override
  String get driverDeliveryAddress => 'Жеткирүү дареги';

  @override
  String get driverNavigateViaMap => 'Карта аркылуу баруу';

  @override
  String get mapSearchHint => 'Аймак же көчө издөө...';

  @override
  String get mapSearchNoResults => 'Эч нерсе табылган жок';

  @override
  String mapSearchFailed(String error) {
    return 'Жерди издөө мүмкүн болбоду: $error';
  }

  @override
  String get mapSearchClear => 'Издөөнү тазалоо';

  @override
  String get supportLiveChatSubtitle =>
      'Тиркемеден жазыңыз, биздин команда дароо жооп берет';

  @override
  String get supportSignInMessage =>
      'Кардарларды тейлөө менен чат баштоо үчүн кириңиз.';

  @override
  String supportLaunchFailed(String phone) {
    return 'Тиркемени ачуу мүмкүн болбоду. Бизге $phone номерине чалсаңыз болот';
  }

  @override
  String get supportChatTitle => 'Кардарларды тейлөө';

  @override
  String get supportChatSubtitle =>
      'Safeer Market командасы бул жерде жооп берет';

  @override
  String get supportChatWelcome =>
      'Кош келиңиз! Сурооңузду же көйгөйүңүздү жазыңыз, кардарларды тейлөө командасы мүмкүн болушунча тез жооп берет.';

  @override
  String get supportMessageHint => 'Билдирүүңүздү жазыңыз...';

  @override
  String supportLoadFailed(String error) {
    return 'Чатты жүктөө мүмкүн болбоду: $error';
  }

  @override
  String get supportSetupMissing =>
      'Түз чат азырынча орнотула элек. Supabase SQL Editor аркылуу supabase/migrations/20261114210000_support_chat.sql файлын иштетиңиз.';

  @override
  String get supportNotAllowed => 'Бул чатка кирүүгө укугуңуз жок';

  @override
  String supportRequestFailed(String error) {
    return 'Сурамды аткаруу мүмкүн болбоду: $error';
  }

  @override
  String get supportCenterTitle => 'Даттануулар жана чаттар';

  @override
  String get supportNoChats => 'Азыр ачык чаттар жок';

  @override
  String get supportSelectChat =>
      'Кардарга жооп берүү үчүн тизмеден чат тандаңыз';

  @override
  String get supportNoMessagesYet => 'Бул чатта азырынча билдирүүлөр жок';

  @override
  String get supportReplyHint => 'Кардарга жообуңузду жазыңыз...';

  @override
  String get supportLatestOrders => 'Акыркы буйрутмалар';

  @override
  String supportLatestOrdersTitle(String name) {
    return '$name акыркы буйрутмалары';
  }

  @override
  String get supportNoOrders => 'Бул кардардын буйрутмалары жок';

  @override
  String supportNewMessageToast(String name, String message) {
    return '$name жаңы билдирүү: $message';
  }

  @override
  String get supportOpenChat => 'Чатты ачуу';

  @override
  String get notificationsTitle => 'Билдирмелер';

  @override
  String get notificationsEmptySubtitle =>
      'Safeer Market\'те жаңы арзандатуулар же журналдар чыкканда дароо кабарлайбыз';

  @override
  String notificationsLoadFailed(String error) {
    return 'Билдирмелерди жүктөө мүмкүн болбоду: $error';
  }

  @override
  String get notificationsSetupMissing =>
      'Билдирмелер азырынча орнотула элек. Supabase SQL Editor аркылуу supabase/migrations/20261114220000_app_notifications.sql файлын иштетиңиз.';

  @override
  String get notificationsNotAllowed =>
      'Билдирмелерди жөнөтүү жана өчүрүү администраторго гана жеткиликтүү';

  @override
  String get timeJustNow => 'Азыр эле';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мүнөт мурун',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count саат мурун',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн мурун',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => 'Жалпы';

  @override
  String get notificationTypePromo => 'Арзандатуулар';

  @override
  String get notificationTypeMagazine => 'Жаңы журнал';

  @override
  String get notificationTypeOrder => 'Буйрутмаларыңыз';

  @override
  String get notificationTypeSupportChat => 'Кардардык кызмат';

  @override
  String get adminSendNotifications => 'Билдирме жөнөтүү';

  @override
  String get adminNotificationFormSubtitle =>
      'Бардык кардарлардын тиркемесинде дароо көрүнөт';

  @override
  String get adminNotificationTitleLabel => 'Билдирменин аталышы';

  @override
  String get adminNotificationTitleHint =>
      'Мисалы: Айдын арзандатуу журналы чыкты! 🔥';

  @override
  String get adminNotificationTitleRequired => 'Билдирменин аталышын жазыңыз';

  @override
  String get adminNotificationBodyLabel => 'Билдирменин тексти';

  @override
  String get adminNotificationBodyHint =>
      'Мисалы: Safeer Market\'тин эң жаңы арзандатууларын карап чыгыңыз';

  @override
  String get adminNotificationBodyRequired => 'Билдирменин текстин жазыңыз';

  @override
  String get adminNotificationTypeLabel => 'Билдирменин түрү';

  @override
  String get adminNotificationImageLabel =>
      'Сүрөттүн шилтемеси - милдеттүү эмес';

  @override
  String get adminNotificationImageInvalid =>
      'https:// менен башталган туура шилтеме жазыңыз';

  @override
  String get adminSendNotificationButton => 'Бардык кардарларга жөнөтүү';

  @override
  String get adminNotificationSent => 'Билдирме бардык кардарларга жөнөтүлдү';

  @override
  String adminNotificationSendFailed(String error) {
    return 'Билдирмени жөнөтүү мүмкүн болбоду: $error';
  }

  @override
  String get adminNotificationsHistory => 'Жөнөтүлгөн билдирмелер';

  @override
  String get adminNoNotificationsSent => 'Азырынча билдирме жөнөтүлө элек';

  @override
  String get adminDeleteNotificationTitle => 'Билдирмени өчүрүү';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return '«$title» билдирмесин өчүрөсүзбү? Ал кардарлардын тиркемесинен жоголот.';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return 'Билдирмени өчүрүү мүмкүн болбоду: $error';
  }

  @override
  String get orderCardShowDetails => 'Толугураак';

  @override
  String get orderCardHideDetails => 'Жашыруу';

  @override
  String get orderCardItemsTitle => 'Буйрутмадагы товарлар';

  @override
  String get orderCardItemsFailed =>
      'Буйрутманын товарларын жүктөө мүмкүн болбоду';

  @override
  String get orderCardNoItems => 'Бул буйрутмада товарлар жок';

  @override
  String get orderCardCancelledNote => 'Бул буйрутма жокко чыгарылды';

  @override
  String get cancelOrder => 'Буйрутманы жокко чыгаруу';

  @override
  String get cancelOrderConfirmTitle => 'Буйрутманы жокко чыгарасызбы?';

  @override
  String get cancelOrderReasonPrompt => 'Жокко чыгаруу себебин тандаңыз:';

  @override
  String get cancelOrderDismiss => 'Артка';

  @override
  String get cancelOrderConfirm => 'Жокко чыгарууну ырастоо';

  @override
  String get cancelReasonDeliveryDelay => 'Жеткирүү кечикти';

  @override
  String get cancelReasonOrderedByMistake => 'Каталап заказ кылдым';

  @override
  String get cancelReasonChangedMind => 'Оюм өзгөрдү';

  @override
  String get cancelReasonOther => 'Башка себеп';

  @override
  String cancellationReasonLine(String reason) {
    return 'Жокко чыгаруу себеби: $reason';
  }

  @override
  String get orderCancelledSuccess => 'Буйрутма ийгиликтүү жокко чыгарылды';

  @override
  String get orderCancelTooLate =>
      'Буйрутма даяр же жолдо болгондуктан жокко чыгаруу мүмкүн эмес';

  @override
  String get orderCancelSetupMissing =>
      'Буйрутманы жокко чыгаруу азырынча орнотула элек. Supabase SQL Editor аркылуу supabase/migrations/20261114240000_customer_cancel_order.sql файлын иштетиңиз.';

  @override
  String orderCancelFailed(String error) {
    return 'Буйрутманы жокко чыгаруу мүмкүн болбоду: $error';
  }

  @override
  String get adminMenuReceiveOrders => 'Буйрутма кабыл алуу';

  @override
  String get adminMenuOrderStatus => 'Буйрутма абалы';

  @override
  String get adminStatusDelayedShort => 'Кечиккен';

  @override
  String get adminStatusCancelledShort => 'Жокко чыгарылган';

  @override
  String get adminResendNotification => 'Кайра жөнөтүү';

  @override
  String get adminResendFillForm => 'Форманы толтуруу';

  @override
  String get adminResendNotificationTitle =>
      'Бул билдирмени кайра жөнөтөсүзбү?';

  @override
  String adminResendNotificationConfirm(String title) {
    return '«$title» билдирмеси кайра бардык кардарларга жөнөтүлөт.';
  }

  @override
  String get adminNotificationSearchHint => 'Аталышы боюнча издөө';

  @override
  String get adminNotificationFilterByDate => 'Дата боюнча чыпкалоо';

  @override
  String get adminNotificationFilterByType => 'Түр боюнча чыпкалоо';

  @override
  String get adminNotificationClearDateFilter => 'Дата чыпкасын тазалоо';

  @override
  String get adminSelectCustomerFirst =>
      'Буйрутманы баштоо үчүн кардарды тандаңыз';
}
