import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../features/addresses/presentation/screens/add_address_screen.dart';
import '../../features/addresses/presentation/screens/addresses_screen.dart';
import '../../features/addresses/presentation/screens/map_picker_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/catalog/presentation/screens/category_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/payment_screen.dart';
import '../../features/driver/presentation/screens/driver_dashboard_screen.dart'; // شاشة الموبايل القديمة
import '../../features/driver/presentation/screens/order_map_screen.dart';
import '../../features/profile/domain/entities/user_role.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/catalog/presentation/screens/product_details_screen.dart';
import '../../features/home/domain/entities/product.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/providers/products_providers.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/product_list_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../features/orders/presentation/screens/order_rating_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/rewards/presentation/screens/cashier_scan_screen.dart';
import '../../features/rewards/presentation/screens/lucky_chest_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/rewards/presentation/screens/scratch_card_screen.dart';
import '../../features/rewards/presentation/screens/wheel_game_screen.dart';
import '../../screens/puzzle_game_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/magazines/presentation/screens/magazines_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/support/presentation/screens/customer_support_chat_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/warehouse/presentation/screens/goods_receipt_screen.dart';
import '../../features/warehouse/presentation/screens/warehouse_dashboard_screen.dart'; // شاشة الموبايل القديمة
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../providers/settings_providers.dart';

// ==========================================
// استيراد الداشبورد المركزي الذكي الجديد فقط
// ==========================================
import '../../features/admin/presentation/providers/staff_session_providers.dart';
import '../../features/admin/presentation/screens/unified_dashboard_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final role = ValueNotifier<UserRole?>(null);
  final staffLoggedIn = ValueNotifier<bool>(false);
  // Onboarding is only for a first launch with no session: a signed-in user
  // (e.g. back from the web Google OAuth redirect) goes straight in.
  bool needsOnboarding() =>
      ref.read(isFirstLaunchProvider) && !hasActiveSession(ref);
  final firstLaunch = ValueNotifier<bool>(needsOnboarding());
  ref
    ..listen(
      userRoleProvider,
      (_, next) => role.value = next.valueOrNull,
      fireImmediately: true,
    )
    ..listen(
      staffSessionProvider,
      (_, next) => staffLoggedIn.value = next != null,
      fireImmediately: true,
    )
    ..listen(
      isFirstLaunchProvider,
      (_, __) => firstLaunch.value = needsOnboarding(),
    )
    ..listen(
      currentUserProvider,
      (_, __) => firstLaunch.value = needsOnboarding(),
    )
    ..onDispose(role.dispose)
    ..onDispose(firstLaunch.dispose)
    ..onDispose(staffLoggedIn.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge([role, firstLaunch, staffLoggedIn]),
    redirect: (context, state) =>
        onboardingRedirect(
          state.matchedLocation,
          firstLaunch: firstLaunch.value,
          role: role.value,
        ) ??
        roleRedirect(
          state.matchedLocation,
          role.value,
          hasStaffSession: staffLoggedIn.value,
        ),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _smoothPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.warehouse,
        name: 'warehouse',
        pageBuilder: (context, state) =>
            _smoothPage(state, const WarehouseDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.goodsReceipt,
        name: 'goods-receipt',
        pageBuilder: (context, state) =>
            _smoothPage(state, const GoodsReceiptScreen()),
      ),
      GoRoute(
        path: AppRoutes.driver,
        name: 'driver',
        pageBuilder: (context, state) =>
            _smoothPage(state, const DriverDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.driverMap,
        name: 'driver-map',
        pageBuilder: (context, state) => _smoothPage(
          state,
          OrderMapScreen(
            latitude:
                double.tryParse(state.uri.queryParameters['lat'] ?? ''),
            longitude:
                double.tryParse(state.uri.queryParameters['lng'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            _smoothPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _smoothPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        pageBuilder: (context, state) =>
            _smoothPage(state, const CartScreen()),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        pageBuilder: (context, state) =>
            _smoothPage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is PaymentRouteArgs) {
            return _smoothPage(
              state,
              PaymentScreen(
                amount: extra.amount,
                initialCard: extra.savedCard,
                orderId: extra.orderId,
              ),
            );
          }
          return _smoothPage(
            state,
            PaymentScreen(amount: extra is double ? extra : 0),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) =>
            _smoothPage(state, const AuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        pageBuilder: (context, state) =>
            _smoothPage(state, const MyOrdersScreen()),
      ),
      GoRoute(
        path: AppRoutes.orderTrackingPattern,
        name: 'order-tracking',
        pageBuilder: (context, state) => _smoothPage(
          state,
          OrderTrackingScreen(
            orderId: state.pathParameters['id']!,
            latitude:
                double.tryParse(state.uri.queryParameters['lat'] ?? ''),
            longitude:
                double.tryParse(state.uri.queryParameters['lng'] ?? ''),
            driverPhone: state.uri.queryParameters['driver_phone'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderRatingPattern,
        name: 'order-rating',
        pageBuilder: (context, state) => _smoothPage(
          state,
          OrderRatingScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) =>
            _smoothPage(state, const FavoritesScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            _smoothPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.addresses,
        name: 'addresses',
        pageBuilder: (context, state) =>
            _smoothPage(state, const AddressesScreen()),
      ),
      GoRoute(
        path: AppRoutes.addAddress,
        name: 'add-address',
        pageBuilder: (context, state) =>
            _smoothPage(state, const AddAddressScreen()),
      ),
      GoRoute(
        path: AppRoutes.mapPicker,
        name: 'map-picker',
        pageBuilder: (context, state) => _smoothPage(
          state,
          MapPickerScreen(
            initialCenter:
                state.extra is LatLng ? state.extra! as LatLng : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) =>
            _smoothPage(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        name: 'wallet',
        pageBuilder: (context, state) =>
            _smoothPage(state, const WalletPage()),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        name: 'rewards',
        pageBuilder: (context, state) =>
            _smoothPage(state, const RewardsScreen()),
      ),
      GoRoute(
        path: AppRoutes.wheelGame,
        name: 'wheel-game',
        pageBuilder: (context, state) =>
            _smoothPage(state, const WheelGameScreen()),
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        name: 'puzzle',
        pageBuilder: (context, state) =>
            _smoothPage(state, const PuzzleGameScreen()),
      ),
      GoRoute(
        path: AppRoutes.scratchCard,
        name: 'scratch-card',
        pageBuilder: (context, state) =>
            _smoothPage(state, const ScratchCardScreen()),
      ),
      GoRoute(
        path: AppRoutes.luckyChest,
        name: 'lucky-chest',
        pageBuilder: (context, state) =>
            _smoothPage(state, const LuckyChestScreen()),
      ),
      GoRoute(
        path: AppRoutes.cashierScan,
        name: 'cashier-scan',
        pageBuilder: (context, state) =>
            _smoothPage(state, const CashierScanScreen()),
      ),
      GoRoute(
        path: AppRoutes.magazines,
        name: 'magazines',
        pageBuilder: (context, state) =>
            _smoothPage(state, const MagazinesScreen()),
      ),
      GoRoute(
        path: AppRoutes.offers,
        name: 'offers',
        pageBuilder: (context, state) {
          final title =
              AppLocalizations.of(context)?.notificationTypePromo ??
                  'عروض وخصومات';
          return _smoothPage(
            state,
            ProductListScreen(
              title: title,
              products: allOfferProductsProvider,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (context, state) =>
            _smoothPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.supportChat,
        name: 'support-chat',
        pageBuilder: (context, state) =>
            _smoothPage(state, const CustomerSupportChatScreen()),
      ),
      GoRoute(
        path: AppRoutes.productPattern,
        name: 'product',
        pageBuilder: (context, state) => _smoothPage(
          state,
          ProductDetailsScreen(
            productId: state.pathParameters['id']!,
            initialProduct:
                state.extra is Product ? state.extra! as Product : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.categoryPattern,
        name: 'category',
        pageBuilder: (context, state) => _smoothPage(
          state,
          CategoryScreen(mainCategoryId: state.pathParameters['id']!),
        ),
      ),

      // ==========================================
      // مسار فريق العمل (داشبورد الإدارة الموحد)
      // ==========================================
      GoRoute(
        path: AppRoutes.adminOrders,
        name: 'admin-orders',
        pageBuilder: (context, state) =>
            _smoothPage(state, const UnifiedDashboardScreen()),
      ),
    ],
  );
});

/// Combined slide + fade used for every GoRouter push/pop.
CustomTransitionPage<void> _smoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(rtl ? -0.05 : 0.05, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Post-splash / post-onboarding destination. Always the storefront — staff
/// open the dashboard explicitly from «المزيد» → «لوحة تحكم الإدارة».
String homeRouteFor(UserRole? role) => AppRoutes.home;

/// A first launch goes through onboarding (signing in from there is allowed);
/// once it is done or skipped, onboarding hands over to the user's home —
/// signed in or as a guest.
String? onboardingRedirect(
  String location, {
  required bool firstLaunch,
  required UserRole? role,
}) {
  if (firstLaunch) {
    const allowed = {AppRoutes.splash, AppRoutes.onboarding, AppRoutes.auth};
    return allowed.contains(location) ? null : AppRoutes.onboarding;
  }
  return location == AppRoutes.onboarding ? homeRouteFor(role) : null;
}

String? roleRedirect(
  String location,
  UserRole? role, {
  bool hasStaffSession = false,
}) {
  if (location == AppRoutes.splash || location == AppRoutes.auth) return null;
  if (location.startsWith(AppRoutes.cashierScan) &&
      !(role?.canRedeemLoyalty ?? false)) {
    return AppRoutes.home;
  }

  final isStaffRole = role == UserRole.driver ||
      role == UserRole.warehouse ||
      role == UserRole.admin ||
      role == UserRole.cashier;
  final isStaffArea = location.startsWith('/admin');

  // Customers cannot open the admin area. Profile staff roles OR an active
  // dashboard staff session may stay on `/admin/...` (staff login gate).
  // Never auto-send staff/admins to the dashboard — they open it themselves.
  if (!isStaffRole && !hasStaffSession && isStaffArea) return AppRoutes.home;
  return null;
}
