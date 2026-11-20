// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get bannerShopBrandProducts => '选购该品牌商品';

  @override
  String get bannerAdd => '添加公司横幅';

  @override
  String get bannerTitleLabel => '公司名称 / 横幅标题';

  @override
  String get bannerKeywordLabel => '公司商品关键词';

  @override
  String get bannerKeywordHint => '例如：Juhayna';

  @override
  String get bannerChooseImage => '选择横幅图片';

  @override
  String get bannerChangeImage => '更换图片';

  @override
  String get bannerImageRequired => '请先选择横幅图片';

  @override
  String get bannerKeywordRequired => '请输入用于打开公司商品的关键词';

  @override
  String get bannerSaved => '横幅添加成功';

  @override
  String bannerSaveFailed(String error) {
    return '无法保存横幅：$error';
  }

  @override
  String bannerDeleteConfirm(String title) {
    return '要删除横幅“$title”吗？';
  }

  @override
  String get bannerExistingHeader => '当前横幅';

  @override
  String get appTitle => '萨菲尔市场';

  @override
  String get home => '首页';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get save => '保存';

  @override
  String get search => '搜索';

  @override
  String get cart => '购物车';

  @override
  String get wallet => '钱包';

  @override
  String get more => '更多';

  @override
  String get exitHint => '再按一次返回即可退出应用';

  @override
  String get newProducts => '新品';

  @override
  String get trendingOffers => '热门优惠';

  @override
  String get noNewNotifications => '暂无新通知';

  @override
  String get loadingLatestProducts => '正在加载最新商品...';

  @override
  String get noNewProductsLast3Days => '近 3 天没有新品';

  @override
  String get loadingOffers => '正在加载优惠...';

  @override
  String get noOffersCurrently => '暂无优惠';

  @override
  String get subscribersExclusiveFeature => '订阅专属功能 👑';

  @override
  String get playAndWinPaywallBody =>
      '“玩并赢”游戏和每周礼品仅面向 Safeer Prime 和 Safeer Pro 订阅用户。升级账户即可享受这些特权！';

  @override
  String get upgradeAccountNow => '立即升级账户';

  @override
  String get exploreSafeer => '探索萨菲尔';

  @override
  String get featuredProducts => '精选商品';

  @override
  String get failedToLoadProducts => '无法加载商品';

  @override
  String get noProductsCurrently => '暂无商品';

  @override
  String get seeAll => '查看全部';

  @override
  String get retry => '重试';

  @override
  String get loyaltyPoints => '积分';

  @override
  String get spinWheelCollectPoints => '转动转盘赢取积分';

  @override
  String get favoriteProducts => '收藏商品';

  @override
  String get myOrders => '我的订单';

  @override
  String get contactUs => '联系我们';

  @override
  String get help => '帮助';

  @override
  String get signOut => '退出登录';

  @override
  String get signIn => '登录';

  @override
  String get signOutConfirmMessage => '确定要退出当前账户吗？';

  @override
  String get signedOut => '已退出登录';

  @override
  String get adminDashboard => '管理控制台';

  @override
  String get adminDashboardSubtitle => '管理客户订单并更新状态';

  @override
  String get guestName => '访客';

  @override
  String welcomeUser(String name) {
    return '欢迎你，$name';
  }

  @override
  String get guestSubtitle => '登录后即可跟踪订单和收藏';

  @override
  String get personalData => '个人资料';

  @override
  String get email => '电子邮箱';

  @override
  String get savedAddresses => '已保存地址';

  @override
  String get savedCards => '已保存银行卡';

  @override
  String get messageAndSmsAlerts => '应用与短信提醒';

  @override
  String get privacyAndTerms => '隐私政策与条款';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountConfirmMessage => '你的账户及所有数据将被永久删除。确定继续吗？';

  @override
  String get deleteAccountSuccess => '账户已成功删除';

  @override
  String get passwordRequirementsTitle => '密码必须包含：';

  @override
  String get passwordRuleMinLength => '至少 8 个字符';

  @override
  String get passwordRuleUppercase => '至少一个大写字母';

  @override
  String get passwordRuleLowercase => '至少一个小写字母';

  @override
  String get passwordRuleDigit => '至少一个数字';

  @override
  String get talkToUs => '联系我们';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportLiveChat => '与客服实时聊天';

  @override
  String loyaltyPointsRedeem(int count) {
    return '$count 积分 • 兑换';
  }

  @override
  String get loyaltyPointsEarnNow => '忠诚积分 • 立即赚取 🎁';

  @override
  String get ok => '确定';

  @override
  String get noEmail => '没有电子邮箱';

  @override
  String get changeEmailContactSupport => '如需更改电子邮箱，请联系客服';

  @override
  String get privacyPolicyBody =>
      '萨菲尔市场尊重你的隐私。我们仅将姓名、电话和地址等数据用于配送订单和改善服务，未经你同意不会与第三方分享。\n\n使用本应用即表示你同意使用条款，包括订购、配送和退货政策。完整政策即将发布。';

  @override
  String get helpTitle => '我们能如何帮助你？';

  @override
  String get helpBody => '萨菲尔市场团队随时为你服务。\n如果订单遇到问题或有疑问，请联系我们，我们会尽快回复。';

  @override
  String get callUs => '致电我们';

  @override
  String get callUsSubtitle => '直接与客服通话';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get whatsappSubtitle => '发消息给我们，我们会尽快回复';

  @override
  String get messageAlerts => '消息提醒';

  @override
  String get appNotifications => '应用通知';

  @override
  String get appNotificationsSubtitle => '优惠与订单状态更新';

  @override
  String get smsMessages => '短信';

  @override
  String get smsMessagesSubtitle => '用于订单确认和配送的短信';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get close => '关闭';

  @override
  String get refresh => '刷新';

  @override
  String get all => '全部';

  @override
  String get shopNow => '立即选购';

  @override
  String get scanBarcode => '扫描条形码';

  @override
  String get phoneNumber => '电话号码';

  @override
  String get categories => '分类';

  @override
  String get magazines => '促销杂志';

  @override
  String get addMagazine => '添加杂志';

  @override
  String get unexpectedError => '发生意外错误';

  @override
  String get networkError => '无法连接网络';

  @override
  String get serverError => '服务器出错';

  @override
  String get serverConnectionError => '无法连接服务器，请重试';

  @override
  String get pleaseSignInFirst => '请先登录';

  @override
  String get noPermissionToEditOrder => '你无权编辑此订单';

  @override
  String orderUpdateFailed(String error) {
    return '无法更新订单：$error';
  }

  @override
  String ordersLoadFailed(String error) {
    return '无法加载订单\n$error';
  }

  @override
  String orderNumber(String id) {
    return '订单 #$id';
  }

  @override
  String get deletedProduct => '已删除的商品';

  @override
  String get product => '商品';

  @override
  String get addNewAddress => '添加新地址';

  @override
  String get manageAddresses => '管理地址';

  @override
  String get editLocation => '编辑位置';

  @override
  String helloName(String name) {
    return '你好，$name';
  }

  @override
  String get cardNumber => '卡号';

  @override
  String get cardholderName => '持卡人姓名';

  @override
  String get asWrittenOnCard => '与卡面上一致';

  @override
  String get expiryDate => '有效期';

  @override
  String get addBankCard => '添加银行卡';

  @override
  String get bankCard => '银行卡';

  @override
  String get adminPaidByVisa => '已用 Visa 支付';

  @override
  String get cameraOpenFailed => '无法打开相机，请检查相机权限';

  @override
  String get addressLabelHome => '家';

  @override
  String get addressLabelWork => '公司';

  @override
  String get puzzleGame => '拼图游戏';

  @override
  String get luckyWheel => '幸运转盘';

  @override
  String get awesome => '太棒了！';

  @override
  String get customer => '客户';

  @override
  String get noLocationForOrder => '此订单没有可用位置';

  @override
  String get branch => '门店';

  @override
  String get safeerCustomer => '萨菲尔客户';

  @override
  String get notSpecified => '未指定';

  @override
  String get cashOnDelivery => '货到付款';

  @override
  String get orderStatusPending => '待处理';

  @override
  String get orderStatusPreparing => '备货中';

  @override
  String get orderStatusReadyForDelivery => '待配送';

  @override
  String get orderStatusOutForDelivery => '配送中';

  @override
  String get orderStatusDelivered => '已送达';

  @override
  String get orderStatusCancelled => '已取消';

  @override
  String get statusNew => '新订单';

  @override
  String get startPreparing => '开始备货';

  @override
  String get total => '合计';

  @override
  String get inStock => '有货';

  @override
  String get outOfStock => '缺货';

  @override
  String get decreaseQuantity => '减少数量';

  @override
  String get increaseQuantity => '增加数量';

  @override
  String get decreaseWeight => '减少重量';

  @override
  String get increaseWeight => '增加重量';

  @override
  String get addToCart => '加入购物车';

  @override
  String get cartEmpty => '购物车是空的';

  @override
  String get productUnavailableNow => '该商品暂时无货';

  @override
  String distanceFromBranch(String distance) {
    return '距门店 $distance';
  }

  @override
  String get invoiceNumberRequired => '请填写发票号';

  @override
  String get addAtLeastOneItem => '请至少添加一件商品';

  @override
  String get orderOnTheWayToYou => '你的订单正在配送途中！';

  @override
  String get deliveryFee => '配送费';

  @override
  String get currencySymbol => 'EGP';

  @override
  String get unitPiece => '件';

  @override
  String get unitKilo => '公斤';

  @override
  String gramsValue(String value) {
    return '$value 克';
  }

  @override
  String kilosValue(String value) {
    return '$value 公斤';
  }

  @override
  String kmValue(String value) {
    return '$value 公里';
  }

  @override
  String get sessionExpired => '会话已过期，请重新登录';

  @override
  String adminStatusUpdateFailed(String error) {
    return '无法更新状态：$error';
  }

  @override
  String get adminDeleteMagazineTitle => '删除杂志';

  @override
  String adminDeleteMagazineConfirm(String title) {
    return '确定删除“$title”吗？';
  }

  @override
  String adminDeleteMagazineFailed(String error) {
    return '无法删除杂志：$error';
  }

  @override
  String adminErrorWithDetails(String error) {
    return '错误：$error';
  }

  @override
  String get adminNoMagazinesYet => '暂无杂志。点击“添加杂志”上传第一本。';

  @override
  String get adminMagazineExpired => '已过期';

  @override
  String get adminMagazineUpcoming => '即将上线';

  @override
  String get adminMagazineActive => '进行中';

  @override
  String adminMagazineDateRange(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String get adminPickMagazinePdfTitle => '选择杂志文件（PDF）';

  @override
  String get adminMagazineStartDate => '开始日期';

  @override
  String get adminMagazineEndDate => '结束日期';

  @override
  String get adminMagazineTitleRequired => '请输入杂志标题';

  @override
  String get adminMagazineCoverRequired => '请选择封面图片';

  @override
  String get adminMagazinePdfRequired => '请为杂志选择 PDF 文件';

  @override
  String get adminMagazineEndBeforeStart => '结束日期必须晚于开始日期';

  @override
  String get adminMagazineAdded => '杂志添加成功';

  @override
  String adminMagazineSaveFailed(String error) {
    return '无法保存杂志：$error';
  }

  @override
  String get adminAddNewMagazine => '添加新杂志';

  @override
  String get adminMagazineTitleLabel => '杂志标题';

  @override
  String get adminPickCoverImage => '选择封面图片';

  @override
  String get adminChangeCover => '更换封面';

  @override
  String get adminPickPdfFile => '选择 PDF 文件';

  @override
  String get adminUploading => '正在上传...';

  @override
  String get adminSupervisorPermissions => '主管权限';

  @override
  String get adminEnterPinHint => '输入 PIN（1234）';

  @override
  String get adminSupervisorModeEnabled => '已启用主管模式';

  @override
  String get adminInvalidPin => 'PIN 错误';

  @override
  String get adminActivate => '启用';

  @override
  String adminAppBarTitleManagement(String appName) {
    return '$appName - 管理';
  }

  @override
  String adminAppBarTitleWorkspace(String appName) {
    return '$appName - 工作台';
  }

  @override
  String get adminCloseManagement => '锁定管理';

  @override
  String get adminEnableManagement => '解锁管理';

  @override
  String get adminExitToStore => '返回商店';

  @override
  String get adminMenuOrders => '订单';

  @override
  String get adminMenuProducts => '商品';

  @override
  String get adminMenuStaff => '员工';

  @override
  String get adminMenuReports => '报表与日志';

  @override
  String get adminStatusPreparingShort => '备货';

  @override
  String get adminStatusReadyForDriverShort => '待骑手';

  @override
  String get adminStatusDeliveryShort => '配送';

  @override
  String get adminStatusCompletedShort => '已完成';

  @override
  String get adminStatusUnknown => '未知';

  @override
  String get adminNoOrders => '暂无订单';

  @override
  String get adminSelectOrderFromList => '从列表中选择一个订单';

  @override
  String get adminItemsToPrepare => '待备货商品：';

  @override
  String get adminNoItemsInOrder => '没有记录的商品';

  @override
  String get adminAvailableActions => '可用操作';

  @override
  String get adminOrderAwaitingPreparer => '订单正在等待备货员';

  @override
  String adminPreparerName(String name) {
    return '备货员：$name';
  }

  @override
  String get adminAwaitingDriverAssignment => '等待主管指派骑手';

  @override
  String get adminPickUpAndStartRoute => '取货并出发 🗺️';

  @override
  String adminDriverName(String name) {
    return '骑手：$name';
  }

  @override
  String get adminOrderReadyAwaitingDriver => '订单备货完成，等待骑手取货。';

  @override
  String get adminMarkDelivered => '已成功送达 💵';

  @override
  String get adminCloseOrderPermanently => '永久关闭订单';

  @override
  String get adminOrderWithDriverOnTheWay => '订单已由骑手配送，正在前往客户处。';

  @override
  String get adminOrderDeliveredAndClosed => '此订单已成功送达并关闭。';

  @override
  String get adminWhoAreYouPickName => '你是谁？（选择你的名字开始）';

  @override
  String get adminNoPreparers => '没有可用的备货员';

  @override
  String get adminFinishOrderPreparation => '完成订单备货';

  @override
  String get adminCheckAllItemsFirst => '⚠️ 抱歉，请先勾选所有商品。';

  @override
  String get adminPreparationFinished => '备货已成功完成。';

  @override
  String get adminAssignDriverTitle => '指派骑手（仅限主管）';

  @override
  String get adminSelectDriver => '选择骑手';

  @override
  String get adminOrderAssignedToDriver => '订单已指派给骑手';

  @override
  String get adminAssignToSelectedDriver => '指派给所选骑手';

  @override
  String get adminCallFailed => '无法拨打电话';

  @override
  String get adminNoPhoneNumber => '无号码';

  @override
  String get adminNoName => '无姓名';

  @override
  String get adminAddressNotSet => '未指定';

  @override
  String get adminCustomerInfo => '客户信息';

  @override
  String get adminManageProducts => '管理商品';

  @override
  String get adminActiveProducts => '已上架商品';

  @override
  String get adminInactiveProducts => '已下架';

  @override
  String get adminSearchProductByName => '按名称搜索商品...';

  @override
  String adminErrorOccurred(String error) {
    return '发生错误：$error';
  }

  @override
  String get adminNoProducts => '暂无商品';

  @override
  String get adminCopyProductName => '复制商品名称';

  @override
  String get adminCopied => '已复制';

  @override
  String get adminCopyBarcode => '复制条形码';

  @override
  String adminBarcodeValue(String barcode) {
    return '条形码：$barcode';
  }

  @override
  String get adminUpdateErrorOccurred => '更新时发生错误';

  @override
  String get adminManageStaff => '管理员工';

  @override
  String get adminAddEmployee => '添加员工';

  @override
  String get adminNoStaff => '没有已登记的员工';

  @override
  String get adminRoleTaker => '接单员';

  @override
  String get adminRolePreparer => '备货员';

  @override
  String get adminRoleDriver => '骑手';

  @override
  String get adminNoPhone => '无电话';

  @override
  String get adminReportsTitle => '报表与汇总日志';

  @override
  String get adminTotalSalesCollected => '总销售额（已收款）';

  @override
  String get adminDeliveredOrdersTitle => '已完成并送达的订单';

  @override
  String get adminOrdersInPreparationTitle => '正在备货的订单';

  @override
  String get adminCancelledOrdersTitle => '已取消的订单';

  @override
  String get adminTotalOrdersCumulative => '订单总数（累计）';

  @override
  String adminOrdersCount(String count) {
    return '$count 个订单';
  }

  @override
  String get adminRecentOrdersLog => '近期订单记录';

  @override
  String get adminOrderNumberColumn => '订单号';

  @override
  String get adminCustomerNameColumn => '客户姓名';

  @override
  String get adminStatusColumn => '状态';

  @override
  String get paymentMethodCashLabel => '货到付款';

  @override
  String get paymentMethodCardLabel => '银行卡（Visa/Mastercard）';

  @override
  String get paymentMethodInstaPayLabel => 'InstaPay';

  @override
  String get paymentMethodInstaPaySubtitle => '通过 InstaPay 即时转账';

  @override
  String get instaPayOpenApp => '打开 InstaPay 立即付款';

  @override
  String get instaPayIpaLabel => '即时付款地址 (IPA)';

  @override
  String get instaPayPhoneLabel => '或通过手机号转账';

  @override
  String get instaPayCopy => '复制';

  @override
  String get instaPayCopied => '已复制';

  @override
  String get instaPayConfirmHint => '通过 InstaPay 完成订单金额转账后，点击下方确认订单。';

  @override
  String get instaPayReceiptTitle => '银行转账回单（截图）';

  @override
  String get instaPayReceiptHint => '请附上 InstaPay 转账成功截图以确认订单';

  @override
  String get instaPayReceiptPick => '选择回单图片或拍照';

  @override
  String get instaPayReceiptRequired => '请先附上转账回单图片';

  @override
  String get adminViewTransferReceipt => '查看转账回单';

  @override
  String get adminCopyReceiptImage => '复制图片';

  @override
  String get adminShareReceipt => '分享回单';

  @override
  String get adminReceiptImageCopied => '回单图片已复制';

  @override
  String get adminReceiptActionFailed => '无法处理回单图片';

  @override
  String get subscriptionConfirmInstaPay => '确认订阅';

  @override
  String get subscriptionPendingSuccessTitle => '已收到升级申请';

  @override
  String get subscriptionPendingSuccessBody =>
      '已收到您的升级申请和付款回单。管理员审核后将立即激活您的 Pro 账户。';

  @override
  String get adminMenuPendingSubscriptions => '待处理订阅';

  @override
  String get adminActivateAccount => '激活账户';

  @override
  String get adminSubscriptionApproved => '订阅已激活';

  @override
  String get adminNoPendingSubscriptions => '暂无待处理的订阅申请';

  @override
  String get adminPendingSubscriptionTier => '申请套餐';

  @override
  String get paymentCopyCardNumber => '复制卡号';

  @override
  String get paymentCardNumberCopied => '卡号已复制';

  @override
  String get checkoutAddressOutOfRange => '该地址不在配送范围内';

  @override
  String get checkoutPinAddressFirst => '请先在地图上标记地址';

  @override
  String checkoutOrderFailed(String error) {
    return '无法下单：$error';
  }

  @override
  String get checkoutTitle => '结算';

  @override
  String get checkoutDeliveryAddress => '配送地址';

  @override
  String get checkoutPaymentMethod => '支付方式';

  @override
  String get checkoutOrderSummary => '订单摘要';

  @override
  String get checkoutSelectAddressFirst => '请先选择配送地址再下单';

  @override
  String get checkoutPinLocationForFee => '在地图上标记地址以计算配送费';

  @override
  String checkoutOrderPlaced(String id) {
    return '已收到你的订单 • 订单 #$id';
  }

  @override
  String checkoutOutOfRange(String distance, String maxDistance) {
    return '抱歉，该地址距离 $distance，超出配送范围（最远 $maxDistance）';
  }

  @override
  String get checkoutSignInToChooseAddress => '登录后选择配送地址';

  @override
  String get checkoutPinThisAddressForFee => '在地图上标记此地址以计算配送费';

  @override
  String get checkoutPinLocation => '标记位置';

  @override
  String get checkoutChangeAddress => '更改';

  @override
  String get checkoutAddDeliveryAddress => '添加配送地址以完成下单';

  @override
  String get checkoutAddAddress => '添加地址';

  @override
  String get checkoutNoAddressChosen => '你还没有选择配送地址';

  @override
  String get checkoutChooseAddress => '选择地址';

  @override
  String get checkoutEstimatedArrival => '预计送达：';

  @override
  String checkoutDeliveryFeeWithDistance(String distance) {
    return '配送费（$distance）';
  }

  @override
  String get checkoutOutOfDeliveryRange => '超出配送范围';

  @override
  String get checkoutItemCount => '商品数量';

  @override
  String get checkoutSubtotal => '小计';

  @override
  String get checkoutGrandTotal => '总计';

  @override
  String get checkoutConfirmOrder => '确认订单';

  @override
  String get paymentCardScanUnsupported => '此设备不支持扫描银行卡';

  @override
  String get paymentCardScanFailed => '无法识别银行卡，请手动输入信息';

  @override
  String get paymentCardScanned => '银行卡已识别，请核对信息并输入 CVV';

  @override
  String get paymentCardTitle => '银行卡支付';

  @override
  String get paymentSecureNotice => '安全加密支付';

  @override
  String paymentPayNow(String amount) {
    return '立即支付 • $amount';
  }

  @override
  String get paymentScanCardTooltip => '用相机扫描银行卡';

  @override
  String get paymentAmountDue => '应付金额';

  @override
  String get cardNumberRequired => '请输入卡号';

  @override
  String get cardNumberInvalid => '卡号无效';

  @override
  String get cardExpiryRequired => '请按 MM/YY 格式输入日期';

  @override
  String get cardExpiryInvalidMonth => '月份无效';

  @override
  String get cardExpired => '银行卡已过期';

  @override
  String get cardCvvInvalid => '安全码无效';

  @override
  String get cardHolderNameRequired => '请输入卡面上的姓名';

  @override
  String get walletCardSaved => '银行卡保存成功';

  @override
  String get walletCardDataProtected => '你的数据受到保护，我们绝不保存 CVV';

  @override
  String get walletSaveCard => '保存银行卡';

  @override
  String get walletAddCardHint => '添加银行卡，下次下单付款更快捷';

  @override
  String get walletInAppBalance => '你的应用内钱包余额';

  @override
  String get walletBalanceLoadFailed => '无法加载余额';

  @override
  String get walletBalanceAutoApplied => '结算时将自动使用你的余额';

  @override
  String get walletSignInToViewBalance => '登录后查看余额';

  @override
  String walletCardExpires(String expiry) {
    return '有效期至 $expiry';
  }

  @override
  String get walletDeleteCard => '删除银行卡';

  @override
  String get checkoutUseOrAddNewCard => '+ 使用或添加新卡';

  @override
  String get checkoutSavedCards => '已保存的银行卡';

  @override
  String get paywallUpgradeAccount => '升级账户';

  @override
  String get paywallDiscoverSafeer => '探索萨菲尔的世界 👑';

  @override
  String get paywallChoosePlan => '选择适合你的套餐，每笔订单都更省钱。';

  @override
  String get paywallProTitle => 'Safeer Pro (VIP)';

  @override
  String get paywallPerMonth => '/ 月';

  @override
  String get paywallProUnlimitedFreeDelivery => '无限次免费配送 🚀';

  @override
  String get paywallProExpressDelivery => '极速配送（优先备货）';

  @override
  String get paywallProWholesalePrices => '专属批发价 💰';

  @override
  String get paywallProNoMinimumOrder => '无最低起送金额';

  @override
  String get paywallProUnlimitedGiveaways => '无限次参与礼品抽奖';

  @override
  String get paywallPrimeTitle => 'Safeer Prime';

  @override
  String get paywallPrimeFreeDeliveryFiveOrders => '5 笔订单免费配送';

  @override
  String get paywallPrimeOffersPriority => '优先抢购重大优惠';

  @override
  String get paywallPrimeWeeklyPlayAndWin => '每周“玩并赢”游戏 🎁';

  @override
  String get paywallFreeTitle => '普通账户';

  @override
  String get paywallFreePrice => '免费';

  @override
  String get paywallFreeStandardDelivery => '按标准费用常规配送';

  @override
  String get paywallFreePublicAccess => '浏览商品和公开优惠';

  @override
  String get paywallBestSeller => '最畅销';

  @override
  String get paywallPaymentComingSoon => '支付功能即将上线';

  @override
  String get paywallSubscribeNow => '立即订阅';

  @override
  String get catDairyEggs => '乳制品和蛋类';

  @override
  String get subcatTetraPakCheese => '利乐包、三角及杯装奶酪';

  @override
  String get subcatPackagedCheeseLabneh => '包装奶酪、酸奶酪、奶油和酥油';

  @override
  String get subcatCheeseByWeight => '散装称重奶酪';

  @override
  String get subcatMozzarella => '马苏里拉奶酪';

  @override
  String get subcatYogurtRicePudding => '酸奶和牛奶米布丁';

  @override
  String get subcatLongLifeDairy => '常温乳制品';

  @override
  String get subcatPackagedButter => '包装黄油';

  @override
  String get subcatPackagedEggs => '盒装鸡蛋';

  @override
  String get catSweetsSnacks => '糖果零食';

  @override
  String get subcatChocolate => '巧克力';

  @override
  String get subcatBiscuits => '饼干';

  @override
  String get subcatSweets => '糖果甜点';

  @override
  String get subcatChipsRoasted => '薯片和烘焙零食';

  @override
  String get subcatNutsByWeight => '散装零食和坚果';

  @override
  String get subcatHalawaSpreads => '芝麻酥糖和涂抹酱';

  @override
  String get subcatRamadanYamish => '斋月干果和坚果';

  @override
  String get catDrinksJuices => '饮料和果汁';

  @override
  String get subcatWaterDrinksIceCream => '饮用水、饮料、果汁和冰淇淋';

  @override
  String get subcatDrinks => '饮料';

  @override
  String get subcatJuices => '果汁';

  @override
  String get subcatPowderedJuices => '固体饮料冲剂';

  @override
  String get catMeatFrozen => '肉类和冷冻食品';

  @override
  String get subcatFrozenPoultry => '冷冻禽肉及禽肉制品';

  @override
  String get subcatFrozenMeat => '冷冻肉类';

  @override
  String get subcatProcessedMeat => '肉制品';

  @override
  String get subcatFrozenFish => '冷冻鱼类';

  @override
  String get subcatSmokedFish => '烟熏鱼';

  @override
  String get subcatFrozenVegFruit => '冷冻蔬菜和水果';

  @override
  String get subcatFrozenPastries => '冷冻面点';

  @override
  String get catBakeryBreakfast => '烘焙和早餐';

  @override
  String get subcatBakery => '烘焙食品';

  @override
  String get subcatPatisserie => '糕点和小蛋糕';

  @override
  String get subcatCerealsOats => '玉米片、什锦麦片和燕麦';

  @override
  String get catPastaRice => '意面和大米';

  @override
  String get subcatPasta => '意面';

  @override
  String get subcatRice => '大米';

  @override
  String get subcatLegumesSpicesBreadcrumbs => '包装豆类、香料和面包糠';

  @override
  String get subcatSoupsStocksMixes => '汤料、高汤和调味料';

  @override
  String get catPantryOils => '食品杂货和食用油';

  @override
  String get subcatOils => '食用油';

  @override
  String get subcatGhee => '酥油';

  @override
  String get subcatSugarFlour => '糖和面粉';

  @override
  String get subcatCannedFood => '罐头食品';

  @override
  String get subcatCondiments => '调味品和开胃小菜';

  @override
  String get subcatOlivesPickles => '橄榄和腌菜';

  @override
  String get subcatPackagedOlivesPickles => '包装橄榄和腌菜';

  @override
  String get subcatSpicesByWeight => '散装称重香料';

  @override
  String get subcatGrainsByWeight => '散装谷物和种子';

  @override
  String get subcatBakingSupplies => '烘焙用品和粉类';

  @override
  String get subcatSaladsByWeight => '散装称重沙拉';

  @override
  String get catCleaningCare => '清洁和家居';

  @override
  String get subcatDetergentsSofteners => '洗衣粉和柔顺剂';

  @override
  String get subcatLiquidSoapStainRemovers => '洗衣液和去渍剂';

  @override
  String get subcatBleachDisinfectants => '漂白剂和消毒剂';

  @override
  String get subcatPolishes => '上光剂';

  @override
  String get subcatInsecticidesFresheners => '杀虫剂和空气清新剂';

  @override
  String get subcatTissuesToiletPaper => '纸巾和卫生纸';

  @override
  String get subcatSteelWoolScrubbers => '钢丝球和洗碗布';

  @override
  String get subcatSpongesSteelWool => '海绵和钢丝球';

  @override
  String get subcatDrainCleaners => '管道疏通剂';

  @override
  String get subcatIncense => '熏香';

  @override
  String get catPersonalCare => '个人护理';

  @override
  String get subcatShampooConditioner => '洗发水和护发素';

  @override
  String get subcatShowerGelHandWash => '沐浴露和洗手液';

  @override
  String get subcatSoap => '香皂';

  @override
  String get subcatPerfumesDeodorants => '香水和止汗剂';

  @override
  String get subcatCreamsSerums => '面霜和精华';

  @override
  String get subcatOralCare => '口腔护理';

  @override
  String get subcatShavingSupplies => '剃须用品';

  @override
  String get subcatHairDyeHenna => '染发剂和指甲花';

  @override
  String get subcatPersonalCareSupplies => '个人护理用品';

  @override
  String get catBabyWorld => '母婴天地';

  @override
  String get subcatDiapersPads => '纸尿裤和卫生巾';

  @override
  String get subcatBabyFood => '婴儿食品';

  @override
  String get subcatBabySupplies => '婴儿用品';

  @override
  String get catHomeSupplies => '家居用品';

  @override
  String get subcatHousewares => '家庭用品';

  @override
  String get subcatElectricalTools => '电动工具';

  @override
  String get subcatElectricalSupplies => '电器配件';

  @override
  String get subcatPlasticsBags => '塑料制品和袋子';

  @override
  String get subcatFoil => '锡纸';

  @override
  String get subcatHardware => '五金杂货';

  @override
  String get subcatBatteries => '电池';

  @override
  String get subcatMatchesLighters => '火柴和打火机';

  @override
  String get subcatPetSupplies => '宠物用品';

  @override
  String get subcatRamadanSupplies => '斋月用品';

  @override
  String get categoryTitle => '分类';

  @override
  String get categoryNotFound => '该分类不存在';

  @override
  String get categoryNoProductsNow => '该分类暂无商品';

  @override
  String get shopFromHome => '去首页选购';

  @override
  String categoryProductCount(String count) {
    return '$count 件商品';
  }

  @override
  String get loadMoreFailedRetry => '无法加载更多，请重试';

  @override
  String get categoriesDrawerTagline => '所需一切，一站购齐';

  @override
  String get productDetailsTitle => '商品详情';

  @override
  String get productNotAvailable => '该商品不可用';

  @override
  String get productLoadFailed => '无法加载商品';

  @override
  String get productImageUpdated => '商品图片更新成功！';

  @override
  String productImageUploadFailed(String error) {
    return '上传失败：$error';
  }

  @override
  String get updateProductImage => '更新商品图片';

  @override
  String get takePhotoWithCamera => '拍照';

  @override
  String get chooseFromGallery => '从相册选择';

  @override
  String get changeProductImage => '更换图片';

  @override
  String get pricePerKiloChooseWeight => '按公斤计价，加入时请选择重量';

  @override
  String get productDescription => '商品描述';

  @override
  String get addToCartButton => '加入购物车';

  @override
  String get productCurrentlyUnavailable => '暂时无货';

  @override
  String get productDetailsInCart => '已在购物车';

  @override
  String get imageLinkCopied => '图片链接已复制';

  @override
  String get copyImageLink => '复制图片链接';

  @override
  String get similarProducts => '相似商品';

  @override
  String get searchInSafeer => '在萨菲尔中搜索';

  @override
  String get searchProductHint => '搜索商品，例如牛奶、奶酪...';

  @override
  String get clearSearch => '清除';

  @override
  String get barcodeScanUnsupported => '此设备不支持扫描条形码';

  @override
  String get searchFailedCheckConnection => '搜索失败，请检查网络连接';

  @override
  String get scanAnotherProduct => '扫描其他商品';

  @override
  String noProductWithBarcode(String barcode) {
    return '没有条形码为“$barcode”的商品';
  }

  @override
  String get productMayBeUnavailable => '该商品可能暂时无货';

  @override
  String get scanAgain => '重新扫描';

  @override
  String noSearchResultsFor(String query) {
    return '没有找到“$query”的相关结果';
  }

  @override
  String get searchTryAnotherWord => '换个关键词试试，或检查拼写';

  @override
  String searchResultsCount(String count, String query) {
    return '“$query”共有 $count 条结果';
  }

  @override
  String get popularSearches => '热门搜索';

  @override
  String get searchIntroSubtitle => '海量商品任你搜，几分钟即可下单';

  @override
  String get searchSuggestionMilk => '牛奶';

  @override
  String get searchSuggestionCheese => '奶酪';

  @override
  String get searchSuggestionRice => '大米';

  @override
  String get searchSuggestionOil => '食用油';

  @override
  String get searchSuggestionSugar => '糖';

  @override
  String get searchSuggestionTea => '茶';

  @override
  String get receiptTypeReceive => '收货';

  @override
  String get receiptTypeSupplierReturn => '退货';

  @override
  String get warehouseGoodsReceiptTitle => '货物入库';

  @override
  String get warehouseGoodsReturnTitle => '货物退回';

  @override
  String get warehouseReceiptSaved => '收货单已保存';

  @override
  String get warehouseReturnSaved => '退货单已保存';

  @override
  String get warehouseSubmitReceipt => '提交收货单';

  @override
  String get warehouseSubmitReturn => '提交退货单';

  @override
  String get warehouseInvoiceDate => '发票日期';

  @override
  String get warehouseScanOrEnterBarcode => '扫描或输入条形码';

  @override
  String get warehouseEnterQuantityAboveZero => '请输入大于零的数量';

  @override
  String get warehouseCompleteRequiredFields => '请先填写必填项';

  @override
  String get warehouseNoItemsYet => '尚未添加商品';

  @override
  String get warehouseDocumentDetails => '单据信息';

  @override
  String get warehouseInvoiceNumberRequiredLabel => '发票号 *';

  @override
  String get warehouseInvoiceDateRequiredLabel => '发票日期 *';

  @override
  String get warehouseInvoiceDateRequired => '请填写发票日期';

  @override
  String get warehouseItems => '商品';

  @override
  String get warehouseBarcode => '条形码';

  @override
  String get warehouseQuantity => '数量';

  @override
  String get warehouseAdd => '添加';

  @override
  String get warehouseReloadSuppliers => '重新加载供应商';

  @override
  String get warehouseSupplierRequiredLabel => '供应商 *';

  @override
  String get warehouseSupplierHint => '搜索或输入供应商编号';

  @override
  String get warehouseSuppliersEmpty => '供应商列表为空';

  @override
  String get warehouseSelectSupplier => '选择供应商';

  @override
  String get warehouseSelectSupplierFromList => '从列表中选择供应商';

  @override
  String get warehouseFetchingProductName => '正在获取商品名称…';

  @override
  String get warehouseUnregisteredProduct => '未登记的商品';

  @override
  String warehouseQuantityValue(String quantity) {
    return '数量：$quantity';
  }

  @override
  String get warehouseSelectDate => '选择日期';

  @override
  String get warehouseClearDate => '清除日期';

  @override
  String warehouseSuppliersLoadFailed(String error) {
    return '无法加载供应商：$error';
  }

  @override
  String warehouseDocumentSaveFailed(String error) {
    return '无法保存单据：$error';
  }

  @override
  String get warehouseOrderAlreadyUpdated => '无法更新订单，订单可能已被更新';

  @override
  String get warehouseSignOutConfirm => '要退出仓库账户吗？';

  @override
  String get warehouseDashboardTitle => '仓库控制台';

  @override
  String get warehouseNewOrdersTab => '新订单';

  @override
  String get warehousePreparingTab => '备货中';

  @override
  String get warehouseItemInquiry => '商品查询';

  @override
  String warehouseItemInquiryFailed(String error) {
    return '无法查询商品\n$error';
  }

  @override
  String get warehouseItemNotRegistered => '数据库中没有登记此商品';

  @override
  String warehouseBarcodeValue(String barcode) {
    return '条形码：$barcode';
  }

  @override
  String warehouseAvailableQuantity(String quantity) {
    return '可用数量：$quantity';
  }

  @override
  String get warehouseNoNewOrders => '暂无新订单\n下拉刷新';

  @override
  String get warehouseNoPreparingOrders => '没有正在备货的订单';

  @override
  String warehousePreparingStarted(String id) {
    return '已开始为订单 #$id 备货，可在“备货中”查看';
  }

  @override
  String warehouseOrderReady(String id) {
    return '订单 #$id 已备好，已通知配送骑手';
  }

  @override
  String warehouseProductsCount(String count) {
    return '商品（$count）';
  }

  @override
  String warehouseCustomerValue(String name) {
    return '客户：$name';
  }

  @override
  String warehouseAddressValue(String address) {
    return '地址：$address';
  }

  @override
  String warehouseTotalValue(String amount) {
    return '合计：$amount';
  }

  @override
  String get driverNewOrderAvailable => '有新的订单可配送！';

  @override
  String driverLocationSharingStartFailed(String error) {
    return '无法开始共享位置：$error';
  }

  @override
  String get driverSignOutConfirm => '要退出骑手账户吗？';

  @override
  String get driverDashboardTitle => '骑手控制台';

  @override
  String get driverAvailableOrdersTab => '可接订单';

  @override
  String get driverNoAvailableOrders => '当前没有可接订单\n下拉刷新';

  @override
  String get driverNoActiveDeliveries => '没有配送中的订单';

  @override
  String driverOrderAccepted(String id) {
    return '已接受订单 #$id，可在“我的订单”查看';
  }

  @override
  String driverOrderDelivered(String id) {
    return '订单 #$id 已送达';
  }

  @override
  String get driverPhoneLabel => '电话';

  @override
  String get driverAddressLabel => '地址';

  @override
  String get driverDistanceLabel => '距离';

  @override
  String get driverDistanceNotSpecified => '未指定';

  @override
  String driverDistanceFromBranch(String distance) {
    return '距门店 $distance';
  }

  @override
  String get driverTotalToCollect => '合计（待收款）';

  @override
  String get driverViewMapAndLocation => '查看地图和位置';

  @override
  String get driverAcceptOrder => '接受订单';

  @override
  String get driverBroadcastingLocation => '正在共享位置...';

  @override
  String driverBroadcastingLocationLastSent(String time) {
    return '正在共享位置... 上次发送于 $time';
  }

  @override
  String get driverRequestingLocationPermission => '正在请求位置权限...';

  @override
  String get driverStartLocationSharing => '开始共享位置';

  @override
  String driverCopyLabel(String label) {
    return '复制$label';
  }

  @override
  String driverCopiedLabel(String label) {
    return '$label已复制';
  }

  @override
  String driverLocationReadFailed(String error) {
    return '无法读取你的位置：$error';
  }

  @override
  String get driverLocationSharingStopped => '位置共享已停止，点击“开始共享位置”继续';

  @override
  String get driverOrderTakenByAnother => '抱歉，此订单已被其他骑手接受';

  @override
  String driverAcceptOrderFailed(String error) {
    return '无法接受订单：$error';
  }

  @override
  String driverLocationSendFailed(String error, String code) {
    return '无法向客户发送你的位置：$error（代码：$code）';
  }

  @override
  String get driverLocationSendNotAssigned => '无法向客户发送你的位置：该订单未分配给你或已不在配送中';

  @override
  String get driverGpsDisabled => '定位服务（GPS）已关闭，请开启以便客户跟踪你';

  @override
  String get driverLocationPermissionDeniedForever =>
      '位置权限被拒绝，请在应用设置中开启以便客户跟踪你';

  @override
  String get driverLocationPermissionDenied => '未允许访问位置，客户将无法跟踪订单';

  @override
  String get driverOpenGoogleMapsFailed => '无法在此设备上打开 Google 地图';

  @override
  String get driverMapAndLocationTitle => '地图和位置';

  @override
  String get driverStartNavigation => '开始导航';

  @override
  String get listSeparator => '、';

  @override
  String get storeCityName => '纳斯尔城';

  @override
  String get addressDefaultTitle => '地址';

  @override
  String get addressLabelOther => '其他';

  @override
  String addressBuildingLine(String building) {
    return '$building 号楼';
  }

  @override
  String addressFloorAptLine(String floor) {
    return '楼层/门牌 $floor';
  }

  @override
  String addressLandmarkLine(String landmark) {
    return '地标：$landmark';
  }

  @override
  String addressSaveFailed(String error) {
    return '无法保存地址：$error';
  }

  @override
  String get addressLocationSaveFailed => '无法保存地址位置';

  @override
  String addressLocationSaveFailedWithError(String error) {
    return '无法保存地址位置：$error';
  }

  @override
  String get locationServiceDisabled => '定位服务（GPS）已关闭，请开启后重试';

  @override
  String get locationPermissionDenied => '未允许访问位置，你可以手动移动地图';

  @override
  String get locationPermissionDeniedForever => '位置权限被拒绝，请在应用设置中开启';

  @override
  String get currentLocationUnavailable => '无法获取你的当前位置，请重试';

  @override
  String get mapAddressReadFailed => '无法从地图读取地址';

  @override
  String get addressesEmptyTitle => '还没有已保存的地址';

  @override
  String get addressesEmptyHint => '添加地址，订单送货更快捷';

  @override
  String get addressesLoadFailed => '无法加载地址';

  @override
  String get signInToManageAddresses => '登录后管理你的地址';

  @override
  String get addressDeleteTitle => '删除地址';

  @override
  String addressDeleteConfirm(String title) {
    return '确定删除地址“$title”吗？';
  }

  @override
  String get addressDeleteFailed => '无法删除地址';

  @override
  String addressSaved(String title) {
    return '地址“$title”已保存';
  }

  @override
  String get addressPickerTitle => '选择配送地址';

  @override
  String get addressPickerEmpty => '没有已保存的地址，添加你的第一个地址';

  @override
  String get addressDetailsTitle => '地址详情';

  @override
  String get addressTitleLabel => '地址名称';

  @override
  String get addressTitleHint => '例如：家、公司';

  @override
  String get addressAreaLabel => '区域';

  @override
  String get addressAreaHint => '例如：纳斯尔城第六区';

  @override
  String get addressStreetLabel => '街道';

  @override
  String get addressBuildingNumberLabel => '楼号';

  @override
  String get addressFloorAptLabel => '楼层 / 门牌';

  @override
  String get addressLandmarkLabel => '地标';

  @override
  String get addressLandmarkHint => '例如：清真寺旁边...';

  @override
  String get addressSaveButton => '保存地址';

  @override
  String addressOptionalFieldLabel(String label) {
    return '$label（选填）';
  }

  @override
  String get addressFieldRequired => '此项为必填项';

  @override
  String get addressReviewAndComplete => '请核对地址并填写其余信息。';

  @override
  String get mapAddressReadFailedFillManually => '无法从地图读取地址，请手动填写信息。';

  @override
  String mapDeliveryQuote(String distance, String fee) {
    return '距门店 $distance · 配送费 $fee';
  }

  @override
  String addressOutOfDeliveryRange(String distance, String maxDistance) {
    return '该位置距离 $distance，超出配送范围（最远 $maxDistance）。';
  }

  @override
  String mapOutOfDeliveryRange(String distance) {
    return '距离 $distance，超出配送范围';
  }

  @override
  String get mapPinHint => '移动地图，将图钉准确放在送货地点';

  @override
  String get mapMyCurrentLocation => '我的当前位置';

  @override
  String get mapConfirmLocation => '确认位置';

  @override
  String get mapSetDeliveryLocation => '设置送货位置';

  @override
  String get myOrdersLoadFailed => '无法加载你的订单';

  @override
  String get myOrdersEmptyTitle => '暂无订单';

  @override
  String get myOrdersEmptySubtitle => '开始购物，你的订单将显示在这里';

  @override
  String get orderStatusReceivedLong => '已收到订单';

  @override
  String get orderStatusPreparingInWarehouse => '仓库正在备货';

  @override
  String get orderStatusAwaitingDriver => '等待配送骑手';

  @override
  String get orderStatusReadyShort => '已备好';

  @override
  String get orderStepReceived => '已接单';

  @override
  String get orderStepPreparing => '备货中';

  @override
  String orderCardStatusLine(String status) {
    return '订单状态：$status';
  }

  @override
  String get orderCardTrackOnMap => '在地图上跟踪订单';

  @override
  String trackingTitle(String id) {
    return '跟踪订单 #$id';
  }

  @override
  String get trackingYourAddressMarker => '你的地址';

  @override
  String get trackingDriverMarker => '配送骑手';

  @override
  String get trackingOrderDelivered => '你的订单已送达，祝你用餐愉快！';

  @override
  String get trackingDriverLocationLive => '骑手位置在地图上实时更新';

  @override
  String get trackingDriverLocating => '正在定位骑手… 稍后将显示在地图上';

  @override
  String authAccountCreatedConfirmEmail(String email) {
    return '账户已创建！我们已向 $email 发送确认链接。请确认邮箱后登录。';
  }

  @override
  String get authFullNameLabel => '全名';

  @override
  String get authEnterFullName => '请输入你的全名';

  @override
  String get authEnterValidEmail => '请输入有效的电子邮箱地址';

  @override
  String get authEnterValidEgyptianPhone => '请输入有效的埃及手机号码（11 位）';

  @override
  String get authPassword => '密码';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authPasswordMinLength => '密码至少需要 6 个字符';

  @override
  String get authSignInButton => '登录';

  @override
  String get authCreateAccountButton => '创建账户';

  @override
  String get authNoAccountPrompt => '还没有账户？';

  @override
  String get authHaveAccountPrompt => '已有账户？';

  @override
  String get authCreateNewAccountLink => '创建新账户';

  @override
  String get authSignInLink => '登录';

  @override
  String get authWelcomeBack => '欢迎回来！';

  @override
  String get authJoinSafeerMarket => '加入萨菲尔市场';

  @override
  String get authSignInSubtitle => '登录以完成你的订单';

  @override
  String get authSignUpSubtitle => '创建账户，畅享萨菲尔优惠';

  @override
  String get authNewAccountTab => '新账户';

  @override
  String get authEmailAlreadyRegistered => '该电子邮箱已注册';

  @override
  String authAccountCreatedProfileSaveFailed(String error) {
    return '账户已创建，但无法保存你的信息：$error';
  }

  @override
  String get authInvalidCredentials => '电子邮箱或密码错误';

  @override
  String get authEmailNotConfirmed => '请先通过我们发送给你的邮件确认电子邮箱';

  @override
  String get authWeakPassword => '密码太弱，请至少使用 6 个字符';

  @override
  String get authTooManyAttempts => '尝试次数过多，请稍后再试';

  @override
  String get editProfileSignInPrompt => '登录后编辑你的信息';

  @override
  String get profileSavedSuccessfully => '你的信息已保存成功';

  @override
  String get profileFullNameLabel => '全名';

  @override
  String get profileEnterFullName => '请输入你的全名';

  @override
  String get profileEnterValidPhone => '请输入有效的埃及手机号码';

  @override
  String get profileSaveChanges => '保存更改';

  @override
  String profileSaveFailed(String error) {
    return '无法保存你的信息：$error';
  }

  @override
  String notificationTokenSaveFailed(String error) {
    return '无法保存通知令牌：$error';
  }

  @override
  String featureComingSoon(String feature) {
    return '$feature即将推出';
  }

  @override
  String rewardsPointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 积分',
    );
    return '$_temp0';
  }

  @override
  String get rewardsGamesTitle => '游戏';

  @override
  String get rewardsGamesSubtitle => '玩游戏，赚取积分';

  @override
  String gameLockedUntilTomorrow(String countdown) {
    return '$countdown 后可再玩';
  }

  @override
  String get scratchCardTitle => '刮刮卡 — 刮开赢积分';

  @override
  String get scratchCardSubtitle => '刮开涂层即可赢取积分';

  @override
  String get scratchCardHint => '刮开银色图层查看奖励';

  @override
  String scratchWonPoints(String points) {
    return '你赢了 $points 积分！';
  }

  @override
  String get scratchBetterLuck => '祝下次好运';

  @override
  String get luckyChestTitle => '每日幸运宝箱 — 打开你的宝箱';

  @override
  String get luckyChestSubtitle => '打开宝箱，最高赢取 10 积分';

  @override
  String get luckyChestHint => '点击宝箱打开并查看奖励';

  @override
  String get luckyChestTapToOpen => '点击打开宝箱';

  @override
  String get luckyChestOpened => '今天的宝箱已打开';

  @override
  String luckyChestWonPoints(String points) {
    return '你从宝箱中赢得 $points 积分！';
  }

  @override
  String get rewardsWheelCardSubtitle => '转动转盘，最高赢取 100 积分';

  @override
  String get rewardsPuzzleCardSubtitle => '拼好标志，赢取 50 积分';

  @override
  String get loyaltyCurrentBalance => '当前积分余额';

  @override
  String get loyaltySignInToSeePoints => '登录后查看你的积分';

  @override
  String get loyaltyLoadFailedRetry => '加载失败 — 重试';

  @override
  String loyaltyPointsLoadFailed(String error) {
    return '无法加载积分：$error';
  }

  @override
  String loyaltyPointsUpdateFailed(String error) {
    return '无法更新积分：$error';
  }

  @override
  String get wheelPrizeTryAgain => '再试一次';

  @override
  String get wheelSpinCollectLoyaltyPoints => '转动转盘，赚取积分';

  @override
  String get wheelSignInToPlay => '登录后即可游戏';

  @override
  String get wheelSpinning => '转盘转动中...';

  @override
  String get wheelSpin => '转动转盘';

  @override
  String get wheelCongrats => '恭喜！';

  @override
  String get wheelTryAgainTitle => '再试一次';

  @override
  String wheelWonPrize(String prize) {
    return '你赢得了 $prize，已添加到你的积分余额。';
  }

  @override
  String get wheelNoPointsThisTime => '这次没有赢得积分，下次转动祝你好运！';

  @override
  String puzzleMoves(String moves) {
    return '步数：$moves';
  }

  @override
  String puzzlePrize(String points) {
    return '奖励：$points 积分';
  }

  @override
  String puzzleSavePoints(String points) {
    return '保存 $points 积分';
  }

  @override
  String get puzzleShuffle => '打乱拼图';

  @override
  String get puzzleOutOfMoves => '下次好运！您已用完所有可用步数。';

  @override
  String get puzzleCongrats => '恭喜！';

  @override
  String puzzleEarnedPoints(String points) {
    return '你获得了 $points 积分 🎉';
  }

  @override
  String get puzzlePointsAddedToBalance => '积分已添加到你的积分余额。';

  @override
  String puzzleGuestEarnedPoints(String points) {
    return '恭喜！你获得了 $points 积分 🎉';
  }

  @override
  String get puzzleSignInToAddPoints => '登录后我们会将积分添加到你的余额。';

  @override
  String get puzzleGoalTitle => '拼好标志';

  @override
  String get puzzleGoalDescription => '滑动空格旁的拼块，直到标志与图片一致';

  @override
  String get unitCarton => '箱';

  @override
  String get unitBox => '盒';

  @override
  String get unitBag => '袋';

  @override
  String get unitPack => '包';

  @override
  String get cartTitle => '购物车';

  @override
  String get clearCart => '清空购物车';

  @override
  String cartSubtotalWithCount(String count) {
    return '小计（$count 件商品）';
  }

  @override
  String get cartDeliveryFeeNextStep => '配送费将在下一步计算';

  @override
  String get cartContinueOrder => '去结算';

  @override
  String get cartEmptySubtitle => '添加你喜欢的商品，开始购物吧';

  @override
  String get cartSaveDeliveryFeesTitle => '节省配送费！💡';

  @override
  String get cartPrimeUpsellSubtitle => '仅需 90 EGP 即可订阅 Safeer Prime。';

  @override
  String cartAddedWeightOfProduct(String weight, String product) {
    return '已将 $weight $product 加入购物车';
  }

  @override
  String cartAddedProduct(String product) {
    return '已将 $product 加入购物车';
  }

  @override
  String get viewCart => '查看购物车';

  @override
  String get removeFromCart => '从购物车移除';

  @override
  String get chooseWeight => '选择重量';

  @override
  String pricePerKilo(String price) {
    return '$price/公斤';
  }

  @override
  String get weightPickerPrice => '价格';

  @override
  String get updateWeight => '更新重量';

  @override
  String get homeNotificationsTooltip => '通知';

  @override
  String get homeSearchHint => '搜索商品或品牌';

  @override
  String homeDeliveringTo(String city) {
    return '配送至 · $city';
  }

  @override
  String get homeChooseYourAddress => '选择你的地址';

  @override
  String get homeMyAccountTooltip => '我的账户';

  @override
  String get homeSignedInSuccessfully => '登录成功';

  @override
  String get homeDeliveryEta => '30 - 45 分钟送达';

  @override
  String get quickActionLatestProducts => '最新商品';

  @override
  String get quickActionOffers => '优惠';

  @override
  String get quickActionPlayAndWin => '玩并赢';

  @override
  String get promoEndlessOffersTitle => '萨菲尔优惠永不停歇';

  @override
  String get promoEndlessOffersSubtitle => '数百种商品每日折扣';

  @override
  String get promoSavingsStoreTitle => '萨菲尔……省钱好去处';

  @override
  String get promoSavingsStoreSubtitle => '全家所需，天天低价';

  @override
  String get promoOpeningDiscountsTitle => '开业折扣';

  @override
  String get promoOpeningDiscountsSubtitle => '首单最高立减 30%';

  @override
  String get promoFreeDeliveryTitle => '免费配送';

  @override
  String get promoFreeDeliverySubtitle => '订单满 300 EGP';

  @override
  String offerDiscountPercent(String percent) {
    return '立减 $percent%';
  }

  @override
  String get offerBadge => '优惠';

  @override
  String get favoritesSignInPrompt => '登录后收藏你喜欢的商品';

  @override
  String get favoritesLoadFailed => '无法加载收藏';

  @override
  String get favoritesEmptyTitle => '还没有收藏的商品';

  @override
  String get favoritesEmptySubtitle => '点击任意商品上的 ♡ 即可收藏到这里';

  @override
  String get favoritesUpdateFailed => '无法更新收藏，请重试';

  @override
  String get removeFromFavorites => '取消收藏';

  @override
  String get addToFavorites => '加入收藏';

  @override
  String get magazinesLoadFailed => '无法加载杂志';

  @override
  String get noMagazinesCurrently => '暂无杂志';

  @override
  String get magazineNoPdf => '此杂志没有 PDF 文件';

  @override
  String get magazineOpenFailed => '无法打开杂志，请稍后重试。';

  @override
  String get magazinePreviousPage => '上一页';

  @override
  String get magazineNextPage => '下一页';

  @override
  String magazinePageOf(String page, String count) {
    return '第 $page 页，共 $count 页';
  }

  @override
  String get authWelcomeTitle => '欢迎来到萨菲尔市场';

  @override
  String get authWelcomeSubtitle => '几秒钟即可登录或创建账户';

  @override
  String get authContinueWithGoogle => '使用 Google 继续';

  @override
  String get authContinueWithPhone => '使用手机号继续';

  @override
  String get authContinueWithEmail => '使用电子邮件继续';

  @override
  String get authOr => '或';

  @override
  String get authOtherSignInOptions => '其他登录方式';

  @override
  String get authTermsNotice => '继续即表示你同意我们的隐私政策和条款';

  @override
  String get authGoogleFailed => '无法使用 Google 登录，请重试';

  @override
  String get authProviderUnavailable => '此登录方式暂不可用';

  @override
  String get authOtpInvalid => '验证码错误或已过期';

  @override
  String get authSmsSendFailed => '无法发送验证短信，请检查号码后重试';

  @override
  String get authPhoneSheetTitle => '使用手机号登录';

  @override
  String get authPhoneSheetSubtitle => '我们将通过短信向你发送 6 位验证码';

  @override
  String get authSendCode => '发送验证码';

  @override
  String get authEnterCodeTitle => '输入验证码';

  @override
  String authCodeSentTo(String phone) {
    return '我们已通过短信将验证码发送至 $phone';
  }

  @override
  String get authVerifyCode => '验证';

  @override
  String get authEnterSixDigitCode => '请输入 6 位验证码';

  @override
  String get authResendCode => '重新发送验证码';

  @override
  String authResendCodeIn(String seconds) {
    return '$seconds 秒后可重新发送';
  }

  @override
  String get authChangeNumber => '更换号码';

  @override
  String get authCodeResent => '新验证码已发送';

  @override
  String get productNoImageBadge => '无图片';

  @override
  String newProductsMissingImageCount(String count) {
    return '新品（无图片：$count）';
  }

  @override
  String missingImageCountBadge(String count) {
    return '无图片：$count';
  }

  @override
  String get productImageSaveBlocked =>
      '图片已上传，但未保存到商品：没有编辑商品的权限。请检查 Supabase 中的管理员权限。';

  @override
  String get authPhoneLoginDisabled => '手机号登录暂不可用，请使用 Google 或电子邮件';

  @override
  String get onboardingLanguageTitle => '选择语言';

  @override
  String get onboardingLanguageSubtitle => '您可以随时在设置中更改';

  @override
  String get onboardingAppearanceTitle => '选择应用外观';

  @override
  String get onboardingAppearanceSubtitle => '浅色、深色或跟随设备';

  @override
  String get onboardingAccountTitle => '登录以获得完整体验';

  @override
  String get onboardingAccountSubtitle => '下单、跟踪订单，并保存地址和收藏';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingSignInOrRegister => '登录或注册';

  @override
  String get onboardingBrowseFirst => '先逛逛';

  @override
  String get appearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get settingsAccountSection => '账户';

  @override
  String get guestSignInTitle => '登录以继续';

  @override
  String get guestCartMessage => '登录或注册后即可将商品加入购物车并下单。';

  @override
  String get guestProfileMessage => '登录后可查看您的资料、订单、地址和收藏。';

  @override
  String get notNow => '以后再说';

  @override
  String get unitSet => '套';

  @override
  String unitBoxOf(String count) {
    return '$count件/盒';
  }

  @override
  String get paywallSignInToSubscribe => '登录以订阅萨菲尔套餐';

  @override
  String get paymentChooseMethod => '选择支付方式';

  @override
  String get paymentMethodCard => '银行卡（Visa / Mastercard / Meeza）';

  @override
  String get paymentMethodWallet => '手机钱包（Vodafone Cash 等）';

  @override
  String get paymentWalletPhoneLabel => '钱包号码';

  @override
  String get paymentWalletPhoneInvalid => '请输入以 01 开头的有效钱包号码';

  @override
  String get paymentContinue => '继续';

  @override
  String get paymentStartFailed => '无法发起支付，请重试。';

  @override
  String get paymentMethodUnavailable => '该支付方式暂不可用';

  @override
  String get paymentPageOpenFailed => '无法打开支付页面';

  @override
  String get paymentVerifying => '正在确认支付…';

  @override
  String get paymentFailedMessage => '支付未完成，您可以重试。';

  @override
  String get paymentStillProcessing => '支付确认尚未完成。你可以在“我的订单”中查看订单状态。';

  @override
  String get subscriptionActivatedTitle => '订阅已成功开通 👑';

  @override
  String subscriptionActiveUntil(String plan, String date) {
    return '您的 $plan 套餐有效期至 $date';
  }

  @override
  String get subscriptionContinueShopping => '继续购物';

  @override
  String get redeemPoints => '兑换积分';

  @override
  String get redeemQrTitle => '向收银员出示此码';

  @override
  String get redeemQrSubtitle => '每 50 积分 = 优惠 1 埃镑。优惠生效后此码会自动关闭。';

  @override
  String get redeemSuccess => '优惠已成功使用';

  @override
  String get scanCustomerCode => '扫描顾客码';

  @override
  String get scanCustomerHint => '将相机对准顾客的二维码';

  @override
  String get scanInvalidCode => '这不是萨菲尔超市的顾客码';

  @override
  String scanCameraFailed(String error) {
    return '无法启动相机：$error';
  }

  @override
  String get redeemInsufficientPoints => '积分不足以抵扣 1 埃镑';

  @override
  String get redeemNotAllowed => '此账户无权兑换积分';

  @override
  String get redeemCustomerNotFound => '未找到该顾客';

  @override
  String redeemFailed(String error) {
    return '无法兑换积分：$error';
  }

  @override
  String get cashierRedeemTitle => '兑换会员积分';

  @override
  String get cashierCustomer => '顾客';

  @override
  String get cashierCurrentBalance => '当前积分';

  @override
  String get cashierPointsToDeduct => '扣除积分';

  @override
  String get cashierDiscount => '优惠金额';

  @override
  String get cashierRemainingPoints => '扣除后积分';

  @override
  String get cashierBarcodeHint => '在收银台扫描此条码，然后确认';

  @override
  String get confirmPointsDeduction => '确认扣除积分';

  @override
  String cashierRedeemDone(String points, String amount) {
    return '已兑换 $points 积分（优惠 $amount）';
  }

  @override
  String get phoneOrdersTitle => '电话订单 / 查找顾客';

  @override
  String get phoneOrderOpen => '电话订单';

  @override
  String get phoneOrderSearchHint => '按电话号码或顾客姓名搜索...';

  @override
  String get phoneOrderNewCustomer => '+ 新顾客';

  @override
  String get phoneOrderTypeToSearch => '输入电话号码或姓名进行搜索';

  @override
  String get phoneOrderNoCustomers => '没有匹配的顾客，请添加为新顾客。';

  @override
  String get phoneOrderAppCustomer => '应用用户';

  @override
  String get phoneOrderPosCustomer => '收银顾客';

  @override
  String get phoneOrderNoAddress => '没有保存的地址';

  @override
  String get phoneOrderChangeCustomer => '更换顾客';

  @override
  String get phoneOrderCustomerName => '顾客姓名';

  @override
  String get phoneOrderCustomerPhone => '电话号码';

  @override
  String get phoneOrderCustomerAddress => '地址';

  @override
  String get phoneOrderCustomerZone => '区域';

  @override
  String get phoneOrderSaveCustomer => '保存顾客';

  @override
  String get phoneOrderNameRequired => '请输入顾客姓名';

  @override
  String get phoneOrderPhoneInvalid => '请输入有效的埃及手机号（01XXXXXXXXX）';

  @override
  String get phoneOrderProductSearchHint => '按商品名称或条码搜索...';

  @override
  String get phoneOrderSearchProductsPrompt => '按名称或条形码搜索商品';

  @override
  String get phoneOrderNoProducts => '没有匹配的商品';

  @override
  String get phoneOrderCartTitle => '顾客购物车';

  @override
  String get phoneOrderCartEmpty => '尚未添加商品';

  @override
  String get phoneOrderItemsTotal => '商品合计';

  @override
  String get phoneOrderTotal => '总计';

  @override
  String get phoneOrderFreeDelivery => '免费';

  @override
  String get phoneOrderConfirm => '确认并下单';

  @override
  String phoneOrderPlaced(String id) {
    return '订单 #$id 已下单';
  }

  @override
  String phoneOrderFailed(String error) {
    return '无法下单：$error';
  }

  @override
  String phoneOrderSearchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String get phoneOrderNotAllowed => '此账户无权接收电话订单';

  @override
  String get phoneOrderBadge => '电话';

  @override
  String phoneOrderSetupMissing(String function) {
    return '数据库函数 $function 不存在。请在 Supabase SQL Editor 中运行 supabase/migrations/20261111010000_phone_orders.sql。';
  }

  @override
  String get adminToggleMenu => '显示/隐藏菜单';

  @override
  String get adminResizeColumn => '拖动以调整列宽';

  @override
  String get phoneOrderShowCart => '显示购物车和配送';

  @override
  String get phoneOrderHideCart => '隐藏购物车';

  @override
  String get driverDeliveryAddress => '送货地址';

  @override
  String get driverNavigateViaMap => '通过地图导航';

  @override
  String get mapSearchHint => '搜索区域或街道...';

  @override
  String get mapSearchNoResults => '未找到地点';

  @override
  String mapSearchFailed(String error) {
    return '无法搜索地点：$error';
  }

  @override
  String get mapSearchClear => '清除搜索';

  @override
  String get supportLiveChatSubtitle => '在应用内给我们留言，我们的团队会立即回复';

  @override
  String get supportSignInMessage => '登录后即可与客服聊天。';

  @override
  String supportLaunchFailed(String phone) {
    return '无法打开应用。您可以拨打 $phone 联系我们';
  }

  @override
  String get supportChatTitle => '客户服务';

  @override
  String get supportChatSubtitle => 'Safeer Market 团队在这里为您解答';

  @override
  String get supportChatWelcome => '欢迎！请写下您的问题，客服团队会尽快回复您。';

  @override
  String get supportMessageHint => '输入消息...';

  @override
  String supportLoadFailed(String error) {
    return '无法加载聊天：$error';
  }

  @override
  String get supportSetupMissing =>
      '实时聊天尚未配置。请在 Supabase SQL Editor 中运行 supabase/migrations/20261114210000_support_chat.sql。';

  @override
  String get supportNotAllowed => '您无权访问此聊天';

  @override
  String supportRequestFailed(String error) {
    return '无法完成请求：$error';
  }

  @override
  String get supportCenterTitle => '投诉与聊天';

  @override
  String get supportNoChats => '当前没有进行中的聊天';

  @override
  String get supportSelectChat => '从列表中选择一个聊天以回复客户';

  @override
  String get supportNoMessagesYet => '此聊天中还没有消息';

  @override
  String get supportReplyHint => '输入给客户的回复...';

  @override
  String get supportLatestOrders => '最近订单';

  @override
  String supportLatestOrdersTitle(String name) {
    return '$name 的最近订单';
  }

  @override
  String get supportNoOrders => '该客户没有订单';

  @override
  String supportNewMessageToast(String name, String message) {
    return '来自 $name 的新消息：$message';
  }

  @override
  String get supportOpenChat => '打开聊天';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmptySubtitle => 'Safeer Market 有新优惠或新杂志时，我们会第一时间通知您';

  @override
  String notificationsLoadFailed(String error) {
    return '无法加载通知：$error';
  }

  @override
  String get notificationsSetupMissing =>
      '通知尚未配置。请在 Supabase SQL Editor 中运行 supabase/migrations/20261114220000_app_notifications.sql。';

  @override
  String get notificationsNotAllowed => '只有管理员账号可以发送和删除通知';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String get notificationTypeGeneral => '通用';

  @override
  String get notificationTypePromo => '优惠折扣';

  @override
  String get notificationTypeMagazine => '新杂志';

  @override
  String get notificationTypeOrder => '您的订单';

  @override
  String get notificationTypeSupportChat => '客服聊天';

  @override
  String get adminSendNotifications => '发送通知';

  @override
  String get adminNotificationFormSubtitle => '立即显示在所有客户的应用中';

  @override
  String get adminNotificationTitleLabel => '通知标题';

  @override
  String get adminNotificationTitleHint => '例如：本月优惠杂志上线啦！🔥';

  @override
  String get adminNotificationTitleRequired => '请输入通知标题';

  @override
  String get adminNotificationBodyLabel => '通知内容';

  @override
  String get adminNotificationBodyHint => '例如：浏览 Safeer Market 最新独家优惠和折扣';

  @override
  String get adminNotificationBodyRequired => '请输入通知内容';

  @override
  String get adminNotificationTypeLabel => '通知类型';

  @override
  String get adminNotificationImageLabel => '优惠图片链接（可选）';

  @override
  String get adminNotificationImageInvalid => '请输入以 https:// 开头的有效链接';

  @override
  String get adminSendNotificationButton => '发送给所有客户';

  @override
  String get adminNotificationSent => '通知已发送给所有客户';

  @override
  String adminNotificationSendFailed(String error) {
    return '无法发送通知：$error';
  }

  @override
  String get adminNotificationsHistory => '已发送的通知';

  @override
  String get adminNoNotificationsSent => '尚未发送任何通知';

  @override
  String get adminDeleteNotificationTitle => '删除通知';

  @override
  String adminDeleteNotificationConfirm(String title) {
    return '删除通知“$title”？它将从客户的应用中消失。';
  }

  @override
  String adminDeleteNotificationFailed(String error) {
    return '无法删除通知：$error';
  }

  @override
  String get orderCardShowDetails => '查看详情';

  @override
  String get orderCardHideDetails => '收起详情';

  @override
  String get orderCardItemsTitle => '订单商品';

  @override
  String get orderCardItemsFailed => '无法加载订单商品';

  @override
  String get orderCardNoItems => '此订单没有商品记录';

  @override
  String get orderCardCancelledNote => '此订单已取消';

  @override
  String get cancelOrder => '取消订单';

  @override
  String get cancelOrderConfirmTitle => '确定要取消订单吗？';

  @override
  String get cancelOrderReasonPrompt => '请选择取消原因：';

  @override
  String get cancelOrderDismiss => '返回';

  @override
  String get cancelOrderConfirm => '确认取消';

  @override
  String get cancelReasonDeliveryDelay => '配送延迟';

  @override
  String get cancelReasonOrderedByMistake => '误下单';

  @override
  String get cancelReasonChangedMind => '改变主意';

  @override
  String get cancelReasonOther => '其他原因';

  @override
  String cancellationReasonLine(String reason) {
    return '取消原因：$reason';
  }

  @override
  String get orderCancelledSuccess => '订单已成功取消';

  @override
  String get orderCancelTooLate => '订单已就绪或正在配送，无法取消';

  @override
  String get orderCancelSetupMissing =>
      '取消订单功能尚未配置。请在 Supabase SQL Editor 中运行 supabase/migrations/20261114240000_customer_cancel_order.sql。';

  @override
  String orderCancelFailed(String error) {
    return '无法取消订单：$error';
  }

  @override
  String get adminMenuReceiveOrders => '接单';

  @override
  String get adminMenuOrderStatus => '订单状态';

  @override
  String get adminStatusDelayedShort => '延迟';

  @override
  String get adminStatusCancelledShort => '已取消';

  @override
  String get adminResendNotification => '重新发送';

  @override
  String get adminResendFillForm => '填入表单';

  @override
  String get adminResendNotificationTitle => '重新发送此通知？';

  @override
  String adminResendNotificationConfirm(String title) {
    return '通知“$title”将再次发送给所有客户。';
  }

  @override
  String get adminNotificationSearchHint => '按标题搜索';

  @override
  String get adminNotificationFilterByDate => '按日期筛选';

  @override
  String get adminNotificationFilterByType => '按类型筛选';

  @override
  String get adminNotificationClearDateFilter => '清除日期筛选';

  @override
  String get adminSelectCustomerFirst => '请先选择客户';
}
