// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get bannerShopBrandProducts => 'Beli produk jenama ini';

  @override
  String get bannerAdd => 'Tambah sepanduk syarikat';

  @override
  String get bannerTitleLabel => 'Nama syarikat / tajuk sepanduk';

  @override
  String get bannerKeywordLabel => 'Kata kunci produk syarikat';

  @override
  String get bannerKeywordHint => 'cth. Juhayna';

  @override
  String get bannerChooseImage => 'Pilih imej sepanduk';

  @override
  String get bannerChangeImage => 'Tukar imej';

  @override
  String get bannerImageRequired => 'Pilih imej sepanduk dahulu';

  @override
  String get bannerKeywordRequired =>
      'Masukkan kata kunci yang membuka produk syarikat';

  @override
  String get bannerSaved => 'Sepanduk berjaya ditambah';

  @override
  String bannerSaveFailed(String error) {
    return 'Sepanduk tidak dapat disimpan: $error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return 'Padam sepanduk \"$title\"?';
  }

  @override
  String get bannerExistingHeader => 'Sepanduk semasa';

  @override
  String get appTitle => 'Safeer Market';

  @override
  String get home => 'Laman Utama';

  @override
  String get settings => 'Tetapan';

  @override
  String get language => 'Bahasa';

  @override
  String get save => 'Simpan';

  @override
  String get search => 'Cari';

  @override
  String get cart => 'Troli';

  @override
  String get wallet => 'Dompet';

  @override
  String get more => 'Lagi';

  @override
  String get exitHint => 'Tekan kembali sekali lagi untuk keluar dari aplikasi';

  @override
  String get newProducts => 'Produk baharu';

  @override
  String get trendingOffers => 'Tawaran popular';

  @override
  String get noNewNotifications => 'Tiada pemberitahuan baharu';

  @override
  String get loadingLatestProducts => 'Memuatkan produk terbaharu...';

  @override
  String get noNewProductsLast3Days =>
      'Tiada produk baharu dalam 3 hari terakhir';

  @override
  String get loadingOffers => 'Memuatkan tawaran...';

  @override
  String get noOffersCurrently => 'Tiada tawaran buat masa ini';

  @override
  String get subscribersExclusiveFeature => 'Ciri eksklusif untuk pelanggan 👑';

  @override
  String get playAndWinPaywallBody =>
      'Permainan Main & Menang serta hadiah mingguan hanya untuk pelanggan Safeer Prime dan Safeer Pro. Naik taraf akaun anda dan nikmati keistimewaannya!';

  @override
  String get upgradeAccountNow => 'Naik taraf sekarang';

  @override
  String get exploreSafeer => 'Teroka Safeer';

  @override
  String get featuredProducts => 'Produk pilihan';

  @override
  String get failedToLoadProducts => 'Tidak dapat memuatkan produk';

  @override
  String get noProductsCurrently => 'Tiada produk buat masa ini';

  @override
  String get seeAll => 'Lihat semua';

  @override
  String get retry => 'Cuba lagi';

  @override
  String get loyaltyPoints => 'Mata kesetiaan';

  @override
  String get spinWheelCollectPoints => 'Putar roda dan kumpul mata';

  @override
  String get favoriteProducts => 'Produk kegemaran';

  @override
  String get myOrders => 'Pesanan saya';

  @override
  String get contactUs => 'Hubungi kami';

  @override
  String get help => 'Bantuan';

  @override
  String get signOut => 'Log keluar';

  @override
  String get signIn => 'Log masuk';

  @override
  String get signOutConfirmMessage =>
      'Adakah anda mahu log keluar daripada akaun anda?';

  @override
  String get signedOut => 'Anda telah log keluar';

  @override
  String get adminDashboard => 'Papan pemuka pentadbir';

  @override
  String get adminDashboardSubtitle =>
      'Urus pesanan pelanggan dan kemas kini statusnya';

  @override
  String get guestName => 'Tetamu';

  @override
  String welcomeUser(String name) {
    return 'Selamat datang, $name';
  }

  @override
  String get guestSubtitle =>
      'Log masuk untuk menjejaki pesanan dan kegemaran anda';

  @override
  String get personalData => 'Data peribadi';

  @override
  String get email => 'E-mel';

  @override
  String get savedAddresses => 'Alamat tersimpan';

  @override
  String get savedCards => 'Kad tersimpan';

  @override
  String get messageAndSmsAlerts => 'Makluman mesej dan SMS';

  @override
  String get privacyAndTerms => 'Dasar privasi dan terma';

  @override
  String get deleteAccount => 'Padam akaun';

  @override
  String get deleteAccountConfirmMessage =>
      'Akaun dan semua data anda akan dipadam secara kekal. Adakah anda pasti?';

  @override
  String get deleteAccountSuccess => 'Akaun anda berjaya dipadam';

  @override
  String get passwordRequirementsTitle => 'Kata laluan mesti mengandungi:';

  @override
  String get passwordRuleMinLength => 'Sekurang-kurangnya 8 aksara';

  @override
  String get passwordRuleUppercase => 'Sekurang-kurangnya 1 huruf besar';

  @override
  String get passwordRuleLowercase => 'Sekurang-kurangnya 1 huruf kecil';

  @override
  String get passwordRuleDigit => 'Sekurang-kurangnya 1 nombor';

  @override
  String get talkToUs => 'Berbual dengan kami';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportLiveChat => 'Sembang langsung dengan khidmat pelanggan';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count mata • Tebus';
  }

  @override
  String get loyaltyPointsEarnNow => 'Mata kesetiaan • Peroleh sekarang 🎁';

  @override
  String get ok => 'OK';

  @override
  String get noEmail => 'Tiada alamat e-mel';

  @override
  String get changeEmailContactSupport =>
      'Untuk menukar e-mel, sila hubungi sokongan';

  @override
  String get privacyPolicyBody =>
      'Di Safeer Market kami menghormati privasi anda. Kami menggunakan data anda seperti nama, nombor telefon dan alamat hanya untuk menghantar pesanan dan menambah baik perkhidmatan, dan kami tidak berkongsinya dengan pihak ketiga tanpa kebenaran anda.\n\nDengan menggunakan aplikasi, anda bersetuju dengan terma penggunaan, termasuk polisi pesanan, penghantaran dan pemulangan. Polisi penuh akan diterbitkan tidak lama lagi.';

  @override
  String get helpTitle => 'Bagaimana kami boleh membantu?';

  @override
  String get helpBody =>
      'Pasukan Safeer Market sentiasa bersedia membantu.\nJika anda menghadapi masalah dengan pesanan atau mempunyai soalan, hubungi kami dan kami akan membalas secepat mungkin.';

  @override
  String get callUs => 'Hubungi kami';

  @override
  String get callUsSubtitle => 'Bercakap terus dengan khidmat pelanggan';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whatsappSubtitle =>
      'Hantar mesej dan kami akan membalas dengan pantas';

  @override
  String get messageAlerts => 'Makluman mesej';

  @override
  String get appNotifications => 'Pemberitahuan aplikasi';

  @override
  String get appNotificationsSubtitle =>
      'Tawaran dan kemas kini status pesanan';

  @override
  String get smsMessages => 'Mesej SMS';

  @override
  String get smsMessagesSubtitle =>
      'Mesej teks untuk pengesahan pesanan dan penghantaran';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Padam';

  @override
  String get close => 'Tutup';

  @override
  String get refresh => 'Muat semula';

  @override
  String get all => 'Semua';

  @override
  String get shopNow => 'Beli sekarang';

  @override
  String get scanBarcode => 'Imbas kod bar';

  @override
  String get phoneNumber => 'Nombor telefon';

  @override
  String get categories => 'Kategori';

  @override
  String get magazines => 'Majalah';

  @override
  String get addMagazine => 'Tambah majalah';

  @override
  String get unexpectedError => 'Ralat tidak dijangka berlaku';

  @override
  String get networkError => 'Tidak dapat menyambung ke rangkaian';

  @override
  String get serverError => 'Ralat pelayan berlaku';

  @override
  String get serverConnectionError =>
      'Tidak dapat menghubungi pelayan, sila cuba lagi';

  @override
  String get pleaseSignInFirst => 'Sila log masuk dahulu';

  @override
  String get noPermissionToEditOrder =>
      'Anda tiada kebenaran untuk mengedit pesanan ini';

  @override
  String orderUpdateFailed(String error) {
    return 'Tidak dapat mengemas kini pesanan: $error';
  }

  @override
  String ordersLoadFailed(String error) {
    return 'Tidak dapat memuatkan pesanan\n$error';
  }

  @override
  String orderNumber(String id) {
    return 'Pesanan #$id';
  }

  @override
  String get deletedProduct => 'Produk dipadam';

  @override
  String get product => 'Produk';

  @override
  String get addNewAddress => 'Tambah alamat baharu';

  @override
  String get manageAddresses => 'Urus alamat';

  @override
  String get editLocation => 'Edit lokasi';

  @override
  String helloName(String name) {
    return 'Hai, $name';
  }

  @override
  String get cardNumber => 'Nombor kad';

  @override
  String get cardholderName => 'Nama pemegang kad';

  @override
  String get asWrittenOnCard => 'Seperti tertera pada kad';

  @override
  String get expiryDate => 'Tarikh luput';

  @override
  String get addBankCard => 'Tambah kad bank';

  @override
  String get bankCard => 'Kad bank';

  @override
  String get adminPaidByVisa => 'Dibayar dengan Visa';

  @override
  String get cameraOpenFailed =>
      'Tidak dapat membuka kamera, semak kebenaran kamera';

  @override
  String get addressLabelHome => 'Rumah';

  @override
  String get addressLabelWork => 'Tempat kerja';

  @override
  String get puzzleGame => 'Permainan teka-teki';

  @override
  String get luckyWheel => 'Roda tuah';

  @override
  String get awesome => 'Hebat!';

  @override
  String get customer => 'Pelanggan';

  @override
  String get noLocationForOrder => 'Tiada lokasi tersedia untuk pesanan ini';

  @override
  String get branch => 'Cawangan';

  @override
  String get safeerCustomer => 'Pelanggan Safeer';

  @override
  String get notSpecified => 'Tidak dinyatakan';

  @override
  String get cashOnDelivery => 'Tunai semasa penghantaran';

  @override
  String get orderStatusPending => 'Menunggu';

  @override
  String get orderStatusPreparing => 'Sedang disediakan';

  @override
  String get orderStatusReadyForDelivery => 'Sedia untuk dihantar';

  @override
  String get orderStatusOutForDelivery => 'Dalam perjalanan';

  @override
  String get orderStatusDelivered => 'Telah dihantar';

  @override
  String get orderStatusCancelled => 'Dibatalkan';

  @override
  String get statusNew => 'Baharu';

  @override
  String get startPreparing => 'Mula menyediakan';

  @override
  String get total => 'Jumlah';

  @override
  String get inStock => 'Ada stok';

  @override
  String get outOfStock => 'Kehabisan stok';

  @override
  String get decreaseQuantity => 'Kurangkan kuantiti';

  @override
  String get increaseQuantity => 'Tambah kuantiti';

  @override
  String get decreaseWeight => 'Kurangkan berat';

  @override
  String get increaseWeight => 'Tambah berat';

  @override
  String get addToCart => 'Tambah ke troli';

  @override
  String get cartEmpty => 'Troli anda kosong';

  @override
  String get productUnavailableNow => 'Produk ini tidak tersedia buat masa ini';

  @override
  String distanceFromBranch(String distance) {
    return '$distance dari cawangan';
  }

  @override
  String get invoiceNumberRequired => 'Nombor invois diperlukan';

  @override
  String get addAtLeastOneItem => 'Tambah sekurang-kurangnya satu item';

  @override
  String get orderOnTheWayToYou => 'Pesanan anda dalam perjalanan!';

  @override
  String get deliveryFee => 'Caj penghantaran';

  @override
  String get currencySymbol => 'EGP';

  @override
  String get unitPiece => 'biji';

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
  String get sessionExpired => 'Sesi anda telah tamat, sila log masuk semula';

  @override
  String adminStatusUpdateFailed(String error) {
    return 'Tidak dapat mengemas kini status: $error';
  }

  @override
  String get adminDeleteMagazineTitle => 'Padam majalah';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return 'Padam “$title”?';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return 'Tidak dapat memadam majalah: $error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return 'Ralat: $error';
  }

  @override
  String get adminNoMagazinesYet =>
      'Belum ada majalah. Ketik “Tambah majalah” untuk memuat naik yang pertama.';

  @override
  String get adminMagazineExpired => 'Tamat tempoh';

  @override
  String get adminMagazineUpcoming => 'Akan datang';

  @override
  String get adminMagazineActive => 'Aktif';

  @override
  String adminMagazineDateRange(String start, String end) {
    return 'Dari $start hingga $end';
  }

  @override
  String get adminPickMagazinePdfTitle => 'Pilih fail majalah (PDF)';

  @override
  String get adminMagazineStartDate => 'Tarikh mula';

  @override
  String get adminMagazineEndDate => 'Tarikh tamat';

  @override
  String get adminMagazineTitleRequired => 'Masukkan tajuk majalah';

  @override
  String get adminMagazineCoverRequired => 'Pilih imej kulit';

  @override
  String get adminMagazinePdfRequired => 'Pilih fail PDF untuk majalah';

  @override
  String get adminMagazineEndBeforeStart =>
      'Tarikh tamat mestilah selepas tarikh mula';

  @override
  String get adminMagazineAdded => 'Majalah berjaya ditambah';

  @override
  String adminMagazineSaveFailed(String error) {
    return 'Tidak dapat menyimpan majalah: $error';
  }

  @override
  String get adminAddNewMagazine => 'Tambah majalah baharu';

  @override
  String get adminMagazineTitleLabel => 'Tajuk majalah';

  @override
  String get adminPickCoverImage => 'Pilih imej kulit';

  @override
  String get adminChangeCover => 'Tukar kulit';

  @override
  String get adminPickPdfFile => 'Pilih fail PDF';

  @override
  String get adminUploading => 'Memuat naik...';

  @override
  String get adminSupervisorPermissions => 'Akses penyelia';

  @override
  String get adminEnterPinHint => 'Masukkan PIN (1234)';

  @override
  String get adminSupervisorModeEnabled => 'Mod penyelia diaktifkan';

  @override
  String get adminInvalidPin => 'PIN salah';

  @override
  String get adminActivate => 'Aktifkan';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - Pentadbir';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - Ruang kerja';
  }

  @override
  String get adminCloseManagement => 'Kunci pentadbir';

  @override
  String get adminEnableManagement => 'Buka kunci pentadbir';

  @override
  String get adminExitToStore => 'Kembali ke kedai';

  @override
  String get adminMenuOrders => 'Pesanan';

  @override
  String get adminMenuProducts => 'Produk';

  @override
  String get adminMenuStaff => 'Kakitangan';

  @override
  String get adminMenuReports => 'Laporan & log harian';

  @override
  String get adminStatusPreparingShort => 'Penyediaan';

  @override
  String get adminStatusReadyForDriverShort => 'Untuk pemandu';

  @override
  String get adminStatusDeliveryShort => 'Penghantaran';

  @override
  String get adminStatusCompletedShort => 'Selesai';

  @override
  String get adminStatusUnknown => 'Tidak diketahui';

  @override
  String get adminNoOrders => 'Tiada pesanan';

  @override
  String get adminSelectOrderFromList => 'Pilih pesanan daripada senarai';

  @override
  String get adminItemsToPrepare => 'Item untuk disediakan:';

  @override
  String get adminNoItemsInOrder => 'Tiada item direkodkan';

  @override
  String get adminAvailableActions => 'Tindakan tersedia';

  @override
  String get adminOrderAwaitingPreparer => 'Pesanan menunggu penyedia';

  @override
  String adminPreparerName(String name) {
    return 'Penyedia: $name';
  }

  @override
  String get adminAwaitingDriverAssignment =>
      'Menunggu penyelia menetapkan pemandu';

  @override
  String get adminPickUpAndStartRoute => 'Ambil dan mulakan perjalanan 🗺️';

  @override
  String adminDriverName(String name) {
    return 'Pemandu: $name';
  }

  @override
  String get adminOrderReadyAwaitingDriver =>
      'Pesanan berjaya disediakan. Menunggu pemandu mengambilnya.';

  @override
  String get adminMarkDelivered => 'Berjaya dihantar 💵';

  @override
  String get adminCloseOrderPermanently => 'Tutup pesanan secara kekal';

  @override
  String get adminOrderWithDriverOnTheWay =>
      'Pesanan kini bersama pemandu dalam perjalanan ke pelanggan.';

  @override
  String get adminOrderDeliveredAndClosed =>
      'Pesanan ini telah berjaya dihantar dan ditutup.';

  @override
  String get adminWhoAreYouPickName =>
      'Siapa anda? (Pilih nama anda untuk bermula)';

  @override
  String get adminNoPreparers => 'Tiada penyedia tersedia';

  @override
  String get adminFinishOrderPreparation => 'Selesaikan penyediaan pesanan';

  @override
  String get adminCheckAllItemsFirst =>
      '⚠️ Maaf, anda mesti menandakan semua item dahulu.';

  @override
  String get adminPreparationFinished => 'Penyediaan berjaya diselesaikan.';

  @override
  String get adminAssignDriverTitle => 'Tetapkan pemandu (penyelia sahaja)';

  @override
  String get adminSelectDriver => 'Pilih pemandu';

  @override
  String get adminOrderAssignedToDriver =>
      'Pesanan telah ditetapkan kepada pemandu';

  @override
  String get adminAssignToSelectedDriver => 'Tetapkan kepada pemandu dipilih';

  @override
  String get adminCallFailed => 'Tidak dapat membuat panggilan';

  @override
  String get adminNoPhoneNumber => 'Tiada nombor';

  @override
  String get adminNoName => 'Tiada nama';

  @override
  String get adminAddressNotSet => 'Tidak dinyatakan';

  @override
  String get adminCustomerInfo => 'Butiran pelanggan';

  @override
  String get adminManageProducts => 'Urus produk';

  @override
  String get adminActiveProducts => 'Produk aktif';

  @override
  String get adminInactiveProducts => 'Tidak aktif';

  @override
  String get adminSearchProductByName => 'Cari produk mengikut nama...';

  @override
  String adminErrorOccurred(String error) {
    return 'Ralat berlaku: $error';
  }

  @override
  String get adminNoProducts => 'Tiada produk';

  @override
  String get adminCopyProductName => 'Salin nama produk';

  @override
  String get adminCopied => 'Disalin';

  @override
  String get adminCopyBarcode => 'Salin kod bar';

  @override
  String adminBarcodeValue(String barcode) {
    return 'Kod bar: $barcode';
  }

  @override
  String get adminUpdateErrorOccurred => 'Ralat berlaku semasa mengemas kini';

  @override
  String get adminManageStaff => 'Urus kakitangan';

  @override
  String get adminAddEmployee => 'Tambah pekerja';

  @override
  String get adminNoStaff => 'Tiada kakitangan berdaftar';

  @override
  String get adminRoleTaker => 'Penerima pesanan';

  @override
  String get adminRolePreparer => 'Penyedia';

  @override
  String get adminRoleDriver => 'Pemandu';

  @override
  String get adminNoPhone => 'Tiada telefon';

  @override
  String get adminReportsTitle => 'Laporan & log harian gabungan';

  @override
  String get adminTotalSalesCollected => 'Jumlah jualan (dikutip)';

  @override
  String get adminDeliveredOrdersTitle => 'Pesanan selesai & dihantar';

  @override
  String get adminOrdersInPreparationTitle => 'Pesanan sedang disediakan';

  @override
  String get adminCancelledOrdersTitle => 'Pesanan dibatalkan';

  @override
  String get adminTotalOrdersCumulative => 'Jumlah pesanan (kumulatif)';

  @override
  String adminOrdersCount(String count) {
    return '$count pesanan';
  }

  @override
  String get adminRecentOrdersLog => 'Log pesanan terkini';

  @override
  String get adminOrderNumberColumn => 'No. pesanan';

  @override
  String get adminCustomerNameColumn => 'Nama pelanggan';

  @override
  String get adminStatusColumn => 'Status';

  @override
  String get paymentMethodCashLabel => 'Tunai semasa penghantaran';

  @override
  String get paymentMethodCardLabel => 'Kad bank (Visa/Mastercard)';

  @override
  String get paymentMethodInstaPayLabel => 'InstaPay';

  @override
  String get paymentMethodInstaPaySubtitle =>
      'Pemindahan segera melalui aplikasi InstaPay';

  @override
  String get instaPayOpenApp => 'Buka InstaPay untuk bayar sekarang';

  @override
  String get instaPayIpaLabel => 'Alamat pembayaran segera (IPA)';

  @override
  String get instaPayPhoneLabel => 'Atau pindahan melalui nombor telefon';

  @override
  String get instaPayCopy => 'Salin';

  @override
  String get instaPayCopied => 'Disalin';

  @override
  String get instaPayConfirmHint =>
      'Selepas memindahkan jumlah pesanan melalui InstaPay, ketik Sahkan pesanan di bawah.';

  @override
  String get instaPayReceiptTitle => 'Resit pindahan bank (tangkapan skrin)';

  @override
  String get instaPayReceiptHint =>
      'Lampirkan tangkapan skrin pindahan InstaPay yang berjaya untuk mengesahkan pesanan';

  @override
  String get instaPayReceiptPick => 'Pilih imej resit atau ambil gambar';

  @override
  String get instaPayReceiptRequired =>
      'Sila lampirkan imej resit pindahan dahulu';

  @override
  String get adminViewTransferReceipt => 'Lihat resit pindahan';

  @override
  String get adminCopyReceiptImage => 'Salin imej';

  @override
  String get adminShareReceipt => 'Kongsi resit';

  @override
  String get adminReceiptImageCopied => 'Imej resit disalin';

  @override
  String get adminReceiptActionFailed => 'Tidak dapat memproses imej resit';

  @override
  String get subscriptionConfirmInstaPay => 'Sahkan langganan';

  @override
  String get subscriptionPendingSuccessTitle =>
      'Permintaan naik taraf diterima';

  @override
  String get subscriptionPendingSuccessBody =>
      'Permintaan naik taraf dan resit pembayaran anda telah diterima. Akaun Pro anda akan diaktifkan selepas semakan admin.';

  @override
  String get adminMenuPendingSubscriptions => 'Langganan menunggu';

  @override
  String get adminActivateAccount => 'Aktifkan akaun';

  @override
  String get adminSubscriptionApproved => 'Langganan diaktifkan';

  @override
  String get adminNoPendingSubscriptions =>
      'Tiada permintaan langganan menunggu';

  @override
  String get adminPendingSubscriptionTier => 'Pelan diminta';

  @override
  String get paymentCopyCardNumber => 'Salin nombor kad';

  @override
  String get paymentCardNumberCopied => 'Nombor kad disalin';

  @override
  String get checkoutAddressOutOfRange =>
      'Alamat berada di luar kawasan penghantaran';

  @override
  String get checkoutPinAddressFirst => 'Tandakan alamat pada peta dahulu';

  @override
  String checkoutOrderFailed(String error) {
    return 'Tidak dapat membuat pesanan: $error';
  }

  @override
  String get checkoutTitle => 'Pembayaran';

  @override
  String get checkoutDeliveryAddress => 'Alamat penghantaran';

  @override
  String get checkoutPaymentMethod => 'Kaedah pembayaran';

  @override
  String get checkoutOrderSummary => 'Ringkasan pesanan';

  @override
  String get checkoutSelectAddressFirst =>
      'Pilih alamat penghantaran dahulu untuk membuat pesanan';

  @override
  String get checkoutPinLocationForFee =>
      'Tandakan alamat pada peta untuk mengira caj penghantaran';

  @override
  String checkoutOrderPlaced(String id) {
    return 'Pesanan anda telah diterima • Pesanan #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return 'Maaf, alamat ini sejauh $distance, di luar kawasan penghantaran (sehingga $maxDistance)';
  }

  @override
  String get checkoutSignInToChooseAddress =>
      'Log masuk untuk memilih alamat penghantaran';

  @override
  String get checkoutPinThisAddressForFee =>
      'Tandakan alamat ini pada peta untuk mengira caj penghantaran';

  @override
  String get checkoutPinLocation => 'Tandakan lokasi';

  @override
  String get checkoutChangeAddress => 'Tukar';

  @override
  String get checkoutAddDeliveryAddress =>
      'Tambah alamat penghantaran untuk membuat pesanan';

  @override
  String get checkoutAddAddress => 'Tambah alamat';

  @override
  String get checkoutNoAddressChosen =>
      'Anda belum memilih alamat penghantaran';

  @override
  String get checkoutChooseAddress => 'Pilih alamat';

  @override
  String get checkoutEstimatedArrival => 'Anggaran ketibaan:';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return 'Caj penghantaran ($distance)';
  }

  @override
  String get checkoutOutOfDeliveryRange => 'Di luar kawasan penghantaran';

  @override
  String get checkoutItemCount => 'Bilangan item';

  @override
  String get checkoutSubtotal => 'Subjumlah';

  @override
  String get checkoutGrandTotal => 'Jumlah keseluruhan';

  @override
  String get checkoutConfirmOrder => 'Sahkan pesanan';

  @override
  String get paymentCardScanUnsupported =>
      'Pengimbasan kad tidak disokong pada peranti ini';

  @override
  String get paymentCardScanFailed =>
      'Kami tidak dapat membaca kad, sila masukkan butiran secara manual';

  @override
  String get paymentCardScanned =>
      'Kad diimbas, semak butiran dan masukkan CVV';

  @override
  String get paymentCardTitle => 'Pembayaran kad';

  @override
  String get paymentSecureNotice => 'Pembayaran selamat dan disulitkan';

  @override
  String paymentPayNow(String amount) {
    return 'Bayar sekarang • $amount';
  }

  @override
  String get paymentScanCardTooltip => 'Imbas kad dengan kamera';

  @override
  String get paymentAmountDue => 'Jumlah perlu dibayar';

  @override
  String get cardNumberRequired => 'Masukkan nombor kad';

  @override
  String get cardNumberInvalid => 'Nombor kad tidak sah';

  @override
  String get cardExpiryRequired => 'Masukkan tarikh dalam format MM/YY';

  @override
  String get cardExpiryInvalidMonth => 'Bulan tidak sah';

  @override
  String get cardExpired => 'Kad telah tamat tempoh';

  @override
  String get cardCvvInvalid => 'Kod tidak sah';

  @override
  String get cardHolderNameRequired => 'Masukkan nama seperti tertera pada kad';

  @override
  String get walletCardSaved => 'Kad berjaya disimpan';

  @override
  String get walletCardDataProtected =>
      'Data anda dilindungi dan kami tidak sesekali menyimpan CVV';

  @override
  String get walletSaveCard => 'Simpan kad';

  @override
  String get walletAddCardHint =>
      'Tambah kad anda untuk membayar dengan lebih pantas pada pesanan seterusnya';

  @override
  String get walletInAppBalance => 'Baki dompet dalam aplikasi anda';

  @override
  String get walletBalanceLoadFailed => 'Tidak dapat memuatkan baki';

  @override
  String get walletBalanceAutoApplied =>
      'Baki anda digunakan secara automatik semasa pembayaran';

  @override
  String get walletSignInToViewBalance => 'Log masuk untuk melihat baki anda';

  @override
  String walletCardExpires(String expiry) {
    return 'Luput $expiry';
  }

  @override
  String get walletDeleteCard => 'Padam kad';

  @override
  String get checkoutUseOrAddNewCard => '+ Guna atau tambah kad baharu';

  @override
  String get checkoutSavedCards => 'Kad tersimpan anda';

  @override
  String get paywallUpgradeAccount => 'Naik taraf akaun';

  @override
  String get paywallDiscoverSafeer => 'Terokai dunia Safeer 👑';

  @override
  String get paywallChoosePlan =>
      'Pilih pelan yang sesuai dengan keperluan anda dan jimat lebih pada setiap pesanan.';

  @override
  String get paywallProTitle => 'Safeer Pro (VIP)';

  @override
  String get paywallPerMonth => '/ bulan';

  @override
  String get paywallProUnlimitedFreeDelivery =>
      'Penghantaran percuma tanpa had 🚀';

  @override
  String get paywallProExpressDelivery =>
      'Penghantaran ekspres (penyediaan diutamakan)';

  @override
  String get paywallProWholesalePrices => 'Harga borong eksklusif 💰';

  @override
  String get paywallProNoMinimumOrder => 'Tiada pesanan minimum';

  @override
  String get paywallProUnlimitedGiveaways =>
      'Penyertaan tanpa had ke cabutan hadiah';

  @override
  String get paywallPrimeTitle => 'Safeer Prime';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders =>
      'Penghantaran percuma untuk 5 pesanan';

  @override
  String get paywallPrimeOffersPriority =>
      'Akses keutamaan kepada tawaran besar';

  @override
  String get paywallPrimeWeeklyPlayAndWin =>
      'Permainan Main & Menang mingguan 🎁';

  @override
  String get paywallFreeTitle => 'Akaun standard';

  @override
  String get paywallFreePrice => 'Percuma';

  @override
  String get paywallFreeStandardDelivery =>
      'Penghantaran biasa pada kos standard';

  @override
  String get paywallFreePublicAccess => 'Akses kepada produk dan tawaran umum';

  @override
  String get paywallBestSeller => 'Paling laris';

  @override
  String get paywallPaymentComingSoon =>
      'Pembayaran akan tersedia tidak lama lagi';

  @override
  String get paywallSubscribeNow => 'Langgan sekarang';

  @override
  String get catDairyEggs => 'Tenusu & Telur';

  @override
  String get subcatTetraPakCheese => 'Keju Tetra Pak, Segi Tiga & Cawan';

  @override
  String get subcatPackagedCheeseLabneh =>
      'Keju Berbungkus, Labneh, Krim & Minyak Sapi';

  @override
  String get subcatCheeseByWeight => 'Keju Mengikut Berat';

  @override
  String get subcatMozzarella => 'Keju Mozzarella';

  @override
  String get subcatYogurtRicePudding => 'Yogurt & Puding Nasi';

  @override
  String get subcatLongLifeDairy => 'Tenusu Tahan Lama';

  @override
  String get subcatPackagedButter => 'Mentega Berbungkus';

  @override
  String get subcatPackagedEggs => 'Telur Berbungkus';

  @override
  String get catSweetsSnacks => 'Manisan & Snek';

  @override
  String get subcatChocolate => 'Coklat';

  @override
  String get subcatBiscuits => 'Biskut';

  @override
  String get subcatSweets => 'Manisan';

  @override
  String get subcatChipsRoasted => 'Kerepek & Snek Panggang';

  @override
  String get subcatNutsByWeight => 'Snek & Kacang Mengikut Berat';

  @override
  String get subcatHalawaSpreads => 'Halwa & Sapuan';

  @override
  String get subcatRamadanYamish => 'Buah Kering & Kacang Ramadan';

  @override
  String get catDrinksJuices => 'Minuman & Jus';

  @override
  String get subcatWaterDrinksIceCream => 'Air, Minuman, Jus & Aiskrim';

  @override
  String get subcatDrinks => 'Minuman';

  @override
  String get subcatJuices => 'Jus';

  @override
  String get subcatPowderedJuices => 'Jus Serbuk';

  @override
  String get catMeatFrozen => 'Daging & Sejuk Beku';

  @override
  String get subcatFrozenPoultry => 'Ayam Sejuk Beku & Diproses';

  @override
  String get subcatFrozenMeat => 'Daging Sejuk Beku';

  @override
  String get subcatProcessedMeat => 'Daging Diproses';

  @override
  String get subcatFrozenFish => 'Ikan Sejuk Beku';

  @override
  String get subcatSmokedFish => 'Ikan Salai';

  @override
  String get subcatFrozenVegFruit => 'Sayur & Buah Sejuk Beku';

  @override
  String get subcatFrozenPastries => 'Pastri Sejuk Beku';

  @override
  String get catBakeryBreakfast => 'Roti & Sarapan';

  @override
  String get subcatBakery => 'Roti & Bakeri';

  @override
  String get subcatPatisserie => 'Pastri & Kek Snek';

  @override
  String get subcatCerealsOats => 'Kornflek, Muesli & Oat';

  @override
  String get catPastaRice => 'Pasta & Beras';

  @override
  String get subcatPasta => 'Pasta';

  @override
  String get subcatRice => 'Beras';

  @override
  String get subcatLegumesSpicesBreadcrumbs =>
      'Kekacang, Rempah & Serbuk Roti Berbungkus';

  @override
  String get subcatSoupsStocksMixes => 'Sup, Stok & Campuran Perasa';

  @override
  String get catPantryOils => 'Barangan Runcit & Minyak';

  @override
  String get subcatOils => 'Minyak';

  @override
  String get subcatGhee => 'Minyak Sapi';

  @override
  String get subcatSugarFlour => 'Gula & Tepung';

  @override
  String get subcatCannedFood => 'Makanan Dalam Tin';

  @override
  String get subcatCondiments => 'Perencah & Pembuka Selera';

  @override
  String get subcatOlivesPickles => 'Zaitun & Jeruk';

  @override
  String get subcatPackagedOlivesPickles => 'Zaitun & Jeruk Berbungkus';

  @override
  String get subcatSpicesByWeight => 'Rempah Mengikut Berat';

  @override
  String get subcatGrainsByWeight => 'Bijirin & Biji Mengikut Berat';

  @override
  String get subcatBakingSupplies => 'Bahan & Serbuk Membuat Kek';

  @override
  String get subcatSaladsByWeight => 'Salad Mengikut Berat';

  @override
  String get catCleaningCare => 'Pembersihan & Rumah Tangga';

  @override
  String get subcatDetergentsSofteners => 'Detergen & Pelembut Fabrik';

  @override
  String get subcatLiquidSoapStainRemovers =>
      'Sabun Cecair & Penanggal Kotoran';

  @override
  String get subcatBleachDisinfectants => 'Peluntur & Pembasmi Kuman';

  @override
  String get subcatPolishes => 'Pengilat';

  @override
  String get subcatInsecticidesFresheners => 'Racun Serangga & Penyegar Udara';

  @override
  String get subcatTissuesToiletPaper => 'Tisu & Kertas Tandas';

  @override
  String get subcatSteelWoolScrubbers => 'Span Besi & Penyental';

  @override
  String get subcatSpongesSteelWool => 'Span & Span Besi';

  @override
  String get subcatDrainCleaners => 'Pembersih Longkang';

  @override
  String get subcatIncense => 'Kemenyan';

  @override
  String get catPersonalCare => 'Penjagaan Diri';

  @override
  String get subcatShampooConditioner => 'Syampu & Perapi';

  @override
  String get subcatShowerGelHandWash => 'Gel Mandian & Pencuci Tangan';

  @override
  String get subcatSoap => 'Sabun';

  @override
  String get subcatPerfumesDeodorants => 'Minyak Wangi & Deodoran';

  @override
  String get subcatCreamsSerums => 'Krim & Serum';

  @override
  String get subcatOralCare => 'Penjagaan Mulut';

  @override
  String get subcatShavingSupplies => 'Kelengkapan Bercukur';

  @override
  String get subcatHairDyeHenna => 'Pewarna Rambut & Inai';

  @override
  String get subcatPersonalCareSupplies => 'Keperluan Penjagaan Diri';

  @override
  String get catBabyWorld => 'Dunia Bayi';

  @override
  String get subcatDiapersPads => 'Lampin & Tuala Wanita';

  @override
  String get subcatBabyFood => 'Makanan Bayi';

  @override
  String get subcatBabySupplies => 'Keperluan Bayi';

  @override
  String get catHomeSupplies => 'Keperluan Rumah';

  @override
  String get subcatHousewares => 'Peralatan Rumah';

  @override
  String get subcatElectricalTools => 'Alatan Elektrik';

  @override
  String get subcatElectricalSupplies => 'Bekalan Elektrik';

  @override
  String get subcatPlasticsBags => 'Plastik & Beg';

  @override
  String get subcatFoil => 'Kerajang';

  @override
  String get subcatHardware => 'Perkakasan & Barangan Kecil';

  @override
  String get subcatBatteries => 'Bateri';

  @override
  String get subcatMatchesLighters => 'Mancis & Pemetik Api';

  @override
  String get subcatPetSupplies => 'Keperluan Haiwan Peliharaan';

  @override
  String get subcatRamadanSupplies => 'Keperluan Ramadan';

  @override
  String get categoryTitle => 'Kategori';

  @override
  String get categoryNotFound => 'Kategori ini tidak wujud';

  @override
  String get categoryNoProductsNow =>
      'Tiada produk dalam kategori ini buat masa ini';

  @override
  String get shopFromHome => 'Beli dari laman utama';

  @override
  String categoryProductCount(String count) {
    return '$count produk';
  }

  @override
  String get loadMoreFailedRetry => 'Tidak dapat memuatkan lagi, cuba semula';

  @override
  String get categoriesDrawerTagline => 'Semua keperluan anda di satu tempat';

  @override
  String get productDetailsTitle => 'Butiran produk';

  @override
  String get productNotAvailable => 'Produk ini tidak tersedia';

  @override
  String get productLoadFailed => 'Tidak dapat memuatkan produk';

  @override
  String get productImageUpdated => 'Imej produk berjaya dikemas kini!';

  @override
  String productImageUploadFailed(String error) {
    return 'Muat naik gagal: $error';
  }

  @override
  String get updateProductImage => 'Kemas kini imej produk';

  @override
  String get takePhotoWithCamera => 'Ambil gambar';

  @override
  String get chooseFromGallery => 'Pilih dari galeri';

  @override
  String get changeProductImage => 'Tukar imej';

  @override
  String get pricePerKiloChooseWeight =>
      'Harga sekilo, pilih berat semasa menambah';

  @override
  String get productDescription => 'Penerangan';

  @override
  String get addToCartButton => 'Tambah ke troli';

  @override
  String get productCurrentlyUnavailable => 'Tidak tersedia buat masa ini';

  @override
  String get productDetailsInCart => 'Dalam troli';

  @override
  String get imageLinkCopied => 'Pautan imej disalin';

  @override
  String get copyImageLink => 'Salin pautan imej';

  @override
  String get similarProducts => 'Produk serupa';

  @override
  String get searchInSafeer => 'Cari di Safeer';

  @override
  String get searchProductHint => 'Cari produk, cth. susu, keju...';

  @override
  String get clearSearch => 'Kosongkan';

  @override
  String get barcodeScanUnsupported =>
      'Pengimbasan kod bar tidak disokong pada peranti ini';

  @override
  String get searchFailedCheckConnection =>
      'Carian gagal, semak sambungan anda';

  @override
  String get scanAnotherProduct => 'Imbas produk lain';

  @override
  String noProductWithBarcode(String barcode) {
    return 'Tiada produk dengan kod bar “$barcode”';
  }

  @override
  String get productMayBeUnavailable =>
      'Produk mungkin tidak tersedia buat masa ini';

  @override
  String get scanAgain => 'Imbas semula';

  @override
  String noSearchResultsFor(String query) {
    return 'Tiada hasil untuk “$query”';
  }

  @override
  String get searchTryAnotherWord => 'Cuba perkataan lain atau semak ejaan';

  @override
  String searchResultsCount(String count, String query) {
    return '$count hasil untuk “$query”';
  }

  @override
  String get popularSearches => 'Carian popular';

  @override
  String get searchIntroSubtitle =>
      'Cari beribu-ribu produk dan pesan dalam beberapa minit';

  @override
  String get searchSuggestionMilk => 'Susu';

  @override
  String get searchSuggestionCheese => 'Keju';

  @override
  String get searchSuggestionRice => 'Beras';

  @override
  String get searchSuggestionOil => 'Minyak';

  @override
  String get searchSuggestionSugar => 'Gula';

  @override
  String get searchSuggestionTea => 'Teh';

  @override
  String get receiptTypeReceive => 'Penerimaan';

  @override
  String get receiptTypeSupplierReturn => 'Pemulangan';

  @override
  String get warehouseGoodsReceiptTitle => 'Terima barang';

  @override
  String get warehouseGoodsReturnTitle => 'Pulangkan barang';

  @override
  String get warehouseReceiptSaved => 'Pesanan penerimaan disimpan';

  @override
  String get warehouseReturnSaved => 'Pesanan pemulangan disimpan';

  @override
  String get warehouseSubmitReceipt => 'Hantar pesanan penerimaan';

  @override
  String get warehouseSubmitReturn => 'Hantar pesanan pemulangan';

  @override
  String get warehouseInvoiceDate => 'Tarikh invois';

  @override
  String get warehouseScanOrEnterBarcode => 'Imbas atau taip kod bar';

  @override
  String get warehouseEnterQuantityAboveZero =>
      'Masukkan kuantiti lebih daripada sifar';

  @override
  String get warehouseCompleteRequiredFields => 'Lengkapkan medan wajib dahulu';

  @override
  String get warehouseNoItemsYet => 'Belum ada item ditambah';

  @override
  String get warehouseDocumentDetails => 'Butiran dokumen';

  @override
  String get warehouseInvoiceNumberRequiredLabel => 'Nombor invois *';

  @override
  String get warehouseInvoiceDateRequiredLabel => 'Tarikh invois *';

  @override
  String get warehouseInvoiceDateRequired => 'Tarikh invois diperlukan';

  @override
  String get warehouseItems => 'Item';

  @override
  String get warehouseBarcode => 'Kod bar';

  @override
  String get warehouseQuantity => 'Kuantiti';

  @override
  String get warehouseAdd => 'Tambah';

  @override
  String get warehouseReloadSuppliers => 'Muat semula pembekal';

  @override
  String get warehouseSupplierRequiredLabel => 'Pembekal *';

  @override
  String get warehouseSupplierHint => 'Cari atau taip nombor pembekal';

  @override
  String get warehouseSuppliersEmpty => 'Senarai pembekal kosong';

  @override
  String get warehouseSelectSupplier => 'Pilih pembekal';

  @override
  String get warehouseSelectSupplierFromList =>
      'Pilih pembekal daripada senarai';

  @override
  String get warehouseFetchingProductName => 'Mendapatkan nama produk…';

  @override
  String get warehouseUnregisteredProduct => 'Produk tidak berdaftar';

  @override
  String warehouseQuantityValue(String quantity) {
    return 'Kuantiti: $quantity';
  }

  @override
  String get warehouseSelectDate => 'Pilih tarikh';

  @override
  String get warehouseClearDate => 'Kosongkan tarikh';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return 'Tidak dapat memuatkan pembekal: $error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return 'Tidak dapat menyimpan dokumen: $error';
  }

  @override
  String get warehouseOrderAlreadyUpdated =>
      'Tidak dapat mengemas kini pesanan, mungkin ia telah dikemas kini';

  @override
  String get warehouseSignOutConfirm =>
      'Adakah anda mahu log keluar daripada akaun gudang?';

  @override
  String get warehouseDashboardTitle => 'Papan pemuka gudang';

  @override
  String get warehouseNewOrdersTab => 'Pesanan baharu';

  @override
  String get warehousePreparingTab => 'Sedang disediakan';

  @override
  String get warehouseItemInquiry => 'Semakan item';

  @override
  String warehouseItemInquiryFailed(String error) {
    return 'Tidak dapat menyemak item\n$error';
  }

  @override
  String get warehouseItemNotRegistered =>
      'Item ini tidak berdaftar dalam pangkalan data';

  @override
  String warehouseBarcodeValue(String barcode) {
    return 'Kod bar: $barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return 'Kuantiti tersedia: $quantity';
  }

  @override
  String get warehouseNoNewOrders =>
      'Tiada pesanan baharu\nTarik untuk muat semula';

  @override
  String get warehouseNoPreparingOrders => 'Tiada pesanan sedang disediakan';

  @override
  String warehousePreparingStarted(String id) {
    return 'Mula menyediakan pesanan #$id, cari di bawah “Sedang disediakan”';
  }

  @override
  String warehouseOrderReady(String id) {
    return 'Pesanan #$id sedia, pemandu penghantaran telah dimaklumkan';
  }

  @override
  String warehouseProductsCount(String count) {
    return 'Produk ($count)';
  }

  @override
  String warehouseCustomerValue(String name) {
    return 'Pelanggan: $name';
  }

  @override
  String warehouseAddressValue(String address) {
    return 'Alamat: $address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return 'Jumlah: $amount';
  }

  @override
  String get driverNewOrderAvailable =>
      'Pesanan baharu tersedia untuk dihantar!';

  @override
  String driverLocationSharingStartFailed(String error) {
    return 'Tidak dapat mula berkongsi lokasi anda: $error';
  }

  @override
  String get driverSignOutConfirm =>
      'Adakah anda mahu log keluar daripada akaun pemandu?';

  @override
  String get driverDashboardTitle => 'Papan pemuka pemandu';

  @override
  String get driverAvailableOrdersTab => 'Pesanan tersedia';

  @override
  String get driverNoAvailableOrders =>
      'Tiada pesanan tersedia sekarang\nTarik untuk muat semula';

  @override
  String get driverNoActiveDeliveries => 'Tiada pesanan dalam penghantaran';

  @override
  String driverOrderAccepted(String id) {
    return 'Pesanan #$id diterima, cari di bawah “Pesanan saya”';
  }

  @override
  String driverOrderDelivered(String id) {
    return 'Pesanan #$id telah dihantar';
  }

  @override
  String get driverPhoneLabel => 'Telefon';

  @override
  String get driverAddressLabel => 'Alamat';

  @override
  String get driverDistanceLabel => 'Jarak';

  @override
  String get driverDistanceNotSpecified => 'Tidak dinyatakan';

  @override
  String driverDistanceFromBranch(String distance) {
    return '$distance dari cawangan';
  }

  @override
  String get driverTotalToCollect => 'Jumlah (untuk dikutip)';

  @override
  String get driverViewMapAndLocation => 'Lihat peta dan lokasi';

  @override
  String get driverAcceptOrder => 'Terima pesanan';

  @override
  String get driverBroadcastingLocation => 'Berkongsi lokasi...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return 'Berkongsi lokasi... terakhir dihantar $time';
  }

  @override
  String get driverRequestingLocationPermission =>
      'Meminta kebenaran lokasi...';

  @override
  String get driverStartLocationSharing => 'Mula berkongsi lokasi';

  @override
  String driverCopyLabel(String label) {
    return 'Salin $label';
  }

  @override
  String driverCopiedLabel(String label) {
    return '$label disalin';
  }

  @override
  String driverLocationReadFailed(String error) {
    return 'Tidak dapat membaca lokasi anda: $error';
  }

  @override
  String get driverLocationSharingStopped =>
      'Perkongsian lokasi dihentikan, ketik “Mula berkongsi lokasi” untuk meneruskan';

  @override
  String get driverOrderTakenByAnother =>
      'Maaf, pemandu lain telah menerima pesanan ini';

  @override
  String driverAcceptOrderFailed(String error) {
    return 'Tidak dapat menerima pesanan: $error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return 'Tidak dapat menghantar lokasi anda kepada pelanggan: $error (kod: $code)';
  }

  @override
  String get driverLocationSendNotAssigned =>
      'Tidak dapat menghantar lokasi anda kepada pelanggan: pesanan tidak ditetapkan kepada anda atau tidak lagi dalam penghantaran';

  @override
  String get driverGpsDisabled =>
      'Perkhidmatan lokasi (GPS) dimatikan, hidupkannya supaya pelanggan dapat menjejaki anda';

  @override
  String get driverLocationPermissionDeniedForever =>
      'Kebenaran lokasi ditolak, dayakannya dalam tetapan aplikasi supaya pelanggan dapat menjejaki anda';

  @override
  String get driverLocationPermissionDenied =>
      'Akses lokasi tidak dibenarkan, pelanggan tidak akan dapat menjejaki pesanan';

  @override
  String get driverOpenGoogleMapsFailed =>
      'Tidak dapat membuka Google Maps pada peranti ini';

  @override
  String get driverMapAndLocationTitle => 'Peta dan lokasi';

  @override
  String get driverStartNavigation => 'Mula navigasi';

  @override
  String get listSeparator => ', ';

  @override
  String get storeCityName => 'Nasr City';

  @override
  String get addressDefaultTitle => 'Alamat';

  @override
  String get addressLabelOther => 'Lain-lain';

  @override
  String addressBuildingLine(String building) {
    return 'Bangunan $building';
  }

  @override
  String addressFloorAptLine(String floor) {
    return 'Tingkat/Unit $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return 'Mercu tanda: $landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return 'Tidak dapat menyimpan alamat: $error';
  }

  @override
  String get addressLocationSaveFailed => 'Tidak dapat menyimpan lokasi alamat';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return 'Tidak dapat menyimpan lokasi alamat: $error';
  }

  @override
  String get locationServiceDisabled =>
      'Perkhidmatan lokasi (GPS) dimatikan. Hidupkannya dan cuba lagi';

  @override
  String get locationPermissionDenied =>
      'Akses lokasi tidak dibenarkan. Anda boleh menggerakkan peta secara manual';

  @override
  String get locationPermissionDeniedForever =>
      'Kebenaran lokasi ditolak. Dayakannya dalam tetapan aplikasi';

  @override
  String get currentLocationUnavailable =>
      'Tidak dapat mengesan lokasi semasa anda, sila cuba lagi';

  @override
  String get mapAddressReadFailed => 'Tidak dapat membaca alamat daripada peta';

  @override
  String get addressesEmptyTitle => 'Belum ada alamat tersimpan';

  @override
  String get addressesEmptyHint =>
      'Tambah alamat anda supaya pesanan dihantar dengan pantas';

  @override
  String get addressesLoadFailed => 'Tidak dapat memuatkan alamat';

  @override
  String get signInToManageAddresses => 'Log masuk untuk mengurus alamat anda';

  @override
  String get addressDeleteTitle => 'Padam alamat';

  @override
  String addressDeleteConfirm(String title) {
    return 'Padam alamat “$title”?';
  }

  @override
  String get addressDeleteFailed => 'Tidak dapat memadam alamat';

  @override
  String addressSaved(String title) {
    return 'Alamat “$title” disimpan';
  }

  @override
  String get addressPickerTitle => 'Pilih alamat penghantaran';

  @override
  String get addressPickerEmpty =>
      'Tiada alamat tersimpan. Tambah alamat pertama anda';

  @override
  String get addressDetailsTitle => 'Butiran alamat';

  @override
  String get addressTitleLabel => 'Nama alamat';

  @override
  String get addressTitleHint => 'cth. Rumah, Tempat kerja';

  @override
  String get addressAreaLabel => 'Kawasan';

  @override
  String get addressAreaHint => 'cth. Nasr City, Daerah Ke-6';

  @override
  String get addressStreetLabel => 'Jalan';

  @override
  String get addressBuildingNumberLabel => 'No. bangunan';

  @override
  String get addressFloorAptLabel => 'Tingkat / Unit';

  @override
  String get addressLandmarkLabel => 'Mercu tanda';

  @override
  String get addressLandmarkHint => 'cth. Bersebelahan masjid...';

  @override
  String get addressSaveButton => 'Simpan alamat';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label (pilihan)';
  }

  @override
  String get addressFieldRequired => 'Medan ini wajib diisi';

  @override
  String get addressReviewAndComplete =>
      'Semak alamat dan isi butiran yang selebihnya.';

  @override
  String get mapAddressReadFailedFillManually =>
      'Tidak dapat membaca alamat daripada peta. Sila isi butiran secara manual.';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return '$distance dari cawangan · Penghantaran $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return 'Lokasi ini sejauh $distance, di luar kawasan penghantaran (sehingga $maxDistance).';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return 'Sejauh $distance, di luar kawasan penghantaran';
  }

  @override
  String get mapPinHint =>
      'Gerakkan peta untuk meletakkan pin tepat di lokasi penghantaran';

  @override
  String get mapMyCurrentLocation => 'Lokasi semasa saya';

  @override
  String get mapConfirmLocation => 'Sahkan lokasi';

  @override
  String get mapSetDeliveryLocation => 'Tetapkan lokasi penghantaran';

  @override
  String get myOrdersLoadFailed => 'Tidak dapat memuatkan pesanan anda';

  @override
  String get myOrdersEmptyTitle => 'Belum ada pesanan';

  @override
  String get myOrdersEmptySubtitle =>
      'Mula membeli-belah dan pesanan anda akan dipaparkan di sini';

  @override
  String get orderStatusReceivedLong => 'Pesanan diterima';

  @override
  String get orderStatusPreparingInWarehouse => 'Sedang disediakan di gudang';

  @override
  String get orderStatusAwaitingDriver => 'Menunggu pemandu penghantaran';

  @override
  String get orderStatusReadyShort => 'Sedia';

  @override
  String get orderStepReceived => 'Diterima';

  @override
  String get orderStepPreparing => 'Penyediaan';

  @override
  String orderCardStatusLine(String status) {
    return 'Status pesanan: $status';
  }

  @override
  String get orderCardTrackOnMap => 'Jejak pesanan pada peta';

  @override
  String trackingTitle(String id) {
    return 'Jejak pesanan #$id';
  }

  @override
  String get trackingYourAddressMarker => 'Alamat anda';

  @override
  String get trackingDriverMarker => 'Pemandu penghantaran';

  @override
  String get trackingOrderDelivered =>
      'Pesanan anda telah dihantar. Selamat menikmati!';

  @override
  String get trackingDriverLocationLive =>
      'Lokasi pemandu dikemas kini secara langsung pada peta';

  @override
  String get trackingDriverLocating =>
      'Mengesan pemandu… mereka akan muncul pada peta sebentar lagi';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return 'Akaun anda telah dicipta! Kami telah menghantar pautan pengesahan ke $email. Sahkan e-mel anda, kemudian log masuk.';
  }

  @override
  String get authFullNameLabel => 'Nama penuh';

  @override
  String get authEnterFullName => 'Masukkan nama penuh anda';

  @override
  String get authEnterValidEmail => 'Masukkan alamat e-mel yang sah';

  @override
  String get authEnterValidEgyptianPhone =>
      'Masukkan nombor telefon Mesir yang sah (11 digit)';

  @override
  String get authPassword => 'Kata laluan';

  @override
  String get authShowPassword => 'Tunjukkan kata laluan';

  @override
  String get authHidePassword => 'Sembunyikan kata laluan';

  @override
  String get authPasswordMinLength =>
      'Kata laluan mestilah sekurang-kurangnya 6 aksara';

  @override
  String get authSignInButton => 'Log masuk';

  @override
  String get authCreateAccountButton => 'Cipta akaun';

  @override
  String get authNoAccountPrompt => 'Belum ada akaun? ';

  @override
  String get authHaveAccountPrompt => 'Sudah ada akaun? ';

  @override
  String get authCreateNewAccountLink => 'Cipta akaun baharu';

  @override
  String get authSignInLink => 'Log masuk';

  @override
  String get authWelcomeBack => 'Selamat kembali!';

  @override
  String get authJoinSafeerMarket => 'Sertai Safeer Market';

  @override
  String get authSignInSubtitle => 'Log masuk untuk melengkapkan pesanan anda';

  @override
  String get authSignUpSubtitle =>
      'Cipta akaun anda dan nikmati tawaran Safeer';

  @override
  String get authNewAccountTab => 'Akaun baharu';

  @override
  String get authEmailAlreadyRegistered => 'E-mel ini sudah didaftarkan';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return 'Akaun anda telah dicipta, tetapi butiran anda tidak dapat disimpan: $error';
  }

  @override
  String get authInvalidCredentials => 'E-mel atau kata laluan salah';

  @override
  String get authEmailNotConfirmed =>
      'Sila sahkan e-mel anda dahulu melalui mesej yang kami hantar';

  @override
  String get authWeakPassword =>
      'Kata laluan terlalu lemah, gunakan sekurang-kurangnya 6 aksara';

  @override
  String get authTooManyAttempts =>
      'Terlalu banyak percubaan, sila cuba lagi sebentar nanti';

  @override
  String get editProfileSignInPrompt => 'Log masuk untuk mengedit butiran anda';

  @override
  String get profileSavedSuccessfully => 'Butiran anda berjaya disimpan';

  @override
  String get profileFullNameLabel => 'Nama penuh';

  @override
  String get profileEnterFullName => 'Masukkan nama penuh anda';

  @override
  String get profileEnterValidPhone => 'Masukkan nombor telefon Mesir yang sah';

  @override
  String get profileSaveChanges => 'Simpan perubahan';

  @override
  String profileSaveFailed(String error) {
    return 'Tidak dapat menyimpan butiran anda: $error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return 'Tidak dapat menyimpan token pemberitahuan: $error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature akan datang tidak lama lagi';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mata',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => 'Permainan';

  @override
  String get rewardsGamesSubtitle => 'Main dan kumpul mata kesetiaan';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return 'Boleh dimainkan semula dalam $countdown';
  }

  @override
  String get scratchCardTitle => 'Kad calar — calar & menang';

  @override
  String get scratchCardSubtitle => 'Calar lapisan untuk mata segera';

  @override
  String get scratchCardHint =>
      'Calar lapisan perak untuk dedahkan hadiah anda';

  @override
  String scratchWonPoints(String points) {
    return 'Anda menang $points mata!';
  }

  @override
  String get scratchBetterLuck => 'Cuba lagi lain kali';

  @override
  String get luckyChestTitle => 'Peti bertuah harian — buka peti anda';

  @override
  String get luckyChestSubtitle => 'Buka peti dan menang sehingga 10 mata';

  @override
  String get luckyChestHint =>
      'Ketik peti untuk membukanya dan dedahkan hadiah';

  @override
  String get luckyChestTapToOpen => 'Ketik untuk buka peti';

  @override
  String get luckyChestOpened => 'Peti hari ini sudah dibuka';

  @override
  String luckyChestWonPoints(String points) {
    return 'Anda menang $points mata dari peti!';
  }

  @override
  String get rewardsWheelCardSubtitle =>
      'Putar roda dan menangi sehingga 100 mata';

  @override
  String get rewardsPuzzleCardSubtitle =>
      'Susun semula logo dan menangi 50 mata';

  @override
  String get loyaltyCurrentBalance => 'Baki semasa anda';

  @override
  String get loyaltySignInToSeePoints => 'Log masuk untuk melihat mata anda';

  @override
  String get loyaltyLoadFailedRetry => 'Tidak dapat memuatkan — Cuba lagi';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return 'Tidak dapat memuatkan mata kesetiaan: $error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return 'Tidak dapat mengemas kini mata kesetiaan: $error';
  }

  @override
  String get wheelPrizeTryAgain => 'Cuba lagi';

  @override
  String get wheelSpinCollectLoyaltyPoints =>
      'Putar roda dan kumpul mata kesetiaan';

  @override
  String get wheelSignInToPlay => 'Log masuk untuk bermain';

  @override
  String get wheelSpinning => 'Sedang berputar...';

  @override
  String get wheelSpin => 'Putar roda';

  @override
  String get wheelCongrats => 'Tahniah!';

  @override
  String get wheelTryAgainTitle => 'Cuba lagi';

  @override
  String wheelWonPrize(String prize) {
    return 'Anda memenangi $prize, telah ditambah ke baki kesetiaan anda.';
  }

  @override
  String get wheelNoPointsThisTime =>
      'Tiada mata kali ini. Semoga bernasib baik pada putaran seterusnya!';

  @override
  String puzzleMoves(String moves) {
    return 'Langkah: $moves';
  }

  @override
  String puzzlePrize(String points) {
    return 'Hadiah: $points mata';
  }

  @override
  String puzzleSavePoints(String points) {
    return 'Simpan $points mata';
  }

  @override
  String get puzzleShuffle => 'Kocok kepingan';

  @override
  String get puzzleOutOfMoves =>
      'Semoga bernasib baik lain kali! Anda telah menggunakan semua pergerakan yang ada.';

  @override
  String get puzzleCongrats => 'Tahniah!';

  @override
  String puzzleEarnedPoints(String points) {
    return 'Anda memperoleh $points mata 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance =>
      'Mata telah ditambah ke baki kesetiaan anda.';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return 'Tahniah! Anda memperoleh $points mata 🎉';
  }

  @override
  String get puzzleSignInToAddPoints =>
      'Log masuk supaya kami boleh menambahkannya ke baki anda.';

  @override
  String get puzzleGoalTitle => 'Susun semula logo';

  @override
  String get puzzleGoalDescription =>
      'Gelongsorkan kepingan di sebelah ruang kosong sehingga logo sepadan dengan gambar';

  @override
  String get unitCarton => 'karton';

  @override
  String get unitBox => 'kotak';

  @override
  String get unitBag => 'beg';

  @override
  String get unitPack => 'pek';

  @override
  String get cartTitle => 'Troli beli-belah';

  @override
  String get clearCart => 'Kosongkan troli';

  @override
  String cartSubtotalWithCount(String count) {
    return 'Subjumlah ($count item)';
  }

  @override
  String get cartDeliveryFeeNextStep =>
      'Caj penghantaran dikira pada langkah seterusnya';

  @override
  String get cartContinueOrder => 'Teruskan ke pembayaran';

  @override
  String get cartEmptySubtitle =>
      'Tambah produk kegemaran anda dan mula membeli-belah';

  @override
  String get cartSaveDeliveryFeesTitle => 'Jimat caj penghantaran! 💡';

  @override
  String get cartPrimeUpsellSubtitle =>
      'Langgan Safeer Prime dengan hanya EGP 90.';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return '$weight $product ditambah ke troli';
  }

  @override
  String cartAddedProduct(String product) {
    return '$product ditambah ke troli';
  }

  @override
  String get viewCart => 'Lihat troli';

  @override
  String get removeFromCart => 'Keluarkan dari troli';

  @override
  String get chooseWeight => 'Pilih berat';

  @override
  String pricePerKilo(String price) {
    return '$price sekilo';
  }

  @override
  String get weightPickerPrice => 'Harga';

  @override
  String get updateWeight => 'Kemas kini berat';

  @override
  String get homeNotificationsTooltip => 'Pemberitahuan';

  @override
  String get homeSearchHint => 'Cari produk atau jenama';

  @override
  String homeDeliveringTo(String city) {
    return 'Hantar ke · $city';
  }

  @override
  String get homeChooseYourAddress => 'Pilih alamat anda';

  @override
  String get homeMyAccountTooltip => 'Akaun saya';

  @override
  String get homeSignedInSuccessfully => 'Berjaya log masuk';

  @override
  String get homeDeliveryEta => 'Penghantaran dalam 30 - 45 minit';

  @override
  String get quickActionLatestProducts => 'Produk terbaharu';

  @override
  String get quickActionOffers => 'Tawaran';

  @override
  String get quickActionPlayAndWin => 'Main & Menang';

  @override
  String get promoEndlessOffersTitle => 'Tawaran Safeer tiada penghujung';

  @override
  String get promoEndlessOffersSubtitle =>
      'Diskaun harian untuk ratusan produk';

  @override
  String get promoSavingsStoreTitle => 'Safeer... kedai penjimatan';

  @override
  String get promoSavingsStoreSubtitle =>
      'Harga lebih rendah setiap hari untuk seisi rumah';

  @override
  String get promoOpeningDiscountsTitle => 'Diskaun pembukaan';

  @override
  String get promoOpeningDiscountsSubtitle =>
      'Diskaun sehingga 30% untuk pesanan pertama anda';

  @override
  String get promoFreeDeliveryTitle => 'Penghantaran percuma';

  @override
  String get promoFreeDeliverySubtitle => 'Untuk pesanan melebihi EGP 300';

  @override
  String offerDiscountPercent(String percent) {
    return 'Diskaun $percent%';
  }

  @override
  String get offerBadge => 'Tawaran';

  @override
  String get favoritesSignInPrompt =>
      'Log masuk untuk menyimpan produk kegemaran anda';

  @override
  String get favoritesLoadFailed => 'Tidak dapat memuatkan kegemaran';

  @override
  String get favoritesEmptyTitle => 'Belum ada produk kegemaran';

  @override
  String get favoritesEmptySubtitle =>
      'Ketik ♡ pada mana-mana produk untuk menyimpannya di sini';

  @override
  String get favoritesUpdateFailed =>
      'Tidak dapat mengemas kini kegemaran, sila cuba lagi';

  @override
  String get removeFromFavorites => 'Buang daripada kegemaran';

  @override
  String get addToFavorites => 'Tambah ke kegemaran';

  @override
  String get magazinesLoadFailed => 'Tidak dapat memuatkan majalah';

  @override
  String get noMagazinesCurrently => 'Tiada majalah buat masa ini';

  @override
  String get magazineNoPdf => 'Majalah ini tiada fail PDF';

  @override
  String get magazineOpenFailed =>
      'Tidak dapat membuka majalah. Sila cuba lagi kemudian.';

  @override
  String get magazinePreviousPage => 'Halaman sebelumnya';

  @override
  String get magazineNextPage => 'Halaman seterusnya';

  @override
  String magazinePageOf(String page, String count) {
    return 'Halaman $page daripada $count';
  }

  @override
  String get authWelcomeTitle => 'Selamat datang ke Safeer Market';

  @override
  String get authWelcomeSubtitle =>
      'Log masuk atau cipta akaun dalam beberapa saat';

  @override
  String get authContinueWithGoogle => 'Teruskan dengan Google';

  @override
  String get authContinueWithPhone => 'Teruskan dengan nombor telefon';

  @override
  String get authContinueWithEmail => 'Teruskan dengan e-mel';

  @override
  String get authOr => 'atau';

  @override
  String get authOtherSignInOptions => 'Pilihan log masuk lain';

  @override
  String get authTermsNotice =>
      'Dengan meneruskan, anda bersetuju dengan dasar privasi dan terma kami';

  @override
  String get authGoogleFailed =>
      'Tidak dapat log masuk dengan Google, sila cuba lagi';

  @override
  String get authProviderUnavailable =>
      'Kaedah log masuk ini tidak tersedia buat masa ini';

  @override
  String get authOtpInvalid => 'Kod tidak betul atau telah tamat tempoh';

  @override
  String get authSmsSendFailed =>
      'Tidak dapat menghantar SMS pengesahan, semak nombor dan cuba lagi';

  @override
  String get authPhoneSheetTitle => 'Log masuk dengan telefon';

  @override
  String get authPhoneSheetSubtitle =>
      'Kami akan menghantar kod pengesahan 6 digit melalui SMS';

  @override
  String get authSendCode => 'Hantar kod';

  @override
  String get authEnterCodeTitle => 'Masukkan kod pengesahan';

  @override
  String authCodeSentTo(String phone) {
    return 'Kami telah menghantar kod melalui SMS ke $phone';
  }

  @override
  String get authVerifyCode => 'Sahkan kod';

  @override
  String get authEnterSixDigitCode => 'Masukkan kod 6 digit';

  @override
  String get authResendCode => 'Hantar semula kod';

  @override
  String authResendCodeIn(String seconds) {
    return 'Hantar semula dalam ${seconds}s';
  }

  @override
  String get authChangeNumber => 'Tukar nombor';

  @override
  String get authCodeResent => 'Kod baharu telah dihantar';

  @override
  String get productNoImageBadge => 'Tiada gambar';

  @override
  String newProductsMissingImageCount(String count) {
    return 'Produk baharu (tiada gambar: $count)';
  }

  @override
  String missingImageCountBadge(String count) {
    return 'Tiada gambar: $count';
  }

  @override
  String get productImageSaveBlocked =>
      'Gambar dimuat naik tetapi tidak disimpan pada produk: kebenaran untuk mengedit produk ditolak. Semak kebenaran pentadbir dalam Supabase.';

  @override
  String get authPhoneLoginDisabled =>
      'Log masuk dengan telefon belum tersedia, sila gunakan Google atau e-mel';

  @override
  String get onboardingLanguageTitle => 'Pilih bahasa anda';

  @override
  String get onboardingLanguageSubtitle =>
      'Anda boleh menukarnya bila-bila masa dalam Tetapan';

  @override
  String get onboardingAppearanceTitle => 'Pilih rupa aplikasi';

  @override
  String get onboardingAppearanceSubtitle =>
      'Cerah, gelap, atau ikut peranti anda';

  @override
  String get onboardingAccountTitle => 'Log masuk untuk pengalaman penuh';

  @override
  String get onboardingAccountSubtitle =>
      'Buat pesanan, jejak pesanan anda dan simpan alamat serta kegemaran';

  @override
  String get onboardingNext => 'Seterusnya';

  @override
  String get onboardingSignInOrRegister => 'Log masuk atau cipta akaun';

  @override
  String get onboardingBrowseFirst => 'Layari aplikasi dahulu';

  @override
  String get appearance => 'Penampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Cerah';

  @override
  String get settingsAccountSection => 'Akaun';

  @override
  String get guestSignInTitle => 'Log masuk untuk meneruskan';

  @override
  String get guestCartMessage =>
      'Log masuk atau cipta akaun untuk menambah produk ke troli dan membuat pesanan.';

  @override
  String get guestProfileMessage =>
      'Log masuk untuk melihat butiran, pesanan, alamat dan kegemaran anda.';

  @override
  String get notNow => 'Bukan sekarang';

  @override
  String get unitSet => 'set';

  @override
  String unitBoxOf(String count) {
    return 'Kotak $count';
  }

  @override
  String get paywallSignInToSubscribe =>
      'Log masuk untuk melanggan pelan Safeer';

  @override
  String get paymentChooseMethod => 'Pilih kaedah pembayaran';

  @override
  String get paymentMethodCard => 'Kad bank (Visa / Mastercard / Meeza)';

  @override
  String get paymentMethodWallet =>
      'Dompet mudah alih (Vodafone Cash dan lain-lain)';

  @override
  String get paymentWalletPhoneLabel => 'Nombor dompet';

  @override
  String get paymentWalletPhoneInvalid =>
      'Masukkan nombor dompet sah bermula dengan 01';

  @override
  String get paymentContinue => 'Teruskan';

  @override
  String get paymentStartFailed =>
      'Tidak dapat memulakan pembayaran. Sila cuba lagi.';

  @override
  String get paymentMethodUnavailable =>
      'Kaedah pembayaran ini tidak tersedia buat masa ini';

  @override
  String get paymentPageOpenFailed => 'Tidak dapat membuka halaman pembayaran';

  @override
  String get paymentVerifying => 'Mengesahkan pembayaran anda…';

  @override
  String get paymentFailedMessage =>
      'Pembayaran tidak berjaya. Anda boleh cuba lagi.';

  @override
  String get paymentStillProcessing =>
      'Pengesahan pembayaran belum selesai. Anda boleh semak status pesanan di Pesanan Saya.';

  @override
  String get subscriptionActivatedTitle => 'Langganan Berjaya Diaktifkan 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return 'Pelan $plan anda aktif sehingga $date';
  }

  @override
  String get subscriptionContinueShopping => 'Teruskan membeli-belah';

  @override
  String get redeemPoints => 'Tebus mata';

  @override
  String get redeemQrTitle => 'Tunjukkan kod ini kepada juruwang';

  @override
  String get redeemQrSubtitle =>
      'Setiap 50 mata = diskaun EGP 1. Kod ini tertutup sendiri selepas diskaun digunakan.';

  @override
  String get redeemSuccess => 'Diskaun berjaya digunakan';

  @override
  String get scanCustomerCode => 'Imbas kod pelanggan';

  @override
  String get scanCustomerHint => 'Halakan kamera ke kod pelanggan';

  @override
  String get scanInvalidCode => 'Ini bukan kod pelanggan Safeer Market';

  @override
  String scanCameraFailed(String error) {
    return 'Tidak dapat memulakan kamera: $error';
  }

  @override
  String get redeemInsufficientPoints => 'Mata tidak cukup untuk diskaun EGP 1';

  @override
  String get redeemNotAllowed => 'Akaun ini tidak dibenarkan menebus mata';

  @override
  String get redeemCustomerNotFound => 'Pelanggan tidak ditemui';

  @override
  String redeemFailed(String error) {
    return 'Tidak dapat menebus mata: $error';
  }

  @override
  String get cashierRedeemTitle => 'Tebus mata kesetiaan';

  @override
  String get cashierCustomer => 'Pelanggan';

  @override
  String get cashierCurrentBalance => 'Baki semasa';

  @override
  String get cashierPointsToDeduct => 'Mata ditolak';

  @override
  String get cashierDiscount => 'Diskaun';

  @override
  String get cashierRemainingPoints => 'Baki selepas';

  @override
  String get cashierBarcodeHint =>
      'Imbas kod bar ini di kaunter, kemudian sahkan';

  @override
  String get confirmPointsDeduction => 'Sahkan penolakan mata';

  @override
  String cashierRedeemDone(String points, String amount) {
    return '$points mata ditebus (diskaun $amount)';
  }

  @override
  String get phoneOrdersTitle => 'Pesanan telefon / Carian pelanggan';

  @override
  String get phoneOrderOpen => 'Pesanan telefon';

  @override
  String get phoneOrderSearchHint =>
      'Cari mengikut nombor telefon atau nama pelanggan...';

  @override
  String get phoneOrderNewCustomer => '+ Pelanggan baharu';

  @override
  String get phoneOrderTypeToSearch =>
      'Taip nombor telefon atau nama untuk mencari';

  @override
  String get phoneOrderNoCustomers =>
      'Tiada pelanggan sepadan. Tambah sebagai pelanggan baharu.';

  @override
  String get phoneOrderAppCustomer => 'Pengguna aplikasi';

  @override
  String get phoneOrderPosCustomer => 'Pelanggan POS';

  @override
  String get phoneOrderNoAddress => 'Tiada alamat disimpan';

  @override
  String get phoneOrderChangeCustomer => 'Tukar pelanggan';

  @override
  String get phoneOrderCustomerName => 'Nama pelanggan';

  @override
  String get phoneOrderCustomerPhone => 'Nombor telefon';

  @override
  String get phoneOrderCustomerAddress => 'Alamat';

  @override
  String get phoneOrderCustomerZone => 'Zon';

  @override
  String get phoneOrderSaveCustomer => 'Simpan pelanggan';

  @override
  String get phoneOrderNameRequired => 'Masukkan nama pelanggan';

  @override
  String get phoneOrderPhoneInvalid =>
      'Masukkan nombor mudah alih Mesir yang sah (01XXXXXXXXX)';

  @override
  String get phoneOrderProductSearchHint =>
      'Cari mengikut nama produk atau kod bar...';

  @override
  String get phoneOrderSearchProductsPrompt =>
      'Cari produk mengikut nama atau kod bar';

  @override
  String get phoneOrderNoProducts => 'Tiada produk sepadan';

  @override
  String get phoneOrderCartTitle => 'Troli pelanggan';

  @override
  String get phoneOrderCartEmpty => 'Belum ada produk ditambah';

  @override
  String get phoneOrderItemsTotal => 'Jumlah barangan';

  @override
  String get phoneOrderTotal => 'Jumlah';

  @override
  String get phoneOrderFreeDelivery => 'Percuma';

  @override
  String get phoneOrderConfirm => 'Sahkan dan buat pesanan';

  @override
  String phoneOrderPlaced(String id) {
    return 'Pesanan #$id dibuat';
  }

  @override
  String phoneOrderFailed(String error) {
    return 'Tidak dapat membuat pesanan: $error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return 'Carian gagal: $error';
  }

  @override
  String get phoneOrderNotAllowed =>
      'Akaun ini tidak dibenarkan mengambil pesanan telefon';

  @override
  String get phoneOrderBadge => 'Telefon';

  @override
  String phoneOrderSetupMissing(String function) {
    return 'Fungsi pangkalan data $function tiada. Jalankan supabase/migrations/20261111010000_phone_orders.sql dalam Supabase SQL Editor.';
  }

  @override
  String get adminToggleMenu => 'Tunjuk/sembunyi menu';

  @override
  String get adminResizeColumn => 'Seret untuk mengubah saiz lajur';

  @override
  String get phoneOrderShowCart => 'Tunjuk troli dan penghantaran';

  @override
  String get phoneOrderHideCart => 'Sembunyi troli';

  @override
  String get driverDeliveryAddress => 'Alamat penghantaran';

  @override
  String get driverNavigateViaMap => 'Navigasi melalui peta';

  @override
  String get mapSearchHint => 'Cari kawasan atau jalan...';

  @override
  String get mapSearchNoResults => 'Tiada tempat ditemui';

  @override
  String mapSearchFailed(String error) {
    return 'Tidak dapat mencari tempat: $error';
  }

  @override
  String get mapSearchClear => 'Kosongkan carian';

  @override
  String get supportLiveChatSubtitle =>
      'Tulis kepada kami dalam aplikasi dan pasukan kami akan membalas segera';

  @override
  String get supportSignInMessage =>
      'Log masuk untuk memulakan sembang dengan khidmat pelanggan.';

  @override
  String supportLaunchFailed(String phone) {
    return 'Tidak dapat membuka aplikasi. Anda boleh menghubungi kami di $phone';
  }

  @override
  String get supportChatTitle => 'Khidmat pelanggan';

  @override
  String get supportChatSubtitle => 'Pasukan Safeer Market membalas di sini';

  @override
  String get supportChatWelcome =>
      'Selamat datang! Tulis soalan atau masalah anda dan pasukan khidmat pelanggan kami akan membalas secepat mungkin.';

  @override
  String get supportMessageHint => 'Tulis mesej anda...';

  @override
  String supportLoadFailed(String error) {
    return 'Tidak dapat memuatkan sembang: $error';
  }

  @override
  String get supportSetupMissing =>
      'Sembang langsung belum disediakan. Jalankan supabase/migrations/20261114210000_support_chat.sql dalam Supabase SQL Editor.';

  @override
  String get supportNotAllowed => 'Anda tiada akses kepada sembang ini';

  @override
  String supportRequestFailed(String error) {
    return 'Tidak dapat melengkapkan permintaan: $error';
  }

  @override
  String get supportCenterTitle => 'Aduan & sembang';

  @override
  String get supportNoChats => 'Tiada sembang terbuka sekarang';

  @override
  String get supportSelectChat =>
      'Pilih sembang daripada senarai untuk membalas pelanggan';

  @override
  String get supportNoMessagesYet => 'Belum ada mesej dalam sembang ini';

  @override
  String get supportReplyHint => 'Tulis balasan anda kepada pelanggan...';

  @override
  String get supportLatestOrders => 'Pesanan terkini';

  @override
  String supportLatestOrdersTitle(String name) {
    return 'Pesanan terkini $name';
  }

  @override
  String get supportNoOrders => 'Pelanggan ini tiada pesanan';

  @override
  String supportNewMessageToast(String name, String message) {
    return 'Mesej baharu daripada $name: $message';
  }

  @override
  String get supportOpenChat => 'Buka sembang';

  @override
  String get notificationsTitle => 'Pemberitahuan';

  @override
  String get notificationsEmptySubtitle =>
      'Kami akan memaklumkan anda sebaik sahaja tawaran atau majalah baharu tersedia daripada Safeer Market';

  @override
  String notificationsLoadFailed(String error) {
    return 'Tidak dapat memuatkan pemberitahuan: $error';
  }

  @override
  String get notificationsSetupMissing =>
      'Pemberitahuan belum disediakan. Jalankan supabase/migrations/20261114220000_app_notifications.sql dalam Supabase SQL Editor.';

  @override
  String get notificationsNotAllowed =>
      'Hanya akaun pentadbir boleh menghantar dan memadam pemberitahuan';

  @override
  String get timeJustNow => 'Baru sahaja';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minit lalu',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam lalu',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari lalu',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => 'Umum';

  @override
  String get notificationTypePromo => 'Tawaran & diskaun';

  @override
  String get notificationTypeMagazine => 'Majalah baharu';

  @override
  String get notificationTypeOrder => 'Pesanan anda';

  @override
  String get notificationTypeSupportChat => 'Sokongan pelanggan';

  @override
  String get adminSendNotifications => 'Hantar pemberitahuan';

  @override
  String get adminNotificationFormSubtitle =>
      'Dipaparkan serta-merta dalam aplikasi semua pelanggan';

  @override
  String get adminNotificationTitleLabel => 'Tajuk pemberitahuan';

  @override
  String get adminNotificationTitleHint =>
      'cth. Majalah tawaran bulan ini sudah keluar! 🔥';

  @override
  String get adminNotificationTitleRequired => 'Masukkan tajuk pemberitahuan';

  @override
  String get adminNotificationBodyLabel => 'Teks pemberitahuan';

  @override
  String get adminNotificationBodyHint =>
      'cth. Lihat tawaran dan diskaun eksklusif terkini di Safeer Market';

  @override
  String get adminNotificationBodyRequired => 'Masukkan teks pemberitahuan';

  @override
  String get adminNotificationTypeLabel => 'Jenis pemberitahuan';

  @override
  String get adminNotificationImageLabel => 'Pautan imej tawaran - pilihan';

  @override
  String get adminNotificationImageInvalid =>
      'Masukkan pautan sah yang bermula dengan https://';

  @override
  String get adminSendNotificationButton => 'Hantar kepada semua pelanggan';

  @override
  String get adminNotificationSent =>
      'Pemberitahuan dihantar kepada semua pelanggan';

  @override
  String adminNotificationSendFailed(String error) {
    return 'Tidak dapat menghantar pemberitahuan: $error';
  }

  @override
  String get adminNotificationsHistory => 'Pemberitahuan dihantar';

  @override
  String get adminNoNotificationsSent => 'Belum ada pemberitahuan dihantar';

  @override
  String get adminDeleteNotificationTitle => 'Padam pemberitahuan';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return 'Padam pemberitahuan \"$title\"? Ia akan hilang daripada aplikasi pelanggan.';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return 'Tidak dapat memadam pemberitahuan: $error';
  }

  @override
  String get orderCardShowDetails => 'Lihat butiran';

  @override
  String get orderCardHideDetails => 'Sembunyi butiran';

  @override
  String get orderCardItemsTitle => 'Item pesanan';

  @override
  String get orderCardItemsFailed => 'Tidak dapat memuatkan item pesanan';

  @override
  String get orderCardNoItems => 'Tiada item direkodkan untuk pesanan ini';

  @override
  String get orderCardCancelledNote => 'Pesanan ini telah dibatalkan';

  @override
  String get cancelOrder => 'Batalkan pesanan';

  @override
  String get cancelOrderConfirmTitle =>
      'Adakah anda pasti mahu membatalkan pesanan?';

  @override
  String get cancelOrderReasonPrompt => 'Pilih sebab pembatalan:';

  @override
  String get cancelOrderDismiss => 'Kembali';

  @override
  String get cancelOrderConfirm => 'Sahkan pembatalan';

  @override
  String get cancelReasonDeliveryDelay => 'Kelewatan penghantaran';

  @override
  String get cancelReasonOrderedByMistake => 'Pesan secara tidak sengaja';

  @override
  String get cancelReasonChangedMind => 'Berubah fikiran';

  @override
  String get cancelReasonOther => 'Sebab lain';

  @override
  String cancellationReasonLine(String reason) {
    return 'Sebab pembatalan: $reason';
  }

  @override
  String get orderCancelledSuccess => 'Pesanan berjaya dibatalkan';

  @override
  String get orderCancelTooLate =>
      'Pesanan ini tidak lagi boleh dibatalkan kerana sudah sedia atau dalam penghantaran';

  @override
  String get orderCancelSetupMissing =>
      'Pembatalan pesanan belum disediakan. Jalankan supabase/migrations/20261114240000_customer_cancel_order.sql dalam Supabase SQL Editor.';

  @override
  String orderCancelFailed(String error) {
    return 'Tidak dapat membatalkan pesanan: $error';
  }

  @override
  String get adminMenuReceiveOrders => 'Terima pesanan';

  @override
  String get adminMenuOrderStatus => 'Status pesanan';

  @override
  String get adminStatusDelayedShort => 'Tertunda';

  @override
  String get adminStatusCancelledShort => 'Dibatalkan';

  @override
  String get adminResendNotification => 'Hantar semula';

  @override
  String get adminResendFillForm => 'Isikan borang';

  @override
  String get adminResendNotificationTitle => 'Hantar semula pemberitahuan ini?';

  @override
  String adminResendNotificationConfirm(String title) {
    return 'Pemberitahuan \"$title\" akan dihantar semula kepada semua pelanggan.';
  }

  @override
  String get adminNotificationSearchHint => 'Cari mengikut tajuk';

  @override
  String get adminNotificationFilterByDate => 'Tapis mengikut tarikh';

  @override
  String get adminNotificationFilterByType => 'Tapis mengikut jenis';

  @override
  String get adminNotificationClearDateFilter => 'Kosongkan penapis tarikh';

  @override
  String get adminSelectCustomerFirst => 'Pilih pelanggan untuk mula pesanan';
}
