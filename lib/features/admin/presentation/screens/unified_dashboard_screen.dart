import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/network/live_query.dart';
import '../../../../core/network/realtime_session.dart';
import '../../../../core/notifications/order_push_dispatcher.dart';
import '../../../../core/notifications/system_alerts_service.dart';
import '../../../../core/providers/settings_providers.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/resizable_columns.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/barcode_scan_icon.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../home/presentation/widgets/product_thumb.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/order_prep_timer.dart';
import '../../domain/staff_session.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../providers/admin_providers.dart';
import '../providers/order_alternatives_providers.dart';
import '../providers/staff_session_providers.dart';
import '../providers/system_admin_providers.dart';
import '../../../support/domain/entities/support_chat.dart';
import '../../../support/presentation/providers/support_providers.dart';
import '../providers/phone_order_providers.dart';
import '../widgets/order_alternatives_panel.dart';
import '../widgets/customer_order_rating_card.dart';
import '../widgets/order_detail_panels.dart';
import '../widgets/order_status_widgets.dart';
import '../widgets/phone_order_column.dart';
import '../widgets/prep_receipt_sheet.dart';
import '../widgets/send_alternatives_sheet.dart';
import '../../../orders/domain/order_editability.dart';
import '../../../orders/presentation/widgets/edit_order_sheet.dart';
import 'admin_order_search_view.dart';
import 'admin_reports_view.dart';
import 'admin_system_view.dart';
import 'staff_login_screen.dart';

export '../widgets/order_detail_panels.dart' show DashboardStatusBadge;
import 'admin_magazines_view.dart';
import 'admin_notifications_view.dart';
import 'admin_pending_subscriptions_view.dart';
import 'admin_support_view.dart';

// ==========================================
// 1. المزودات (Providers)
// ==========================================

/// Sidebar entries, as values of [adminMenuProvider].
abstract final class AdminMenu {
  static const receiveOrders = 0;
  static const orderStatus = 1;
  static const products = 2;
  static const staff = 3;
  static const reports = 4;
  static const magazines = 5;
  static const support = 6;
  static const notifications = 7;
  static const pendingSubscriptions = 8;
  static const search = 9;

  /// The five main sections, shown as tabs under the AppBar. Everything
  /// else lives in the side menu ([secondary]).
  static const tabs = [receiveOrders, orderStatus, search, reports, staff];

  /// Secondary sections, reachable from the side menu / drawer.
  static const secondary = [
    products,
    magazines,
    support,
    notifications,
    pendingSubscriptions,
  ];
}


final localAdminModeProvider = StateProvider<bool>((ref) => false);
final adminMenuProvider = StateProvider<int>((ref) => AdminMenu.receiveOrders);

/// Wide screens: whether the navigation sidebar is open (the AppBar's ☰).
final adminSidebarVisibleProvider = StateProvider<bool>((ref) => true);
final orderStatusFilterProvider = StateProvider<String?>((ref) => null);
final selectedOrderIdProvider = StateProvider<String?>((ref) => null);
final orderPrepChecklistProvider = StateProvider<Set<String>>((ref) => {});

final adminProductSearchProvider = StateProvider<String>((ref) => '');
final adminProductFilterProvider = StateProvider<int>((ref) => 0);

/// Live admin/taker orders: HTTP `.select()` first, Realtime in the background.
/// WebSocket / token failures never become a dead error screen — the last
/// loaded list stays visible while we refetch and resubscribe.
final liveOrdersProvider = AsyncNotifierProvider.autoDispose<LiveOrdersNotifier,
    List<Map<String, dynamic>>>(LiveOrdersNotifier.new);

class LiveOrdersNotifier
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  LiveQuery<List<Map<String, dynamic>>>? _live;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final client = Supabase.instance.client;

    Future<List<Map<String, dynamic>>> fetch() async {
      final rows = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    }

    final live = LiveQuery<List<Map<String, dynamic>>>(
      fetch: fetch,
      onReconnect: () => ensureRealtimeAuth(client),
      disconnectedPollInterval: const Duration(seconds: 20),
      subscribe: (onData, onError) {
        final subscription = client
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .listen(
              onData,
              onError: onError,
              onDone: () => onError(StateError('orders Realtime closed')),
              cancelOnError: false,
            );
        return subscription.cancel;
      },
    );
    _live = live;
    ref.onDispose(live.dispose);

    live.addListener(() {
      if (!live.hasValue) return;
      // Always AsyncData once we have rows — never AsyncError for sockets.
      state = AsyncData(live.value ?? const []);
    });

    await live.start();
    if (live.hasValue) return live.value ?? const [];
    // First HTTP load failed and Realtime has not delivered yet.
    throw live.fatalError ?? StateError('Could not load orders');
  }

  Future<void> refresh() => _live?.refresh() ?? Future.value();
}

/// Test / preview override: a fixed orders list with no Realtime socket.
class FixedLiveOrdersNotifier extends LiveOrdersNotifier {
  FixedLiveOrdersNotifier(this.orders);

  final List<Map<String, dynamic>> orders;

  @override
  Future<List<Map<String, dynamic>>> build() async => orders;
}

/// Names and phones by user id, for ids joined with ','.
final orderCustomersProvider = FutureProvider.autoDispose
    .family<Map<String, OrderCustomer>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return const {};
  return ref
      .watch(adminOrdersRepositoryProvider)
      .fetchCustomers(idsKey.split(','));
});

/// The customer of every live order, from `profiles` (the orders stream
/// can't embed it). Read again only when the set of customers changes, not
/// on every status update.
final liveOrderCustomersProvider =
    Provider.autoDispose<Map<String, OrderCustomer>>((ref) {
  final orders = ref.watch(liveOrdersProvider).valueOrNull ?? const [];
  final ids = {
    for (final order in orders)
      if (order['user_id'] != null) order['user_id'].toString(),
  }.toList()
    ..sort();
  return ref.watch(orderCustomersProvider(ids.join(','))).valueOrNull ??
      const {};
});

/// The order's own customer name and phone (phone orders store them), else
/// the customer's profile.
({String? name, String? phone}) orderCustomerOf(
  WidgetRef ref,
  Map<String, dynamic> order,
) {
  String? text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  final profile =
      ref.watch(liveOrderCustomersProvider)[order['user_id']?.toString()];
  return (
    name: text(order['customer_name']) ?? profile?.fullName,
    phone: text(order['customer_phone']) ?? profile?.phone,
  );
}

final activeStaffProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await Supabase.instance.client
      .from('staff')
      .select('id, name, role, phone')
      .order('created_at');
  return List<Map<String, dynamic>>.from(res);
});

final adminProductsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(adminProductSearchProvider);
  final filter = ref.watch(adminProductFilterProvider);

  // تقسيم كلمة البحث لكي نبحث بمرونة تامة عن أي كلمات مقطعة
  final words =
      query.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final firstPart = words.isNotEmpty ? words.first : '';

  var request = Supabase.instance.client
      .from('products')
      .select(
          'id, barcode, name, price, image_url, is_active, stock_quantity');

  // نسحب كمية كافية بناءً على أول كلمة لتشمل أي منتجات مشابهة
  if (firstPart.isNotEmpty) request = request.ilike('name', '%$firstPart%');
  if (filter == 1) request = request.eq('is_active', true);
  if (filter == 2) request = request.eq('is_active', false);

  final response = await request.limit(300);
  final allProducts = List<Map<String, dynamic>>.from(response);

  // إذا لم يكن هناك كلمات للبحث، نعرض المنتجات كما هي
  if (words.isEmpty) return allProducts;

  // هنا نقوم بالفلترة الذكية: نعرض المنتج فقط إذا كانت جميع الكلمات المقطعة موجودة في اسمه بغض النظر عن الترتيب
  return allProducts.where((product) {
    final name = (product['name'] as String? ?? '').toLowerCase();
    return words.every((word) => name.contains(word.toLowerCase()));
  }).toList();
});

// ==========================================
// 2. الشاشة المركزية الموحدة (متجاوبة مع الموبايل)
// ==========================================
class UnifiedDashboardScreen extends ConsumerStatefulWidget {
  const UnifiedDashboardScreen({super.key});
  @override
  ConsumerState<UnifiedDashboardScreen> createState() =>
      _UnifiedDashboardScreenState();
}

class _UnifiedDashboardScreenState
    extends ConsumerState<UnifiedDashboardScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _pendingCount = 0;

  /// Orders placed on this device via «تلقي الطلبات»; they must not ring
  /// the local alarm (other devices still hear them).
  final Set<String> _locallyPlacedOrderIds = {};

  @override
  void initState() {
    super.initState();
    // Capture Esc at the platform level so GoRouter / the previous
    // «المزيد» route never see it while this dashboard is mounted.
    HardwareKeyboard.instance.addHandler(_onHardwareEscape);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareEscape);
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Always consumes Esc while the admin dashboard is alive.
  bool _onHardwareEscape(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (!mounted) return false;
    _handleEscape();
    return true;
  }

  /// Close inner overlays / step back inside the dashboard only.
  /// Never pops the `/admin` route (exit is the AppBar arrow only).
  void _handleEscape() {
    if (!mounted) return;

    // Close the mobile drawer if open.
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
      return;
    }

    // Pop dialogs / sheets / menus only — leave page routes alone.
    final rootNav = Navigator.of(context, rootNavigator: true);
    var closedOverlay = false;
    rootNav.popUntil((route) {
      if (route is PopupRoute) {
        closedOverlay = true;
        return false;
      }
      return true;
    });
    if (closedOverlay) return;

    final activeMenu = ref.read(adminMenuProvider);
    final selectedId = ref.read(selectedOrderIdProvider);

    // Dismiss product search popup on تلقي الطلبات.
    if (activeMenu == AdminMenu.receiveOrders &&
        ref.read(phoneOrderSearchOpenProvider)) {
      ref.read(phoneOrderDismissSearchProvider.notifier).state++;
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    // Order status detail → list.
    if (activeMenu == AdminMenu.orderStatus && selectedId != null) {
      ref.read(selectedOrderIdProvider.notifier).state = null;
      return;
    }

    // Locked customer with empty cart → customer lookup.
    if (activeMenu == AdminMenu.receiveOrders) {
      final order = ref.read(phoneOrderControllerProvider);
      if (order.customer != null && order.lines.isEmpty) {
        ref.read(phoneOrderControllerProvider.notifier).clear();
      }
    }
    // Otherwise: stay on the dashboard main screen (no route pop).
  }

  void _handleAlarms(List<Map<String, dynamic>> orders) {
    // Drop ignored ids that are no longer pending so the set stays small.
    final pendingIds = {
      for (final order in orders)
        if (order['status'] == 'pending') '${order['id']}',
    };
    _locallyPlacedOrderIds.removeWhere((id) => !pendingIds.contains(id));

    final muted = ref.read(adminOrderAlarmMutedProvider);
    final placingPhoneOrder =
        ref.read(phoneOrderControllerProvider).submitting;
    final currentPending = pendingIds
        .where((id) => !_locallyPlacedOrderIds.contains(id))
        .length;

    // While this device is placing a phone order, skip the ring (the new
    // row often lands in the live feed before we know its id) but keep
    // _pendingCount so a real concurrent order still rings afterwards.
    if (placingPhoneOrder) return;

    if (!muted && currentPending > _pendingCount) {
      _audioPlayer.setReleaseMode(ReleaseMode.loop).then((_) {
        _audioPlayer.play(UrlSource(
            'https://jugdxfhmjakmzjvfltjv.supabase.co/storage/v1/object/public/product_images/new_order.mp3.ogg'));
      });
    } else if (muted || currentPending == 0) {
      _audioPlayer.stop();
    }
    _pendingCount = currentPending;
  }

  /// Unread count per open support chat when last seen; null until the
  /// first list arrives, which only sets the badges.
  Map<String, int>? _seenUnread;

  /// A customer's new support message: a toast that opens their chat,
  /// unless it is already open.
  void _handleSupportChats(List<SupportChat> chats) {
    if (!mounted) return;
    final previous = _seenUnread;
    _seenUnread = {for (final chat in chats) chat.id: chat.unreadAdminCount};
    if (previous == null) return;
    final viewing = ref.read(adminMenuProvider) == AdminMenu.support
        ? ref.read(selectedSupportChatIdProvider)
        : null;
    final chat = chats
        .where((chat) =>
            chat.id != viewing &&
            chat.unreadAdminCount > (previous[chat.id] ?? 0))
        .firstOrNull;
    if (chat == null) return;
    final l10n = AppLocalizations.of(context)!;
    final preview = l10n.supportNewMessageToast(
      chat.customerName ?? l10n.adminNoName,
      chat.lastMessage ?? '',
    );
    // OS / browser banner when the dashboard tab is in the background.
    unawaited(ref.read(systemAlertsServiceProvider).present(
          id: 'admin-support-${chat.id}-${chat.unreadAdminCount}',
          title: 'سفير ماركت',
          body: preview,
          route: AppRoutes.adminOrders,
        ));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('support-toast'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade900,
        duration: const Duration(seconds: 8),
        content: Row(children: [
          const Icon(Icons.forum_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        action: SnackBarAction(
          label: l10n.supportOpenChat,
          textColor: Colors.amberAccent,
          onPressed: () => _openSupportCenter(chatId: chat.id),
        ),
      ));
  }

  void _openSupportCenter({String? chatId}) {
    ref.read(selectedOrderIdProvider.notifier).state = null;
    ref.read(adminMenuProvider.notifier).state = AdminMenu.support;
    if (chatId != null) {
      ref.read(selectedSupportChatIdProvider.notifier).state = chatId;
    }
  }

  /// Wide enough for the receive-orders customer/products | cart split.
  static const receiveOrdersSplitMinWidth = 900.0;

  /// A phone order just placed: mute its local alarm, then open it.
  void _selectPlacedOrder(String orderId) {
    _locallyPlacedOrderIds.add(orderId);
    ref.read(orderPrepChecklistProvider.notifier).state = {};
    ref.read(selectedOrderIdProvider.notifier).state = orderId;
    ref.read(adminMenuProvider.notifier).state = AdminMenu.orderStatus;
  }

  void _showPinDialog() {
    final pinCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.admin_panel_settings, color: palette.accent),
          const SizedBox(width: 8),
          Text(l10n.adminSupervisorPermissions)
        ]),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              hintText: l10n.adminEnterPinHint,
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (pinCtrl.text == '1234') {
                ref.read(localAdminModeProvider.notifier).state = true;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.adminSupervisorModeEnabled),
                    backgroundColor: AppColors.success));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.adminInvalidPin),
                    backgroundColor: AppColors.secondary));
              }
            },
            child: Text(l10n.adminActivate),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffSession = ref.watch(staffSessionProvider);
    if (staffSession == null) {
      return const StaffLoginScreen();
    }

    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(localAdminModeProvider);
    final activeMenu = ref.watch(adminMenuProvider);
    final liveOrdersAsync = ref.watch(liveOrdersProvider);
    final userRole = ref.watch(userRoleProvider).value;
    final selectedId = ref.watch(selectedOrderIdProvider);

    final bool isSuperAdmin = userRole == UserRole.admin;
    // Staff session drives tabs; profile admin / PIN still unlocks sidebar tools.
    final bool showAdminFeatures =
        isAdmin || isSuperAdmin || staffSession.isAdmin || staffSession.isTaker;
    // System sidebar (products / magazines / notifications / …) is admin-only.
    final bool showSystemSidebar = staffSession.isAdmin;
    final palette = context.palette;

    // Role tabs ∩ granted menu permissions (see staffAllowedMenusProvider).
    final allowed = ref.watch(staffAllowedMenusProvider);
    final canOpenActive = allowed.contains(activeMenu) ||
        (showSystemSidebar &&
            StaffSession.systemSidebarMenus.contains(activeMenu));
    if (!canOpenActive) {
      final fallback =
          allowed.isNotEmpty ? allowed.first : AdminMenu.orderStatus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(adminMenuProvider.notifier).state = fallback;
      });
    }

    var supportUnread = 0;
    if (showAdminFeatures) {
      supportUnread = ref.watch(supportUnreadTotalProvider);
      // Keep the chats stream alive on every menu, mark customer messages
      // delivered (✓✓) as soon as the dashboard is online, and toast new ones.
      watchAdminSupportDelivered(ref);
      final chats = ref.watch(openSupportChatsProvider).valueOrNull;
      if (chats != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _handleSupportChats(chats));
      }
    } else {
      _seenUnread = null;
    }

    if (showAdminFeatures) {
      ref.listen(liveOrdersProvider, (previous, next) {
        next.whenData(_handleAlarms);
      });
    }

    return LayoutBuilder(builder: (context, constraints) {
      final bool isDesktop = constraints.maxWidth >= 850;
      final sidebarVisible = ref.watch(adminSidebarVisibleProvider);
      final splitReceiveOrders =
          constraints.maxWidth >= receiveOrdersSplitMinWidth;

      // At the start edge (the right, in Arabic): ☰ first, then back.
      final leading = <Widget>[
        if (showSystemSidebar)
          Builder(
            builder: (c) => IconButton(
              key: const Key('admin-menu-toggle'),
              tooltip: l10n.adminToggleMenu,
              icon: const Icon(Icons.menu),
              onPressed: () => isDesktop
                  ? ref.read(adminSidebarVisibleProvider.notifier).state =
                      !sidebarVisible
                  : Scaffold.of(c).openDrawer(),
            ),
          ),
        if (!isDesktop &&
            activeMenu == AdminMenu.orderStatus &&
            selectedId != null)
          BackButton(
              onPressed: () =>
                  ref.read(selectedOrderIdProvider.notifier).state = null)
        else if (Navigator.of(context).canPop())
          const BackButton(),
      ];

      Widget orderStatusBody() {
        // Never show RealtimeSubscribeException / WebSocket failures: keep
        // the last HTTP snapshot on screen (or a spinner on first load).
        final orders = liveOrdersAsync.valueOrNull ?? const <Map<String, dynamic>>[];
        final waitingFirstLoad =
            liveOrdersAsync.isLoading && liveOrdersAsync.valueOrNull == null;
        if (waitingFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }
        // Only a true first-load HTTP failure has no list yet.
        if (liveOrdersAsync.valueOrNull == null && liveOrdersAsync.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminErrorWithDetails('${liveOrdersAsync.error}')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(liveOrdersProvider.notifier).refresh(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }
        if (isDesktop) {
          return ResizableColumns(
            layoutId: 'admin-order-status',
            columns: [
              ResizableColumn(
                flex: 3,
                minWidth: 240,
                child: _OrdersList(
                  orders: orders,
                  userRole: userRole,
                  deliveryOnly: staffSession.deliveryOrdersOnly,
                ),
              ),
              ResizableColumn(
                flex: 7,
                minWidth: 360,
                child: _OrderDetailsView(
                    orders: orders,
                    userRole: userRole,
                    showAdminFeatures: showAdminFeatures,
                    isDesktop: true),
              ),
            ],
          );
        }
        if (selectedId == null) {
          return _OrdersList(
            orders: orders,
            userRole: userRole,
            deliveryOnly: staffSession.deliveryOrdersOnly,
          );
        }
        return _OrderDetailsView(
            orders: orders,
            userRole: userRole,
            showAdminFeatures: showAdminFeatures,
            isDesktop: false);
      }

      final canReceive =
          allowed.contains(AdminMenu.receiveOrders) && showAdminFeatures;
      final canSearch = allowed.contains(AdminMenu.search);
      final canReports = allowed.contains(AdminMenu.reports);
      final canSystem = allowed.contains(AdminMenu.staff);

      final Widget menuBody = switch (activeMenu) {
        AdminMenu.receiveOrders when canReceive => PhoneOrderColumn(
            key: const Key('admin-receive-orders'),
            splitLayout: splitReceiveOrders,
            onPlaced: _selectPlacedOrder,
            onOpenPendingAlternatives: () {
              ref.read(adminMenuProvider.notifier).state =
                  AdminMenu.orderStatus;
            },
          ),
        AdminMenu.orderStatus => orderStatusBody(),
        AdminMenu.products when showSystemSidebar => const _ProductsGridView(),
        AdminMenu.staff when canSystem => const AdminSystemView(),
        AdminMenu.search when canSearch => const AdminOrderSearchView(),
        AdminMenu.reports when canReports => const AdminReportsView(),
        AdminMenu.magazines when showSystemSidebar =>
          const AdminMagazinesView(),
        AdminMenu.support when showSystemSidebar => const AdminSupportView(),
        AdminMenu.notifications when showSystemSidebar =>
          const AdminNotificationsView(),
        AdminMenu.pendingSubscriptions when showSystemSidebar =>
          const AdminPendingSubscriptionsView(),
        _ => orderStatusBody(),
      };

      return PopScope(
        // System / gesture back must not leave لوحة التحكم والإدارة.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleEscape();
        },
        // Do NOT autofocus / steal keys from TextFields (تلقي الطلبات search).
        // Esc is already handled by HardwareKeyboard above; this only
        // catches bubbling Esc and ignores every other key.
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _handleEscape();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Scaffold(
        backgroundColor:
            palette.isDark ? palette.background : const Color(0xFFF4F6F8),
        drawer: (!isDesktop && showSystemSidebar)
            ? Drawer(child: SafeArea(child: _SidebarMenu(isDesktop: false)))
            : null,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showAdminFeatures
                    ? l10n.adminAppBarTitleManagement(l10n.appTitle)
                    : l10n.adminAppBarTitleWorkspace(l10n.appTitle),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                '${staffSession.name} • ${staffSession.roleLabel}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor:
              showAdminFeatures ? Colors.blue.shade900 : AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: _AdminTopTabs(allowedMenus: allowed),
          leadingWidth: leading.length * 48.0 + 8,
          leading: leading.isEmpty
              ? null
              : Row(mainAxisSize: MainAxisSize.min, children: leading),
          actions: [
            if (showAdminFeatures) ...[
              Builder(builder: (context) {
                final muted = ref.watch(adminOrderAlarmMutedProvider);
                return IconButton(
                  key: const Key('admin-alarm-mute'),
                  tooltip: muted
                      ? 'تشغيل منبّه الطلبات'
                      : 'كتم منبّه الطلبات',
                  icon: Icon(
                    muted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_active_rounded,
                  ),
                  onPressed: () {
                    final next = !muted;
                    ref.read(adminOrderAlarmMutedProvider.notifier).state = next;
                    if (next) _audioPlayer.stop();
                  },
                );
              }),
              if (showSystemSidebar)
                IconButton(
                  key: const Key('support-inbox'),
                  tooltip: l10n.supportCenterTitle,
                  onPressed: _openSupportCenter,
                  icon: Badge(
                    isLabelVisible: supportUnread > 0,
                    backgroundColor: Colors.red,
                    label: Text(
                      unreadLabel(supportUnread),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    child: const Icon(Icons.forum_rounded),
                  ),
                ),
            ],
            IconButton(
              key: const Key('staff-logout'),
              tooltip: 'تبديل الموظف / تسجيل الخروج',
              icon: const Icon(Icons.switch_account_rounded),
              onPressed: () async {
                await ref.read(staffSessionProvider.notifier).logout();
                ref.read(adminMenuProvider.notifier).state =
                    AdminMenu.orderStatus;
                ref.read(localAdminModeProvider.notifier).state = false;
              },
            ),
            if (!isSuperAdmin && staffSession.isAdmin)
              IconButton(
                tooltip: isAdmin
                    ? l10n.adminCloseManagement
                    : l10n.adminEnableManagement,
                icon: Icon(
                    isAdmin ? Icons.lock_open_rounded : Icons.lock_rounded),
                onPressed: () {
                  if (isAdmin) {
                    ref.read(localAdminModeProvider.notifier).state = false;
                    ref.read(adminMenuProvider.notifier).state =
                        AdminMenu.receiveOrders;
                  } else {
                    _showPinDialog();
                  }
                },
              ),
            IconButton(
                tooltip: l10n.adminExitToStore,
                icon: const Icon(Icons.exit_to_app_rounded),
                onPressed: () => context.go('/home')),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop && showSystemSidebar)
              AnimatedContainer(
                key: const Key('admin-sidebar'),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                width: sidebarVisible ? _SidebarMenu.width : 0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: const OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: _SidebarMenu.width,
                  maxWidth: _SidebarMenu.width,
                  child: _SidebarMenu(isDesktop: true),
                ),
              ),
            Expanded(child: menuBody),
          ],
        ),
      ),
        ),
      );
    });
  }
}

// ==========================================
// 3. القائمة الجانبية (Sidebar)
// ==========================================
class _SidebarMenu extends ConsumerWidget {
  static const width = 220.0;

  final bool isDesktop;
  const _SidebarMenu({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeMenu = ref.watch(adminMenuProvider);
    final palette = context.palette;
    final supportUnread = ref.watch(supportUnreadTotalProvider);
    // Only the secondary sections live here; the five main ones are the
    // tabs under the AppBar ([_AdminTopTabs]).
    final isAdmin = ref.watch(isRealAdminProvider) ||
        (ref.watch(staffSessionProvider)?.isAdmin ?? false);
    bool can(AdminPermission permission) =>
        isAdmin || ref.watch(adminCanProvider(permission));

    final entries = <({int menu, String label, IconData icon})>[
      if (can(AdminPermission.manageProducts))
        (
          menu: AdminMenu.products,
          label: l10n.adminMenuProducts,
          icon: Icons.inventory_2
        ),
      if (can(AdminPermission.manageMagazines))
        (
          menu: AdminMenu.magazines,
          label: l10n.magazines,
          icon: Icons.menu_book_rounded
        ),
      if (can(AdminPermission.manageSupport))
        (
          menu: AdminMenu.support,
          label: l10n.supportCenterTitle,
          icon: Icons.forum_rounded
        ),
      if (can(AdminPermission.sendNotifications))
        (
          menu: AdminMenu.notifications,
          label: l10n.adminSendNotifications,
          icon: Icons.campaign_rounded
        ),
      if (can(AdminPermission.approveSubscriptions))
        (
          menu: AdminMenu.pendingSubscriptions,
          label: l10n.adminMenuPendingSubscriptions,
          icon: Icons.workspace_premium_rounded
        ),
    ];

    // Material, not a coloured Container: the tiles paint their selected
    // colour and ripple on it.
    return SizedBox(
      width: isDesktop ? width : double.infinity,
      child: Material(
        color: palette.card,
        child: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isActive = activeMenu == entry.menu;
            final icon = Icon(entry.icon,
                color: isActive ? palette.accent : palette.muted);
            return ListTile(
              key: Key('admin-menu-${entry.menu}'),
              leading: entry.menu == AdminMenu.support
                  ? Badge(
                      key: const Key('support-menu-badge'),
                      isLabelVisible: supportUnread > 0,
                      backgroundColor: Colors.red,
                      label: Text(
                        unreadLabel(supportUnread),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      child: icon,
                    )
                  : icon,
              title: Text(entry.label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? palette.accent : palette.muted)),
              selected: isActive,
              selectedTileColor: palette.accent.withValues(alpha: 0.1),
              onTap: () {
                ref.read(adminMenuProvider.notifier).state = entry.menu;
                ref.read(selectedOrderIdProvider.notifier).state =
                    null; // تفريغ التحديد
                if (!isDesktop) {
                  Navigator.pop(context); // قفل الـ Drawer في الموبايل
                }
              },
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// 3b. شريط التبويبات العلوي (الأقسام الخمسة الرئيسية)
// ==========================================
class _AdminTopTabs extends ConsumerWidget implements PreferredSizeWidget {
  const _AdminTopTabs({required this.allowedMenus});

  final List<int> allowedMenus;

  static const height = 46.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final active = ref.watch(adminMenuProvider);
    final allTabs = <({int menu, String label, IconData icon})>[
      (
        menu: AdminMenu.receiveOrders,
        label: l10n.adminMenuReceiveOrders,
        icon: Icons.headset_mic
      ),
      (
        menu: AdminMenu.orderStatus,
        label: l10n.adminMenuOrderStatus,
        icon: Icons.shopping_bag
      ),
      (menu: AdminMenu.search, label: 'بحث', icon: Icons.search_rounded),
      (
        menu: AdminMenu.reports,
        label: l10n.adminMenuReports,
        icon: Icons.pie_chart_rounded
      ),
      (
        menu: AdminMenu.staff,
        label: 'إدارة النظام',
        icon: Icons.settings_rounded
      ),
    ];
    final tabs = [
      for (final tab in allTabs)
        if (allowedMenus.contains(tab.menu)) tab,
    ];

    return Container(
      key: const Key('admin-top-tabs'),
      height: height,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final tab in tabs)
                  _AdminTab(
                    key: Key('admin-tab-${tab.menu}'),
                    label: tab.label,
                    icon: tab.icon,
                    selected: active == tab.menu,
                    onTap: () {
                      ref.read(adminMenuProvider.notifier).state = tab.menu;
                      ref.read(selectedOrderIdProvider.notifier).state = null;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  const _AdminTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.muted;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: _AdminTopTabs.height - 1,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? palette.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. قائمة الطلبات (Orders List)
// ==========================================
class _OrdersList extends ConsumerWidget {
  final List<Map<String, dynamic>> orders;
  final UserRole? userRole;
  final bool deliveryOnly;
  const _OrdersList({
    required this.orders,
    required this.userRole,
    this.deliveryOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedId = ref.watch(selectedOrderIdProvider);
    final statusFilter = ref.watch(orderStatusFilterProvider);
    final palette = context.palette;

    var roleOrders = orders;
    if (deliveryOnly || userRole == UserRole.driver) {
      roleOrders = orders.where((o) {
        final status = OrderStatus.normalize('${o['status'] ?? ''}');
        return status == OrderStatus.readyForDelivery.value ||
            status == OrderStatus.outForDelivery.value;
      }).toList();
    }

    final defs = orderFilterDefs(
      all: l10n.all,
      fresh: l10n.statusNew,
      delayed: l10n.adminStatusDelayedShort,
      preparing: l10n.adminStatusPreparingShort,
      forDriver: l10n.adminStatusReadyForDriverShort,
      delivery: l10n.adminStatusDeliveryShort,
      completed: l10n.adminStatusCompletedShort,
      cancelled: l10n.adminStatusCancelledShort,
    );

    // One clock for the whole list: the countdowns, the late filter and the
    // tab counts all read the same `now`, so they never disagree.
    return LiveClock(
      active: roleOrders.any(orderRunsPrepClock),
      builder: (context, now) {
        final counts = countOrdersByFilter(roleOrders, defs, now: now);
        final visibleOrders = roleOrders
            .where((o) => orderMatchesFilter(o, statusFilter, now: now))
            .toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              color: palette.card,
              padding: const EdgeInsets.all(10),
              child: OrderFilterTabs(
                defs: defs,
                counts: counts,
                selected: statusFilter,
                onSelected: (filter) => ref
                    .read(orderStatusFilterProvider.notifier)
                    .state = filter,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: visibleOrders.isEmpty
                  ? Center(
                      child: Text(l10n.adminNoOrders,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: visibleOrders.length,
                      itemBuilder: (context, index) {
                        final order = visibleOrders[index];
                        return _OrderCard(
                          order: order,
                          now: now,
                          isSelected: order['id'] == selectedId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({
    required this.order,
    required this.now,
    required this.isSelected,
  });

  final Map<String, dynamic> order;
  final DateTime now;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final customerName = orderCustomerOf(ref, order).name;
    final id = order['id'].toString();
    final displayId = id.length >= 6 ? id.substring(0, 6) : id;
    final countdown = orderPrepCountdown(order, now);

    final total = Text(
      AppCurrency.of(double.tryParse(order['total_amount'].toString()) ?? 0),
      style: TextStyle(color: palette.accent, fontWeight: FontWeight.bold),
    );
    final paymentBadge = order['payment_method'] != null &&
            '${order['payment_method']}'.isNotEmpty
        ? PaymentMethodBadge(method: '${order['payment_method']}')
        : null;

    return InkWell(
      onTap: () {
        ref.read(orderPrepChecklistProvider.notifier).state = {};
        ref.read(selectedOrderIdProvider.notifier).state = order['id'];
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (palette.isDark
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.shade50)
              : palette.card,
          border: Border.all(
              color: isSelected ? Colors.blue : palette.border,
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        // The pastel prep fill sits behind the text, inside the border, so
        // the selected highlight stays on top. Done / cancelled orders have
        // no countdown and keep the plain card.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 10 : 11),
          child: Stack(
            children: [
              if (countdown != null)
                Positioned.fill(child: PrepCardFill(countdown: countdown)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('#$displayId',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        DashboardStatusBadge(
                            status: '${order['status'] ?? ''}'),
                      ],
                    ),
                    if (customerName != null ||
                        order['order_source'] == 'phone') ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        if (order['order_source'] == 'phone')
                          Container(
                            margin:
                                const EdgeInsetsDirectional.only(end: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(l10n.phoneOrderBadge,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade800)),
                          ),
                        Expanded(
                          child: Text(
                            customerName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                      ]),
                    ],
                    Builder(builder: (_) {
                      final pendingIds = ref
                              .watch(pendingAlternativeOrderIdsProvider)
                              .valueOrNull ??
                          const {};
                      if (!pendingIds.contains(id)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz_rounded,
                                  size: 14, color: Colors.deepOrange),
                              SizedBox(width: 4),
                              Text(
                                'بدائل بانتظار الرد',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Bottom row: total · countdown (centered) · payment.
                    if (countdown == null)
                      Row(
                        children: [
                          Expanded(child: total),
                          if (paymentBadge != null) paymentBadge,
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: total,
                              ),
                            ),
                          ),
                          PrepCountdownLabel(countdown: countdown),
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: paymentBadge == null
                                  ? const SizedBox.shrink()
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerEnd,
                                      child: paymentBadge,
                                    ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ==========================================
// 5. عرض تفاصيل الطلب (بطاقة عريضة + لوحتان)
// ==========================================
class _OrderDetailsView extends ConsumerWidget {
  final List<Map<String, dynamic>> orders;
  final UserRole? userRole;
  final bool showAdminFeatures;
  final bool isDesktop;

  const _OrderDetailsView(
      {required this.orders,
      required this.userRole,
      required this.showAdminFeatures,
      required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedId = ref.watch(selectedOrderIdProvider);
    final palette = context.palette;
    if (selectedId == null) {
      return Center(
          child: Text(l10n.adminSelectOrderFromList,
              style: TextStyle(color: palette.muted)));
    }

    final order =
        orders.firstWhere((o) => o['id'] == selectedId, orElse: () => {});
    if (order.isEmpty) return const SizedBox();

    final customer = orderCustomerOf(ref, order);
    final status = OrderStatus.normalize('${order['status'] ?? ''}');
    final canCheck = status == OrderStatus.preparing.value &&
        order['prep_completed_at'] == null &&
        userRole != UserRole.driver;

    // أعلى: بطاقة التفاصيل العريضة.
    final infoCard = OrderInfoCard(
      order: order,
      customerName: customer.name,
      customerPhone: customer.phone,
    );

    final orderId = '${order['id']}';
    final isPhoneOrder = order['order_source'] == 'phone';
    final customerUserId = order['user_id']?.toString();
    final customerPhone = customer.phone;

    // أسفل (وسط): المنتجات المطلوبة للتجهيز.
    final productsPanel = OrderPanel(
      key: const Key('order-products-panel'),
      title: 'المنتجات المطلوبة للتجهيز',
      icon: Icons.shopping_basket_outlined,
      child: Consumer(builder: (context, ref, child) {
        final itemsAsync = ref.watch(adminOrderItemsProvider(orderId));
        return itemsAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
          error: (e, _) => Text(l10n.failedToLoadProducts),
          data: (items) {
            if (items.isEmpty) return Text(l10n.adminNoItemsInOrder);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderAlternativesPanel(
                  orderId: orderId,
                  forStaff: isPhoneOrder,
                  customerPhone: customerPhone,
                ),
                if (canCheck)
                  _CheckableProductsList(
                    items: items,
                    orderId: orderId,
                    notifyCustomer: !isPhoneOrder,
                    customerUserId: customerUserId,
                  )
                else
                  for (final item in items) OrderProductTile(item: item),
              ],
            );
          },
        );
      }),
    );

    // أسفل (يسار): الإجراءات المتاحة.
    final actionsPanel = OrderPanel(
      key: const Key('order-actions-panel'),
      title: l10n.adminAvailableActions,
      icon: Icons.bolt_rounded,
      child: _buildActionButtons(context, ref, order),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoCard,
          CustomerOrderRatingCard(orderId: orderId),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth >= 640) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: productsPanel),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: actionsPanel),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                productsPanel,
                const SizedBox(height: 16),
                actionsPanel,
              ],
            );
          }),
        ],
      ),
    );
  }

  /// The workflow: start prep → finish prep → assign a driver and start
  /// delivery («للطيار») → the driver accepts («توصيل») → delivered.
  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context)!;
    final status = OrderStatus.normalize('${order['status'] ?? ''}');
    final isDriver = userRole == UserRole.driver;
    final prepDone = order['prep_completed_at'] != null;
    final driverName = order['driver_name']?.toString().trim();
    final hasDriver = driverName != null && driverName.isNotEmpty;

    Widget gap() => const SizedBox(height: 16);

    final orderId = '${order['id']}';
    final preparerName = order['preparer_name']?.toString().trim();
    final hasPreparer = preparerName != null && preparerName.isNotEmpty;
    final staff = ref.watch(staffSessionProvider);
    // Preparers / drivers never see «تعديل الطلب» — only print / finish prep.
    final blockedStaffRole =
        staff?.isPreparer == true || staff?.isDriver == true || isDriver;
    final isStaffAdmin = staff?.isAdmin == true;
    final isStaffTaker = staff?.isTaker == true;
    final isStaffPreparer = staff?.isPreparer == true;
    final isStaffDriver = staff?.isDriver == true;
    // Super-admin / staff admin always; cashiers need «تعديل الطلبات».
    final hasEditPermission = ref.watch(isRealAdminProvider) ||
        isStaffAdmin ||
        ref.watch(adminCanProvider(AdminPermission.editOrders));
    final canEdit = !blockedStaffRole &&
        orderAllowsLiveEdit(
          status: status,
          prepCompletedAt: order['prep_completed_at'],
        ) &&
        (isStaffAdmin || isStaffTaker || hasEditPermission);
    final canStartPrep = isStaffPreparer ||
        isStaffAdmin ||
        ref.watch(adminCanProvider(AdminPermission.startPrep));
    final canFinishPrep = isStaffPreparer ||
        isStaffAdmin ||
        ref.watch(adminCanProvider(AdminPermission.finishPrep));
    final canAssignDriver = isStaffAdmin ||
        ref.watch(adminCanProvider(AdminPermission.assignDriver));
    final beingEdited = order['is_being_edited'] == true;
    final deliveryFee = switch (order['delivery_fee']) {
      final num n => n.toDouble(),
      final String t => double.tryParse(t) ?? 0,
      _ => 0.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Receipt only after a preparer is chosen (admin + preparer).
        // Preparers must check off every item before printing / scanning.
        if (!isDriver && !isStaffDriver) ...[
          if (hasPreparer)
            Builder(builder: (context) {
              final checkedIds = ref.watch(orderPrepChecklistProvider);
              final itemsAsync = ref.watch(adminOrderItemsProvider(orderId));
              final totalItems = itemsAsync.valueOrNull?.length ?? 0;
              final allItemsPrepared =
                  prepDone || (totalItems > 0 && checkedIds.length == totalItems);
              final lockPrint = isStaffPreparer && !allItemsPrepared;
              return _ActionCard(
                key: const Key('action-print-prep-receipt'),
                title: 'طباعة إيصال التحضير',
                desc: lockPrint
                    ? 'أكمل تجهيز جميع الأصناف أولاً'
                    : 'QR للكاشير • $preparerName',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF1565C0),
                enabled: !lockPrint,
                onTap: () => showPrepReceiptSheet(context, orderId: orderId),
              );
            })
          else
            _StatusBanner(
              key: const Key('prep-receipt-need-preparer'),
              color: Colors.blueGrey,
              icon: Icons.receipt_long_rounded,
              text: 'اختر المحضر أولاً ثم اطبع إيصال التحضير',
            ),
          gap(),
        ],
        if (canEdit) ...[
          _ActionCard(
            key: const Key('action-edit-order'),
            title: 'تعديل الطلب',
            desc: beingEdited
                ? 'جاري التعديل الآن'
                : 'إضافة / حذف أصناف أو تغيير الكميات',
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF00897B),
            onTap: () async {
              final saved = await showEditOrderSheet(
                context,
                orderId: orderId,
                startedBy: isStaffAdmin || ref.read(isRealAdminProvider)
                    ? 'admin'
                    : 'taker',
                deliveryFee: deliveryFee,
              );
              ref.invalidate(adminOrderItemsProvider(orderId));
              if (saved && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('تم حفظ تعديلات الطلب'),
                  ),
                );
              }
            },
          ),
          gap(),
        ],
        if (status == OrderStatus.pending.value &&
            !isDriver &&
            !isStaffDriver &&
            canStartPrep)
          _ActionCard(
            key: const Key('action-start-prep'),
            title: l10n.startPreparing,
            desc: l10n.adminOrderAwaitingPreparer,
            icon: Icons.play_circle_fill,
            color: Colors.orange,
            onTap: () => _onStartPreparing(context, ref, orderId),
          ),
        if (status == OrderStatus.preparing.value) ...[
          Text(l10n.adminPreparerName('${order['preparer_name']}'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.orange)),
          gap(),
          if (prepDone)
            const _StatusBanner(
              key: Key('prep-done-banner'),
              color: Colors.green,
              icon: Icons.check_circle,
              text: 'تم إتمام تجهيز الطلب',
            )
          else if (!isDriver && !isStaffDriver && canFinishPrep)
            _FinishPrepButton(order: order),
          if (showAdminFeatures && canAssignDriver) ...[
            gap(),
            _AdminDriverAssigner(
              key: ValueKey('assign-${order['id']}'),
              order: order,
              enabled: prepDone,
              startDelivery: true,
            ),
          ] else if (prepDone && !isStaffDriver) ...[
            gap(),
            _StatusBanner(
              color: Colors.red,
              icon: Icons.hourglass_top_rounded,
              text: l10n.adminAwaitingDriverAssignment,
            ),
          ],
        ],
        if (status == OrderStatus.readyForDelivery.value) ...[
          if (!hasDriver) ...[
            if (showAdminFeatures && canAssignDriver)
              _AdminDriverAssigner(
                key: ValueKey('assign-${order['id']}'),
                order: order,
                enabled: true,
                startDelivery: false,
              )
            else if (isStaffDriver || isDriver)
              _ActionCard(
                key: const Key('action-driver-accept'),
                title: l10n.adminPickUpAndStartRoute,
                desc: staff?.name ?? '',
                icon: Icons.motorcycle_rounded,
                color: Colors.blue,
                onTap: () => _onDriverAccept(context, ref, order),
              )
            else
              _StatusBanner(
                color: Colors.red,
                icon: Icons.hourglass_top_rounded,
                text: l10n.adminAwaitingDriverAssignment,
              ),
          ] else ...[
            _StatusBanner(
              key: const Key('assigned-driver-banner'),
              color: Colors.purple,
              icon: Icons.motorcycle_rounded,
              text: 'تم إسناد الأوردر للطيار: $driverName',
            ),
            gap(),
            if (isDriver || isStaffDriver || showAdminFeatures)
              _ActionCard(
                key: const Key('action-driver-accept'),
                title: l10n.adminPickUpAndStartRoute,
                desc: l10n.adminDriverName('$driverName'),
                icon: Icons.motorcycle_rounded,
                color: Colors.blue,
                onTap: () => _onDriverAccept(context, ref, order),
              )
            else
              _StatusBanner(
                color: Colors.green,
                icon: Icons.check_circle,
                text: l10n.adminOrderReadyAwaitingDriver,
              ),
          ],
        ],
        if (status == OrderStatus.outForDelivery.value) ...[
          if (isDriver || isStaffDriver || showAdminFeatures)
            _ActionCard(
              title: l10n.adminMarkDelivered,
              desc: l10n.adminCloseOrderPermanently,
              icon: Icons.done_all,
              color: AppColors.success,
              onTap: () async {
                final id = order['id'].toString();
                final previous =
                    (order['status'] ?? 'out_for_delivery').toString();
                await Supabase.instance.client.from('orders').update({
                  'status': OrderStatus.delivered.value,
                }).eq('id', id);
                dispatchOrderPush(
                  Supabase.instance.client,
                  orderId: id,
                  trigger: 'status',
                  previousStatus: previous,
                );
                if (!isDesktop && context.mounted) {
                  ref.read(selectedOrderIdProvider.notifier).state =
                      null; // يرجع للستة
                }
              },
            )
          else
            _StatusBanner(
              color: Colors.blue,
              icon: Icons.motorcycle,
              text: l10n.adminOrderWithDriverOnTheWay,
            ),
        ],
        if (status == OrderStatus.delivered.value)
          _StatusBanner(
            color: Colors.green,
            icon: Icons.done_all,
            text: l10n.adminOrderDeliveredAndClosed,
          ),
        if (status == OrderStatus.cancelled.value)
          _StatusBanner(
            color: Colors.red,
            icon: Icons.cancel_outlined,
            text: l10n.orderStatusCancelled,
          ),
      ],
    );
  }

  Future<void> _onStartPreparing(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) async {
    final staff = ref.read(staffSessionProvider);
    // Admins keep the manual picker; logged-in preparers self-assign.
    if (staff?.isPreparer == true && staff?.isAdmin != true) {
      await _autoStartAsPreparer(context, ref, orderId, staff!);
      return;
    }
    _showPreparerDialog(context, ref, orderId);
  }

  Future<void> _autoStartAsPreparer(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    StaffSession staff,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Only unfinished prep counts: «إتمام تجهيز الطلب» stamps
      // prep_completed_at while status stays «preparing» until a driver
      // is assigned — those must not block the next order.
      final busy = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('status', OrderStatus.preparing.value)
          .eq('preparer_name', staff.name)
          .isFilter('prep_completed_at', null)
          .limit(1);
      if ((busy as List).isNotEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text(
            'لديك طلب قيد التجهيز حالياً، يرجى إتمام تجهيزه أولاً قبل بدء طلب جديد',
          ),
          backgroundColor: AppColors.secondary,
        ));
        return;
      }

      final patch = <String, dynamic>{
        'status': OrderStatus.preparing.value,
        'preparer_name': staff.name,
      };
      Map<String, dynamic>? existing;
      for (final o in orders) {
        if ('${o['id']}' == orderId) {
          existing = o;
          break;
        }
      }
      final taker = existing?['taker_name']?.toString().trim();
      if (taker == null || taker.isEmpty) {
        patch['taker_name'] = staff.name;
      }
      await Supabase.instance.client
          .from('orders')
          .update(patch)
          .eq('id', orderId);
      dispatchOrderPush(
        Supabase.instance.client,
        orderId: orderId,
        trigger: 'status',
        previousStatus: OrderStatus.pending.value,
      );
      AudioPlayer().play(UrlSource(
          'https://jugdxfhmjakmzjvfltjv.supabase.co/storage/v1/object/public/product_images/accept_order.mp3.mp3'));
    } on PostgrestException catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: AppColors.secondary,
      ));
    }
  }

  Future<void> _onDriverAccept(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> order,
  ) async {
    final staff = ref.read(staffSessionProvider);
    final messenger = ScaffoldMessenger.of(context);
    final orderId = order['id'].toString();
    final previous = (order['status'] ?? 'ready_for_delivery').toString();
    final existingDriver = order['driver_name']?.toString().trim();
    final isAdminActor =
        staff?.isAdmin == true || ref.read(isRealAdminProvider);

    // Logged-in drivers self-assign; admins keep the assigned name as-is.
    final assignName = (!isAdminActor && staff?.isDriver == true)
        ? staff!.name
        : (existingDriver != null && existingDriver.isNotEmpty
            ? existingDriver
            : staff?.name);

    if (assignName == null || assignName.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('لم يتم تحديد الطيار'),
        backgroundColor: AppColors.secondary,
      ));
      return;
    }

    if (!isAdminActor && staff?.isDriver == true) {
      try {
        final busy = await Supabase.instance.client
            .from('orders')
            .select('id')
            .eq('status', OrderStatus.outForDelivery.value)
            .eq('driver_name', assignName)
            .limit(1);
        if ((busy as List).isNotEmpty) {
          messenger.showSnackBar(const SnackBar(
            content: Text(
              'لديك طلب قيد التوصيل حالياً، يرجى إتمام توصيله أولاً قبل استلام طلب جديد',
            ),
            backgroundColor: AppColors.secondary,
          ));
          return;
        }
      } on PostgrestException catch (error) {
        messenger.showSnackBar(SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.secondary,
        ));
        return;
      }
    }

    try {
      await Supabase.instance.client.from('orders').update({
        'status': OrderStatus.outForDelivery.value,
        'driver_name': assignName,
      }).eq('id', orderId);
      dispatchOrderPush(
        Supabase.instance.client,
        orderId: orderId,
        trigger: 'status',
        previousStatus: previous,
      );
      if (context.mounted) navigateToOrder(context, ref, order);
    } on PostgrestException catch (error) {
      messenger.showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: AppColors.secondary,
      ));
    }
  }

  void _showPreparerDialog(
    BuildContext context,
    WidgetRef ref,
    String orderId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminWhoAreYouPickName,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        content: FutureBuilder<List<Map<String, dynamic>>>(
            future: Supabase.instance.client
                .from('staff')
                .select('name, is_active')
                .eq('role', 'preparer')
                .order('name'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
              final preparers = [
                for (final p in snapshot.data ?? const <Map<String, dynamic>>[])
                  if (p['is_active'] != false) p,
              ];
              if (preparers.isEmpty) return Text(l10n.adminNoPreparers);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: preparers
                    .map((p) => ListTile(
                          title: Text('${p['name']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          trailing:
                              const Icon(Icons.touch_app, color: Colors.orange),
                          onTap: () async {
                            Navigator.pop(ctx);
                            final staff = ref.read(staffSessionProvider);
                            final patch = <String, dynamic>{
                              'status': OrderStatus.preparing.value,
                              'preparer_name': p['name'],
                            };
                            // Keep taker on the receipt when missing.
                            Map<String, dynamic>? existing;
                            for (final o in orders) {
                              if ('${o['id']}' == orderId) {
                                existing = o;
                                break;
                              }
                            }
                            final taker =
                                existing?['taker_name']?.toString().trim();
                            if ((taker == null || taker.isEmpty) &&
                                staff != null) {
                              patch['taker_name'] = staff.name;
                            }
                            await Supabase.instance.client
                                .from('orders')
                                .update(patch)
                                .eq('id', orderId);
                            dispatchOrderPush(
                              Supabase.instance.client,
                              orderId: orderId,
                              trigger: 'status',
                              previousStatus: OrderStatus.pending.value,
                            );
                            AudioPlayer().play(UrlSource(
                                'https://jugdxfhmjakmzjvfltjv.supabase.co/storage/v1/object/public/product_images/accept_order.mp3.mp3'));
                          },
                        ))
                    .toList(),
              );
            }),
      ),
    );
  }
}

// ==========================================
// 6. مكونات فرعية (زرار الإنهاء، الكروت، التشيك بوكس)
// ==========================================

/// A coloured one-line status note in the actions panel.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

/// «إتمام تجهيز الطلب»: stamps `prep_completed_at`, which stops the prep
/// clock. The order stays «تحضير» until a driver is assigned and delivery
/// starts.
class _FinishPrepButton extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _FinishPrepButton({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final checkedIds = ref.watch(orderPrepChecklistProvider);
    final itemsAsync = ref.watch(adminOrderItemsProvider(order['id']));
    final beingEdited = order['is_being_edited'] == true;

    // When the edit lock clears, refresh items so the preparer sees finals.
    ref.listen(liveOrdersProvider, (previous, next) {
      final prevList = previous?.valueOrNull;
      final nextList = next.valueOrNull;
      if (prevList == null || nextList == null) return;
      Map<String, dynamic>? prevOrder;
      Map<String, dynamic>? nextOrder;
      for (final row in prevList) {
        if ('${row['id']}' == '${order['id']}') {
          prevOrder = row;
          break;
        }
      }
      for (final row in nextList) {
        if ('${row['id']}' == '${order['id']}') {
          nextOrder = row;
          break;
        }
      }
      if (prevOrder == null || nextOrder == null) return;
      if (prevOrder['is_being_edited'] == true &&
          nextOrder['is_being_edited'] != true) {
        ref.invalidate(adminOrderItemsProvider('${order['id']}'));
      }
    });

    final totalItems = itemsAsync.valueOrNull?.length ?? 0;
    final allChecked = totalItems > 0 && checkedIds.length == totalItems;
    final locked = beingEdited;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        key: const Key('action-finish-prep'),
        icon: Icon(locked ? Icons.lock_clock_rounded : Icons.inventory_rounded),
        label: Text(
          locked
              ? (order['editing_started_by']?.toString() == 'customer'
                  ? 'بانتظار تعديل العميل للطلب'
                  : 'بانتظار تعديل الطلب')
              : l10n.adminFinishOrderPreparation,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: locked
              ? const Color(0xFFFFA000)
              : (allChecked ? AppColors.success : Colors.grey),
          foregroundColor: locked ? Colors.black87 : null,
        ),
        onPressed: locked
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                if (!allChecked) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(l10n.adminCheckAllItemsFirst),
                      backgroundColor: AppColors.secondary));
                  return;
                }
                try {
                  await Supabase.instance.client.from('orders').update({
                    'prep_completed_at':
                        DateTime.now().toUtc().toIso8601String(),
                  }).eq('id', order['id']);
                  messenger.showSnackBar(SnackBar(
                      content: Text(l10n.adminPreparationFinished),
                      backgroundColor: AppColors.success));
                } on PostgrestException catch (error) {
                  messenger.showSnackBar(SnackBar(
                      content: Text(error.message),
                      backgroundColor: AppColors.secondary));
                }
              },
      ),
    );
  }
}

/// «إسناد الأوردر للطيار»: pick a driver, then «بدء التوصيل» assigns him and
/// moves the order to «للطيار». [enabled] is false until the prep is done.
/// With [startDelivery] false it only records the driver (orders already
/// marked ready by the warehouse).
class _AdminDriverAssigner extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  final bool enabled;
  final bool startDelivery;
  const _AdminDriverAssigner({
    super.key,
    required this.order,
    required this.enabled,
    required this.startDelivery,
  });

  @override
  ConsumerState<_AdminDriverAssigner> createState() =>
      _AdminDriverAssignerState();
}

class _AdminDriverAssignerState extends ConsumerState<_AdminDriverAssigner> {
  String? selectedDriver;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    selectedDriver = widget.order['driver_name']?.toString();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final orderId = widget.order['id'].toString();
      final previous = (widget.order['status'] ?? 'preparing').toString();
      await Supabase.instance.client.from('orders').update({
        'driver_name': selectedDriver,
        if (widget.startDelivery)
          'status': OrderStatus.readyForDelivery.value,
      }).eq('id', orderId);
      if (widget.startDelivery) {
        dispatchOrderPush(
          Supabase.instance.client,
          orderId: orderId,
          trigger: 'status',
          previousStatus: previous,
        );
      }
      messenger.showSnackBar(SnackBar(
          content: Text(l10n.adminOrderAssignedToDriver),
          backgroundColor: AppColors.success));
    } on PostgrestException catch (error) {
      messenger.showSnackBar(SnackBar(
          content: Text(error.message), backgroundColor: AppColors.secondary));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final staff = ref.watch(activeStaffProvider);
    final drivers = [
      for (final member in staff.valueOrNull ?? const [])
        if (member['role'] == 'driver') '${member['name']}',
    ];
    final value = drivers.contains(selectedDriver) ? selectedDriver : null;

    return Container(
      key: const Key('driver-assigner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: palette.isDark
              ? Colors.blue.withValues(alpha: 0.15)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: palette.isDark
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.blue.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('إسناد الأوردر للطيار',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.blue)),
          if (!widget.enabled) ...[
            const SizedBox(height: 4),
            Text('أتمم تجهيز الطلب أولاً',
                key: const Key('driver-assigner-locked'),
                style: TextStyle(fontSize: 12, color: palette.muted)),
          ],
          const SizedBox(height: 12),
          if (staff.isLoading)
            const LinearProgressIndicator()
          else
            DropdownButtonFormField<String>(
              key: const Key('driver-dropdown'),
              initialValue: value,
              isExpanded: true,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  fillColor: palette.card,
                  filled: true),
              hint: Text(l10n.adminSelectDriver),
              items: [
                for (final name in drivers)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: widget.enabled
                  ? (val) => setState(() => selectedDriver = val)
                  : null,
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const Key('action-start-delivery'),
              style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: widget.enabled && value != null && !_saving
                  ? _submit
                  : null,
              icon: Icon(widget.startDelivery
                  ? Icons.delivery_dining_rounded
                  : Icons.person_add_alt_1_rounded),
              label: Text(
                widget.startDelivery ? 'بدء التوصيل' : l10n.adminAssignToSelectedDriver,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckableProductsList extends ConsumerWidget {
  const _CheckableProductsList({
    required this.items,
    required this.orderId,
    required this.notifyCustomer,
    this.customerUserId,
  });

  final List<AdminOrderItem> items;
  final String orderId;
  final bool notifyCustomer;
  final String? customerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedItemIds = ref.watch(orderPrepChecklistProvider);
    final palette = context.palette;
    final pendingAlts =
        ref.watch(pendingOrderAlternativesProvider(orderId)).valueOrNull ??
            const [];
    final pendingItemIds = {
      for (final a in pendingAlts) a.originalOrderItemId,
    };

    return Column(
      children: [
        for (final item in items)
          _PrepItemCard(
            item: item,
            isChecked: checkedItemIds.contains(item.id),
            hasPendingAlternatives: pendingItemIds.contains(item.id),
            onToggle: (checked) {
              if (checked) {
                ref
                    .read(orderPrepChecklistProvider.notifier)
                    .update((state) => {...state, item.id});
              } else {
                ref
                    .read(orderPrepChecklistProvider.notifier)
                    .update((state) => {...state}..remove(item.id));
              }
            },
            onSendAlternatives: () async {
              final sent = await showSendAlternativesSheet(
                context,
                orderId: orderId,
                item: item,
                notifyCustomer: notifyCustomer,
                customerUserId: customerUserId,
              );
              if (!sent) return;
              ref.invalidate(orderAlternativesProvider(orderId));
              ref.invalidate(pendingOrderAlternativesProvider(orderId));
              ref.invalidate(pendingAlternativeOrderIdsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    notifyCustomer
                        ? 'تم إرسال البدائل للعميل'
                        : 'تم إرسال البدائل للمتلقي',
                  ),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            canSendAlternatives: ref.watch(staffSessionProvider)?.isAdmin ==
                    true ||
                ref.watch(adminCanProvider(AdminPermission.sendAlternatives)),
            palette: palette,
          ),
      ],
    );
  }
}

class _PrepItemCard extends StatelessWidget {
  const _PrepItemCard({
    required this.item,
    required this.isChecked,
    required this.hasPendingAlternatives,
    required this.onToggle,
    required this.onSendAlternatives,
    required this.canSendAlternatives,
    required this.palette,
  });

  final AdminOrderItem item;
  final bool isChecked;
  final bool hasPendingAlternatives;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSendAlternatives;
  final bool canSendAlternatives;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final barcode = item.barcode?.trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isChecked
            ? (palette.isDark
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.green.shade50)
            : palette.card,
        border: Border.all(
          color: hasPendingAlternatives
              ? Colors.deepOrange
              : isChecked
                  ? Colors.green
                  : palette.border,
          width: isChecked || hasPendingAlternatives ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: isChecked,
                  activeColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => onToggle(val == true),
                ),
              ),
              const SizedBox(width: 8),
              ProductThumb(imageUrl: item.imageUrl, size: 50, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? palette.muted : palette.onSurface,
                      ),
                    ),
                    if (item.isWeighted)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.quantityLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ),
                    if (barcode != null && barcode.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: barcode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الباركود'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BarcodeIcon(size: 15, color: palette.muted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  barcode,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    color: palette.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.copy_rounded,
                                  size: 13, color: palette.muted),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      AppCurrency.of(item.price),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.quantityLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (canSendAlternatives) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: hasPendingAlternatives ? null : onSendAlternatives,
                icon: Icon(
                  hasPendingAlternatives
                      ? Icons.hourglass_top_rounded
                      : Icons.swap_horiz_rounded,
                  size: 18,
                ),
                label: Text(
                  hasPendingAlternatives
                      ? 'بدائل بانتظار الرد'
                      : 'إرسال بدائل',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _ActionCard(
      {super.key,
      required this.title,
      required this.desc,
      required this.icon,
      required this.color,
      required this.onTap,
      this.enabled = true});
  @override
  Widget build(BuildContext context) {
    final effective = enabled ? color : Colors.blueGrey;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: effective.withValues(alpha: 0.1),
              border: Border.all(color: effective.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(
              enabled ? icon : Icons.lock_rounded,
              color: effective,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: effective)),
                  Text(desc, style: TextStyle(color: context.palette.muted))
                ]))
          ]),
        ),
      ),
    );
  }
}

// ==========================================
// 8. شاشات الإدارة الكاملة (المنتجات، الطاقم، التقارير)
// ==========================================

class _ProductsGridView extends ConsumerWidget {
  const _ProductsGridView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(adminProductsProvider);
    final currentFilter = ref.watch(adminProductFilterProvider);
    final palette = context.palette;

    Widget filterBtn(int index, String title) {
      final isSelected = currentFilter == index;
      return InkWell(
        onTap: () =>
            ref.read(adminProductFilterProvider.notifier).state = index,
        child: Container(
          margin: const EdgeInsets.only(left: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(
                  color: isSelected ? palette.accent : palette.border),
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? palette.accent.withValues(alpha: 0.1)
                  : palette.card),
          child: Text(title,
              style: TextStyle(
                  color: isSelected ? palette.accent : palette.muted,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Container(
      color: palette.isDark ? palette.background : const Color(0xFFF4F6F8),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminManageProducts,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              filterBtn(0, l10n.all),
              filterBtn(1, l10n.adminActiveProducts),
              filterBtn(2, l10n.adminInactiveProducts),
              const SizedBox(width: 16),
              SizedBox(
                  width: 300,
                  child: TextField(
                      onChanged: (val) => ref
                          .read(adminProductSearchProvider.notifier)
                          .state = val,
                      decoration: InputDecoration(
                          hintText: l10n.adminSearchProductByName,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: palette.card,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none)))),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text(l10n.adminErrorOccurred('$err'))),
              data: (products) {
                if (products.isEmpty)
                  return Center(
                      child: Text(l10n.adminNoProducts,
                          style:
                              TextStyle(fontSize: 18, color: palette.muted)));
                return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 320,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final isActive = p['is_active'] ?? true;
                      final barcode =
                          p['barcode'] ?? p['id'].toString().substring(0, 6);
                      final stock = switch (p['stock_quantity']) {
                        final num n => n.round(),
                        final String t => int.tryParse(t) ?? 0,
                        _ => 0,
                      };
                      return Container(
                        decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.border)),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: palette.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Center(
                                      child: ProductImage(
                                        imageUrl: p['image_url'],
                                        fit: BoxFit.contain,
                                        placeholderBackground: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Tooltip(
                                      message: l10n.adminCopyProductName,
                                      child: InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(
                                                text: p['name'] ?? ''));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        l10n.adminCopied)));
                                          },
                                          child: Text(p['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold)))),
                                  const SizedBox(height: 4),
                                  Tooltip(
                                      message: l10n.adminCopyBarcode,
                                      child: InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                                ClipboardData(text: barcode));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        l10n.adminCopied)));
                                          },
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    l10n.adminBarcodeValue(
                                                        '$barcode'),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: palette.muted)),
                                                const SizedBox(width: 4),
                                                Icon(Icons.copy,
                                                    size: 12,
                                                    color: palette.muted)
                                              ]))),
                                  const SizedBox(height: 4),
                                  Text(
                                    'المخزون: $stock',
                                    key: Key('admin-product-stock-${p['id']}'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: stock <= 5
                                          ? Colors.orange.shade800
                                          : palette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      AppCurrency.of(double.tryParse(
                                              p['price'].toString()) ??
                                          0),
                                      style: TextStyle(
                                          color: palette.accent,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final scaffold = ScaffoldMessenger.of(context);
                                try {
                                  await Supabase.instance.client
                                      .from('products')
                                      .update({'is_active': !isActive}).eq(
                                          'id', p['id']);
                                  ref.invalidate(adminProductsProvider);
                                } catch (e) {
                                  scaffold.showSnackBar(SnackBar(
                                      content:
                                          Text(l10n.adminUpdateErrorOccurred),
                                      backgroundColor: Colors.red));
                                }
                              },
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.success
                                            .withValues(alpha: 0.1)
                                        : palette.surface,
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12))),
                                alignment: Alignment.center,
                                child: Text(
                                    isActive ? l10n.inStock : l10n.outOfStock,
                                    style: TextStyle(
                                        color: isActive
                                            ? AppColors.success
                                            : palette.muted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            )
                          ],
                        ),
                      );
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}

