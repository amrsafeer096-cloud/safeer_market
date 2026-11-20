import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ky'),
    Locale('ms'),
    Locale('uz'),
    Locale('zh')
  ];

  /// No description provided for @bannerShopBrandProducts.
  ///
  /// In ar, this message translates to:
  /// **'تسوق منتجات الشركة'**
  String get bannerShopBrandProducts;

  /// No description provided for @bannerAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إعلان شركة'**
  String get bannerAdd;

  /// No description provided for @bannerTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة / عنوان الإعلان'**
  String get bannerTitleLabel;

  /// No description provided for @bannerKeywordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة البحث عن منتجات الشركة'**
  String get bannerKeywordLabel;

  /// No description provided for @bannerKeywordHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: جهينة'**
  String get bannerKeywordHint;

  /// No description provided for @bannerChooseImage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة الإعلان'**
  String get bannerChooseImage;

  /// No description provided for @bannerChangeImage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get bannerChangeImage;

  /// No description provided for @bannerImageRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة الإعلان أولاً'**
  String get bannerImageRequired;

  /// No description provided for @bannerKeywordRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة البحث التي تفتح منتجات الشركة'**
  String get bannerKeywordRequired;

  /// No description provided for @bannerSaved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الإعلان بنجاح'**
  String get bannerSaved;

  /// No description provided for @bannerSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الإعلان: {error}'**
  String bannerSaveFailed(String error);

  /// No description provided for @bannerDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف إعلان «{title}»؟'**
  String bannerDeleteConfirm(String title);

  /// No description provided for @bannerExistingHeader.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات الحالية'**
  String get bannerExistingHeader;

  /// Application title shown in the system and home header
  ///
  /// In ar, this message translates to:
  /// **'سفير ماركت'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get search;

  /// No description provided for @cart.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cart;

  /// No description provided for @wallet.
  ///
  /// In ar, this message translates to:
  /// **'المحفظة'**
  String get wallet;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @exitHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرة أخرى للخروج من التطبيق'**
  String get exitHint;

  /// No description provided for @newProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات جديدة'**
  String get newProducts;

  /// No description provided for @trendingOffers.
  ///
  /// In ar, this message translates to:
  /// **'عروض رائجة'**
  String get trendingOffers;

  /// No description provided for @noNewNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات جديدة'**
  String get noNewNotifications;

  /// No description provided for @loadingLatestProducts.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل أحدث المنتجات...'**
  String get loadingLatestProducts;

  /// No description provided for @noNewProductsLast3Days.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات جديدة خلال آخر 3 أيام'**
  String get noNewProductsLast3Days;

  /// No description provided for @loadingOffers.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل العروض...'**
  String get loadingOffers;

  /// No description provided for @noOffersCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عروض حالياً'**
  String get noOffersCurrently;

  /// No description provided for @subscribersExclusiveFeature.
  ///
  /// In ar, this message translates to:
  /// **'ميزة حصرية للمشتركين 👑'**
  String get subscribersExclusiveFeature;

  /// No description provided for @playAndWinPaywallBody.
  ///
  /// In ar, this message translates to:
  /// **'لعبة \"العب واكسب\" والهدايا الأسبوعية متاحة فقط لمشتركي باقات سفير برايم وسفير برو. رقي حسابك واستمتع بالمميزات!'**
  String get playAndWinPaywallBody;

  /// No description provided for @upgradeAccountNow.
  ///
  /// In ar, this message translates to:
  /// **'رقي حسابك الآن'**
  String get upgradeAccountNow;

  /// No description provided for @exploreSafeer.
  ///
  /// In ar, this message translates to:
  /// **'استكشف سفير'**
  String get exploreSafeer;

  /// No description provided for @featuredProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات مختارة'**
  String get featuredProducts;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المنتجات'**
  String get failedToLoadProducts;

  /// No description provided for @noProductsCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات حالياً'**
  String get noProductsCurrently;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loyaltyPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقاط الولاء'**
  String get loyaltyPoints;

  /// No description provided for @spinWheelCollectPoints.
  ///
  /// In ar, this message translates to:
  /// **'لف العجلة واجمع النقاط'**
  String get spinWheelCollectPoints;

  /// No description provided for @favoriteProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات المفضلة'**
  String get favoriteProducts;

  /// No description provided for @myOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myOrders;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'تحدث معنا'**
  String get contactUs;

  /// No description provided for @help.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get help;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك'**
  String get signIn;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حسابك؟'**
  String get signOutConfirmMessage;

  /// No description provided for @signedOut.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج'**
  String get signedOut;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم الإدارة'**
  String get adminDashboard;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة طلبات العملاء وتحديث حالتها'**
  String get adminDashboardSubtitle;

  /// No description provided for @guestName.
  ///
  /// In ar, this message translates to:
  /// **'ضيفنا'**
  String get guestName;

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك يا {name}'**
  String welcomeUser(String name);

  /// No description provided for @guestSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لتتابع طلباتك ومفضلتك'**
  String get guestSubtitle;

  /// No description provided for @personalData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الشخصية'**
  String get personalData;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @savedAddresses.
  ///
  /// In ar, this message translates to:
  /// **'العناوين المحفوظة'**
  String get savedAddresses;

  /// No description provided for @savedCards.
  ///
  /// In ar, this message translates to:
  /// **'البطاقات المحفوظة'**
  String get savedCards;

  /// No description provided for @messageAndSmsAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الرسائل والرسائل النصية'**
  String get messageAndSmsAlerts;

  /// No description provided for @privacyAndTerms.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية والشروط'**
  String get privacyAndTerms;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف حسابك وجميع بياناتك نهائياً. هل أنت متأكد؟'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف حسابك بنجاح'**
  String get deleteAccountSuccess;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تحتوي كلمة المرور على:'**
  String get passwordRequirementsTitle;

  /// No description provided for @passwordRuleMinLength.
  ///
  /// In ar, this message translates to:
  /// **'8 حروف على الأقل'**
  String get passwordRuleMinLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In ar, this message translates to:
  /// **'حرف كبير واحد على الأقل'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In ar, this message translates to:
  /// **'حرف صغير واحد على الأقل'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleDigit.
  ///
  /// In ar, this message translates to:
  /// **'رقم واحد على الأقل'**
  String get passwordRuleDigit;

  /// No description provided for @talkToUs.
  ///
  /// In ar, this message translates to:
  /// **'تحدث معنا'**
  String get talkToUs;

  /// No description provided for @supportWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get supportWhatsApp;

  /// No description provided for @supportLiveChat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة فورية مع خدمة العملاء'**
  String get supportLiveChat;

  /// No description provided for @loyaltyPointsRedeem.
  ///
  /// In ar, this message translates to:
  /// **'{count} نقطة • استبدال'**
  String loyaltyPointsRedeem(int count);

  /// No description provided for @loyaltyPointsEarnNow.
  ///
  /// In ar, this message translates to:
  /// **'نقاط الولاء • اكسب الآن 🎁'**
  String get loyaltyPointsEarnNow;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get ok;

  /// No description provided for @noEmail.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بريد إلكتروني'**
  String get noEmail;

  /// No description provided for @changeEmailContactSupport.
  ///
  /// In ar, this message translates to:
  /// **'لتغيير البريد الإلكتروني يرجى التواصل مع الدعم'**
  String get changeEmailContactSupport;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In ar, this message translates to:
  /// **'نحن في سفير ماركت نحترم خصوصيتك. نستخدم بياناتك مثل الاسم ورقم الهاتف والعنوان فقط لتوصيل طلباتك وتحسين خدماتنا، ولا نشاركها مع أي طرف ثالث دون موافقتك.\n\nباستخدامك للتطبيق فإنك توافق على شروط الاستخدام، بما في ذلك سياسات الطلب والتوصيل والاسترجاع. سيتم نشر النسخة الكاملة من السياسة قريباً.'**
  String get privacyPolicyBody;

  /// No description provided for @helpTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف يمكننا مساعدتك؟'**
  String get helpTitle;

  /// No description provided for @helpBody.
  ///
  /// In ar, this message translates to:
  /// **'فريق سفير ماركت جاهز دائماً لخدمتك.\nإذا واجهتك أي مشكلة في طلبك أو لديك استفسار، تواصل معنا وسنرد عليك في أسرع وقت.'**
  String get helpBody;

  /// No description provided for @callUs.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بنا'**
  String get callUs;

  /// No description provided for @callUsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحدث مع خدمة العملاء مباشرة'**
  String get callUsSubtitle;

  /// No description provided for @whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsapp;

  /// No description provided for @whatsappSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راسلنا وسنرد عليك سريعاً'**
  String get whatsappSubtitle;

  /// No description provided for @messageAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الرسائل'**
  String get messageAlerts;

  /// No description provided for @appNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات التطبيق'**
  String get appNotifications;

  /// No description provided for @appNotificationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'العروض وتحديثات حالة الطلب'**
  String get appNotificationsSubtitle;

  /// No description provided for @smsMessages.
  ///
  /// In ar, this message translates to:
  /// **'رسائل SMS'**
  String get smsMessages;

  /// No description provided for @smsMessagesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رسائل نصية بتأكيد الطلب والتوصيل'**
  String get smsMessagesSubtitle;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @shopNow.
  ///
  /// In ar, this message translates to:
  /// **'تسوق الآن'**
  String get shopNow;

  /// No description provided for @scanBarcode.
  ///
  /// In ar, this message translates to:
  /// **'مسح الباركود'**
  String get scanBarcode;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'الأقسام'**
  String get categories;

  /// No description provided for @magazines.
  ///
  /// In ar, this message translates to:
  /// **'المجلات'**
  String get magazines;

  /// No description provided for @addMagazine.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلة'**
  String get addMagazine;

  /// No description provided for @unexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get unexpectedError;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالشبكة'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في الخادم'**
  String get serverError;

  /// No description provided for @serverConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالخادم، حاول مرة أخرى'**
  String get serverConnectionError;

  /// No description provided for @pleaseSignInFirst.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تسجيل الدخول أولاً'**
  String get pleaseSignInFirst;

  /// No description provided for @noPermissionToEditOrder.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية تعديل هذا الطلب'**
  String get noPermissionToEditOrder;

  /// No description provided for @orderUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث الطلب: {error}'**
  String orderUpdateFailed(String error);

  /// No description provided for @ordersLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الطلبات\n{error}'**
  String ordersLoadFailed(String error);

  /// No description provided for @orderNumber.
  ///
  /// In ar, this message translates to:
  /// **'طلب #{id}'**
  String orderNumber(String id);

  /// No description provided for @deletedProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج محذوف'**
  String get deletedProduct;

  /// No description provided for @product.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get product;

  /// No description provided for @addNewAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get addNewAddress;

  /// No description provided for @manageAddresses.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العناوين'**
  String get manageAddresses;

  /// No description provided for @editLocation.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الموقع'**
  String get editLocation;

  /// No description provided for @helloName.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً يا {name}'**
  String helloName(String name);

  /// No description provided for @cardNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم البطاقة'**
  String get cardNumber;

  /// No description provided for @cardholderName.
  ///
  /// In ar, this message translates to:
  /// **'اسم حامل البطاقة'**
  String get cardholderName;

  /// No description provided for @asWrittenOnCard.
  ///
  /// In ar, this message translates to:
  /// **'كما هو مكتوب على البطاقة'**
  String get asWrittenOnCard;

  /// No description provided for @expiryDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get expiryDate;

  /// No description provided for @addBankCard.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بطاقة بنكية'**
  String get addBankCard;

  /// No description provided for @bankCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة بنكية'**
  String get bankCard;

  /// No description provided for @adminPaidByVisa.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع بالفيزا'**
  String get adminPaidByVisa;

  /// No description provided for @cameraOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح الكاميرا، تحقق من صلاحية الكاميرا'**
  String get cameraOpenFailed;

  /// No description provided for @addressLabelHome.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get addressLabelHome;

  /// No description provided for @addressLabelWork.
  ///
  /// In ar, this message translates to:
  /// **'العمل'**
  String get addressLabelWork;

  /// No description provided for @puzzleGame.
  ///
  /// In ar, this message translates to:
  /// **'لعبة البازل'**
  String get puzzleGame;

  /// No description provided for @luckyWheel.
  ///
  /// In ar, this message translates to:
  /// **'عجلة الحظ'**
  String get luckyWheel;

  /// No description provided for @awesome.
  ///
  /// In ar, this message translates to:
  /// **'رائع!'**
  String get awesome;

  /// No description provided for @customer.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get customer;

  /// No description provided for @noLocationForOrder.
  ///
  /// In ar, this message translates to:
  /// **'لا يتوفر موقع لهذا الطلب'**
  String get noLocationForOrder;

  /// No description provided for @branch.
  ///
  /// In ar, this message translates to:
  /// **'الفرع'**
  String get branch;

  /// No description provided for @safeerCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل سفير'**
  String get safeerCustomer;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @cashOnDelivery.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عند الاستلام'**
  String get cashOnDelivery;

  /// No description provided for @orderStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get orderStatusPending;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In ar, this message translates to:
  /// **'جاري التجهيز'**
  String get orderStatusPreparing;

  /// No description provided for @orderStatusReadyForDelivery.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للتوصيل'**
  String get orderStatusReadyForDelivery;

  /// No description provided for @orderStatusOutForDelivery.
  ///
  /// In ar, this message translates to:
  /// **'في الطريق'**
  String get orderStatusOutForDelivery;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get orderStatusCancelled;

  /// No description provided for @statusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get statusNew;

  /// No description provided for @startPreparing.
  ///
  /// In ar, this message translates to:
  /// **'بدء التجهيز'**
  String get startPreparing;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @inStock.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get outOfStock;

  /// No description provided for @decreaseQuantity.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الكمية'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الكمية'**
  String get increaseQuantity;

  /// No description provided for @decreaseWeight.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الوزن'**
  String get decreaseWeight;

  /// No description provided for @increaseWeight.
  ///
  /// In ar, this message translates to:
  /// **'زيادة الوزن'**
  String get increaseWeight;

  /// No description provided for @addToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف للسلة'**
  String get addToCart;

  /// No description provided for @cartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'سلتك فارغة'**
  String get cartEmpty;

  /// No description provided for @productUnavailableNow.
  ///
  /// In ar, this message translates to:
  /// **'هذا المنتج غير متوفر حالياً'**
  String get productUnavailableNow;

  /// No description provided for @distanceFromBranch.
  ///
  /// In ar, this message translates to:
  /// **'يبعد {distance} عن الفرع'**
  String distanceFromBranch(String distance);

  /// No description provided for @invoiceNumberRequired.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة مطلوب'**
  String get invoiceNumberRequired;

  /// No description provided for @addAtLeastOneItem.
  ///
  /// In ar, this message translates to:
  /// **'أضف صنفاً واحداً على الأقل'**
  String get addAtLeastOneItem;

  /// No description provided for @orderOnTheWayToYou.
  ///
  /// In ar, this message translates to:
  /// **'الطلب في الطريق إليك!'**
  String get orderOnTheWayToYou;

  /// No description provided for @deliveryFee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل'**
  String get deliveryFee;

  /// No description provided for @currencySymbol.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get currencySymbol;

  /// No description provided for @unitPiece.
  ///
  /// In ar, this message translates to:
  /// **'قطعة'**
  String get unitPiece;

  /// No description provided for @unitKilo.
  ///
  /// In ar, this message translates to:
  /// **'كيلو'**
  String get unitKilo;

  /// No description provided for @gramsValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} جرام'**
  String gramsValue(String value);

  /// No description provided for @kilosValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} كيلو'**
  String kilosValue(String value);

  /// No description provided for @kmValue.
  ///
  /// In ar, this message translates to:
  /// **'{value} كم'**
  String kmValue(String value);

  /// No description provided for @sessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى'**
  String get sessionExpired;

  /// No description provided for @adminStatusUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث الحالة: {error}'**
  String adminStatusUpdateFailed(String error);

  /// No description provided for @adminDeleteMagazineTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المجلة'**
  String get adminDeleteMagazineTitle;

  /// No description provided for @adminDeleteMagazineConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف «{title}»؟'**
  String adminDeleteMagazineConfirm(String title);

  /// No description provided for @adminDeleteMagazineFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف المجلة: {error}'**
  String adminDeleteMagazineFailed(String error);

  /// No description provided for @adminErrorWithDetails.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String adminErrorWithDetails(String error);

  /// No description provided for @adminNoMagazinesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلات بعد. اضغط «إضافة مجلة» لرفع أول مجلة.'**
  String get adminNoMagazinesYet;

  /// No description provided for @adminMagazineExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get adminMagazineExpired;

  /// No description provided for @adminMagazineUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get adminMagazineUpcoming;

  /// No description provided for @adminMagazineActive.
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get adminMagazineActive;

  /// No description provided for @adminMagazineDateRange.
  ///
  /// In ar, this message translates to:
  /// **'من {start} إلى {end}'**
  String adminMagazineDateRange(String start, String end);

  /// No description provided for @adminPickMagazinePdfTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف المجلة (PDF)'**
  String get adminPickMagazinePdfTitle;

  /// No description provided for @adminMagazineStartDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية'**
  String get adminMagazineStartDate;

  /// No description provided for @adminMagazineEndDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النهاية'**
  String get adminMagazineEndDate;

  /// No description provided for @adminMagazineTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنوان المجلة'**
  String get adminMagazineTitleRequired;

  /// No description provided for @adminMagazineCoverRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة الغلاف'**
  String get adminMagazineCoverRequired;

  /// No description provided for @adminMagazinePdfRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملف PDF للمجلة'**
  String get adminMagazinePdfRequired;

  /// No description provided for @adminMagazineEndBeforeStart.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النهاية يجب أن يكون بعد تاريخ البداية'**
  String get adminMagazineEndBeforeStart;

  /// No description provided for @adminMagazineAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة المجلة بنجاح'**
  String get adminMagazineAdded;

  /// No description provided for @adminMagazineSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ المجلة: {error}'**
  String adminMagazineSaveFailed(String error);

  /// No description provided for @adminAddNewMagazine.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلة جديدة'**
  String get adminAddNewMagazine;

  /// No description provided for @adminMagazineTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المجلة'**
  String get adminMagazineTitleLabel;

  /// No description provided for @adminPickCoverImage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة الغلاف'**
  String get adminPickCoverImage;

  /// No description provided for @adminChangeCover.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الغلاف'**
  String get adminChangeCover;

  /// No description provided for @adminPickPdfFile.
  ///
  /// In ar, this message translates to:
  /// **'اختيار ملف PDF'**
  String get adminPickPdfFile;

  /// No description provided for @adminUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الرفع...'**
  String get adminUploading;

  /// No description provided for @adminSupervisorPermissions.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات المشرف'**
  String get adminSupervisorPermissions;

  /// No description provided for @adminEnterPinHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل PIN (1234)'**
  String get adminEnterPinHint;

  /// No description provided for @adminSupervisorModeEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل وضع المشرف'**
  String get adminSupervisorModeEnabled;

  /// No description provided for @adminInvalidPin.
  ///
  /// In ar, this message translates to:
  /// **'PIN غير صحيح'**
  String get adminInvalidPin;

  /// No description provided for @adminActivate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get adminActivate;

  /// No description provided for @adminAppBarTitleManagement.
  ///
  /// In ar, this message translates to:
  /// **'{appName} - الإدارة'**
  String adminAppBarTitleManagement(String appName);

  /// No description provided for @adminAppBarTitleWorkspace.
  ///
  /// In ar, this message translates to:
  /// **'{appName} - لوحة العمل'**
  String adminAppBarTitleWorkspace(String appName);

  /// No description provided for @adminCloseManagement.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الإدارة'**
  String get adminCloseManagement;

  /// No description provided for @adminEnableManagement.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإدارة'**
  String get adminEnableManagement;

  /// No description provided for @adminExitToStore.
  ///
  /// In ar, this message translates to:
  /// **'خروج للمتجر'**
  String get adminExitToStore;

  /// No description provided for @adminMenuOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get adminMenuOrders;

  /// No description provided for @adminMenuProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get adminMenuProducts;

  /// No description provided for @adminMenuStaff.
  ///
  /// In ar, this message translates to:
  /// **'طاقم العمل'**
  String get adminMenuStaff;

  /// No description provided for @adminMenuReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير واليومية'**
  String get adminMenuReports;

  /// No description provided for @adminStatusPreparingShort.
  ///
  /// In ar, this message translates to:
  /// **'تحضير'**
  String get adminStatusPreparingShort;

  /// No description provided for @adminStatusReadyForDriverShort.
  ///
  /// In ar, this message translates to:
  /// **'للطيار'**
  String get adminStatusReadyForDriverShort;

  /// No description provided for @adminStatusDeliveryShort.
  ///
  /// In ar, this message translates to:
  /// **'توصيل'**
  String get adminStatusDeliveryShort;

  /// No description provided for @adminStatusCompletedShort.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get adminStatusCompletedShort;

  /// No description provided for @adminStatusUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get adminStatusUnknown;

  /// No description provided for @adminNoOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get adminNoOrders;

  /// No description provided for @adminSelectOrderFromList.
  ///
  /// In ar, this message translates to:
  /// **'اختر طلب من القائمة'**
  String get adminSelectOrderFromList;

  /// No description provided for @adminItemsToPrepare.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات المطلوبة للتجهيز:'**
  String get adminItemsToPrepare;

  /// No description provided for @adminNoItemsInOrder.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مسجلة'**
  String get adminNoItemsInOrder;

  /// No description provided for @adminAvailableActions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات المتاحة'**
  String get adminAvailableActions;

  /// No description provided for @adminOrderAwaitingPreparer.
  ///
  /// In ar, this message translates to:
  /// **'الطلب بانتظار محضر'**
  String get adminOrderAwaitingPreparer;

  /// No description provided for @adminPreparerName.
  ///
  /// In ar, this message translates to:
  /// **'المحضر: {name}'**
  String adminPreparerName(String name);

  /// No description provided for @adminAwaitingDriverAssignment.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المشرف لتحديد الطيار'**
  String get adminAwaitingDriverAssignment;

  /// No description provided for @adminPickUpAndStartRoute.
  ///
  /// In ar, this message translates to:
  /// **'استلام وبدء التوجه 🗺️'**
  String get adminPickUpAndStartRoute;

  /// No description provided for @adminDriverName.
  ///
  /// In ar, this message translates to:
  /// **'الطيار: {name}'**
  String adminDriverName(String name);

  /// No description provided for @adminOrderReadyAwaitingDriver.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز الطلب بنجاح. في انتظار استلام الطيار.'**
  String get adminOrderReadyAwaitingDriver;

  /// No description provided for @adminMarkDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التوصيل بنجاح 💵'**
  String get adminMarkDelivered;

  /// No description provided for @adminCloseOrderPermanently.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الطلب نهائياً'**
  String get adminCloseOrderPermanently;

  /// No description provided for @adminOrderWithDriverOnTheWay.
  ///
  /// In ar, this message translates to:
  /// **'الطلب الآن مع الطيار في الطريق للعميل.'**
  String get adminOrderWithDriverOnTheWay;

  /// No description provided for @adminOrderDeliveredAndClosed.
  ///
  /// In ar, this message translates to:
  /// **'تم توصيل هذا الطلب وإغلاقه بنجاح.'**
  String get adminOrderDeliveredAndClosed;

  /// No description provided for @adminWhoAreYouPickName.
  ///
  /// In ar, this message translates to:
  /// **'أنت مين؟ (اختر اسمك للبدء)'**
  String get adminWhoAreYouPickName;

  /// No description provided for @adminNoPreparers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محضرين'**
  String get adminNoPreparers;

  /// No description provided for @adminFinishOrderPreparation.
  ///
  /// In ar, this message translates to:
  /// **'إتمام تجهيز الطلب'**
  String get adminFinishOrderPreparation;

  /// No description provided for @adminCheckAllItemsFirst.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ عذراً، يجب تحديد جميع المنتجات بعلامة (صح) أولاً.'**
  String get adminCheckAllItemsFirst;

  /// No description provided for @adminPreparationFinished.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء التجهيز بنجاح.'**
  String get adminPreparationFinished;

  /// No description provided for @adminAssignDriverTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الطيار (صلاحية المشرف)'**
  String get adminAssignDriverTitle;

  /// No description provided for @adminSelectDriver.
  ///
  /// In ar, this message translates to:
  /// **'اختر الطيار'**
  String get adminSelectDriver;

  /// No description provided for @adminOrderAssignedToDriver.
  ///
  /// In ar, this message translates to:
  /// **'تم إسناد الطلب للطيار بنجاح'**
  String get adminOrderAssignedToDriver;

  /// No description provided for @adminAssignToSelectedDriver.
  ///
  /// In ar, this message translates to:
  /// **'إسناد للطيار المختار'**
  String get adminAssignToSelectedDriver;

  /// No description provided for @adminCallFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال'**
  String get adminCallFailed;

  /// No description provided for @adminNoPhoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'بدون رقم'**
  String get adminNoPhoneNumber;

  /// No description provided for @adminNoName.
  ///
  /// In ar, this message translates to:
  /// **'بدون اسم'**
  String get adminNoName;

  /// No description provided for @adminAddressNotSet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم التحديد'**
  String get adminAddressNotSet;

  /// No description provided for @adminCustomerInfo.
  ///
  /// In ar, this message translates to:
  /// **'بيانات العميل'**
  String get adminCustomerInfo;

  /// No description provided for @adminManageProducts.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المنتجات'**
  String get adminManageProducts;

  /// No description provided for @adminActiveProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات المفعلة'**
  String get adminActiveProducts;

  /// No description provided for @adminInactiveProducts.
  ///
  /// In ar, this message translates to:
  /// **'غير مفعلة'**
  String get adminInactiveProducts;

  /// No description provided for @adminSearchProductByName.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج بالاسم...'**
  String get adminSearchProductByName;

  /// No description provided for @adminErrorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String adminErrorOccurred(String error);

  /// No description provided for @adminNoProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات'**
  String get adminNoProducts;

  /// No description provided for @adminCopyProductName.
  ///
  /// In ar, this message translates to:
  /// **'نسخ اسم المنتج'**
  String get adminCopyProductName;

  /// No description provided for @adminCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get adminCopied;

  /// No description provided for @adminCopyBarcode.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الباركود'**
  String get adminCopyBarcode;

  /// No description provided for @adminBarcodeValue.
  ///
  /// In ar, this message translates to:
  /// **'باركود: {barcode}'**
  String adminBarcodeValue(String barcode);

  /// No description provided for @adminUpdateErrorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء التحديث'**
  String get adminUpdateErrorOccurred;

  /// No description provided for @adminManageStaff.
  ///
  /// In ar, this message translates to:
  /// **'إدارة طاقم العاملين'**
  String get adminManageStaff;

  /// No description provided for @adminAddEmployee.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get adminAddEmployee;

  /// No description provided for @adminNoStaff.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفين مسجلين'**
  String get adminNoStaff;

  /// No description provided for @adminRoleTaker.
  ///
  /// In ar, this message translates to:
  /// **'تيكر'**
  String get adminRoleTaker;

  /// No description provided for @adminRolePreparer.
  ///
  /// In ar, this message translates to:
  /// **'محضر'**
  String get adminRolePreparer;

  /// No description provided for @adminRoleDriver.
  ///
  /// In ar, this message translates to:
  /// **'طيار'**
  String get adminRoleDriver;

  /// No description provided for @adminNoPhone.
  ///
  /// In ar, this message translates to:
  /// **'بدون هاتف'**
  String get adminNoPhone;

  /// No description provided for @adminReportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التقارير واليومية المجمعة'**
  String get adminReportsTitle;

  /// No description provided for @adminTotalSalesCollected.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات (المحصلة)'**
  String get adminTotalSalesCollected;

  /// No description provided for @adminDeliveredOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مكتملة وتم توصيلها'**
  String get adminDeliveredOrdersTitle;

  /// No description provided for @adminOrdersInPreparationTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات قيد التحضير حالياً'**
  String get adminOrdersInPreparationTitle;

  /// No description provided for @adminCancelledOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات ملغاة'**
  String get adminCancelledOrdersTitle;

  /// No description provided for @adminTotalOrdersCumulative.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الطلبات (التراكمي)'**
  String get adminTotalOrdersCumulative;

  /// No description provided for @adminOrdersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} طلب'**
  String adminOrdersCount(String count);

  /// No description provided for @adminRecentOrdersLog.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلبات الأخير'**
  String get adminRecentOrdersLog;

  /// No description provided for @adminOrderNumberColumn.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب'**
  String get adminOrderNumberColumn;

  /// No description provided for @adminCustomerNameColumn.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get adminCustomerNameColumn;

  /// No description provided for @adminStatusColumn.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get adminStatusColumn;

  /// No description provided for @paymentMethodCashLabel.
  ///
  /// In ar, this message translates to:
  /// **'كاش عند الاستلام'**
  String get paymentMethodCashLabel;

  /// No description provided for @paymentMethodCardLabel.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة بنكية (فيزا/ماستركارد)'**
  String get paymentMethodCardLabel;

  /// No description provided for @paymentMethodInstaPayLabel.
  ///
  /// In ar, this message translates to:
  /// **'إنستا باي (InstaPay)'**
  String get paymentMethodInstaPayLabel;

  /// No description provided for @paymentMethodInstaPaySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحويل فوري عبر تطبيق InstaPay'**
  String get paymentMethodInstaPaySubtitle;

  /// No description provided for @instaPayOpenApp.
  ///
  /// In ar, this message translates to:
  /// **'افتح تطبيق InstaPay للدفع الآن'**
  String get instaPayOpenApp;

  /// No description provided for @instaPayIpaLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الدفع اللحظي IPA'**
  String get instaPayIpaLabel;

  /// No description provided for @instaPayPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'أو التحويل برقم الهاتف'**
  String get instaPayPhoneLabel;

  /// No description provided for @instaPayCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get instaPayCopy;

  /// No description provided for @instaPayCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get instaPayCopied;

  /// No description provided for @instaPayConfirmHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد إتمام التحويل بقيمة الطلب عبر إنستا باي، اضغط على تأكيد الطلب بالأسفل.'**
  String get instaPayConfirmHint;

  /// No description provided for @instaPayReceiptTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيصال التحويل البنكي (سكرين شوت)'**
  String get instaPayReceiptTitle;

  /// No description provided for @instaPayReceiptHint.
  ///
  /// In ar, this message translates to:
  /// **'يجب إرفاق لقطة شاشة لنجاح عملية التحويل من تطبيق إنستا باي لتأكيد الطلب'**
  String get instaPayReceiptHint;

  /// No description provided for @instaPayReceiptPick.
  ///
  /// In ar, this message translates to:
  /// **'اختر صورة الإيصال أو التقاط صورة'**
  String get instaPayReceiptPick;

  /// No description provided for @instaPayReceiptRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إرفاق صورة إيصال التحويل أولاً'**
  String get instaPayReceiptRequired;

  /// No description provided for @adminViewTransferReceipt.
  ///
  /// In ar, this message translates to:
  /// **'عرض إيصال التحويل'**
  String get adminViewTransferReceipt;

  /// No description provided for @adminCopyReceiptImage.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الصورة'**
  String get adminCopyReceiptImage;

  /// No description provided for @adminShareReceipt.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الإيصال'**
  String get adminShareReceipt;

  /// No description provided for @adminReceiptImageCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ صورة الإيصال'**
  String get adminReceiptImageCopied;

  /// No description provided for @adminReceiptActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تنفيذ العملية على صورة الإيصال'**
  String get adminReceiptActionFailed;

  /// No description provided for @subscriptionConfirmInstaPay.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاشتراك'**
  String get subscriptionConfirmInstaPay;

  /// No description provided for @subscriptionPendingSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب الترقية'**
  String get subscriptionPendingSuccessTitle;

  /// No description provided for @subscriptionPendingSuccessBody.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب الترقية وإيصال الدفع. سيتم تفعيل حسابك (Pro) فور مراجعة الإدارة.'**
  String get subscriptionPendingSuccessBody;

  /// No description provided for @adminMenuPendingSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الترقية المعلقة'**
  String get adminMenuPendingSubscriptions;

  /// No description provided for @adminActivateAccount.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الحساب'**
  String get adminActivateAccount;

  /// No description provided for @adminSubscriptionApproved.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل الاشتراك'**
  String get adminSubscriptionApproved;

  /// No description provided for @adminNoPendingSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات ترقية معلقة'**
  String get adminNoPendingSubscriptions;

  /// No description provided for @adminPendingSubscriptionTier.
  ///
  /// In ar, this message translates to:
  /// **'الباقة المطلوبة'**
  String get adminPendingSubscriptionTier;

  /// No description provided for @paymentCopyCardNumber.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رقم البطاقة'**
  String get paymentCopyCardNumber;

  /// No description provided for @paymentCardNumberCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رقم البطاقة'**
  String get paymentCardNumberCopied;

  /// No description provided for @checkoutAddressOutOfRange.
  ///
  /// In ar, this message translates to:
  /// **'العنوان خارج نطاق التوصيل'**
  String get checkoutAddressOutOfRange;

  /// No description provided for @checkoutPinAddressFirst.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقع العنوان على الخريطة أولاً'**
  String get checkoutPinAddressFirst;

  /// No description provided for @checkoutOrderFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إتمام الطلب: {error}'**
  String checkoutOrderFailed(String error);

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get checkoutTitle;

  /// No description provided for @checkoutDeliveryAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get checkoutDeliveryAddress;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutOrderSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطلب'**
  String get checkoutOrderSummary;

  /// No description provided for @checkoutSelectAddressFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر عنوان التوصيل أولاً لإتمام طلبك'**
  String get checkoutSelectAddressFirst;

  /// No description provided for @checkoutPinLocationForFee.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقع العنوان على الخريطة لحساب مصاريف التوصيل'**
  String get checkoutPinLocationForFee;

  /// No description provided for @checkoutOrderPlaced.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلبك بنجاح • رقم الطلب #{id}'**
  String checkoutOrderPlaced(String id);

  /// No description provided for @checkoutOutOfRange.
  ///
  /// In ar, this message translates to:
  /// **'عذراً، العنوان يبعد {distance} وخارج نطاق التوصيل (حتى {maxDistance})'**
  String checkoutOutOfRange(String distance, String maxDistance);

  /// No description provided for @checkoutSignInToChooseAddress.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لاختيار عنوان التوصيل'**
  String get checkoutSignInToChooseAddress;

  /// No description provided for @checkoutPinThisAddressForFee.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقع هذا العنوان على الخريطة لحساب مصاريف التوصيل'**
  String get checkoutPinThisAddressForFee;

  /// No description provided for @checkoutPinLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدد الموقع'**
  String get checkoutPinLocation;

  /// No description provided for @checkoutChangeAddress.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get checkoutChangeAddress;

  /// No description provided for @checkoutAddDeliveryAddress.
  ///
  /// In ar, this message translates to:
  /// **'أضف عنوان التوصيل لإتمام طلبك'**
  String get checkoutAddDeliveryAddress;

  /// No description provided for @checkoutAddAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان'**
  String get checkoutAddAddress;

  /// No description provided for @checkoutNoAddressChosen.
  ///
  /// In ar, this message translates to:
  /// **'لم تختر عنوان التوصيل بعد'**
  String get checkoutNoAddressChosen;

  /// No description provided for @checkoutChooseAddress.
  ///
  /// In ar, this message translates to:
  /// **'اختر العنوان'**
  String get checkoutChooseAddress;

  /// No description provided for @checkoutEstimatedArrival.
  ///
  /// In ar, this message translates to:
  /// **'وقت الوصول المتوقع:'**
  String get checkoutEstimatedArrival;

  /// No description provided for @checkoutDeliveryFeeWithDistance.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل ({distance})'**
  String checkoutDeliveryFeeWithDistance(String distance);

  /// No description provided for @checkoutOutOfDeliveryRange.
  ///
  /// In ar, this message translates to:
  /// **'خارج نطاق التوصيل'**
  String get checkoutOutOfDeliveryRange;

  /// No description provided for @checkoutItemCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد المنتجات'**
  String get checkoutItemCount;

  /// No description provided for @checkoutSubtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get checkoutSubtotal;

  /// No description provided for @checkoutGrandTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي النهائي'**
  String get checkoutGrandTotal;

  /// No description provided for @checkoutConfirmOrder.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب'**
  String get checkoutConfirmOrder;

  /// No description provided for @paymentCardScanUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'مسح البطاقة غير مدعوم على هذا الجهاز'**
  String get paymentCardScanUnsupported;

  /// No description provided for @paymentCardScanFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم نتمكن من قراءة البطاقة، أدخل البيانات يدويًا'**
  String get paymentCardScanFailed;

  /// No description provided for @paymentCardScanned.
  ///
  /// In ar, this message translates to:
  /// **'تمت قراءة البطاقة، راجع البيانات وأدخل رمز CVV'**
  String get paymentCardScanned;

  /// No description provided for @paymentCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدفع بالبطاقة'**
  String get paymentCardTitle;

  /// No description provided for @paymentSecureNotice.
  ///
  /// In ar, this message translates to:
  /// **'عملية دفع آمنة ومشفرة'**
  String get paymentSecureNotice;

  /// No description provided for @paymentPayNow.
  ///
  /// In ar, this message translates to:
  /// **'ادفع الآن • {amount}'**
  String paymentPayNow(String amount);

  /// No description provided for @paymentScanCardTooltip.
  ///
  /// In ar, this message translates to:
  /// **'مسح البطاقة بالكاميرا'**
  String get paymentScanCardTooltip;

  /// No description provided for @paymentAmountDue.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المطلوب'**
  String get paymentAmountDue;

  /// No description provided for @cardNumberRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم البطاقة'**
  String get cardNumberRequired;

  /// No description provided for @cardNumberInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم البطاقة غير صحيح'**
  String get cardNumberInvalid;

  /// No description provided for @cardExpiryRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل التاريخ MM/YY'**
  String get cardExpiryRequired;

  /// No description provided for @cardExpiryInvalidMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهر غير صحيح'**
  String get cardExpiryInvalidMonth;

  /// No description provided for @cardExpired.
  ///
  /// In ar, this message translates to:
  /// **'البطاقة منتهية'**
  String get cardExpired;

  /// No description provided for @cardCvvInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صحيح'**
  String get cardCvvInvalid;

  /// No description provided for @cardHolderNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الاسم كما هو على البطاقة'**
  String get cardHolderNameRequired;

  /// No description provided for @walletCardSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ البطاقة بنجاح'**
  String get walletCardSaved;

  /// No description provided for @walletCardDataProtected.
  ///
  /// In ar, this message translates to:
  /// **'بياناتك محمية ولن نحتفظ برمز CVV'**
  String get walletCardDataProtected;

  /// No description provided for @walletSaveCard.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البطاقة'**
  String get walletSaveCard;

  /// No description provided for @walletAddCardHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف بطاقتك للدفع بشكل أسرع في طلباتك القادمة'**
  String get walletAddCardHint;

  /// No description provided for @walletInAppBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد محفظتك في التطبيق'**
  String get walletInAppBalance;

  /// No description provided for @walletBalanceLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الرصيد'**
  String get walletBalanceLoadFailed;

  /// No description provided for @walletBalanceAutoApplied.
  ///
  /// In ar, this message translates to:
  /// **'يُستخدم رصيدك تلقائياً عند الدفع'**
  String get walletBalanceAutoApplied;

  /// No description provided for @walletSignInToViewBalance.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك لعرض رصيدك'**
  String get walletSignInToViewBalance;

  /// No description provided for @walletCardExpires.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي {expiry}'**
  String walletCardExpires(String expiry);

  /// No description provided for @walletDeleteCard.
  ///
  /// In ar, this message translates to:
  /// **'حذف البطاقة'**
  String get walletDeleteCard;

  /// No description provided for @checkoutUseOrAddNewCard.
  ///
  /// In ar, this message translates to:
  /// **'+ استخدام أو إضافة بطاقة جديدة'**
  String get checkoutUseOrAddNewCard;

  /// No description provided for @checkoutSavedCards.
  ///
  /// In ar, this message translates to:
  /// **'بطاقاتك المحفوظة'**
  String get checkoutSavedCards;

  /// No description provided for @paywallUpgradeAccount.
  ///
  /// In ar, this message translates to:
  /// **'ترقية الحساب'**
  String get paywallUpgradeAccount;

  /// No description provided for @paywallDiscoverSafeer.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف عالم سفير 👑'**
  String get paywallDiscoverSafeer;

  /// No description provided for @paywallChoosePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر الباقة التي تناسب احتياجاتك ووفر أكثر مع كل طلب.'**
  String get paywallChoosePlan;

  /// No description provided for @paywallProTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفير برو (VIP)'**
  String get paywallProTitle;

  /// No description provided for @paywallPerMonth.
  ///
  /// In ar, this message translates to:
  /// **'/ شهرياً'**
  String get paywallPerMonth;

  /// No description provided for @paywallProUnlimitedFreeDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل مجاني غير محدود 🚀'**
  String get paywallProUnlimitedFreeDelivery;

  /// No description provided for @paywallProExpressDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل إكسبريس (أولوية التجهيز)'**
  String get paywallProExpressDelivery;

  /// No description provided for @paywallProWholesalePrices.
  ///
  /// In ar, this message translates to:
  /// **'أسعار الجملة الحصرية 💰'**
  String get paywallProWholesalePrices;

  /// No description provided for @paywallProNoMinimumOrder.
  ///
  /// In ar, this message translates to:
  /// **'بدون حد أدنى للطلب'**
  String get paywallProNoMinimumOrder;

  /// No description provided for @paywallProUnlimitedGiveaways.
  ///
  /// In ar, this message translates to:
  /// **'دخول غير محدود لسحوبات الهدايا'**
  String get paywallProUnlimitedGiveaways;

  /// No description provided for @paywallPrimeTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفير برايم'**
  String get paywallPrimeTitle;

  /// No description provided for @paywallPrimeFreeDeliveryFiveOrders.
  ///
  /// In ar, this message translates to:
  /// **'توصيل مجاني لـ 5 طلبات'**
  String get paywallPrimeFreeDeliveryFiveOrders;

  /// No description provided for @paywallPrimeOffersPriority.
  ///
  /// In ar, this message translates to:
  /// **'أولوية حجز العروض الكبرى'**
  String get paywallPrimeOffersPriority;

  /// No description provided for @paywallPrimeWeeklyPlayAndWin.
  ///
  /// In ar, this message translates to:
  /// **'لعبة العب واكسب أسبوعياً 🎁'**
  String get paywallPrimeWeeklyPlayAndWin;

  /// No description provided for @paywallFreeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب عادي'**
  String get paywallFreeTitle;

  /// No description provided for @paywallFreePrice.
  ///
  /// In ar, this message translates to:
  /// **'مجاناً'**
  String get paywallFreePrice;

  /// No description provided for @paywallFreeStandardDelivery.
  ///
  /// In ar, this message translates to:
  /// **'توصيل عادي بتكلفة قياسية'**
  String get paywallFreeStandardDelivery;

  /// No description provided for @paywallFreePublicAccess.
  ///
  /// In ar, this message translates to:
  /// **'الوصول للمنتجات والعروض العامة'**
  String get paywallFreePublicAccess;

  /// No description provided for @paywallBestSeller.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مبيعاً'**
  String get paywallBestSeller;

  /// No description provided for @paywallPaymentComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم ربط الدفع قريباً'**
  String get paywallPaymentComingSoon;

  /// No description provided for @paywallSubscribeNow.
  ///
  /// In ar, this message translates to:
  /// **'اشترك الآن'**
  String get paywallSubscribeNow;

  /// No description provided for @catDairyEggs.
  ///
  /// In ar, this message translates to:
  /// **'ألبان وبيض'**
  String get catDairyEggs;

  /// No description provided for @subcatTetraPakCheese.
  ///
  /// In ar, this message translates to:
  /// **'جبن تترباك و مثلثات و كوب'**
  String get subcatTetraPakCheese;

  /// No description provided for @subcatPackagedCheeseLabneh.
  ///
  /// In ar, this message translates to:
  /// **'اجبان معبأ ولبنة و كريمة وسمنة'**
  String get subcatPackagedCheeseLabneh;

  /// No description provided for @subcatCheeseByWeight.
  ///
  /// In ar, this message translates to:
  /// **'أجبان وزن'**
  String get subcatCheeseByWeight;

  /// No description provided for @subcatMozzarella.
  ///
  /// In ar, this message translates to:
  /// **'جبن موزاريلا'**
  String get subcatMozzarella;

  /// No description provided for @subcatYogurtRicePudding.
  ///
  /// In ar, this message translates to:
  /// **'زبادي وارز باللبن'**
  String get subcatYogurtRicePudding;

  /// No description provided for @subcatLongLifeDairy.
  ///
  /// In ar, this message translates to:
  /// **'البان طويلة الاجل'**
  String get subcatLongLifeDairy;

  /// No description provided for @subcatPackagedButter.
  ///
  /// In ar, this message translates to:
  /// **'زبدة معبأ'**
  String get subcatPackagedButter;

  /// No description provided for @subcatPackagedEggs.
  ///
  /// In ar, this message translates to:
  /// **'بيض مغلف'**
  String get subcatPackagedEggs;

  /// No description provided for @catSweetsSnacks.
  ///
  /// In ar, this message translates to:
  /// **'حلويات وتسالي'**
  String get catSweetsSnacks;

  /// No description provided for @subcatChocolate.
  ///
  /// In ar, this message translates to:
  /// **'شيكولاتة'**
  String get subcatChocolate;

  /// No description provided for @subcatBiscuits.
  ///
  /// In ar, this message translates to:
  /// **'بسكويت'**
  String get subcatBiscuits;

  /// No description provided for @subcatSweets.
  ///
  /// In ar, this message translates to:
  /// **'حلويات'**
  String get subcatSweets;

  /// No description provided for @subcatChipsRoasted.
  ///
  /// In ar, this message translates to:
  /// **'مقرمشات و محمصات'**
  String get subcatChipsRoasted;

  /// No description provided for @subcatNutsByWeight.
  ///
  /// In ar, this message translates to:
  /// **'تسالي و مكسرات وزن'**
  String get subcatNutsByWeight;

  /// No description provided for @subcatHalawaSpreads.
  ///
  /// In ar, this message translates to:
  /// **'حلاوة وزبدة'**
  String get subcatHalawaSpreads;

  /// No description provided for @subcatRamadanYamish.
  ///
  /// In ar, this message translates to:
  /// **'ياميش رمضان'**
  String get subcatRamadanYamish;

  /// No description provided for @catDrinksJuices.
  ///
  /// In ar, this message translates to:
  /// **'مشروبات وعصائر'**
  String get catDrinksJuices;

  /// No description provided for @subcatWaterDrinksIceCream.
  ///
  /// In ar, this message translates to:
  /// **'مياه ومشروبات و عصائر و ايس كريم'**
  String get subcatWaterDrinksIceCream;

  /// No description provided for @subcatDrinks.
  ///
  /// In ar, this message translates to:
  /// **'مشروبات'**
  String get subcatDrinks;

  /// No description provided for @subcatJuices.
  ///
  /// In ar, this message translates to:
  /// **'عصائر'**
  String get subcatJuices;

  /// No description provided for @subcatPowderedJuices.
  ///
  /// In ar, this message translates to:
  /// **'عصائر بودر'**
  String get subcatPowderedJuices;

  /// No description provided for @catMeatFrozen.
  ///
  /// In ar, this message translates to:
  /// **'لحوم ومجمدات'**
  String get catMeatFrozen;

  /// No description provided for @subcatFrozenPoultry.
  ///
  /// In ar, this message translates to:
  /// **'دواجن مجمدة ومصنعات دوراجن'**
  String get subcatFrozenPoultry;

  /// No description provided for @subcatFrozenMeat.
  ///
  /// In ar, this message translates to:
  /// **'لحوم مجمدة'**
  String get subcatFrozenMeat;

  /// No description provided for @subcatProcessedMeat.
  ///
  /// In ar, this message translates to:
  /// **'مصنعات لحوم'**
  String get subcatProcessedMeat;

  /// No description provided for @subcatFrozenFish.
  ///
  /// In ar, this message translates to:
  /// **'أسماك مجمدة'**
  String get subcatFrozenFish;

  /// No description provided for @subcatSmokedFish.
  ///
  /// In ar, this message translates to:
  /// **'اسماك مدخنة'**
  String get subcatSmokedFish;

  /// No description provided for @subcatFrozenVegFruit.
  ///
  /// In ar, this message translates to:
  /// **'خضروات وفاكهه مجمدة'**
  String get subcatFrozenVegFruit;

  /// No description provided for @subcatFrozenPastries.
  ///
  /// In ar, this message translates to:
  /// **'معجنات مجمدة'**
  String get subcatFrozenPastries;

  /// No description provided for @catBakeryBreakfast.
  ///
  /// In ar, this message translates to:
  /// **'مخبوزات وفطار'**
  String get catBakeryBreakfast;

  /// No description provided for @subcatBakery.
  ///
  /// In ar, this message translates to:
  /// **'مخبوزات'**
  String get subcatBakery;

  /// No description provided for @subcatPatisserie.
  ///
  /// In ar, this message translates to:
  /// **'باتيه و وتش'**
  String get subcatPatisserie;

  /// No description provided for @subcatCerealsOats.
  ///
  /// In ar, this message translates to:
  /// **'كورن فليكس و موسلي وشوفان'**
  String get subcatCerealsOats;

  /// No description provided for @catPastaRice.
  ///
  /// In ar, this message translates to:
  /// **'مكرونة وأرز'**
  String get catPastaRice;

  /// No description provided for @subcatPasta.
  ///
  /// In ar, this message translates to:
  /// **'مكرونه'**
  String get subcatPasta;

  /// No description provided for @subcatRice.
  ///
  /// In ar, this message translates to:
  /// **'ارز'**
  String get subcatRice;

  /// No description provided for @subcatLegumesSpicesBreadcrumbs.
  ///
  /// In ar, this message translates to:
  /// **'بقوليات وعطارة وبقسماط معبأة'**
  String get subcatLegumesSpicesBreadcrumbs;

  /// No description provided for @subcatSoupsStocksMixes.
  ///
  /// In ar, this message translates to:
  /// **'شوربات ومرقات و خلطات'**
  String get subcatSoupsStocksMixes;

  /// No description provided for @catPantryOils.
  ///
  /// In ar, this message translates to:
  /// **'بقالة وزيوت'**
  String get catPantryOils;

  /// No description provided for @subcatOils.
  ///
  /// In ar, this message translates to:
  /// **'زيوت'**
  String get subcatOils;

  /// No description provided for @subcatGhee.
  ///
  /// In ar, this message translates to:
  /// **'سمن'**
  String get subcatGhee;

  /// No description provided for @subcatSugarFlour.
  ///
  /// In ar, this message translates to:
  /// **'سكر ودقيق'**
  String get subcatSugarFlour;

  /// No description provided for @subcatCannedFood.
  ///
  /// In ar, this message translates to:
  /// **'معلبات'**
  String get subcatCannedFood;

  /// No description provided for @subcatCondiments.
  ///
  /// In ar, this message translates to:
  /// **'مشهيات'**
  String get subcatCondiments;

  /// No description provided for @subcatOlivesPickles.
  ///
  /// In ar, this message translates to:
  /// **'زيتون ومخللات'**
  String get subcatOlivesPickles;

  /// No description provided for @subcatPackagedOlivesPickles.
  ///
  /// In ar, this message translates to:
  /// **'زيتون ومخلل معبأ'**
  String get subcatPackagedOlivesPickles;

  /// No description provided for @subcatSpicesByWeight.
  ///
  /// In ar, this message translates to:
  /// **'عطارة وزن'**
  String get subcatSpicesByWeight;

  /// No description provided for @subcatGrainsByWeight.
  ///
  /// In ar, this message translates to:
  /// **'علافة وزن'**
  String get subcatGrainsByWeight;

  /// No description provided for @subcatBakingSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات حلويات وبودر'**
  String get subcatBakingSupplies;

  /// No description provided for @subcatSaladsByWeight.
  ///
  /// In ar, this message translates to:
  /// **'سلاطات أنواع وزن'**
  String get subcatSaladsByWeight;

  /// No description provided for @catCleaningCare.
  ///
  /// In ar, this message translates to:
  /// **'منظفات وعناية'**
  String get catCleaningCare;

  /// No description provided for @subcatDetergentsSofteners.
  ///
  /// In ar, this message translates to:
  /// **'مساحيق ومنعمات'**
  String get subcatDetergentsSofteners;

  /// No description provided for @subcatLiquidSoapStainRemovers.
  ///
  /// In ar, this message translates to:
  /// **'صابون سائل ومزيلات بقع'**
  String get subcatLiquidSoapStainRemovers;

  /// No description provided for @subcatBleachDisinfectants.
  ///
  /// In ar, this message translates to:
  /// **'كلور ومطهرات'**
  String get subcatBleachDisinfectants;

  /// No description provided for @subcatPolishes.
  ///
  /// In ar, this message translates to:
  /// **'ملمعات'**
  String get subcatPolishes;

  /// No description provided for @subcatInsecticidesFresheners.
  ///
  /// In ar, this message translates to:
  /// **'مبيدات ومعطرات'**
  String get subcatInsecticidesFresheners;

  /// No description provided for @subcatTissuesToiletPaper.
  ///
  /// In ar, this message translates to:
  /// **'مناديل و ورق تواليت'**
  String get subcatTissuesToiletPaper;

  /// No description provided for @subcatSteelWoolScrubbers.
  ///
  /// In ar, this message translates to:
  /// **'سلك وليف'**
  String get subcatSteelWoolScrubbers;

  /// No description provided for @subcatSpongesSteelWool.
  ///
  /// In ar, this message translates to:
  /// **'أسفنج و سلك'**
  String get subcatSpongesSteelWool;

  /// No description provided for @subcatDrainCleaners.
  ///
  /// In ar, this message translates to:
  /// **'مسلكات بلوعات'**
  String get subcatDrainCleaners;

  /// No description provided for @subcatIncense.
  ///
  /// In ar, this message translates to:
  /// **'بخور'**
  String get subcatIncense;

  /// No description provided for @catPersonalCare.
  ///
  /// In ar, this message translates to:
  /// **'عناية شخصية'**
  String get catPersonalCare;

  /// No description provided for @subcatShampooConditioner.
  ///
  /// In ar, this message translates to:
  /// **'شامبو وبلسم'**
  String get subcatShampooConditioner;

  /// No description provided for @subcatShowerGelHandWash.
  ///
  /// In ar, this message translates to:
  /// **'شاور جل وهاند ووش'**
  String get subcatShowerGelHandWash;

  /// No description provided for @subcatSoap.
  ///
  /// In ar, this message translates to:
  /// **'صابون'**
  String get subcatSoap;

  /// No description provided for @subcatPerfumesDeodorants.
  ///
  /// In ar, this message translates to:
  /// **'برفانات ومزيلات عرق'**
  String get subcatPerfumesDeodorants;

  /// No description provided for @subcatCreamsSerums.
  ///
  /// In ar, this message translates to:
  /// **'كريمات وسيرم'**
  String get subcatCreamsSerums;

  /// No description provided for @subcatOralCare.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات أسنان'**
  String get subcatOralCare;

  /// No description provided for @subcatShavingSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات حلاقة'**
  String get subcatShavingSupplies;

  /// No description provided for @subcatHairDyeHenna.
  ///
  /// In ar, this message translates to:
  /// **'صبغات وحنة'**
  String get subcatHairDyeHenna;

  /// No description provided for @subcatPersonalCareSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات عناية شخصية'**
  String get subcatPersonalCareSupplies;

  /// No description provided for @catBabyWorld.
  ///
  /// In ar, this message translates to:
  /// **'عالم الطفل'**
  String get catBabyWorld;

  /// No description provided for @subcatDiapersPads.
  ///
  /// In ar, this message translates to:
  /// **'حافضات و فوط صحية'**
  String get subcatDiapersPads;

  /// No description provided for @subcatBabyFood.
  ///
  /// In ar, this message translates to:
  /// **'اكل اطفال'**
  String get subcatBabyFood;

  /// No description provided for @subcatBabySupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات اطفال'**
  String get subcatBabySupplies;

  /// No description provided for @catHomeSupplies.
  ///
  /// In ar, this message translates to:
  /// **'أدوات منزلية'**
  String get catHomeSupplies;

  /// No description provided for @subcatHousewares.
  ///
  /// In ar, this message translates to:
  /// **'ادوات منزلية'**
  String get subcatHousewares;

  /// No description provided for @subcatElectricalTools.
  ///
  /// In ar, this message translates to:
  /// **'ادوات كهربية'**
  String get subcatElectricalTools;

  /// No description provided for @subcatElectricalSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات كهربائية'**
  String get subcatElectricalSupplies;

  /// No description provided for @subcatPlasticsBags.
  ///
  /// In ar, this message translates to:
  /// **'بلاستيكات وأكياس'**
  String get subcatPlasticsBags;

  /// No description provided for @subcatFoil.
  ///
  /// In ar, this message translates to:
  /// **'فويل'**
  String get subcatFoil;

  /// No description provided for @subcatHardware.
  ///
  /// In ar, this message translates to:
  /// **'خردوات'**
  String get subcatHardware;

  /// No description provided for @subcatBatteries.
  ///
  /// In ar, this message translates to:
  /// **'بطاريات وحجاره'**
  String get subcatBatteries;

  /// No description provided for @subcatMatchesLighters.
  ///
  /// In ar, this message translates to:
  /// **'كبريت و ولاعات'**
  String get subcatMatchesLighters;

  /// No description provided for @subcatPetSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات حيوانات'**
  String get subcatPetSupplies;

  /// No description provided for @subcatRamadanSupplies.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات رمضان'**
  String get subcatRamadanSupplies;

  /// No description provided for @categoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'القسم'**
  String get categoryTitle;

  /// No description provided for @categoryNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم غير موجود'**
  String get categoryNotFound;

  /// No description provided for @categoryNoProductsNow.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات في هذا القسم حالياً'**
  String get categoryNoProductsNow;

  /// No description provided for @shopFromHome.
  ///
  /// In ar, this message translates to:
  /// **'تسوق من الرئيسية'**
  String get shopFromHome;

  /// No description provided for @categoryProductCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} منتج'**
  String categoryProductCount(String count);

  /// No description provided for @loadMoreFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المزيد، إعادة المحاولة'**
  String get loadMoreFailedRetry;

  /// No description provided for @categoriesDrawerTagline.
  ///
  /// In ar, this message translates to:
  /// **'كل اللي محتاجه في مكان واحد'**
  String get categoriesDrawerTagline;

  /// No description provided for @productDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المنتج'**
  String get productDetailsTitle;

  /// No description provided for @productNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا المنتج غير متاح'**
  String get productNotAvailable;

  /// No description provided for @productLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المنتج'**
  String get productLoadFailed;

  /// No description provided for @productImageUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث صورة المنتج بنجاح!'**
  String get productImageUpdated;

  /// No description provided for @productImageUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الرفع: {error}'**
  String productImageUploadFailed(String error);

  /// No description provided for @updateProductImage.
  ///
  /// In ar, this message translates to:
  /// **'تحديث صورة المنتج'**
  String get updateProductImage;

  /// No description provided for @takePhotoWithCamera.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة بالكاميرا'**
  String get takePhotoWithCamera;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من المعرض'**
  String get chooseFromGallery;

  /// No description provided for @changeProductImage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get changeProductImage;

  /// No description provided for @pricePerKiloChooseWeight.
  ///
  /// In ar, this message translates to:
  /// **'السعر للكيلو، اختر الوزن عند الإضافة'**
  String get pricePerKiloChooseWeight;

  /// No description provided for @productDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get productDescription;

  /// No description provided for @addToCartButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للسلة'**
  String get addToCartButton;

  /// No description provided for @productCurrentlyUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر حالياً'**
  String get productCurrentlyUnavailable;

  /// No description provided for @productDetailsInCart.
  ///
  /// In ar, this message translates to:
  /// **'في السلة'**
  String get productDetailsInCart;

  /// No description provided for @imageLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط الصورة بنجاح'**
  String get imageLinkCopied;

  /// No description provided for @copyImageLink.
  ///
  /// In ar, this message translates to:
  /// **'نسخ رابط الصورة'**
  String get copyImageLink;

  /// No description provided for @similarProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات مشابهة'**
  String get similarProducts;

  /// No description provided for @searchInSafeer.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في سفير'**
  String get searchInSafeer;

  /// No description provided for @searchProductHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج، مثل: لبن، جبنة...'**
  String get searchProductHint;

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearSearch;

  /// No description provided for @barcodeScanUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'مسح الباركود غير مدعوم على هذا الجهاز'**
  String get barcodeScanUnsupported;

  /// No description provided for @searchFailedCheckConnection.
  ///
  /// In ar, this message translates to:
  /// **'تعذر البحث، تحقق من اتصالك'**
  String get searchFailedCheckConnection;

  /// No description provided for @scanAnotherProduct.
  ///
  /// In ar, this message translates to:
  /// **'امسح منتجًا آخر'**
  String get scanAnotherProduct;

  /// No description provided for @noProductWithBarcode.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد منتج بالباركود «{barcode}»'**
  String noProductWithBarcode(String barcode);

  /// No description provided for @productMayBeUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'قد يكون المنتج غير متوفر حاليًا'**
  String get productMayBeUnavailable;

  /// No description provided for @scanAgain.
  ///
  /// In ar, this message translates to:
  /// **'امسح مرة أخرى'**
  String get scanAgain;

  /// No description provided for @noSearchResultsFor.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج لـ «{query}»'**
  String noSearchResultsFor(String query);

  /// No description provided for @searchTryAnotherWord.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة أخرى أو تأكد من الإملاء'**
  String get searchTryAnotherWord;

  /// No description provided for @searchResultsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة لـ «{query}»'**
  String searchResultsCount(String count, String query);

  /// No description provided for @popularSearches.
  ///
  /// In ar, this message translates to:
  /// **'عمليات بحث شائعة'**
  String get popularSearches;

  /// No description provided for @searchIntroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بين آلاف المنتجات واطلبها في دقائق'**
  String get searchIntroSubtitle;

  /// No description provided for @searchSuggestionMilk.
  ///
  /// In ar, this message translates to:
  /// **'لبن'**
  String get searchSuggestionMilk;

  /// No description provided for @searchSuggestionCheese.
  ///
  /// In ar, this message translates to:
  /// **'جبنة'**
  String get searchSuggestionCheese;

  /// No description provided for @searchSuggestionRice.
  ///
  /// In ar, this message translates to:
  /// **'أرز'**
  String get searchSuggestionRice;

  /// No description provided for @searchSuggestionOil.
  ///
  /// In ar, this message translates to:
  /// **'زيت'**
  String get searchSuggestionOil;

  /// No description provided for @searchSuggestionSugar.
  ///
  /// In ar, this message translates to:
  /// **'سكر'**
  String get searchSuggestionSugar;

  /// No description provided for @searchSuggestionTea.
  ///
  /// In ar, this message translates to:
  /// **'شاي'**
  String get searchSuggestionTea;

  /// No description provided for @receiptTypeReceive.
  ///
  /// In ar, this message translates to:
  /// **'استلام'**
  String get receiptTypeReceive;

  /// No description provided for @receiptTypeSupplierReturn.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get receiptTypeSupplierReturn;

  /// No description provided for @warehouseGoodsReceiptTitle.
  ///
  /// In ar, this message translates to:
  /// **'استلام بضاعة'**
  String get warehouseGoodsReceiptTitle;

  /// No description provided for @warehouseGoodsReturnTitle.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع بضاعة'**
  String get warehouseGoodsReturnTitle;

  /// No description provided for @warehouseReceiptSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ أمر الاستلام'**
  String get warehouseReceiptSaved;

  /// No description provided for @warehouseReturnSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ أمر الاسترجاع'**
  String get warehouseReturnSaved;

  /// No description provided for @warehouseSubmitReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إرسال أمر الاستلام'**
  String get warehouseSubmitReceipt;

  /// No description provided for @warehouseSubmitReturn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال أمر الاسترجاع'**
  String get warehouseSubmitReturn;

  /// No description provided for @warehouseInvoiceDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة'**
  String get warehouseInvoiceDate;

  /// No description provided for @warehouseScanOrEnterBarcode.
  ///
  /// In ar, this message translates to:
  /// **'امسح الباركود أو اكتبه'**
  String get warehouseScanOrEnterBarcode;

  /// No description provided for @warehouseEnterQuantityAboveZero.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كمية أكبر من صفر'**
  String get warehouseEnterQuantityAboveZero;

  /// No description provided for @warehouseCompleteRequiredFields.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الحقول المطلوبة أولاً'**
  String get warehouseCompleteRequiredFields;

  /// No description provided for @warehouseNoItemsYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف أصناف بعد'**
  String get warehouseNoItemsYet;

  /// No description provided for @warehouseDocumentDetails.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المستند'**
  String get warehouseDocumentDetails;

  /// No description provided for @warehouseInvoiceNumberRequiredLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة *'**
  String get warehouseInvoiceNumberRequiredLabel;

  /// No description provided for @warehouseInvoiceDateRequiredLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة *'**
  String get warehouseInvoiceDateRequiredLabel;

  /// No description provided for @warehouseInvoiceDateRequired.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الفاتورة مطلوب'**
  String get warehouseInvoiceDateRequired;

  /// No description provided for @warehouseItems.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف'**
  String get warehouseItems;

  /// No description provided for @warehouseBarcode.
  ///
  /// In ar, this message translates to:
  /// **'الباركود'**
  String get warehouseBarcode;

  /// No description provided for @warehouseQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get warehouseQuantity;

  /// No description provided for @warehouseAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get warehouseAdd;

  /// No description provided for @warehouseReloadSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحميل الموردين'**
  String get warehouseReloadSuppliers;

  /// No description provided for @warehouseSupplierRequiredLabel.
  ///
  /// In ar, this message translates to:
  /// **'المورد *'**
  String get warehouseSupplierRequiredLabel;

  /// No description provided for @warehouseSupplierHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث أو اكتب رقم المورد'**
  String get warehouseSupplierHint;

  /// No description provided for @warehouseSuppliersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الموردين فارغة'**
  String get warehouseSuppliersEmpty;

  /// No description provided for @warehouseSelectSupplier.
  ///
  /// In ar, this message translates to:
  /// **'اختر المورد'**
  String get warehouseSelectSupplier;

  /// No description provided for @warehouseSelectSupplierFromList.
  ///
  /// In ar, this message translates to:
  /// **'اختر المورد من القائمة'**
  String get warehouseSelectSupplierFromList;

  /// No description provided for @warehouseFetchingProductName.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ جلب اسم المنتج…'**
  String get warehouseFetchingProductName;

  /// No description provided for @warehouseUnregisteredProduct.
  ///
  /// In ar, this message translates to:
  /// **'منتج غير مسجل'**
  String get warehouseUnregisteredProduct;

  /// No description provided for @warehouseQuantityValue.
  ///
  /// In ar, this message translates to:
  /// **'الكمية: {quantity}'**
  String warehouseQuantityValue(String quantity);

  /// No description provided for @warehouseSelectDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ'**
  String get warehouseSelectDate;

  /// No description provided for @warehouseClearDate.
  ///
  /// In ar, this message translates to:
  /// **'مسح التاريخ'**
  String get warehouseClearDate;

  /// No description provided for @warehouseSuppliersLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الموردين: {error}'**
  String warehouseSuppliersLoadFailed(String error);

  /// No description provided for @warehouseDocumentSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ المستند: {error}'**
  String warehouseDocumentSaveFailed(String error);

  /// No description provided for @warehouseOrderAlreadyUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث الطلب، ربما تم تحديثه بالفعل'**
  String get warehouseOrderAlreadyUpdated;

  /// No description provided for @warehouseSignOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حساب المخزن؟'**
  String get warehouseSignOutConfirm;

  /// No description provided for @warehouseDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المخزن'**
  String get warehouseDashboardTitle;

  /// No description provided for @warehouseNewOrdersTab.
  ///
  /// In ar, this message translates to:
  /// **'طلبات جديدة'**
  String get warehouseNewOrdersTab;

  /// No description provided for @warehousePreparingTab.
  ///
  /// In ar, this message translates to:
  /// **'قيد التجهيز'**
  String get warehousePreparingTab;

  /// No description provided for @warehouseItemInquiry.
  ///
  /// In ar, this message translates to:
  /// **'استعلام عن صنف'**
  String get warehouseItemInquiry;

  /// No description provided for @warehouseItemInquiryFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاستعلام عن الصنف\n{error}'**
  String warehouseItemInquiryFailed(String error);

  /// No description provided for @warehouseItemNotRegistered.
  ///
  /// In ar, this message translates to:
  /// **'الصنف غير مسجل في قاعدة البيانات'**
  String get warehouseItemNotRegistered;

  /// No description provided for @warehouseBarcodeValue.
  ///
  /// In ar, this message translates to:
  /// **'الباركود: {barcode}'**
  String warehouseBarcodeValue(String barcode);

  /// No description provided for @warehouseAvailableQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المتاحة: {quantity}'**
  String warehouseAvailableQuantity(String quantity);

  /// No description provided for @warehouseNoNewOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات جديدة\nاسحب للتحديث'**
  String get warehouseNoNewOrders;

  /// No description provided for @warehouseNoPreparingOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات قيد التجهيز'**
  String get warehouseNoPreparingOrders;

  /// No description provided for @warehousePreparingStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدأ تجهيز الطلب #{id}، تجده في «قيد التجهيز»'**
  String warehousePreparingStarted(String id);

  /// No description provided for @warehouseOrderReady.
  ///
  /// In ar, this message translates to:
  /// **'الطلب #{id} جاهز، تم إشعار مناديب التوصيل'**
  String warehouseOrderReady(String id);

  /// No description provided for @warehouseProductsCount.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات ({count})'**
  String warehouseProductsCount(String count);

  /// No description provided for @warehouseCustomerValue.
  ///
  /// In ar, this message translates to:
  /// **'العميل: {name}'**
  String warehouseCustomerValue(String name);

  /// No description provided for @warehouseAddressValue.
  ///
  /// In ar, this message translates to:
  /// **'العنوان: {address}'**
  String warehouseAddressValue(String address);

  /// No description provided for @warehouseTotalValue.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي: {amount}'**
  String warehouseTotalValue(String amount);

  /// No description provided for @driverNewOrderAvailable.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد متاح للتوصيل!'**
  String get driverNewOrderAvailable;

  /// No description provided for @driverLocationSharingStartFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر بدء مشاركة موقعك: {error}'**
  String driverLocationSharingStartFailed(String error);

  /// No description provided for @driverSignOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حساب السائق؟'**
  String get driverSignOutConfirm;

  /// No description provided for @driverDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة السائق'**
  String get driverDashboardTitle;

  /// No description provided for @driverAvailableOrdersTab.
  ///
  /// In ar, this message translates to:
  /// **'طلبات متاحة'**
  String get driverAvailableOrdersTab;

  /// No description provided for @driverNoAvailableOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات متاحة الآن\nاسحب للتحديث'**
  String get driverNoAvailableOrders;

  /// No description provided for @driverNoActiveDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات قيد التوصيل'**
  String get driverNoActiveDeliveries;

  /// No description provided for @driverOrderAccepted.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول الطلب #{id}، تجده في «طلباتي»'**
  String driverOrderAccepted(String id);

  /// No description provided for @driverOrderDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم توصيل الطلب #{id}'**
  String driverOrderDelivered(String id);

  /// No description provided for @driverPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get driverPhoneLabel;

  /// No description provided for @driverAddressLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get driverAddressLabel;

  /// No description provided for @driverDistanceLabel.
  ///
  /// In ar, this message translates to:
  /// **'المسافة'**
  String get driverDistanceLabel;

  /// No description provided for @driverDistanceNotSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get driverDistanceNotSpecified;

  /// No description provided for @driverDistanceFromBranch.
  ///
  /// In ar, this message translates to:
  /// **'{distance} من الفرع'**
  String driverDistanceFromBranch(String distance);

  /// No description provided for @driverTotalToCollect.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي (تحصيل)'**
  String get driverTotalToCollect;

  /// No description provided for @driverViewMapAndLocation.
  ///
  /// In ar, this message translates to:
  /// **'عرض الخريطة والموقع'**
  String get driverViewMapAndLocation;

  /// No description provided for @driverAcceptOrder.
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get driverAcceptOrder;

  /// No description provided for @driverBroadcastingLocation.
  ///
  /// In ar, this message translates to:
  /// **'جاري بث الموقع...'**
  String get driverBroadcastingLocation;

  /// No description provided for @driverBroadcastingLocationLastSent.
  ///
  /// In ar, this message translates to:
  /// **'جاري بث الموقع... آخر إرسال {time}'**
  String driverBroadcastingLocationLastSent(String time);

  /// No description provided for @driverRequestingLocationPermission.
  ///
  /// In ar, this message translates to:
  /// **'جاري طلب إذن الموقع...'**
  String get driverRequestingLocationPermission;

  /// No description provided for @driverStartLocationSharing.
  ///
  /// In ar, this message translates to:
  /// **'بدء بث الموقع'**
  String get driverStartLocationSharing;

  /// No description provided for @driverCopyLabel.
  ///
  /// In ar, this message translates to:
  /// **'نسخ {label}'**
  String driverCopyLabel(String label);

  /// No description provided for @driverCopiedLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ {label}'**
  String driverCopiedLabel(String label);

  /// No description provided for @driverLocationReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة موقعك: {error}'**
  String driverLocationReadFailed(String error);

  /// No description provided for @driverLocationSharingStopped.
  ///
  /// In ar, this message translates to:
  /// **'توقف بث الموقع، اضغط «بدء بث الموقع» للمتابعة'**
  String get driverLocationSharingStopped;

  /// No description provided for @driverOrderTakenByAnother.
  ///
  /// In ar, this message translates to:
  /// **'عذراً، تم قبول هذا الطلب من سائق آخر'**
  String get driverOrderTakenByAnother;

  /// No description provided for @driverAcceptOrderFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قبول الطلب: {error}'**
  String driverAcceptOrderFailed(String error);

  /// No description provided for @driverLocationSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال موقعك للعميل: {error} (code: {code})'**
  String driverLocationSendFailed(String error, String code);

  /// No description provided for @driverLocationSendNotAssigned.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال موقعك للعميل: الطلب غير مُسند إليك أو لم يعد قيد التوصيل'**
  String get driverLocationSendNotAssigned;

  /// No description provided for @driverGpsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع (GPS) متوقفة، فعّلها ليتمكن العميل من تتبعك'**
  String get driverGpsDisabled;

  /// No description provided for @driverLocationPermissionDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض، فعّله من إعدادات التطبيق ليتمكن العميل من تتبعك'**
  String get driverLocationPermissionDeniedForever;

  /// No description provided for @driverLocationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم السماح بالوصول لموقعك، لن يتمكن العميل من تتبع الطلب'**
  String get driverLocationPermissionDenied;

  /// No description provided for @driverOpenGoogleMapsFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح خرائط جوجل على هذا الجهاز'**
  String get driverOpenGoogleMapsFailed;

  /// No description provided for @driverMapAndLocationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة والموقع'**
  String get driverMapAndLocationTitle;

  /// No description provided for @driverStartNavigation.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التوجيه'**
  String get driverStartNavigation;

  /// No description provided for @listSeparator.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get listSeparator;

  /// No description provided for @storeCityName.
  ///
  /// In ar, this message translates to:
  /// **'مدينة نصر'**
  String get storeCityName;

  /// No description provided for @addressDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان'**
  String get addressDefaultTitle;

  /// No description provided for @addressLabelOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get addressLabelOther;

  /// No description provided for @addressBuildingLine.
  ///
  /// In ar, this message translates to:
  /// **'عمارة {building}'**
  String addressBuildingLine(String building);

  /// No description provided for @addressFloorAptLine.
  ///
  /// In ar, this message translates to:
  /// **'الدور/الشقة {floor}'**
  String addressFloorAptLine(String floor);

  /// No description provided for @addressLandmarkLine.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة: {landmark}'**
  String addressLandmarkLine(String landmark);

  /// No description provided for @addressSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ العنوان: {error}'**
  String addressSaveFailed(String error);

  /// No description provided for @addressLocationSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ موقع العنوان'**
  String get addressLocationSaveFailed;

  /// No description provided for @addressLocationSaveFailedWithError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ موقع العنوان: {error}'**
  String addressLocationSaveFailedWithError(String error);

  /// No description provided for @locationServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع (GPS) متوقفة، فعّلها وحاول مرة أخرى'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم السماح بالوصول لموقعك، يمكنك تحريك الخريطة يدوياً'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض، فعّله من إعدادات التطبيق'**
  String get locationPermissionDeniedForever;

  /// No description provided for @currentLocationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديد موقعك الحالي، حاول مرة أخرى'**
  String get currentLocationUnavailable;

  /// No description provided for @mapAddressReadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة العنوان من الخريطة'**
  String get mapAddressReadFailed;

  /// No description provided for @addressesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة بعد'**
  String get addressesEmptyTitle;

  /// No description provided for @addressesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف عنوانك لتوصيل طلباتك بسرعة'**
  String get addressesEmptyHint;

  /// No description provided for @addressesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل العناوين'**
  String get addressesLoadFailed;

  /// No description provided for @signInToManageAddresses.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لإدارة عناوينك'**
  String get signInToManageAddresses;

  /// No description provided for @addressDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنوان'**
  String get addressDeleteTitle;

  /// No description provided for @addressDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف عنوان «{title}»؟'**
  String addressDeleteConfirm(String title);

  /// No description provided for @addressDeleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف العنوان'**
  String get addressDeleteFailed;

  /// No description provided for @addressSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ عنوان «{title}»'**
  String addressSaved(String title);

  /// No description provided for @addressPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر عنوان التوصيل'**
  String get addressPickerTitle;

  /// No description provided for @addressPickerEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة، أضف عنوانك الأول'**
  String get addressPickerEmpty;

  /// No description provided for @addressDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العنوان'**
  String get addressDetailsTitle;

  /// No description provided for @addressTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان'**
  String get addressTitleLabel;

  /// No description provided for @addressTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: المنزل، العمل'**
  String get addressTitleHint;

  /// No description provided for @addressAreaLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get addressAreaLabel;

  /// No description provided for @addressAreaHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مدينة نصر، الحي السادس'**
  String get addressAreaHint;

  /// No description provided for @addressStreetLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشارع'**
  String get addressStreetLabel;

  /// No description provided for @addressBuildingNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم العمارة'**
  String get addressBuildingNumberLabel;

  /// No description provided for @addressFloorAptLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور / الشقة'**
  String get addressFloorAptLabel;

  /// No description provided for @addressLandmarkLabel.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة'**
  String get addressLandmarkLabel;

  /// No description provided for @addressLandmarkHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: بجوار مسجد...'**
  String get addressLandmarkHint;

  /// No description provided for @addressSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get addressSaveButton;

  /// No description provided for @addressOptionalFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'{label} (اختياري)'**
  String addressOptionalFieldLabel(String label);

  /// No description provided for @addressFieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get addressFieldRequired;

  /// No description provided for @addressReviewAndComplete.
  ///
  /// In ar, this message translates to:
  /// **'راجع العنوان وأكمل باقي البيانات.'**
  String get addressReviewAndComplete;

  /// No description provided for @mapAddressReadFailedFillManually.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة العنوان من الخريطة، أكمل البيانات يدوياً.'**
  String get mapAddressReadFailedFillManually;

  /// No description provided for @mapDeliveryQuote.
  ///
  /// In ar, this message translates to:
  /// **'يبعد {distance} عن الفرع · التوصيل {fee}'**
  String mapDeliveryQuote(String distance, String fee);

  /// No description provided for @addressOutOfDeliveryRange.
  ///
  /// In ar, this message translates to:
  /// **'هذا الموقع يبعد {distance}، خارج نطاق التوصيل (حتى {maxDistance}).'**
  String addressOutOfDeliveryRange(String distance, String maxDistance);

  /// No description provided for @mapOutOfDeliveryRange.
  ///
  /// In ar, this message translates to:
  /// **'يبعد {distance}، خارج نطاق التوصيل'**
  String mapOutOfDeliveryRange(String distance);

  /// No description provided for @mapPinHint.
  ///
  /// In ar, this message translates to:
  /// **'حرّك الخريطة لوضع الدبوس على مكان التوصيل بالضبط'**
  String get mapPinHint;

  /// No description provided for @mapMyCurrentLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقعي الحالي'**
  String get mapMyCurrentLocation;

  /// No description provided for @mapConfirmLocation.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الموقع'**
  String get mapConfirmLocation;

  /// No description provided for @mapSetDeliveryLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدد موقع التوصيل'**
  String get mapSetDeliveryLocation;

  /// No description provided for @myOrdersLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل طلباتك'**
  String get myOrdersLoadFailed;

  /// No description provided for @myOrdersEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بعد'**
  String get myOrdersEmptyTitle;

  /// No description provided for @myOrdersEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسوق وستظهر طلباتك هنا'**
  String get myOrdersEmptySubtitle;

  /// No description provided for @orderStatusReceivedLong.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام الطلب'**
  String get orderStatusReceivedLong;

  /// No description provided for @orderStatusPreparingInWarehouse.
  ///
  /// In ar, this message translates to:
  /// **'جاري التجهيز في المخزن'**
  String get orderStatusPreparingInWarehouse;

  /// No description provided for @orderStatusAwaitingDriver.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار مندوب التوصيل'**
  String get orderStatusAwaitingDriver;

  /// No description provided for @orderStatusReadyShort.
  ///
  /// In ar, this message translates to:
  /// **'جاهز'**
  String get orderStatusReadyShort;

  /// No description provided for @orderStepReceived.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستلام'**
  String get orderStepReceived;

  /// No description provided for @orderStepPreparing.
  ///
  /// In ar, this message translates to:
  /// **'التجهيز'**
  String get orderStepPreparing;

  /// No description provided for @orderCardStatusLine.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب: {status}'**
  String orderCardStatusLine(String status);

  /// No description provided for @orderCardTrackOnMap.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الطلب على الخريطة'**
  String get orderCardTrackOnMap;

  /// No description provided for @trackingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تتبع الطلب #{id}'**
  String trackingTitle(String id);

  /// No description provided for @trackingYourAddressMarker.
  ///
  /// In ar, this message translates to:
  /// **'عنوانك'**
  String get trackingYourAddressMarker;

  /// No description provided for @trackingDriverMarker.
  ///
  /// In ar, this message translates to:
  /// **'مندوب التوصيل'**
  String get trackingDriverMarker;

  /// No description provided for @trackingOrderDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم توصيل طلبك، بالهناء والشفاء!'**
  String get trackingOrderDelivered;

  /// No description provided for @trackingDriverLocationLive.
  ///
  /// In ar, this message translates to:
  /// **'يتم تحديث موقع المندوب على الخريطة مباشرة'**
  String get trackingDriverLocationLive;

  /// No description provided for @trackingDriverLocating.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحديد موقع المندوب… سيظهر على الخريطة قريباً'**
  String get trackingDriverLocating;

  /// No description provided for @authAccountCreatedConfirmEmail.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حسابك! أرسلنا رابط التأكيد إلى {email}، أكّد بريدك ثم سجّل الدخول.'**
  String authAccountCreatedConfirmEmail(String email);

  /// No description provided for @authFullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authFullNameLabel;

  /// No description provided for @authEnterFullName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك الكامل'**
  String get authEnterFullName;

  /// No description provided for @authEnterValidEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريداً إلكترونياً صحيحاً'**
  String get authEnterValidEmail;

  /// No description provided for @authEnterValidEgyptianPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف مصري صحيح (11 رقماً)'**
  String get authEnterValidEgyptianPhone;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authShowPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get authHidePassword;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور 6 أحرف على الأقل'**
  String get authPasswordMinLength;

  /// No description provided for @authSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authSignInButton;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authCreateAccountButton;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ '**
  String get authNoAccountPrompt;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟ '**
  String get authHaveAccountPrompt;

  /// No description provided for @authCreateNewAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً جديداً'**
  String get authCreateNewAccountLink;

  /// No description provided for @authSignInLink.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول'**
  String get authSignInLink;

  /// No description provided for @authWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك!'**
  String get authWelcomeBack;

  /// No description provided for @authJoinSafeerMarket.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى سفير ماركت'**
  String get authJoinSafeerMarket;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لإتمام طلبك'**
  String get authSignInSubtitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابك واستمتع بعروض سفير'**
  String get authSignUpSubtitle;

  /// No description provided for @authNewAccountTab.
  ///
  /// In ar, this message translates to:
  /// **'حساب جديد'**
  String get authNewAccountTab;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجل بالفعل'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authAccountCreatedProfileSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب لكن تعذر حفظ البيانات: {error}'**
  String authAccountCreatedProfileSaveFailed(String error);

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بريدك الإلكتروني أولاً من الرسالة المرسلة إليك'**
  String get authEmailNotConfirmed;

  /// No description provided for @authWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل'**
  String get authWeakPassword;

  /// No description provided for @authTooManyAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، يرجى المحاولة بعد قليل'**
  String get authTooManyAttempts;

  /// No description provided for @editProfileSignInPrompt.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك لتعديل بياناتك'**
  String get editProfileSignInPrompt;

  /// No description provided for @profileSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بياناتك بنجاح'**
  String get profileSavedSuccessfully;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get profileFullNameLabel;

  /// No description provided for @profileEnterFullName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك بالكامل'**
  String get profileEnterFullName;

  /// No description provided for @profileEnterValidPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف مصري صحيح'**
  String get profileEnterValidPhone;

  /// No description provided for @profileSaveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get profileSaveChanges;

  /// No description provided for @profileSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ البيانات: {error}'**
  String profileSaveFailed(String error);

  /// No description provided for @notificationTokenSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ رمز الإشعارات: {error}'**
  String notificationTokenSaveFailed(String error);

  /// No description provided for @featureComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'{feature} متاح قريباً'**
  String featureComingSoon(String feature);

  /// No description provided for @rewardsPointsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{{count} نقاط} other{{count} نقطة}}'**
  String rewardsPointsCount(int count);

  /// No description provided for @rewardsGamesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الألعاب'**
  String get rewardsGamesTitle;

  /// No description provided for @rewardsGamesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'العب واجمع نقاط الولاء'**
  String get rewardsGamesSubtitle;

  /// No description provided for @gameLockedUntilTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'متاح مرة أخرى بعد {countdown}'**
  String gameLockedUntilTomorrow(String countdown);

  /// No description provided for @scratchCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة الخدش - امسح واربح'**
  String get scratchCardTitle;

  /// No description provided for @scratchCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'امسح الطبقة واربح نقاطاً فورية'**
  String get scratchCardSubtitle;

  /// No description provided for @scratchCardHint.
  ///
  /// In ar, this message translates to:
  /// **'امسح الطبقة الفضية لكشف جائزتك'**
  String get scratchCardHint;

  /// No description provided for @scratchWonPoints.
  ///
  /// In ar, this message translates to:
  /// **'ربحت {points} نقطة!'**
  String scratchWonPoints(String points);

  /// No description provided for @scratchBetterLuck.
  ///
  /// In ar, this message translates to:
  /// **'حظ أوفر'**
  String get scratchBetterLuck;

  /// No description provided for @luckyChestTitle.
  ///
  /// In ar, this message translates to:
  /// **'صندوق الحظ اليومي - افتح صندوقك'**
  String get luckyChestTitle;

  /// No description provided for @luckyChestSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصندوق واربح حتى 10 نقاط'**
  String get luckyChestSubtitle;

  /// No description provided for @luckyChestHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الصندوق لفتحه وكشف جائزتك'**
  String get luckyChestHint;

  /// No description provided for @luckyChestTapToOpen.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لفتح الصندوق'**
  String get luckyChestTapToOpen;

  /// No description provided for @luckyChestOpened.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح الصندوق لهذا اليوم'**
  String get luckyChestOpened;

  /// No description provided for @luckyChestWonPoints.
  ///
  /// In ar, this message translates to:
  /// **'ربحت {points} نقطة من الصندوق!'**
  String luckyChestWonPoints(String points);

  /// No description provided for @rewardsWheelCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لف العجلة واربح حتى 100 نقطة'**
  String get rewardsWheelCardSubtitle;

  /// No description provided for @rewardsPuzzleCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رتّب الشعار واربح 50 نقطة'**
  String get rewardsPuzzleCardSubtitle;

  /// No description provided for @loyaltyCurrentBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيدك الحالي'**
  String get loyaltyCurrentBalance;

  /// No description provided for @loyaltySignInToSeePoints.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لترى نقاطك'**
  String get loyaltySignInToSeePoints;

  /// No description provided for @loyaltyLoadFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التحميل — إعادة المحاولة'**
  String get loyaltyLoadFailedRetry;

  /// No description provided for @loyaltyPointsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل نقاط الولاء: {error}'**
  String loyaltyPointsLoadFailed(String error);

  /// No description provided for @loyaltyPointsUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث نقاط الولاء: {error}'**
  String loyaltyPointsUpdateFailed(String error);

  /// No description provided for @wheelPrizeTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مجدداً'**
  String get wheelPrizeTryAgain;

  /// No description provided for @wheelSpinCollectLoyaltyPoints.
  ///
  /// In ar, this message translates to:
  /// **'لف العجلة واجمع نقاط الولاء'**
  String get wheelSpinCollectLoyaltyPoints;

  /// No description provided for @wheelSignInToPlay.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك لتلعب'**
  String get wheelSignInToPlay;

  /// No description provided for @wheelSpinning.
  ///
  /// In ar, this message translates to:
  /// **'العجلة تدور...'**
  String get wheelSpinning;

  /// No description provided for @wheelSpin.
  ///
  /// In ar, this message translates to:
  /// **'لف العجلة'**
  String get wheelSpin;

  /// No description provided for @wheelCongrats.
  ///
  /// In ar, this message translates to:
  /// **'مبروك!'**
  String get wheelCongrats;

  /// No description provided for @wheelTryAgainTitle.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get wheelTryAgainTitle;

  /// No description provided for @wheelWonPrize.
  ///
  /// In ar, this message translates to:
  /// **'ربحت {prize} ولاء وأُضيفت إلى رصيدك.'**
  String wheelWonPrize(String prize);

  /// No description provided for @wheelNoPointsThisTime.
  ///
  /// In ar, this message translates to:
  /// **'لم تربح نقاطاً هذه المرة. حظاً أوفر في اللفة القادمة!'**
  String get wheelNoPointsThisTime;

  /// No description provided for @puzzleMoves.
  ///
  /// In ar, this message translates to:
  /// **'الحركات: {moves}'**
  String puzzleMoves(String moves);

  /// No description provided for @puzzlePrize.
  ///
  /// In ar, this message translates to:
  /// **'الجائزة: {points} نقطة'**
  String puzzlePrize(String points);

  /// No description provided for @puzzleSavePoints.
  ///
  /// In ar, this message translates to:
  /// **'احفظ {points} نقطة'**
  String puzzleSavePoints(String points);

  /// No description provided for @puzzleShuffle.
  ///
  /// In ar, this message translates to:
  /// **'خلط القطع'**
  String get puzzleShuffle;

  /// No description provided for @puzzleOutOfMoves.
  ///
  /// In ar, this message translates to:
  /// **'حظ أوفر المرة القادمة! لقد استنفدت عدد الحركات المتاحة.'**
  String get puzzleOutOfMoves;

  /// No description provided for @puzzleCongrats.
  ///
  /// In ar, this message translates to:
  /// **'مبرووك!'**
  String get puzzleCongrats;

  /// No description provided for @puzzleEarnedPoints.
  ///
  /// In ar, this message translates to:
  /// **'كسبت {points} نقطة 🎉'**
  String puzzleEarnedPoints(String points);

  /// No description provided for @puzzlePointsAddedToBalance.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت النقاط إلى رصيد الولاء.'**
  String get puzzlePointsAddedToBalance;

  /// No description provided for @puzzleGuestEarnedPoints.
  ///
  /// In ar, this message translates to:
  /// **'مبرووك! كسبت {points} نقطة 🎉'**
  String puzzleGuestEarnedPoints(String points);

  /// No description provided for @puzzleSignInToAddPoints.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لنضيفها إلى رصيدك.'**
  String get puzzleSignInToAddPoints;

  /// No description provided for @puzzleGoalTitle.
  ///
  /// In ar, this message translates to:
  /// **'رتّب الشعار'**
  String get puzzleGoalTitle;

  /// No description provided for @puzzleGoalDescription.
  ///
  /// In ar, this message translates to:
  /// **'حرّك القطع المجاورة للفراغ حتى يعود الشعار كما في الصورة'**
  String get puzzleGoalDescription;

  /// No description provided for @unitCarton.
  ///
  /// In ar, this message translates to:
  /// **'كرتونة'**
  String get unitCarton;

  /// No description provided for @unitBox.
  ///
  /// In ar, this message translates to:
  /// **'علبة'**
  String get unitBox;

  /// No description provided for @unitBag.
  ///
  /// In ar, this message translates to:
  /// **'كيس'**
  String get unitBag;

  /// No description provided for @unitPack.
  ///
  /// In ar, this message translates to:
  /// **'باكو'**
  String get unitPack;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلة التسوق'**
  String get cartTitle;

  /// No description provided for @clearCart.
  ///
  /// In ar, this message translates to:
  /// **'إفراغ السلة'**
  String get clearCart;

  /// No description provided for @cartSubtotalWithCount.
  ///
  /// In ar, this message translates to:
  /// **'المجموع ({count} منتج)'**
  String cartSubtotalWithCount(String count);

  /// No description provided for @cartDeliveryFeeNextStep.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل تُحسب في الخطوة التالية'**
  String get cartDeliveryFeeNextStep;

  /// No description provided for @cartContinueOrder.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الطلب'**
  String get cartContinueOrder;

  /// No description provided for @cartEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاتك المفضلة وابدأ التسوق'**
  String get cartEmptySubtitle;

  /// No description provided for @cartSaveDeliveryFeesTitle.
  ///
  /// In ar, this message translates to:
  /// **'وفر رسوم التوصيل! 💡'**
  String get cartSaveDeliveryFeesTitle;

  /// No description provided for @cartPrimeUpsellSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اشترك في سفير برايم بـ 90 ج.م فقط.'**
  String get cartPrimeUpsellSubtitle;

  /// No description provided for @cartAddedWeightOfProduct.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة {weight} من {product} إلى السلة'**
  String cartAddedWeightOfProduct(String weight, String product);

  /// No description provided for @cartAddedProduct.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة {product} إلى السلة'**
  String cartAddedProduct(String product);

  /// No description provided for @viewCart.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة'**
  String get viewCart;

  /// No description provided for @removeFromCart.
  ///
  /// In ar, this message translates to:
  /// **'حذف من السلة'**
  String get removeFromCart;

  /// No description provided for @chooseWeight.
  ///
  /// In ar, this message translates to:
  /// **'اختر الوزن'**
  String get chooseWeight;

  /// No description provided for @pricePerKilo.
  ///
  /// In ar, this message translates to:
  /// **'{price} للكيلو'**
  String pricePerKilo(String price);

  /// No description provided for @weightPickerPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get weightPickerPrice;

  /// No description provided for @updateWeight.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الوزن'**
  String get updateWeight;

  /// No description provided for @homeNotificationsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get homeNotificationsTooltip;

  /// No description provided for @homeSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج أو ماركة'**
  String get homeSearchHint;

  /// No description provided for @homeDeliveringTo.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل إلى · {city}'**
  String homeDeliveringTo(String city);

  /// No description provided for @homeChooseYourAddress.
  ///
  /// In ar, this message translates to:
  /// **'اختر عنوانك'**
  String get homeChooseYourAddress;

  /// No description provided for @homeMyAccountTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get homeMyAccountTooltip;

  /// No description provided for @homeSignedInSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get homeSignedInSuccessfully;

  /// No description provided for @homeDeliveryEta.
  ///
  /// In ar, this message translates to:
  /// **'توصيل خلال 30 - 45 دقيقة'**
  String get homeDeliveryEta;

  /// No description provided for @quickActionLatestProducts.
  ///
  /// In ar, this message translates to:
  /// **'أحدث المنتجات'**
  String get quickActionLatestProducts;

  /// No description provided for @quickActionOffers.
  ///
  /// In ar, this message translates to:
  /// **'العروض'**
  String get quickActionOffers;

  /// No description provided for @quickActionPlayAndWin.
  ///
  /// In ar, this message translates to:
  /// **'العب واكسب'**
  String get quickActionPlayAndWin;

  /// No description provided for @promoEndlessOffersTitle.
  ///
  /// In ar, this message translates to:
  /// **'عروض سفير ما بتنتهيش'**
  String get promoEndlessOffersTitle;

  /// No description provided for @promoEndlessOffersSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خصومات يومية على مئات المنتجات'**
  String get promoEndlessOffersSubtitle;

  /// No description provided for @promoSavingsStoreTitle.
  ///
  /// In ar, this message translates to:
  /// **'سفير... محل التوفير'**
  String get promoSavingsStoreTitle;

  /// No description provided for @promoSavingsStoreSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أسعار أقل كل يوم لكل البيت'**
  String get promoSavingsStoreSubtitle;

  /// No description provided for @promoOpeningDiscountsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خصومات الافتتاح'**
  String get promoOpeningDiscountsTitle;

  /// No description provided for @promoOpeningDiscountsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حتى 30% على أول طلب'**
  String get promoOpeningDiscountsSubtitle;

  /// No description provided for @promoFreeDeliveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'توصيل مجاني'**
  String get promoFreeDeliveryTitle;

  /// No description provided for @promoFreeDeliverySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'على الطلبات فوق 300 ج.م'**
  String get promoFreeDeliverySubtitle;

  /// No description provided for @offerDiscountPercent.
  ///
  /// In ar, this message translates to:
  /// **'خصم {percent}%'**
  String offerDiscountPercent(String percent);

  /// No description provided for @offerBadge.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get offerBadge;

  /// No description provided for @favoritesSignInPrompt.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لحفظ منتجاتك المفضلة'**
  String get favoritesSignInPrompt;

  /// No description provided for @favoritesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المفضلة'**
  String get favoritesLoadFailed;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مفضلة بعد'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على ♡ في أي منتج لحفظه هنا'**
  String get favoritesEmptySubtitle;

  /// No description provided for @favoritesUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث المفضلة، حاول مرة أخرى'**
  String get favoritesUpdateFailed;

  /// No description provided for @removeFromFavorites.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المفضلة'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In ar, this message translates to:
  /// **'أضف للمفضلة'**
  String get addToFavorites;

  /// No description provided for @magazinesLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المجلات'**
  String get magazinesLoadFailed;

  /// No description provided for @noMagazinesCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلات حالياً'**
  String get noMagazinesCurrently;

  /// No description provided for @magazineNoPdf.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ملف PDF لهذه المجلة'**
  String get magazineNoPdf;

  /// No description provided for @magazineOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح المجلة. حاول مرة أخرى لاحقاً.'**
  String get magazineOpenFailed;

  /// No description provided for @magazinePreviousPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة السابقة'**
  String get magazinePreviousPage;

  /// No description provided for @magazineNextPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التالية'**
  String get magazineNextPage;

  /// No description provided for @magazinePageOf.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page} من {count}'**
  String magazinePageOf(String page, String count);

  /// No description provided for @authWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في سفير ماركت'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك أو أنشئ حساباً في ثوانٍ'**
  String get authWelcomeSubtitle;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithPhone.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة برقم الهاتف'**
  String get authContinueWithPhone;

  /// No description provided for @authContinueWithEmail.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة بالبريد الإلكتروني'**
  String get authContinueWithEmail;

  /// No description provided for @authOr.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get authOr;

  /// No description provided for @authOtherSignInOptions.
  ///
  /// In ar, this message translates to:
  /// **'طرق دخول أخرى'**
  String get authOtherSignInOptions;

  /// No description provided for @authTermsNotice.
  ///
  /// In ar, this message translates to:
  /// **'بالمتابعة، أنت توافق على سياسة الخصوصية والشروط'**
  String get authTermsNotice;

  /// No description provided for @authGoogleFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الدخول بحساب Google، حاول مرة أخرى'**
  String get authGoogleFailed;

  /// No description provided for @authProviderUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'طريقة تسجيل الدخول هذه غير متاحة حالياً'**
  String get authProviderUnavailable;

  /// No description provided for @authOtpInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح أو انتهت صلاحيته'**
  String get authOtpInvalid;

  /// No description provided for @authSmsSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال رسالة التحقق، تأكد من الرقم وحاول مرة أخرى'**
  String get authSmsSendFailed;

  /// No description provided for @authPhoneSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدخول برقم الهاتف'**
  String get authPhoneSheetTitle;

  /// No description provided for @authPhoneSheetSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سنرسل لك رمز تحقق مكوّناً من 6 أرقام في رسالة نصية'**
  String get authPhoneSheetSubtitle;

  /// No description provided for @authSendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get authSendCode;

  /// No description provided for @authEnterCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get authEnterCodeTitle;

  /// No description provided for @authCodeSentTo.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا الرمز في رسالة نصية إلى {phone}'**
  String authCodeSentTo(String phone);

  /// No description provided for @authVerifyCode.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get authVerifyCode;

  /// No description provided for @authEnterSixDigitCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام'**
  String get authEnterSixDigitCode;

  /// No description provided for @authResendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get authResendCode;

  /// No description provided for @authResendCodeIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {seconds} ث'**
  String authResendCodeIn(String seconds);

  /// No description provided for @authChangeNumber.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get authChangeNumber;

  /// No description provided for @authCodeResent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رمز جديد'**
  String get authCodeResent;

  /// No description provided for @productNoImageBadge.
  ///
  /// In ar, this message translates to:
  /// **'بدون صورة'**
  String get productNoImageBadge;

  /// No description provided for @newProductsMissingImageCount.
  ///
  /// In ar, this message translates to:
  /// **'منتجات جديدة (بدون صورة: {count})'**
  String newProductsMissingImageCount(String count);

  /// No description provided for @missingImageCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'بدون صورة: {count}'**
  String missingImageCountBadge(String count);

  /// No description provided for @productImageSaveBlocked.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع الصورة لكن لم يتم حفظها على المنتج: صلاحية تعديل المنتجات مرفوضة. راجع صلاحيات المسؤول في Supabase.'**
  String get productImageSaveBlocked;

  /// No description provided for @authPhoneLoginDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول برقم الهاتف غير مفعّل حالياً، استخدم Google أو البريد الإلكتروني'**
  String get authPhoneLoginDisabled;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر لغتك'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغييرها في أي وقت من الإعدادات'**
  String get onboardingLanguageSubtitle;

  /// No description provided for @onboardingAppearanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مظهر التطبيق'**
  String get onboardingAppearanceTitle;

  /// No description provided for @onboardingAppearanceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'فاتح أو داكن، أو حسب إعدادات جهازك'**
  String get onboardingAppearanceSubtitle;

  /// No description provided for @onboardingAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لتجربة كاملة'**
  String get onboardingAccountTitle;

  /// No description provided for @onboardingAccountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اطلب منتجاتك، تابع طلباتك، واحفظ عناوينك ومفضلتك'**
  String get onboardingAccountSubtitle;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingSignInOrRegister.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول أو إنشاء حساب'**
  String get onboardingSignInOrRegister;

  /// No description provided for @onboardingBrowseFirst.
  ///
  /// In ar, this message translates to:
  /// **'تصفح التطبيق أولاً'**
  String get onboardingBrowseFirst;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @settingsAccountSection.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccountSection;

  /// No description provided for @guestSignInTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك للمتابعة'**
  String get guestSignInTitle;

  /// No description provided for @guestCartMessage.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً أو سجّل دخولك لإضافة المنتجات إلى السلة وإتمام طلبك.'**
  String get guestCartMessage;

  /// No description provided for @guestProfileMessage.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لعرض بياناتك وطلباتك وعناوينك ومفضلتك.'**
  String get guestProfileMessage;

  /// No description provided for @notNow.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get notNow;

  /// No description provided for @unitSet.
  ///
  /// In ar, this message translates to:
  /// **'طقم'**
  String get unitSet;

  /// No description provided for @unitBoxOf.
  ///
  /// In ar, this message translates to:
  /// **'علبة {count} قطعة'**
  String unitBoxOf(String count);

  /// No description provided for @paywallSignInToSubscribe.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك للاشتراك في باقات سفير'**
  String get paywallSignInToSubscribe;

  /// No description provided for @paymentChooseMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الدفع'**
  String get paymentChooseMethod;

  /// No description provided for @paymentMethodCard.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة بنكية (فيزا / ماستركارد / ميزة)'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodWallet.
  ///
  /// In ar, this message translates to:
  /// **'محفظة إلكترونية (فودافون كاش وغيرها)'**
  String get paymentMethodWallet;

  /// No description provided for @paymentWalletPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم المحفظة'**
  String get paymentWalletPhoneLabel;

  /// No description provided for @paymentWalletPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم محفظة صحيحاً يبدأ بـ 01'**
  String get paymentWalletPhoneInvalid;

  /// No description provided for @paymentContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get paymentContinue;

  /// No description provided for @paymentStartFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء الدفع، حاول مرة أخرى'**
  String get paymentStartFailed;

  /// No description provided for @paymentMethodUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع هذه غير متاحة حالياً'**
  String get paymentMethodUnavailable;

  /// No description provided for @paymentPageOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح صفحة الدفع'**
  String get paymentPageOpenFailed;

  /// No description provided for @paymentVerifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من الدفع…'**
  String get paymentVerifying;

  /// No description provided for @paymentFailedMessage.
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل عملية الدفع أو تم رفض البطاقة من البنك. يرجى المحاولة مرة أخرى.'**
  String get paymentFailedMessage;

  /// No description provided for @paymentStillProcessing.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل تأكيد الدفع بعد. يمكنك مراجعة حالة طلبك من طلباتي.'**
  String get paymentStillProcessing;

  /// No description provided for @subscriptionActivatedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل الاشتراك بنجاح 👑'**
  String get subscriptionActivatedTitle;

  /// No description provided for @subscriptionActiveUntil.
  ///
  /// In ar, this message translates to:
  /// **'باقة {plan} فعّالة حتى {date}'**
  String subscriptionActiveUntil(String plan, String date);

  /// No description provided for @subscriptionContinueShopping.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التسوق'**
  String get subscriptionContinueShopping;

  /// No description provided for @redeemPoints.
  ///
  /// In ar, this message translates to:
  /// **'تبديل النقاط'**
  String get redeemPoints;

  /// No description provided for @redeemQrTitle.
  ///
  /// In ar, this message translates to:
  /// **'اعرض الكود على الكاشير'**
  String get redeemQrTitle;

  /// No description provided for @redeemQrSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل 50 نقطة = 1 جنيه خصم. يُغلق الكود تلقائياً بعد تطبيق الخصم.'**
  String get redeemQrSubtitle;

  /// No description provided for @redeemSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تطبيق الخصم بنجاح'**
  String get redeemSuccess;

  /// No description provided for @scanCustomerCode.
  ///
  /// In ar, this message translates to:
  /// **'مسح كود العميل'**
  String get scanCustomerCode;

  /// No description provided for @scanCustomerHint.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا إلى كود العميل'**
  String get scanCustomerHint;

  /// No description provided for @scanInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'هذا ليس كود عميل من سفير ماركت'**
  String get scanInvalidCode;

  /// No description provided for @scanCameraFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل الكاميرا: {error}'**
  String scanCameraFailed(String error);

  /// No description provided for @redeemInsufficientPoints.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد لا يكفي لخصم 1 جنيه'**
  String get redeemInsufficientPoints;

  /// No description provided for @redeemNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مصرّح له بخصم النقاط'**
  String get redeemNotAllowed;

  /// No description provided for @redeemCustomerNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على العميل'**
  String get redeemCustomerNotFound;

  /// No description provided for @redeemFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر خصم النقاط: {error}'**
  String redeemFailed(String error);

  /// No description provided for @cashierRedeemTitle.
  ///
  /// In ar, this message translates to:
  /// **'خصم نقاط الولاء'**
  String get cashierRedeemTitle;

  /// No description provided for @cashierCustomer.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get cashierCustomer;

  /// No description provided for @cashierCurrentBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الحالي'**
  String get cashierCurrentBalance;

  /// No description provided for @cashierPointsToDeduct.
  ///
  /// In ar, this message translates to:
  /// **'النقاط المخصومة'**
  String get cashierPointsToDeduct;

  /// No description provided for @cashierDiscount.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الخصم'**
  String get cashierDiscount;

  /// No description provided for @cashierRemainingPoints.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد بعد الخصم'**
  String get cashierRemainingPoints;

  /// No description provided for @cashierBarcodeHint.
  ///
  /// In ar, this message translates to:
  /// **'امسح هذا الباركود بجهاز الكاشير، ثم اضغط تأكيد'**
  String get cashierBarcodeHint;

  /// No description provided for @confirmPointsDeduction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد خصم النقاط'**
  String get confirmPointsDeduction;

  /// No description provided for @cashierRedeemDone.
  ///
  /// In ar, this message translates to:
  /// **'تم خصم {points} نقطة (خصم {amount}) بنجاح'**
  String cashierRedeemDone(String points, String amount);

  /// No description provided for @phoneOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات التليفون / بحث العملاء'**
  String get phoneOrdersTitle;

  /// No description provided for @phoneOrderOpen.
  ///
  /// In ar, this message translates to:
  /// **'طلب تليفون'**
  String get phoneOrderOpen;

  /// No description provided for @phoneOrderSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم الهاتف أو اسم العميل...'**
  String get phoneOrderSearchHint;

  /// No description provided for @phoneOrderNewCustomer.
  ///
  /// In ar, this message translates to:
  /// **'+ عميل جديد'**
  String get phoneOrderNewCustomer;

  /// No description provided for @phoneOrderTypeToSearch.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم الهاتف أو الاسم للبحث'**
  String get phoneOrderTypeToSearch;

  /// No description provided for @phoneOrderNoCustomers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عميل مطابق. أضفه كعميل جديد.'**
  String get phoneOrderNoCustomers;

  /// No description provided for @phoneOrderAppCustomer.
  ///
  /// In ar, this message translates to:
  /// **'مسجل بالتطبيق'**
  String get phoneOrderAppCustomer;

  /// No description provided for @phoneOrderPosCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل الكاشير'**
  String get phoneOrderPosCustomer;

  /// No description provided for @phoneOrderNoAddress.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عنوان محفوظ'**
  String get phoneOrderNoAddress;

  /// No description provided for @phoneOrderChangeCustomer.
  ///
  /// In ar, this message translates to:
  /// **'تغيير العميل'**
  String get phoneOrderChangeCustomer;

  /// No description provided for @phoneOrderCustomerName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get phoneOrderCustomerName;

  /// No description provided for @phoneOrderCustomerPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneOrderCustomerPhone;

  /// No description provided for @phoneOrderCustomerAddress.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get phoneOrderCustomerAddress;

  /// No description provided for @phoneOrderCustomerZone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get phoneOrderCustomerZone;

  /// No description provided for @phoneOrderSaveCustomer.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العميل'**
  String get phoneOrderSaveCustomer;

  /// No description provided for @phoneOrderNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم العميل'**
  String get phoneOrderNameRequired;

  /// No description provided for @phoneOrderPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم موبايل مصري صحيح (01XXXXXXXXX)'**
  String get phoneOrderPhoneInvalid;

  /// No description provided for @phoneOrderProductSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم المنتج أو الباركود...'**
  String get phoneOrderProductSearchHint;

  /// No description provided for @phoneOrderSearchProductsPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتج بالاسم أو الباركود'**
  String get phoneOrderSearchProductsPrompt;

  /// No description provided for @phoneOrderNoProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مطابقة'**
  String get phoneOrderNoProducts;

  /// No description provided for @phoneOrderCartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلة العميل'**
  String get phoneOrderCartTitle;

  /// No description provided for @phoneOrderCartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة منتجات بعد'**
  String get phoneOrderCartEmpty;

  /// No description provided for @phoneOrderItemsTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المنتجات'**
  String get phoneOrderItemsTotal;

  /// No description provided for @phoneOrderTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get phoneOrderTotal;

  /// No description provided for @phoneOrderFreeDelivery.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get phoneOrderFreeDelivery;

  /// No description provided for @phoneOrderConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إتمام وتسجيل الطلب'**
  String get phoneOrderConfirm;

  /// No description provided for @phoneOrderPlaced.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الطلب #{id}'**
  String phoneOrderPlaced(String id);

  /// No description provided for @phoneOrderFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الطلب: {error}'**
  String phoneOrderFailed(String error);

  /// No description provided for @phoneOrderSearchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث: {error}'**
  String phoneOrderSearchFailed(String error);

  /// No description provided for @phoneOrderNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مصرّح له بتسجيل طلبات التليفون'**
  String get phoneOrderNotAllowed;

  /// No description provided for @phoneOrderBadge.
  ///
  /// In ar, this message translates to:
  /// **'تليفون'**
  String get phoneOrderBadge;

  /// No description provided for @phoneOrderSetupMissing.
  ///
  /// In ar, this message translates to:
  /// **'الدالة {function} غير موجودة في قاعدة البيانات. شغّل ملف supabase/migrations/20261111010000_phone_orders.sql من Supabase SQL Editor.'**
  String phoneOrderSetupMissing(String function);

  /// No description provided for @adminToggleMenu.
  ///
  /// In ar, this message translates to:
  /// **'إظهار/إخفاء القائمة'**
  String get adminToggleMenu;

  /// No description provided for @adminResizeColumn.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لتغيير عرض العمود'**
  String get adminResizeColumn;

  /// No description provided for @phoneOrderShowCart.
  ///
  /// In ar, this message translates to:
  /// **'عرض السلة والتوصيل'**
  String get phoneOrderShowCart;

  /// No description provided for @phoneOrderHideCart.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء السلة'**
  String get phoneOrderHideCart;

  /// No description provided for @driverDeliveryAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التوصيل'**
  String get driverDeliveryAddress;

  /// No description provided for @driverNavigateViaMap.
  ///
  /// In ar, this message translates to:
  /// **'التوجه عبر الخريطة'**
  String get driverNavigateViaMap;

  /// No description provided for @mapSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منطقة أو شارع...'**
  String get mapSearchHint;

  /// No description provided for @mapSearchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج لهذا البحث'**
  String get mapSearchNoResults;

  /// No description provided for @mapSearchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث عن المكان: {error}'**
  String mapSearchFailed(String error);

  /// No description provided for @mapSearchClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get mapSearchClear;

  /// No description provided for @supportLiveChatSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب لنا من داخل التطبيق وسيرد عليك فريقنا مباشرة'**
  String get supportLiveChatSubtitle;

  /// No description provided for @supportSignInMessage.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لتبدأ محادثة مع خدمة العملاء.'**
  String get supportSignInMessage;

  /// No description provided for @supportLaunchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح التطبيق، يمكنك الاتصال بنا على {phone}'**
  String supportLaunchFailed(String phone);

  /// No description provided for @supportChatTitle.
  ///
  /// In ar, this message translates to:
  /// **'خدمة العملاء'**
  String get supportChatTitle;

  /// No description provided for @supportChatSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'فريق سفير ماركت يرد عليك هنا'**
  String get supportChatSubtitle;

  /// No description provided for @supportChatWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك! اكتب سؤالك أو مشكلتك وسيرد عليك فريق خدمة العملاء في أقرب وقت.'**
  String get supportChatWelcome;

  /// No description provided for @supportMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالتك...'**
  String get supportMessageHint;

  /// No description provided for @supportLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المحادثة: {error}'**
  String supportLoadFailed(String error);

  /// No description provided for @supportSetupMissing.
  ///
  /// In ar, this message translates to:
  /// **'خدمة المحادثة غير مفعلة بعد. شغّل supabase/migrations/20261114210000_support_chat.sql في Supabase SQL Editor.'**
  String get supportSetupMissing;

  /// No description provided for @supportNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية الوصول إلى هذه المحادثة'**
  String get supportNotAllowed;

  /// No description provided for @supportRequestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إتمام العملية: {error}'**
  String supportRequestFailed(String error);

  /// No description provided for @supportCenterTitle.
  ///
  /// In ar, this message translates to:
  /// **'الشكاوى والمحادثات'**
  String get supportCenterTitle;

  /// No description provided for @supportNoChats.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات مفتوحة حالياً'**
  String get supportNoChats;

  /// No description provided for @supportSelectChat.
  ///
  /// In ar, this message translates to:
  /// **'اختر محادثة من القائمة للرد على العميل'**
  String get supportSelectChat;

  /// No description provided for @supportNoMessagesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل في هذه المحادثة بعد'**
  String get supportNoMessagesYet;

  /// No description provided for @supportReplyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ردك على العميل...'**
  String get supportReplyHint;

  /// No description provided for @supportLatestOrders.
  ///
  /// In ar, this message translates to:
  /// **'آخر الطلبات'**
  String get supportLatestOrders;

  /// No description provided for @supportLatestOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر طلبات {name}'**
  String supportLatestOrdersTitle(String name);

  /// No description provided for @supportNoOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات لهذا العميل'**
  String get supportNoOrders;

  /// No description provided for @supportNewMessageToast.
  ///
  /// In ar, this message translates to:
  /// **'رسالة جديدة من {name}: {message}'**
  String supportNewMessageToast(String name, String message);

  /// No description provided for @supportOpenChat.
  ///
  /// In ar, this message translates to:
  /// **'فتح المحادثة'**
  String get supportOpenChat;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سنقوم بإشعارك فور توفر عروض أو مجلات جديدة من سفير ماركت'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الإشعارات: {error}'**
  String notificationsLoadFailed(String error);

  /// No description provided for @notificationsSetupMissing.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات غير مفعلة بعد. شغّل supabase/migrations/20261114220000_app_notifications.sql في Supabase SQL Editor.'**
  String get notificationsSetupMissing;

  /// No description provided for @notificationsNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الإشعارات وحذفها متاح لحساب المدير فقط'**
  String get notificationsNotAllowed;

  /// No description provided for @timeJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{منذ دقيقة} =2{منذ دقيقتين} few{منذ {count} دقائق} other{منذ {count} دقيقة}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{منذ ساعة} =2{منذ ساعتين} few{منذ {count} ساعات} other{منذ {count} ساعة}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{منذ يوم} =2{منذ يومين} few{منذ {count} أيام} other{منذ {count} يوماً}}'**
  String timeDaysAgo(int count);

  /// No description provided for @notificationTypeGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get notificationTypeGeneral;

  /// No description provided for @notificationTypePromo.
  ///
  /// In ar, this message translates to:
  /// **'عروض وخصومات'**
  String get notificationTypePromo;

  /// No description provided for @notificationTypeMagazine.
  ///
  /// In ar, this message translates to:
  /// **'مجلة جديدة'**
  String get notificationTypeMagazine;

  /// No description provided for @notificationTypeOrder.
  ///
  /// In ar, this message translates to:
  /// **'طلباتك'**
  String get notificationTypeOrder;

  /// No description provided for @notificationTypeSupportChat.
  ///
  /// In ar, this message translates to:
  /// **'خدمة العملاء'**
  String get notificationTypeSupportChat;

  /// No description provided for @adminSendNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إرسال إشعارات'**
  String get adminSendNotifications;

  /// No description provided for @adminNotificationFormSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يظهر الإشعار فوراً في تطبيق جميع العملاء'**
  String get adminNotificationFormSubtitle;

  /// No description provided for @adminNotificationTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإشعار'**
  String get adminNotificationTitleLabel;

  /// No description provided for @adminNotificationTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مجلة عروض الشهر نزلت الآن! 🔥'**
  String get adminNotificationTitleHint;

  /// No description provided for @adminNotificationTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنوان الإشعار'**
  String get adminNotificationTitleRequired;

  /// No description provided for @adminNotificationBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'نص الإشعار'**
  String get adminNotificationBodyLabel;

  /// No description provided for @adminNotificationBodyHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تصفح أحدث العروض والخصومات الحصرية في سفير ماركت'**
  String get adminNotificationBodyHint;

  /// No description provided for @adminNotificationBodyRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نص الإشعار'**
  String get adminNotificationBodyRequired;

  /// No description provided for @adminNotificationTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الإشعار'**
  String get adminNotificationTypeLabel;

  /// No description provided for @adminNotificationImageLabel.
  ///
  /// In ar, this message translates to:
  /// **'رابط صورة العرض - اختياري'**
  String get adminNotificationImageLabel;

  /// No description provided for @adminNotificationImageInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رابطاً صحيحاً يبدأ بـ https://'**
  String get adminNotificationImageInvalid;

  /// No description provided for @adminSendNotificationButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الإشعار لجميع العملاء'**
  String get adminSendNotificationButton;

  /// No description provided for @adminNotificationSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الإشعار لجميع العملاء'**
  String get adminNotificationSent;

  /// No description provided for @adminNotificationSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال الإشعار: {error}'**
  String adminNotificationSendFailed(String error);

  /// No description provided for @adminNotificationsHistory.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات المرسلة'**
  String get adminNotificationsHistory;

  /// No description provided for @adminNoNotificationsSent.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إرسال أي إشعارات بعد'**
  String get adminNoNotificationsSent;

  /// No description provided for @adminDeleteNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإشعار'**
  String get adminDeleteNotificationTitle;

  /// No description provided for @adminDeleteNotificationConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف الإشعار «{title}»؟ سيختفي من تطبيق العملاء.'**
  String adminDeleteNotificationConfirm(String title);

  /// No description provided for @adminDeleteNotificationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف الإشعار: {error}'**
  String adminDeleteNotificationFailed(String error);

  /// No description provided for @orderCardShowDetails.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get orderCardShowDetails;

  /// No description provided for @orderCardHideDetails.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء التفاصيل'**
  String get orderCardHideDetails;

  /// No description provided for @orderCardItemsTitle.
  ///
  /// In ar, this message translates to:
  /// **'منتجات الطلب'**
  String get orderCardItemsTitle;

  /// No description provided for @orderCardItemsFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل منتجات الطلب'**
  String get orderCardItemsFailed;

  /// No description provided for @orderCardNoItems.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مسجلة لهذا الطلب'**
  String get orderCardNoItems;

  /// No description provided for @orderCardCancelledNote.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء هذا الطلب'**
  String get orderCardCancelledNote;

  /// No description provided for @cancelOrder.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء الطلب؟'**
  String get cancelOrderConfirmTitle;

  /// No description provided for @cancelOrderReasonPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر سبب الإلغاء:'**
  String get cancelOrderReasonPrompt;

  /// No description provided for @cancelOrderDismiss.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get cancelOrderDismiss;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإلغاء'**
  String get cancelOrderConfirm;

  /// No description provided for @cancelReasonDeliveryDelay.
  ///
  /// In ar, this message translates to:
  /// **'تأخير في التوصيل'**
  String get cancelReasonDeliveryDelay;

  /// No description provided for @cancelReasonOrderedByMistake.
  ///
  /// In ar, this message translates to:
  /// **'طلبت بالخطأ'**
  String get cancelReasonOrderedByMistake;

  /// No description provided for @cancelReasonChangedMind.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رأيي'**
  String get cancelReasonChangedMind;

  /// No description provided for @cancelReasonOther.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get cancelReasonOther;

  /// No description provided for @cancellationReasonLine.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء: {reason}'**
  String cancellationReasonLine(String reason);

  /// No description provided for @orderCancelledSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب بنجاح'**
  String get orderCancelledSuccess;

  /// No description provided for @orderCancelTooLate.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إلغاء الطلب لأن تجهيزه اكتمل أو خرج للتوصيل'**
  String get orderCancelTooLate;

  /// No description provided for @orderCancelSetupMissing.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب غير مفعّل بعد. شغّل supabase/migrations/20261114240000_customer_cancel_order.sql في Supabase SQL Editor.'**
  String get orderCancelSetupMissing;

  /// No description provided for @orderCancelFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إلغاء الطلب: {error}'**
  String orderCancelFailed(String error);

  /// No description provided for @adminMenuReceiveOrders.
  ///
  /// In ar, this message translates to:
  /// **'تلقي الطلبات'**
  String get adminMenuReceiveOrders;

  /// No description provided for @adminMenuOrderStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get adminMenuOrderStatus;

  /// No description provided for @adminStatusDelayedShort.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get adminStatusDelayedShort;

  /// No description provided for @adminStatusCancelledShort.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get adminStatusCancelledShort;

  /// No description provided for @adminResendNotification.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال'**
  String get adminResendNotification;

  /// No description provided for @adminResendFillForm.
  ///
  /// In ar, this message translates to:
  /// **'تعبئة النموذج'**
  String get adminResendFillForm;

  /// No description provided for @adminResendNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الإشعار؟'**
  String get adminResendNotificationTitle;

  /// No description provided for @adminResendNotificationConfirm.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إرسال الإشعار «{title}» لجميع العملاء مرة أخرى.'**
  String adminResendNotificationConfirm(String title);

  /// No description provided for @adminNotificationSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالاسم أو العنوان'**
  String get adminNotificationSearchHint;

  /// No description provided for @adminNotificationFilterByDate.
  ///
  /// In ar, this message translates to:
  /// **'فلترة بالتاريخ'**
  String get adminNotificationFilterByDate;

  /// No description provided for @adminNotificationFilterByType.
  ///
  /// In ar, this message translates to:
  /// **'فلترة بالسبب/النوع'**
  String get adminNotificationFilterByType;

  /// No description provided for @adminNotificationClearDateFilter.
  ///
  /// In ar, this message translates to:
  /// **'مسح فلتر التاريخ'**
  String get adminNotificationClearDateFilter;

  /// No description provided for @adminSelectCustomerFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلاً لبدء الطلب'**
  String get adminSelectCustomerFirst;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'ky',
        'ms',
        'uz',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ms':
      return AppLocalizationsMs();
    case 'uz':
      return AppLocalizationsUz();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
