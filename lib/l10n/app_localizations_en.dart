// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get bannerShopBrandProducts => 'Shop this brand';

  @override
  String get bannerAdd => 'Add company banner';

  @override
  String get bannerTitleLabel => 'Company / banner title';

  @override
  String get bannerKeywordLabel => 'Keyword for the company\'s products';

  @override
  String get bannerKeywordHint => 'e.g. Juhayna';

  @override
  String get bannerChooseImage => 'Choose banner image';

  @override
  String get bannerChangeImage => 'Change image';

  @override
  String get bannerImageRequired => 'Choose the banner image first';

  @override
  String get bannerKeywordRequired =>
      'Enter the keyword that opens the company\'s products';

  @override
  String get bannerSaved => 'Banner added successfully';

  @override
  String bannerSaveFailed(String error) {
    return 'Could not save the banner: $error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return 'Delete the banner \"$title\"?';
  }

  @override
  String get bannerExistingHeader => 'Current banners';

  @override
  String get appTitle => 'Safeer Market';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get save => 'Save';

  @override
  String get search => 'Search';

  @override
  String get cart => 'Cart';

  @override
  String get wallet => 'Wallet';

  @override
  String get more => 'More';

  @override
  String get exitHint => 'Press back again to exit the app';

  @override
  String get newProducts => 'New products';

  @override
  String get trendingOffers => 'Trending offers';

  @override
  String get noNewNotifications => 'No new notifications';

  @override
  String get loadingLatestProducts => 'Loading the latest products...';

  @override
  String get noNewProductsLast3Days => 'No new products in the last 3 days';

  @override
  String get loadingOffers => 'Loading offers...';

  @override
  String get noOffersCurrently => 'No offers right now';

  @override
  String get subscribersExclusiveFeature => 'Subscribers-only feature 👑';

  @override
  String get playAndWinPaywallBody =>
      'The Play & Win game and weekly gifts are available only to Safeer Prime and Safeer Pro subscribers. Upgrade your account and enjoy the perks!';

  @override
  String get upgradeAccountNow => 'Upgrade now';

  @override
  String get exploreSafeer => 'Explore Safeer';

  @override
  String get featuredProducts => 'Featured products';

  @override
  String get failedToLoadProducts => 'Could not load products';

  @override
  String get noProductsCurrently => 'No products right now';

  @override
  String get seeAll => 'See all';

  @override
  String get retry => 'Retry';

  @override
  String get loyaltyPoints => 'Loyalty points';

  @override
  String get spinWheelCollectPoints => 'Spin the wheel and collect points';

  @override
  String get favoriteProducts => 'Favorite products';

  @override
  String get myOrders => 'My orders';

  @override
  String get contactUs => 'Contact us';

  @override
  String get help => 'Help';

  @override
  String get signOut => 'Sign out';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOutConfirmMessage =>
      'Do you want to sign out of your account?';

  @override
  String get signedOut => 'You have signed out';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get adminDashboardSubtitle =>
      'Manage customer orders and update their status';

  @override
  String get guestName => 'Guest';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get guestSubtitle => 'Sign in to follow your orders and favorites';

  @override
  String get personalData => 'Personal details';

  @override
  String get email => 'Email';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get savedCards => 'Saved cards';

  @override
  String get messageAndSmsAlerts => 'App and SMS alerts';

  @override
  String get privacyAndTerms => 'Privacy policy and terms';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmMessage =>
      'Your account and all of your data will be permanently deleted. Are you sure?';

  @override
  String get deleteAccountSuccess => 'Your account was deleted successfully';

  @override
  String get passwordRequirementsTitle => 'Password must include:';

  @override
  String get passwordRuleMinLength => 'At least 8 characters';

  @override
  String get passwordRuleUppercase => 'At least 1 uppercase letter';

  @override
  String get passwordRuleLowercase => 'At least 1 lowercase letter';

  @override
  String get passwordRuleDigit => 'At least 1 number';

  @override
  String get talkToUs => 'Talk to us';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportLiveChat => 'Live chat with customer service';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count pts • Redeem';
  }

  @override
  String get loyaltyPointsEarnNow => 'Loyalty points • Earn now 🎁';

  @override
  String get ok => 'OK';

  @override
  String get noEmail => 'No email address';

  @override
  String get changeEmailContactSupport =>
      'To change your email, please contact support';

  @override
  String get privacyPolicyBody =>
      'At Safeer Market we respect your privacy. We use your data such as name, phone number, and address only to deliver your orders and improve our services, and we do not share it with any third party without your consent.\n\nBy using the app you agree to the terms of use, including order, delivery, and return policies. The full policy will be published soon.';

  @override
  String get helpTitle => 'How can we help you?';

  @override
  String get helpBody =>
      'The Safeer Market team is always ready to help.\nIf you have an issue with your order or a question, contact us and we will get back to you as soon as possible.';

  @override
  String get callUs => 'Call us';

  @override
  String get callUsSubtitle => 'Speak with customer service directly';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whatsappSubtitle => 'Message us and we will reply quickly';

  @override
  String get messageAlerts => 'Message alerts';

  @override
  String get appNotifications => 'App notifications';

  @override
  String get appNotificationsSubtitle => 'Offers and order status updates';

  @override
  String get smsMessages => 'SMS messages';

  @override
  String get smsMessagesSubtitle =>
      'Text messages for order confirmation and delivery';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get refresh => 'Refresh';

  @override
  String get all => 'All';

  @override
  String get shopNow => 'Shop now';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get categories => 'Categories';

  @override
  String get magazines => 'Magazines';

  @override
  String get addMagazine => 'Add magazine';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get networkError => 'Could not connect to the network';

  @override
  String get serverError => 'A server error occurred';

  @override
  String get serverConnectionError =>
      'Could not reach the server, please try again';

  @override
  String get pleaseSignInFirst => 'Please sign in first';

  @override
  String get noPermissionToEditOrder =>
      'You don\'t have permission to edit this order';

  @override
  String orderUpdateFailed(String error) {
    return 'Could not update the order: $error';
  }

  @override
  String ordersLoadFailed(String error) {
    return 'Could not load orders\n$error';
  }

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get deletedProduct => 'Deleted product';

  @override
  String get product => 'Product';

  @override
  String get addNewAddress => 'Add a new address';

  @override
  String get manageAddresses => 'Manage addresses';

  @override
  String get editLocation => 'Edit location';

  @override
  String helloName(String name) {
    return 'Hi, $name';
  }

  @override
  String get cardNumber => 'Card number';

  @override
  String get cardholderName => 'Cardholder name';

  @override
  String get asWrittenOnCard => 'As written on the card';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get addBankCard => 'Add a bank card';

  @override
  String get bankCard => 'Bank card';

  @override
  String get adminPaidByVisa => 'Paid by Visa';

  @override
  String get cameraOpenFailed =>
      'Could not open the camera, check the camera permission';

  @override
  String get addressLabelHome => 'Home';

  @override
  String get addressLabelWork => 'Work';

  @override
  String get puzzleGame => 'Puzzle game';

  @override
  String get luckyWheel => 'Wheel of fortune';

  @override
  String get awesome => 'Awesome!';

  @override
  String get customer => 'Customer';

  @override
  String get noLocationForOrder => 'No location is available for this order';

  @override
  String get branch => 'Branch';

  @override
  String get safeerCustomer => 'Safeer customer';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get cashOnDelivery => 'Cash on delivery';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusReadyForDelivery => 'Ready for delivery';

  @override
  String get orderStatusOutForDelivery => 'On the way';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get statusNew => 'New';

  @override
  String get startPreparing => 'Start preparing';

  @override
  String get total => 'Total';

  @override
  String get inStock => 'In stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get decreaseWeight => 'Decrease weight';

  @override
  String get increaseWeight => 'Increase weight';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get productUnavailableNow => 'This product is currently unavailable';

  @override
  String distanceFromBranch(String distance) {
    return '$distance from the branch';
  }

  @override
  String get invoiceNumberRequired => 'Invoice number is required';

  @override
  String get addAtLeastOneItem => 'Add at least one item';

  @override
  String get orderOnTheWayToYou => 'Your order is on the way!';

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get currencySymbol => 'EGP';

  @override
  String get unitPiece => 'piece';

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
  String get sessionExpired => 'Your session has expired, please sign in again';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'Could not update status: $error';
  }

  @override
  String get adminDeleteMagazineTitle => 'Delete magazine';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return 'Could not delete magazine: $error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get adminNoMagazinesYet =>
      'No magazines yet. Tap \"Add magazine\" to upload the first one.';

  @override
  String get adminMagazineExpired => 'Expired';

  @override
  String get adminMagazineUpcoming => 'Upcoming';

  @override
  String get adminMagazineActive => 'Active';

  @override
  String adminMagazineDateRange(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String get adminPickMagazinePdfTitle => 'Choose the magazine file (PDF)';

  @override
  String get adminMagazineStartDate => 'Start date';

  @override
  String get adminMagazineEndDate => 'End date';

  @override
  String get adminMagazineTitleRequired => 'Enter the magazine title';

  @override
  String get adminMagazineCoverRequired => 'Choose a cover image';

  @override
  String get adminMagazinePdfRequired => 'Choose a PDF file for the magazine';

  @override
  String get adminMagazineEndBeforeStart =>
      'End date must be after the start date';

  @override
  String get adminMagazineAdded => 'Magazine added successfully';

  @override
  String adminMagazineSaveFailed(String error) {
    return 'Could not save magazine: $error';
  }

  @override
  String get adminAddNewMagazine => 'Add new magazine';

  @override
  String get adminMagazineTitleLabel => 'Magazine title';

  @override
  String get adminPickCoverImage => 'Choose cover image';

  @override
  String get adminChangeCover => 'Change cover';

  @override
  String get adminPickPdfFile => 'Choose PDF file';

  @override
  String get adminUploading => 'Uploading...';

  @override
  String get adminSupervisorPermissions => 'Supervisor access';

  @override
  String get adminEnterPinHint => 'Enter PIN (1234)';

  @override
  String get adminSupervisorModeEnabled => 'Supervisor mode enabled';

  @override
  String get adminInvalidPin => 'Incorrect PIN';

  @override
  String get adminActivate => 'Activate';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - Admin';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - Workspace';
  }

  @override
  String get adminCloseManagement => 'Lock admin';

  @override
  String get adminEnableManagement => 'Unlock admin';

  @override
  String get adminExitToStore => 'Back to store';

  @override
  String get adminMenuOrders => 'Orders';

  @override
  String get adminMenuProducts => 'Products';

  @override
  String get adminMenuStaff => 'Staff';

  @override
  String get adminMenuReports => 'Reports & daily log';

  @override
  String get adminStatusPreparingShort => 'Preparing';

  @override
  String get adminStatusReadyForDriverShort => 'For driver';

  @override
  String get adminStatusDeliveryShort => 'Delivery';

  @override
  String get adminStatusCompletedShort => 'Completed';

  @override
  String get adminStatusUnknown => 'Unknown';

  @override
  String get adminNoOrders => 'No orders';

  @override
  String get adminSelectOrderFromList => 'Select an order from the list';

  @override
  String get adminItemsToPrepare => 'Items to prepare:';

  @override
  String get adminNoItemsInOrder => 'No items recorded';

  @override
  String get adminAvailableActions => 'Available actions';

  @override
  String get adminOrderAwaitingPreparer => 'Order is waiting for a preparer';

  @override
  String adminPreparerName(String name) {
    return 'Preparer: $name';
  }

  @override
  String get adminAwaitingDriverAssignment =>
      'Waiting for the supervisor to assign a driver';

  @override
  String get adminPickUpAndStartRoute => 'Pick up and start route 🗺️';

  @override
  String adminDriverName(String name) {
    return 'Driver: $name';
  }

  @override
  String get adminOrderReadyAwaitingDriver =>
      'Order prepared successfully. Waiting for the driver to pick it up.';

  @override
  String get adminMarkDelivered => 'Delivered successfully 💵';

  @override
  String get adminCloseOrderPermanently => 'Close the order permanently';

  @override
  String get adminOrderWithDriverOnTheWay =>
      'The order is now with the driver on the way to the customer.';

  @override
  String get adminOrderDeliveredAndClosed =>
      'This order was delivered and closed successfully.';

  @override
  String get adminWhoAreYouPickName => 'Who are you? (Pick your name to start)';

  @override
  String get adminNoPreparers => 'No preparers available';

  @override
  String get adminFinishOrderPreparation => 'Finish order preparation';

  @override
  String get adminCheckAllItemsFirst =>
      '⚠️ Sorry, you must check off all items first.';

  @override
  String get adminPreparationFinished => 'Preparation finished successfully.';

  @override
  String get adminAssignDriverTitle => 'Assign driver (supervisor only)';

  @override
  String get adminSelectDriver => 'Select driver';

  @override
  String get adminOrderAssignedToDriver => 'Order assigned to the driver';

  @override
  String get adminAssignToSelectedDriver => 'Assign to selected driver';

  @override
  String get adminCallFailed => 'Could not place the call';

  @override
  String get adminNoPhoneNumber => 'No number';

  @override
  String get adminNoName => 'No name';

  @override
  String get adminAddressNotSet => 'Not specified';

  @override
  String get adminCustomerInfo => 'Customer details';

  @override
  String get adminManageProducts => 'Manage products';

  @override
  String get adminActiveProducts => 'Active products';

  @override
  String get adminInactiveProducts => 'Inactive';

  @override
  String get adminSearchProductByName => 'Search products by name...';

  @override
  String adminErrorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get adminNoProducts => 'No products';

  @override
  String get adminCopyProductName => 'Copy product name';

  @override
  String get adminCopied => 'Copied';

  @override
  String get adminCopyBarcode => 'Copy barcode';

  @override
  String adminBarcodeValue(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String get adminUpdateErrorOccurred => 'An error occurred while updating';

  @override
  String get adminManageStaff => 'Manage staff';

  @override
  String get adminAddEmployee => 'Add employee';

  @override
  String get adminNoStaff => 'No registered staff';

  @override
  String get adminRoleTaker => 'Order taker';

  @override
  String get adminRolePreparer => 'Preparer';

  @override
  String get adminRoleDriver => 'Driver';

  @override
  String get adminNoPhone => 'No phone';

  @override
  String get adminReportsTitle => 'Reports & consolidated daily log';

  @override
  String get adminTotalSalesCollected => 'Total sales (collected)';

  @override
  String get adminDeliveredOrdersTitle => 'Completed & delivered orders';

  @override
  String get adminOrdersInPreparationTitle => 'Orders currently in preparation';

  @override
  String get adminCancelledOrdersTitle => 'Cancelled orders';

  @override
  String get adminTotalOrdersCumulative => 'Total orders (cumulative)';

  @override
  String adminOrdersCount(String count) {
    return '$count orders';
  }

  @override
  String get adminRecentOrdersLog => 'Recent orders log';

  @override
  String get adminOrderNumberColumn => 'Order no.';

  @override
  String get adminCustomerNameColumn => 'Customer name';

  @override
  String get adminStatusColumn => 'Status';

  @override
  String get paymentMethodCashLabel => 'Cash on delivery';

  @override
  String get paymentMethodCardLabel => 'Bank card (Visa/Mastercard)';

  @override
  String get paymentMethodInstaPayLabel => 'InstaPay';

  @override
  String get paymentMethodInstaPaySubtitle =>
      'Instant transfer via the InstaPay app';

  @override
  String get instaPayOpenApp => 'Open InstaPay to pay now';

  @override
  String get instaPayIpaLabel => 'Instant payment address (IPA)';

  @override
  String get instaPayPhoneLabel => 'Or transfer by phone number';

  @override
  String get instaPayCopy => 'Copy';

  @override
  String get instaPayCopied => 'Copied';

  @override
  String get instaPayConfirmHint =>
      'After transferring the order total via InstaPay, tap Confirm order below.';

  @override
  String get instaPayReceiptTitle => 'Bank transfer receipt (screenshot)';

  @override
  String get instaPayReceiptHint =>
      'Attach a screenshot of a successful InstaPay transfer to confirm the order';

  @override
  String get instaPayReceiptPick => 'Choose a receipt photo or take a picture';

  @override
  String get instaPayReceiptRequired =>
      'Please attach the transfer receipt image first';

  @override
  String get adminViewTransferReceipt => 'View transfer receipt';

  @override
  String get adminCopyReceiptImage => 'Copy image';

  @override
  String get adminShareReceipt => 'Share receipt';

  @override
  String get adminReceiptImageCopied => 'Receipt image copied';

  @override
  String get adminReceiptActionFailed => 'Could not process the receipt image';

  @override
  String get subscriptionConfirmInstaPay => 'Confirm subscription';

  @override
  String get subscriptionPendingSuccessTitle => 'Upgrade request received';

  @override
  String get subscriptionPendingSuccessBody =>
      'Your upgrade request and payment receipt were received. Your Pro account will be activated once the admin reviews it.';

  @override
  String get adminMenuPendingSubscriptions => 'Pending subscriptions';

  @override
  String get adminActivateAccount => 'Activate account';

  @override
  String get adminSubscriptionApproved => 'Subscription activated';

  @override
  String get adminNoPendingSubscriptions => 'No pending subscription requests';

  @override
  String get adminPendingSubscriptionTier => 'Requested plan';

  @override
  String get paymentCopyCardNumber => 'Copy card number';

  @override
  String get paymentCardNumberCopied => 'Card number copied';

  @override
  String get checkoutAddressOutOfRange =>
      'The address is outside the delivery area';

  @override
  String get checkoutPinAddressFirst => 'Pin the address on the map first';

  @override
  String checkoutOrderFailed(String error) {
    return 'Could not place the order: $error';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutDeliveryAddress => 'Delivery address';

  @override
  String get checkoutPaymentMethod => 'Payment method';

  @override
  String get checkoutOrderSummary => 'Order summary';

  @override
  String get checkoutSelectAddressFirst =>
      'Choose a delivery address first to place your order';

  @override
  String get checkoutPinLocationForFee =>
      'Pin the address on the map to calculate the delivery fee';

  @override
  String checkoutOrderPlaced(String id) {
    return 'Your order was received • Order #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return 'Sorry, the address is $distance away, outside the delivery area (up to $maxDistance)';
  }

  @override
  String get checkoutSignInToChooseAddress =>
      'Sign in to choose a delivery address';

  @override
  String get checkoutPinThisAddressForFee =>
      'Pin this address on the map to calculate the delivery fee';

  @override
  String get checkoutPinLocation => 'Pin location';

  @override
  String get checkoutChangeAddress => 'Change';

  @override
  String get checkoutAddDeliveryAddress =>
      'Add a delivery address to place your order';

  @override
  String get checkoutAddAddress => 'Add address';

  @override
  String get checkoutNoAddressChosen =>
      'You haven\'t chosen a delivery address yet';

  @override
  String get checkoutChooseAddress => 'Choose address';

  @override
  String get checkoutEstimatedArrival => 'Estimated arrival:';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return 'Delivery fee ($distance)';
  }

  @override
  String get checkoutOutOfDeliveryRange => 'Outside delivery area';

  @override
  String get checkoutItemCount => 'Number of items';

  @override
  String get checkoutSubtotal => 'Subtotal';

  @override
  String get checkoutGrandTotal => 'Grand total';

  @override
  String get checkoutConfirmOrder => 'Confirm order';

  @override
  String get paymentCardScanUnsupported =>
      'Card scanning isn\'t supported on this device';

  @override
  String get paymentCardScanFailed =>
      'We couldn\'t read the card, please enter the details manually';

  @override
  String get paymentCardScanned =>
      'Card scanned, review the details and enter the CVV';

  @override
  String get paymentCardTitle => 'Card payment';

  @override
  String get paymentSecureNotice => 'Secure, encrypted payment';

  @override
  String paymentPayNow(String amount) {
    return 'Pay now • $amount';
  }

  @override
  String get paymentScanCardTooltip => 'Scan card with camera';

  @override
  String get paymentAmountDue => 'Amount due';

  @override
  String get cardNumberRequired => 'Enter the card number';

  @override
  String get cardNumberInvalid => 'Invalid card number';

  @override
  String get cardExpiryRequired => 'Enter the date as MM/YY';

  @override
  String get cardExpiryInvalidMonth => 'Invalid month';

  @override
  String get cardExpired => 'Card has expired';

  @override
  String get cardCvvInvalid => 'Invalid code';

  @override
  String get cardHolderNameRequired =>
      'Enter the name as it appears on the card';

  @override
  String get walletCardSaved => 'Card saved successfully';

  @override
  String get walletCardDataProtected =>
      'Your data is protected and we never store the CVV';

  @override
  String get walletSaveCard => 'Save card';

  @override
  String get walletAddCardHint =>
      'Add your card to pay faster on your next orders';

  @override
  String get walletInAppBalance => 'Your in-app wallet balance';

  @override
  String get walletBalanceLoadFailed => 'Could not load the balance';

  @override
  String get walletBalanceAutoApplied =>
      'Your balance is applied automatically at checkout';

  @override
  String get walletSignInToViewBalance => 'Sign in to view your balance';

  @override
  String walletCardExpires(String expiry) {
    return 'Expires $expiry';
  }

  @override
  String get walletDeleteCard => 'Delete card';

  @override
  String get checkoutUseOrAddNewCard => '+ Use or add a new card';

  @override
  String get checkoutSavedCards => 'Your saved cards';

  @override
  String get paywallUpgradeAccount => 'Upgrade account';

  @override
  String get paywallDiscoverSafeer => 'Discover the Safeer world 👑';

  @override
  String get paywallChoosePlan =>
      'Choose the plan that fits your needs and save more on every order.';

  @override
  String get paywallProTitle => 'Safeer Pro (VIP)';

  @override
  String get paywallPerMonth => '/ month';

  @override
  String get paywallProUnlimitedFreeDelivery => 'Unlimited free delivery 🚀';

  @override
  String get paywallProExpressDelivery =>
      'Express delivery (priority preparation)';

  @override
  String get paywallProWholesalePrices => 'Exclusive wholesale prices 💰';

  @override
  String get paywallProNoMinimumOrder => 'No minimum order';

  @override
  String get paywallProUnlimitedGiveaways => 'Unlimited entries to gift draws';

  @override
  String get paywallPrimeTitle => 'Safeer Prime';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders => 'Free delivery on 5 orders';

  @override
  String get paywallPrimeOffersPriority => 'Priority access to major offers';

  @override
  String get paywallPrimeWeeklyPlayAndWin => 'Weekly Play & Win game 🎁';

  @override
  String get paywallFreeTitle => 'Standard account';

  @override
  String get paywallFreePrice => 'Free';

  @override
  String get paywallFreeStandardDelivery => 'Regular delivery at standard cost';

  @override
  String get paywallFreePublicAccess => 'Access to products and public offers';

  @override
  String get paywallBestSeller => 'Best seller';

  @override
  String get paywallPaymentComingSoon => 'Payment will be available soon';

  @override
  String get paywallSubscribeNow => 'Subscribe now';

  @override
  String get catDairyEggs => 'Dairy & Eggs';

  @override
  String get subcatTetraPakCheese => 'Tetra Pak, Triangle & Cup Cheese';

  @override
  String get subcatPackagedCheeseLabneh =>
      'Packaged Cheese, Labneh, Cream & Ghee';

  @override
  String get subcatCheeseByWeight => 'Cheese by Weight';

  @override
  String get subcatMozzarella => 'Mozzarella Cheese';

  @override
  String get subcatYogurtRicePudding => 'Yogurt & Rice Pudding';

  @override
  String get subcatLongLifeDairy => 'Long-Life Dairy';

  @override
  String get subcatPackagedButter => 'Packaged Butter';

  @override
  String get subcatPackagedEggs => 'Packaged Eggs';

  @override
  String get catSweetsSnacks => 'Sweets & Snacks';

  @override
  String get subcatChocolate => 'Chocolate';

  @override
  String get subcatBiscuits => 'Biscuits';

  @override
  String get subcatSweets => 'Sweets';

  @override
  String get subcatChipsRoasted => 'Chips & Roasted Snacks';

  @override
  String get subcatNutsByWeight => 'Snacks & Nuts by Weight';

  @override
  String get subcatHalawaSpreads => 'Halawa & Spreads';

  @override
  String get subcatRamadanYamish => 'Ramadan Dried Fruits & Nuts';

  @override
  String get catDrinksJuices => 'Drinks & Juices';

  @override
  String get subcatWaterDrinksIceCream => 'Water, Drinks, Juices & Ice Cream';

  @override
  String get subcatDrinks => 'Beverages';

  @override
  String get subcatJuices => 'Juices';

  @override
  String get subcatPowderedJuices => 'Powdered Juices';

  @override
  String get catMeatFrozen => 'Meat & Frozen';

  @override
  String get subcatFrozenPoultry => 'Frozen & Processed Poultry';

  @override
  String get subcatFrozenMeat => 'Frozen Meat';

  @override
  String get subcatProcessedMeat => 'Processed Meat';

  @override
  String get subcatFrozenFish => 'Frozen Fish';

  @override
  String get subcatSmokedFish => 'Smoked Fish';

  @override
  String get subcatFrozenVegFruit => 'Frozen Vegetables & Fruit';

  @override
  String get subcatFrozenPastries => 'Frozen Pastries';

  @override
  String get catBakeryBreakfast => 'Bakery & Breakfast';

  @override
  String get subcatBakery => 'Bakery';

  @override
  String get subcatPatisserie => 'Pastries & Snack Cakes';

  @override
  String get subcatCerealsOats => 'Cornflakes, Muesli & Oats';

  @override
  String get catPastaRice => 'Pasta & Rice';

  @override
  String get subcatPasta => 'Pasta';

  @override
  String get subcatRice => 'Rice';

  @override
  String get subcatLegumesSpicesBreadcrumbs =>
      'Packaged Legumes, Spices & Breadcrumbs';

  @override
  String get subcatSoupsStocksMixes => 'Soups, Stocks & Seasoning Mixes';

  @override
  String get catPantryOils => 'Grocery & Oils';

  @override
  String get subcatOils => 'Oils';

  @override
  String get subcatGhee => 'Ghee';

  @override
  String get subcatSugarFlour => 'Sugar & Flour';

  @override
  String get subcatCannedFood => 'Canned Food';

  @override
  String get subcatCondiments => 'Condiments & Appetizers';

  @override
  String get subcatOlivesPickles => 'Olives & Pickles';

  @override
  String get subcatPackagedOlivesPickles => 'Packaged Olives & Pickles';

  @override
  String get subcatSpicesByWeight => 'Spices by Weight';

  @override
  String get subcatGrainsByWeight => 'Grains & Seeds by Weight';

  @override
  String get subcatBakingSupplies => 'Baking Supplies & Powders';

  @override
  String get subcatSaladsByWeight => 'Salads by Weight';

  @override
  String get catCleaningCare => 'Cleaning & Household';

  @override
  String get subcatDetergentsSofteners => 'Detergents & Softeners';

  @override
  String get subcatLiquidSoapStainRemovers => 'Liquid Soap & Stain Removers';

  @override
  String get subcatBleachDisinfectants => 'Bleach & Disinfectants';

  @override
  String get subcatPolishes => 'Polishes';

  @override
  String get subcatInsecticidesFresheners => 'Insecticides & Air Fresheners';

  @override
  String get subcatTissuesToiletPaper => 'Tissues & Toilet Paper';

  @override
  String get subcatSteelWoolScrubbers => 'Steel Wool & Scrubbers';

  @override
  String get subcatSpongesSteelWool => 'Sponges & Steel Wool';

  @override
  String get subcatDrainCleaners => 'Drain Cleaners';

  @override
  String get subcatIncense => 'Incense';

  @override
  String get catPersonalCare => 'Personal Care';

  @override
  String get subcatShampooConditioner => 'Shampoo & Conditioner';

  @override
  String get subcatShowerGelHandWash => 'Shower Gel & Hand Wash';

  @override
  String get subcatSoap => 'Soap';

  @override
  String get subcatPerfumesDeodorants => 'Perfumes & Deodorants';

  @override
  String get subcatCreamsSerums => 'Creams & Serums';

  @override
  String get subcatOralCare => 'Oral Care';

  @override
  String get subcatShavingSupplies => 'Shaving Supplies';

  @override
  String get subcatHairDyeHenna => 'Hair Dye & Henna';

  @override
  String get subcatPersonalCareSupplies => 'Personal Care Essentials';

  @override
  String get catBabyWorld => 'Baby World';

  @override
  String get subcatDiapersPads => 'Diapers & Sanitary Pads';

  @override
  String get subcatBabyFood => 'Baby Food';

  @override
  String get subcatBabySupplies => 'Baby Supplies';

  @override
  String get catHomeSupplies => 'Home Supplies';

  @override
  String get subcatHousewares => 'Housewares';

  @override
  String get subcatElectricalTools => 'Electrical Tools';

  @override
  String get subcatElectricalSupplies => 'Electrical Supplies';

  @override
  String get subcatPlasticsBags => 'Plastics & Bags';

  @override
  String get subcatFoil => 'Foil';

  @override
  String get subcatHardware => 'Hardware & Odds';

  @override
  String get subcatBatteries => 'Batteries';

  @override
  String get subcatMatchesLighters => 'Matches & Lighters';

  @override
  String get subcatPetSupplies => 'Pet Supplies';

  @override
  String get subcatRamadanSupplies => 'Ramadan Supplies';

  @override
  String get categoryTitle => 'Category';

  @override
  String get categoryNotFound => 'This category doesn\'t exist';

  @override
  String get categoryNoProductsNow => 'No products in this category right now';

  @override
  String get shopFromHome => 'Shop from home';

  @override
  String categoryProductCount(String count) {
    return '$count products';
  }

  @override
  String get loadMoreFailedRetry => 'Couldn\'t load more, retry';

  @override
  String get categoriesDrawerTagline => 'Everything you need in one place';

  @override
  String get productDetailsTitle => 'Product details';

  @override
  String get productNotAvailable => 'This product isn\'t available';

  @override
  String get productLoadFailed => 'Couldn\'t load the product';

  @override
  String get productImageUpdated => 'Product image updated successfully!';

  @override
  String productImageUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get updateProductImage => 'Update product image';

  @override
  String get takePhotoWithCamera => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get changeProductImage => 'Change image';

  @override
  String get pricePerKiloChooseWeight =>
      'Price per kilo, choose the weight when adding';

  @override
  String get productDescription => 'Description';

  @override
  String get addToCartButton => 'Add to cart';

  @override
  String get productCurrentlyUnavailable => 'Currently unavailable';

  @override
  String get productDetailsInCart => 'In cart';

  @override
  String get imageLinkCopied => 'Image link copied';

  @override
  String get copyImageLink => 'Copy image link';

  @override
  String get similarProducts => 'Similar products';

  @override
  String get searchInSafeer => 'Search Safeer';

  @override
  String get searchProductHint => 'Search for a product, e.g. milk, cheese...';

  @override
  String get clearSearch => 'Clear';

  @override
  String get barcodeScanUnsupported =>
      'Barcode scanning isn\'t supported on this device';

  @override
  String get searchFailedCheckConnection =>
      'Search failed, check your connection';

  @override
  String get scanAnotherProduct => 'Scan another product';

  @override
  String noProductWithBarcode(String barcode) {
    return 'No product with barcode “$barcode”';
  }

  @override
  String get productMayBeUnavailable =>
      'The product may be currently unavailable';

  @override
  String get scanAgain => 'Scan again';

  @override
  String noSearchResultsFor(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchTryAnotherWord => 'Try another word or check the spelling';

  @override
  String searchResultsCount(String count, String query) {
    return '$count results for “$query”';
  }

  @override
  String get popularSearches => 'Popular searches';

  @override
  String get searchIntroSubtitle =>
      'Search thousands of products and order in minutes';

  @override
  String get searchSuggestionMilk => 'Milk';

  @override
  String get searchSuggestionCheese => 'Cheese';

  @override
  String get searchSuggestionRice => 'Rice';

  @override
  String get searchSuggestionOil => 'Oil';

  @override
  String get searchSuggestionSugar => 'Sugar';

  @override
  String get searchSuggestionTea => 'Tea';

  @override
  String get receiptTypeReceive => 'Receipt';

  @override
  String get receiptTypeSupplierReturn => 'Return';

  @override
  String get warehouseGoodsReceiptTitle => 'Receive goods';

  @override
  String get warehouseGoodsReturnTitle => 'Return goods';

  @override
  String get warehouseReceiptSaved => 'Receipt order saved';

  @override
  String get warehouseReturnSaved => 'Return order saved';

  @override
  String get warehouseSubmitReceipt => 'Submit receipt order';

  @override
  String get warehouseSubmitReturn => 'Submit return order';

  @override
  String get warehouseInvoiceDate => 'Invoice date';

  @override
  String get warehouseScanOrEnterBarcode => 'Scan or type the barcode';

  @override
  String get warehouseEnterQuantityAboveZero =>
      'Enter a quantity greater than zero';

  @override
  String get warehouseCompleteRequiredFields =>
      'Complete the required fields first';

  @override
  String get warehouseNoItemsYet => 'No items added yet';

  @override
  String get warehouseDocumentDetails => 'Document details';

  @override
  String get warehouseInvoiceNumberRequiredLabel => 'Invoice number *';

  @override
  String get warehouseInvoiceDateRequiredLabel => 'Invoice date *';

  @override
  String get warehouseInvoiceDateRequired => 'Invoice date is required';

  @override
  String get warehouseItems => 'Items';

  @override
  String get warehouseBarcode => 'Barcode';

  @override
  String get warehouseQuantity => 'Quantity';

  @override
  String get warehouseAdd => 'Add';

  @override
  String get warehouseReloadSuppliers => 'Reload suppliers';

  @override
  String get warehouseSupplierRequiredLabel => 'Supplier *';

  @override
  String get warehouseSupplierHint => 'Search or type the supplier number';

  @override
  String get warehouseSuppliersEmpty => 'The supplier list is empty';

  @override
  String get warehouseSelectSupplier => 'Select the supplier';

  @override
  String get warehouseSelectSupplierFromList =>
      'Select the supplier from the list';

  @override
  String get warehouseFetchingProductName => 'Fetching product name…';

  @override
  String get warehouseUnregisteredProduct => 'Unregistered product';

  @override
  String warehouseQuantityValue(String quantity) {
    return 'Quantity: $quantity';
  }

  @override
  String get warehouseSelectDate => 'Select a date';

  @override
  String get warehouseClearDate => 'Clear date';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return 'Could not load suppliers: $error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return 'Could not save the document: $error';
  }

  @override
  String get warehouseOrderAlreadyUpdated =>
      'Could not update the order, it may have already been updated';

  @override
  String get warehouseSignOutConfirm =>
      'Do you want to sign out of the warehouse account?';

  @override
  String get warehouseDashboardTitle => 'Warehouse dashboard';

  @override
  String get warehouseNewOrdersTab => 'New orders';

  @override
  String get warehousePreparingTab => 'Preparing';

  @override
  String get warehouseItemInquiry => 'Item lookup';

  @override
  String warehouseItemInquiryFailed(String error) {
    return 'Could not look up the item\n$error';
  }

  @override
  String get warehouseItemNotRegistered =>
      'This item is not registered in the database';

  @override
  String warehouseBarcodeValue(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return 'Available quantity: $quantity';
  }

  @override
  String get warehouseNoNewOrders => 'No new orders\nPull to refresh';

  @override
  String get warehouseNoPreparingOrders => 'No orders being prepared';

  @override
  String warehousePreparingStarted(String id) {
    return 'Started preparing order #$id, find it under \"Preparing\"';
  }

  @override
  String warehouseOrderReady(String id) {
    return 'Order #$id is ready, delivery drivers have been notified';
  }

  @override
  String warehouseProductsCount(String count) {
    return 'Products ($count)';
  }

  @override
  String warehouseCustomerValue(String name) {
    return 'Customer: $name';
  }

  @override
  String warehouseAddressValue(String address) {
    return 'Address: $address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return 'Total: $amount';
  }

  @override
  String get driverNewOrderAvailable =>
      'A new order is available for delivery!';

  @override
  String driverLocationSharingStartFailed(String error) {
    return 'Could not start sharing your location: $error';
  }

  @override
  String get driverSignOutConfirm =>
      'Do you want to sign out of the driver account?';

  @override
  String get driverDashboardTitle => 'Driver dashboard';

  @override
  String get driverAvailableOrdersTab => 'Available orders';

  @override
  String get driverNoAvailableOrders =>
      'No orders available right now\nPull to refresh';

  @override
  String get driverNoActiveDeliveries => 'No orders out for delivery';

  @override
  String driverOrderAccepted(String id) {
    return 'Order #$id accepted, find it under \"My orders\"';
  }

  @override
  String driverOrderDelivered(String id) {
    return 'Order #$id delivered';
  }

  @override
  String get driverPhoneLabel => 'Phone';

  @override
  String get driverAddressLabel => 'Address';

  @override
  String get driverDistanceLabel => 'Distance';

  @override
  String get driverDistanceNotSpecified => 'Not specified';

  @override
  String driverDistanceFromBranch(String distance) {
    return '$distance from the branch';
  }

  @override
  String get driverTotalToCollect => 'Total (to collect)';

  @override
  String get driverViewMapAndLocation => 'View map and location';

  @override
  String get driverAcceptOrder => 'Accept order';

  @override
  String get driverBroadcastingLocation => 'Sharing location...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return 'Sharing location... last sent $time';
  }

  @override
  String get driverRequestingLocationPermission =>
      'Requesting location permission...';

  @override
  String get driverStartLocationSharing => 'Start sharing location';

  @override
  String driverCopyLabel(String label) {
    return 'Copy $label';
  }

  @override
  String driverCopiedLabel(String label) {
    return '$label copied';
  }

  @override
  String driverLocationReadFailed(String error) {
    return 'Could not read your location: $error';
  }

  @override
  String get driverLocationSharingStopped =>
      'Location sharing stopped, tap \"Start sharing location\" to continue';

  @override
  String get driverOrderTakenByAnother =>
      'Sorry, another driver has already accepted this order';

  @override
  String driverAcceptOrderFailed(String error) {
    return 'Could not accept the order: $error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return 'Could not send your location to the customer: $error (code: $code)';
  }

  @override
  String get driverLocationSendNotAssigned =>
      'Could not send your location to the customer: the order isn\'t assigned to you or is no longer out for delivery';

  @override
  String get driverGpsDisabled =>
      'Location services (GPS) are off, turn them on so the customer can track you';

  @override
  String get driverLocationPermissionDeniedForever =>
      'Location permission is denied, enable it in the app settings so the customer can track you';

  @override
  String get driverLocationPermissionDenied =>
      'Location access was not allowed, the customer won\'t be able to track the order';

  @override
  String get driverOpenGoogleMapsFailed =>
      'Could not open Google Maps on this device';

  @override
  String get driverMapAndLocationTitle => 'Map and location';

  @override
  String get driverStartNavigation => 'Start navigation';

  @override
  String get listSeparator => ', ';

  @override
  String get storeCityName => 'Nasr City';

  @override
  String get addressDefaultTitle => 'Address';

  @override
  String get addressLabelOther => 'Other';

  @override
  String addressBuildingLine(String building) {
    return 'Building $building';
  }

  @override
  String addressFloorAptLine(String floor) {
    return 'Floor/Apt $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return 'Landmark: $landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return 'Could not save the address: $error';
  }

  @override
  String get addressLocationSaveFailed => 'Could not save the address location';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return 'Could not save the address location: $error';
  }

  @override
  String get locationServiceDisabled =>
      'Location services (GPS) are off. Turn them on and try again';

  @override
  String get locationPermissionDenied =>
      'Location access wasn\'t allowed. You can move the map manually';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission is denied. Enable it in the app settings';

  @override
  String get currentLocationUnavailable =>
      'Could not find your current location, please try again';

  @override
  String get mapAddressReadFailed => 'Could not read the address from the map';

  @override
  String get addressesEmptyTitle => 'No saved addresses yet';

  @override
  String get addressesEmptyHint =>
      'Add your address to get your orders delivered fast';

  @override
  String get addressesLoadFailed => 'Could not load addresses';

  @override
  String get signInToManageAddresses => 'Sign in to manage your addresses';

  @override
  String get addressDeleteTitle => 'Delete address';

  @override
  String addressDeleteConfirm(String title) {
    return 'Delete the address “$title”?';
  }

  @override
  String get addressDeleteFailed => 'Could not delete the address';

  @override
  String addressSaved(String title) {
    return 'Address “$title” saved';
  }

  @override
  String get addressPickerTitle => 'Choose a delivery address';

  @override
  String get addressPickerEmpty => 'No saved addresses. Add your first address';

  @override
  String get addressDetailsTitle => 'Address details';

  @override
  String get addressTitleLabel => 'Address name';

  @override
  String get addressTitleHint => 'e.g. Home, Work';

  @override
  String get addressAreaLabel => 'Area';

  @override
  String get addressAreaHint => 'e.g. Nasr City, 6th District';

  @override
  String get addressStreetLabel => 'Street';

  @override
  String get addressBuildingNumberLabel => 'Building no.';

  @override
  String get addressFloorAptLabel => 'Floor / Apt';

  @override
  String get addressLandmarkLabel => 'Landmark';

  @override
  String get addressLandmarkHint => 'e.g. Next to a mosque...';

  @override
  String get addressSaveButton => 'Save address';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label (optional)';
  }

  @override
  String get addressFieldRequired => 'This field is required';

  @override
  String get addressReviewAndComplete =>
      'Review the address and fill in the remaining details.';

  @override
  String get mapAddressReadFailedFillManually =>
      'Could not read the address from the map. Please fill in the details manually.';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return '$distance from the branch · Delivery $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return 'This location is $distance away, outside the delivery range (up to $maxDistance).';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return '$distance away, outside the delivery range';
  }

  @override
  String get mapPinHint =>
      'Move the map to place the pin exactly on the delivery spot';

  @override
  String get mapMyCurrentLocation => 'My current location';

  @override
  String get mapConfirmLocation => 'Confirm location';

  @override
  String get mapSetDeliveryLocation => 'Set delivery location';

  @override
  String get myOrdersLoadFailed => 'Could not load your orders';

  @override
  String get myOrdersEmptyTitle => 'No orders yet';

  @override
  String get myOrdersEmptySubtitle =>
      'Start shopping and your orders will show up here';

  @override
  String get orderStatusReceivedLong => 'Order received';

  @override
  String get orderStatusPreparingInWarehouse =>
      'Being prepared in the warehouse';

  @override
  String get orderStatusAwaitingDriver => 'Waiting for a delivery driver';

  @override
  String get orderStatusReadyShort => 'Ready';

  @override
  String get orderStepReceived => 'Received';

  @override
  String get orderStepPreparing => 'Preparing';

  @override
  String orderCardStatusLine(String status) {
    return 'Order status: $status';
  }

  @override
  String get orderCardTrackOnMap => 'Track order on the map';

  @override
  String trackingTitle(String id) {
    return 'Track order #$id';
  }

  @override
  String get trackingYourAddressMarker => 'Your address';

  @override
  String get trackingDriverMarker => 'Delivery driver';

  @override
  String get trackingOrderDelivered => 'Your order has been delivered. Enjoy!';

  @override
  String get trackingDriverLocationLive =>
      'The driver\'s location is updated live on the map';

  @override
  String get trackingDriverLocating =>
      'Locating the driver… they\'ll appear on the map shortly';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return 'Your account has been created! We sent a confirmation link to $email. Confirm your email, then sign in.';
  }

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authEnterFullName => 'Enter your full name';

  @override
  String get authEnterValidEmail => 'Enter a valid email address';

  @override
  String get authEnterValidEgyptianPhone =>
      'Enter a valid Egyptian phone number (11 digits)';

  @override
  String get authPassword => 'Password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account? ';

  @override
  String get authHaveAccountPrompt => 'Already have an account? ';

  @override
  String get authCreateNewAccountLink => 'Create a new account';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get authWelcomeBack => 'Welcome back!';

  @override
  String get authJoinSafeerMarket => 'Join Safeer Market';

  @override
  String get authSignInSubtitle => 'Sign in to complete your order';

  @override
  String get authSignUpSubtitle =>
      'Create your account and enjoy Safeer offers';

  @override
  String get authNewAccountTab => 'New account';

  @override
  String get authEmailAlreadyRegistered => 'This email is already registered';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return 'Your account was created, but your details could not be saved: $error';
  }

  @override
  String get authInvalidCredentials => 'Incorrect email or password';

  @override
  String get authEmailNotConfirmed =>
      'Please confirm your email first using the message we sent you';

  @override
  String get authWeakPassword =>
      'Password is too weak, use at least 6 characters';

  @override
  String get authTooManyAttempts =>
      'Too many attempts, please try again shortly';

  @override
  String get editProfileSignInPrompt => 'Sign in to edit your details';

  @override
  String get profileSavedSuccessfully => 'Your details were saved successfully';

  @override
  String get profileFullNameLabel => 'Full name';

  @override
  String get profileEnterFullName => 'Enter your full name';

  @override
  String get profileEnterValidPhone => 'Enter a valid Egyptian phone number';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String profileSaveFailed(String error) {
    return 'Could not save your details: $error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return 'Could not save the notification token: $error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature is coming soon';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => 'Games';

  @override
  String get rewardsGamesSubtitle => 'Play and collect loyalty points';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return 'Available again in $countdown';
  }

  @override
  String get scratchCardTitle => 'Scratch card — wipe & win';

  @override
  String get scratchCardSubtitle => 'Scratch the cover for instant points';

  @override
  String get scratchCardHint => 'Scratch the silver layer to reveal your prize';

  @override
  String scratchWonPoints(String points) {
    return 'You won $points points!';
  }

  @override
  String get scratchBetterLuck => 'Better luck next time';

  @override
  String get luckyChestTitle => 'Daily lucky chest — open yours';

  @override
  String get luckyChestSubtitle => 'Open the chest and win up to 10 points';

  @override
  String get luckyChestHint => 'Tap the chest to open it and reveal your prize';

  @override
  String get luckyChestTapToOpen => 'Tap to open the chest';

  @override
  String get luckyChestOpened => 'Chest already opened for today';

  @override
  String luckyChestWonPoints(String points) {
    return 'You won $points points from the chest!';
  }

  @override
  String get rewardsWheelCardSubtitle =>
      'Spin the wheel and win up to 100 points';

  @override
  String get rewardsPuzzleCardSubtitle => 'Rebuild the logo and win 50 points';

  @override
  String get loyaltyCurrentBalance => 'Your current balance';

  @override
  String get loyaltySignInToSeePoints => 'Sign in to see your points';

  @override
  String get loyaltyLoadFailedRetry => 'Couldn\'t load — Retry';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return 'Could not load loyalty points: $error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return 'Could not update loyalty points: $error';
  }

  @override
  String get wheelPrizeTryAgain => 'Try again';

  @override
  String get wheelSpinCollectLoyaltyPoints =>
      'Spin the wheel and collect loyalty points';

  @override
  String get wheelSignInToPlay => 'Sign in to play';

  @override
  String get wheelSpinning => 'Spinning...';

  @override
  String get wheelSpin => 'Spin the wheel';

  @override
  String get wheelCongrats => 'Congratulations!';

  @override
  String get wheelTryAgainTitle => 'Try again';

  @override
  String wheelWonPrize(String prize) {
    return 'You won $prize, added to your loyalty balance.';
  }

  @override
  String get wheelNoPointsThisTime =>
      'No points this time. Better luck on your next spin!';

  @override
  String puzzleMoves(String moves) {
    return 'Moves: $moves';
  }

  @override
  String puzzlePrize(String points) {
    return 'Prize: $points points';
  }

  @override
  String puzzleSavePoints(String points) {
    return 'Save $points points';
  }

  @override
  String get puzzleShuffle => 'Shuffle pieces';

  @override
  String get puzzleOutOfMoves =>
      'Better luck next time! You\'ve used up all your moves.';

  @override
  String get puzzleCongrats => 'Congratulations!';

  @override
  String puzzleEarnedPoints(String points) {
    return 'You earned $points points 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance =>
      'The points were added to your loyalty balance.';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return 'Congratulations! You earned $points points 🎉';
  }

  @override
  String get puzzleSignInToAddPoints =>
      'Sign in so we can add them to your balance.';

  @override
  String get puzzleGoalTitle => 'Rebuild the logo';

  @override
  String get puzzleGoalDescription =>
      'Slide the pieces next to the empty space until the logo matches the picture';

  @override
  String get unitCarton => 'carton';

  @override
  String get unitBox => 'box';

  @override
  String get unitBag => 'bag';

  @override
  String get unitPack => 'pack';

  @override
  String get cartTitle => 'Shopping cart';

  @override
  String get clearCart => 'Empty cart';

  @override
  String cartSubtotalWithCount(String count) {
    return 'Subtotal ($count items)';
  }

  @override
  String get cartDeliveryFeeNextStep =>
      'Delivery fee is calculated in the next step';

  @override
  String get cartContinueOrder => 'Continue to checkout';

  @override
  String get cartEmptySubtitle =>
      'Add your favorite products and start shopping';

  @override
  String get cartSaveDeliveryFeesTitle => 'Save on delivery fees! 💡';

  @override
  String get cartPrimeUpsellSubtitle =>
      'Subscribe to Safeer Prime for only EGP 90.';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return 'Added $weight of $product to the cart';
  }

  @override
  String cartAddedProduct(String product) {
    return 'Added $product to the cart';
  }

  @override
  String get viewCart => 'View cart';

  @override
  String get removeFromCart => 'Remove from cart';

  @override
  String get chooseWeight => 'Choose weight';

  @override
  String pricePerKilo(String price) {
    return '$price per kilo';
  }

  @override
  String get weightPickerPrice => 'Price';

  @override
  String get updateWeight => 'Update weight';

  @override
  String get homeNotificationsTooltip => 'Notifications';

  @override
  String get homeSearchHint => 'Search for a product or brand';

  @override
  String homeDeliveringTo(String city) {
    return 'Delivering to · $city';
  }

  @override
  String get homeChooseYourAddress => 'Choose your address';

  @override
  String get homeMyAccountTooltip => 'My account';

  @override
  String get homeSignedInSuccessfully => 'Signed in successfully';

  @override
  String get homeDeliveryEta => 'Delivery in 30 - 45 minutes';

  @override
  String get quickActionLatestProducts => 'Latest products';

  @override
  String get quickActionOffers => 'Offers';

  @override
  String get quickActionPlayAndWin => 'Play & Win';

  @override
  String get promoEndlessOffersTitle => 'Safeer offers never end';

  @override
  String get promoEndlessOffersSubtitle =>
      'Daily discounts on hundreds of products';

  @override
  String get promoSavingsStoreTitle => 'Safeer... the savings store';

  @override
  String get promoSavingsStoreSubtitle =>
      'Lower prices every day for the whole home';

  @override
  String get promoOpeningDiscountsTitle => 'Opening discounts';

  @override
  String get promoOpeningDiscountsSubtitle => 'Up to 30% off your first order';

  @override
  String get promoFreeDeliveryTitle => 'Free delivery';

  @override
  String get promoFreeDeliverySubtitle => 'On orders over EGP 300';

  @override
  String offerDiscountPercent(String percent) {
    return '$percent% off';
  }

  @override
  String get offerBadge => 'Offer';

  @override
  String get favoritesSignInPrompt => 'Sign in to save your favorite products';

  @override
  String get favoritesLoadFailed => 'Could not load favorites';

  @override
  String get favoritesEmptyTitle => 'No favorite products yet';

  @override
  String get favoritesEmptySubtitle => 'Tap ♡ on any product to save it here';

  @override
  String get favoritesUpdateFailed =>
      'Could not update favorites, please try again';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get magazinesLoadFailed => 'Could not load magazines';

  @override
  String get noMagazinesCurrently => 'No magazines right now';

  @override
  String get magazineNoPdf => 'This magazine has no PDF file';

  @override
  String get magazineOpenFailed =>
      'Could not open the magazine. Please try again later.';

  @override
  String get magazinePreviousPage => 'Previous page';

  @override
  String get magazineNextPage => 'Next page';

  @override
  String magazinePageOf(String page, String count) {
    return 'Page $page of $count';
  }

  @override
  String get authWelcomeTitle => 'Welcome to Safeer Market';

  @override
  String get authWelcomeSubtitle => 'Sign in or create an account in seconds';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithPhone => 'Continue with phone number';

  @override
  String get authContinueWithEmail => 'Continue with email';

  @override
  String get authOr => 'or';

  @override
  String get authOtherSignInOptions => 'Other sign-in options';

  @override
  String get authTermsNotice =>
      'By continuing, you agree to our privacy policy and terms';

  @override
  String get authGoogleFailed =>
      'Could not sign in with Google, please try again';

  @override
  String get authProviderUnavailable =>
      'This sign-in method is not available right now';

  @override
  String get authOtpInvalid => 'The code is incorrect or has expired';

  @override
  String get authSmsSendFailed =>
      'Could not send the verification SMS, check the number and try again';

  @override
  String get authPhoneSheetTitle => 'Sign in with your phone';

  @override
  String get authPhoneSheetSubtitle =>
      'We will text you a 6-digit verification code';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authEnterCodeTitle => 'Enter the verification code';

  @override
  String authCodeSentTo(String phone) {
    return 'We sent the code by SMS to $phone';
  }

  @override
  String get authVerifyCode => 'Verify code';

  @override
  String get authEnterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get authResendCode => 'Resend code';

  @override
  String authResendCodeIn(String seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authChangeNumber => 'Change number';

  @override
  String get authCodeResent => 'A new code has been sent';

  @override
  String get productNoImageBadge => 'No image';

  @override
  String newProductsMissingImageCount(String count) {
    return 'New products (no image: $count)';
  }

  @override
  String missingImageCountBadge(String count) {
    return 'No image: $count';
  }

  @override
  String get productImageSaveBlocked =>
      'The photo was uploaded but not saved on the product: permission to edit products was denied. Check the admin permissions in Supabase.';

  @override
  String get authPhoneLoginDisabled =>
      'Phone sign-in is not available yet, please use Google or email';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingLanguageSubtitle =>
      'You can change it anytime in Settings';

  @override
  String get onboardingAppearanceTitle => 'Choose how the app looks';

  @override
  String get onboardingAppearanceSubtitle =>
      'Light, dark, or follow your device';

  @override
  String get onboardingAccountTitle => 'Sign in for the full experience';

  @override
  String get onboardingAccountSubtitle =>
      'Order, track your orders, and save your addresses and favorites';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSignInOrRegister => 'Sign in or create an account';

  @override
  String get onboardingBrowseFirst => 'Browse the app first';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get guestSignInTitle => 'Sign in to continue';

  @override
  String get guestCartMessage =>
      'Sign in or create an account to add products to your cart and place your order.';

  @override
  String get guestProfileMessage =>
      'Sign in to see your details, orders, addresses and favorites.';

  @override
  String get notNow => 'Not now';

  @override
  String get unitSet => 'set';

  @override
  String unitBoxOf(String count) {
    return 'Box of $count';
  }

  @override
  String get paywallSignInToSubscribe =>
      'Sign in to subscribe to a Safeer plan';

  @override
  String get paymentChooseMethod => 'Choose a payment method';

  @override
  String get paymentMethodCard => 'Bank card (Visa / Mastercard / Meeza)';

  @override
  String get paymentMethodWallet => 'Mobile wallet (Vodafone Cash and others)';

  @override
  String get paymentWalletPhoneLabel => 'Wallet number';

  @override
  String get paymentWalletPhoneInvalid =>
      'Enter a valid wallet number starting with 01';

  @override
  String get paymentContinue => 'Continue';

  @override
  String get paymentStartFailed =>
      'Couldn\'t start the payment. Please try again.';

  @override
  String get paymentMethodUnavailable =>
      'This payment method isn\'t available right now';

  @override
  String get paymentPageOpenFailed => 'Couldn\'t open the payment page';

  @override
  String get paymentVerifying => 'Verifying your payment…';

  @override
  String get paymentFailedMessage =>
      'Payment was not completed or the card was declined by the bank. Please try again.';

  @override
  String get paymentStillProcessing =>
      'Payment confirmation is not complete yet. You can check your order status in My Orders.';

  @override
  String get subscriptionActivatedTitle =>
      'Subscription Activated Successfully 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return 'Your $plan plan is active until $date';
  }

  @override
  String get subscriptionContinueShopping => 'Continue shopping';

  @override
  String get redeemPoints => 'Redeem points';

  @override
  String get redeemQrTitle => 'Show this code to the cashier';

  @override
  String get redeemQrSubtitle =>
      'Every 50 points = EGP 1 off. This closes by itself once the discount is applied.';

  @override
  String get redeemSuccess => 'Discount applied successfully';

  @override
  String get scanCustomerCode => 'Scan customer code';

  @override
  String get scanCustomerHint => 'Point the camera at the customer\'s code';

  @override
  String get scanInvalidCode => 'This isn\'t a Safeer Market customer code';

  @override
  String scanCameraFailed(String error) {
    return 'Couldn\'t start the camera: $error';
  }

  @override
  String get redeemInsufficientPoints => 'Not enough points for EGP 1 off';

  @override
  String get redeemNotAllowed => 'This account isn\'t allowed to redeem points';

  @override
  String get redeemCustomerNotFound => 'Customer not found';

  @override
  String redeemFailed(String error) {
    return 'Couldn\'t redeem the points: $error';
  }

  @override
  String get cashierRedeemTitle => 'Redeem loyalty points';

  @override
  String get cashierCustomer => 'Customer';

  @override
  String get cashierCurrentBalance => 'Current balance';

  @override
  String get cashierPointsToDeduct => 'Points to deduct';

  @override
  String get cashierDiscount => 'Discount';

  @override
  String get cashierRemainingPoints => 'Balance after';

  @override
  String get cashierBarcodeHint =>
      'Scan this barcode at the till, then confirm';

  @override
  String get confirmPointsDeduction => 'Confirm points deduction';

  @override
  String cashierRedeemDone(String points, String amount) {
    return '$points points redeemed ($amount off)';
  }

  @override
  String get phoneOrdersTitle => 'Phone orders / Customer lookup';

  @override
  String get phoneOrderOpen => 'Phone order';

  @override
  String get phoneOrderSearchHint =>
      'Search by phone number or customer name...';

  @override
  String get phoneOrderNewCustomer => '+ New customer';

  @override
  String get phoneOrderTypeToSearch =>
      'Type a phone number or a name to search';

  @override
  String get phoneOrderNoCustomers =>
      'No matching customer. Add them as a new customer.';

  @override
  String get phoneOrderAppCustomer => 'App user';

  @override
  String get phoneOrderPosCustomer => 'POS customer';

  @override
  String get phoneOrderNoAddress => 'No saved address';

  @override
  String get phoneOrderChangeCustomer => 'Change customer';

  @override
  String get phoneOrderCustomerName => 'Customer name';

  @override
  String get phoneOrderCustomerPhone => 'Phone number';

  @override
  String get phoneOrderCustomerAddress => 'Address';

  @override
  String get phoneOrderCustomerZone => 'Zone';

  @override
  String get phoneOrderSaveCustomer => 'Save customer';

  @override
  String get phoneOrderNameRequired => 'Enter the customer\'s name';

  @override
  String get phoneOrderPhoneInvalid =>
      'Enter a valid Egyptian mobile number (01XXXXXXXXX)';

  @override
  String get phoneOrderProductSearchHint =>
      'Search by product name or barcode...';

  @override
  String get phoneOrderSearchProductsPrompt =>
      'Search for a product by name or barcode';

  @override
  String get phoneOrderNoProducts => 'No matching products';

  @override
  String get phoneOrderCartTitle => 'Customer\'s cart';

  @override
  String get phoneOrderCartEmpty => 'No products added yet';

  @override
  String get phoneOrderItemsTotal => 'Items total';

  @override
  String get phoneOrderTotal => 'Total';

  @override
  String get phoneOrderFreeDelivery => 'Free';

  @override
  String get phoneOrderConfirm => 'Confirm and place order';

  @override
  String phoneOrderPlaced(String id) {
    return 'Order #$id placed';
  }

  @override
  String phoneOrderFailed(String error) {
    return 'Couldn\'t place the order: $error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String get phoneOrderNotAllowed =>
      'This account isn\'t allowed to take phone orders';

  @override
  String get phoneOrderBadge => 'Phone';

  @override
  String phoneOrderSetupMissing(String function) {
    return 'The database function $function is missing. Run supabase/migrations/20261111010000_phone_orders.sql in the Supabase SQL Editor.';
  }

  @override
  String get adminToggleMenu => 'Show/hide menu';

  @override
  String get adminResizeColumn => 'Drag to resize the column';

  @override
  String get phoneOrderShowCart => 'Show cart and delivery';

  @override
  String get phoneOrderHideCart => 'Hide cart';

  @override
  String get driverDeliveryAddress => 'Delivery address';

  @override
  String get driverNavigateViaMap => 'Navigate via Map';

  @override
  String get mapSearchHint => 'Search for an area or street...';

  @override
  String get mapSearchNoResults => 'No places found';

  @override
  String mapSearchFailed(String error) {
    return 'Couldn\'t search for the place: $error';
  }

  @override
  String get mapSearchClear => 'Clear search';

  @override
  String get supportLiveChatSubtitle =>
      'Write to us in the app and our team will reply right away';

  @override
  String get supportSignInMessage =>
      'Sign in to start a chat with customer service.';

  @override
  String supportLaunchFailed(String phone) {
    return 'Couldn\'t open the app. You can call us on $phone';
  }

  @override
  String get supportChatTitle => 'Customer service';

  @override
  String get supportChatSubtitle => 'The Safeer Market team replies here';

  @override
  String get supportChatWelcome =>
      'Welcome! Write your question or problem and our customer service team will reply as soon as possible.';

  @override
  String get supportMessageHint => 'Write your message...';

  @override
  String supportLoadFailed(String error) {
    return 'Couldn\'t load the chat: $error';
  }

  @override
  String get supportSetupMissing =>
      'Live chat isn\'t set up yet. Run supabase/migrations/20261114210000_support_chat.sql in the Supabase SQL Editor.';

  @override
  String get supportNotAllowed => 'You don\'t have access to this chat';

  @override
  String supportRequestFailed(String error) {
    return 'Couldn\'t complete the request: $error';
  }

  @override
  String get supportCenterTitle => 'Complaints & chats';

  @override
  String get supportNoChats => 'No open chats right now';

  @override
  String get supportSelectChat =>
      'Pick a chat from the list to reply to the customer';

  @override
  String get supportNoMessagesYet => 'No messages in this chat yet';

  @override
  String get supportReplyHint => 'Write your reply to the customer...';

  @override
  String get supportLatestOrders => 'Latest orders';

  @override
  String supportLatestOrdersTitle(String name) {
    return '$name\'s latest orders';
  }

  @override
  String get supportNoOrders => 'This customer has no orders';

  @override
  String supportNewMessageToast(String name, String message) {
    return 'New message from $name: $message';
  }

  @override
  String get supportOpenChat => 'Open chat';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptySubtitle =>
      'We\'ll let you know as soon as new offers or magazines are available from Safeer Market';

  @override
  String notificationsLoadFailed(String error) {
    return 'Couldn\'t load notifications: $error';
  }

  @override
  String get notificationsSetupMissing =>
      'Notifications aren\'t set up yet. Run supabase/migrations/20261114220000_app_notifications.sql in the Supabase SQL Editor.';

  @override
  String get notificationsNotAllowed =>
      'Only the admin account can send and delete notifications';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'Yesterday',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => 'General';

  @override
  String get notificationTypePromo => 'Offers & discounts';

  @override
  String get notificationTypeMagazine => 'New magazine';

  @override
  String get notificationTypeOrder => 'Your orders';

  @override
  String get notificationTypeSupportChat => 'Customer support';

  @override
  String get adminSendNotifications => 'Send notifications';

  @override
  String get adminNotificationFormSubtitle =>
      'Shows up right away in every customer\'s app';

  @override
  String get adminNotificationTitleLabel => 'Notification title';

  @override
  String get adminNotificationTitleHint =>
      'e.g. This month\'s offers magazine is out! 🔥';

  @override
  String get adminNotificationTitleRequired => 'Enter the notification title';

  @override
  String get adminNotificationBodyLabel => 'Notification text';

  @override
  String get adminNotificationBodyHint =>
      'e.g. Browse the latest exclusive offers and discounts at Safeer Market';

  @override
  String get adminNotificationBodyRequired => 'Enter the notification text';

  @override
  String get adminNotificationTypeLabel => 'Notification type';

  @override
  String get adminNotificationImageLabel => 'Offer image link - optional';

  @override
  String get adminNotificationImageInvalid =>
      'Enter a valid link starting with https://';

  @override
  String get adminSendNotificationButton => 'Send to all customers';

  @override
  String get adminNotificationSent => 'Notification sent to all customers';

  @override
  String adminNotificationSendFailed(String error) {
    return 'Couldn\'t send the notification: $error';
  }

  @override
  String get adminNotificationsHistory => 'Sent notifications';

  @override
  String get adminNoNotificationsSent => 'No notifications sent yet';

  @override
  String get adminDeleteNotificationTitle => 'Delete notification';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return 'Delete the notification \"$title\"? It will disappear from customers\' apps.';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return 'Couldn\'t delete the notification: $error';
  }

  @override
  String get orderCardShowDetails => 'Show details';

  @override
  String get orderCardHideDetails => 'Hide details';

  @override
  String get orderCardItemsTitle => 'Order items';

  @override
  String get orderCardItemsFailed => 'Couldn\'t load the order items';

  @override
  String get orderCardNoItems => 'No items recorded for this order';

  @override
  String get orderCardCancelledNote => 'This order was cancelled';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirmTitle =>
      'Are you sure you want to cancel the order?';

  @override
  String get cancelOrderReasonPrompt => 'Choose a cancellation reason:';

  @override
  String get cancelOrderDismiss => 'Go back';

  @override
  String get cancelOrderConfirm => 'Confirm cancellation';

  @override
  String get cancelReasonDeliveryDelay => 'Delay in delivery';

  @override
  String get cancelReasonOrderedByMistake => 'Ordered by mistake';

  @override
  String get cancelReasonChangedMind => 'Changed my mind';

  @override
  String get cancelReasonOther => 'Other reason';

  @override
  String cancellationReasonLine(String reason) {
    return 'Cancellation reason: $reason';
  }

  @override
  String get orderCancelledSuccess => 'Order cancelled successfully';

  @override
  String get orderCancelTooLate =>
      'This order can no longer be cancelled because it\'s ready or already out for delivery';

  @override
  String get orderCancelSetupMissing =>
      'Order cancellation isn\'t set up yet. Run supabase/migrations/20261114240000_customer_cancel_order.sql in the Supabase SQL Editor.';

  @override
  String orderCancelFailed(String error) {
    return 'Couldn\'t cancel the order: $error';
  }

  @override
  String get adminMenuReceiveOrders => 'Receive orders';

  @override
  String get adminMenuOrderStatus => 'Order status';

  @override
  String get adminStatusDelayedShort => 'Delayed';

  @override
  String get adminStatusCancelledShort => 'Cancelled';

  @override
  String get adminResendNotification => 'Resend';

  @override
  String get adminResendFillForm => 'Fill the form';

  @override
  String get adminResendNotificationTitle => 'Resend this notification?';

  @override
  String adminResendNotificationConfirm(String title) {
    return 'The notification \"$title\" will be sent to every customer again.';
  }

  @override
  String get adminNotificationSearchHint => 'Search by title';

  @override
  String get adminNotificationFilterByDate => 'Filter by date';

  @override
  String get adminNotificationFilterByType => 'Filter by type';

  @override
  String get adminNotificationClearDateFilter => 'Clear date filter';

  @override
  String get adminSelectCustomerFirst => 'Select a customer to start the order';
}
