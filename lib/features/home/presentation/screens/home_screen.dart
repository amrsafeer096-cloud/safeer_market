import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../cart/presentation/widgets/cart_flight.dart';
import '../../../catalog/presentation/widgets/categories_drawer.dart';
import '../../../profile/presentation/screens/more_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../support/presentation/providers/support_providers.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../domain/entities/product.dart';
import '../providers/home_providers.dart';
import '../providers/products_providers.dart';
import '../widgets/categories_grid.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_support_speed_dial.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../widgets/promo_carousel.dart';
import 'product_list_screen.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../../subscriptions/presentation/screens/paywall_screen.dart';
import '../providers/product_visibility_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const exitWindow = Duration(seconds: 2);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static List<({String label, IconData icon, IconData active})> _tabs(
    AppLocalizations l10n,
  ) =>
      [
        (
          label: l10n.home,
          icon: Icons.home_outlined,
          active: Icons.home_rounded
        ),
        (
          label: l10n.search,
          icon: Icons.search_rounded,
          active: Icons.search_rounded
        ),
        (
          label: l10n.cart,
          icon: Icons.shopping_cart_outlined,
          active: Icons.shopping_cart_rounded,
        ),
        (
          label: l10n.wallet,
          icon: Icons.account_balance_wallet_outlined,
          active: Icons.account_balance_wallet_rounded,
        ),
        (
          label: l10n.more,
          icon: Icons.menu_rounded,
          active: Icons.menu_open_rounded
        ),
      ];

  DateTime? _lastBackPress;

  final _cartKey = GlobalKey<CartIconKey>();

  /// Cart icon in the search header; flights land there on the search tab.
  final _searchCartKey = GlobalKey<CartIconKey>();

  GlobalKey<CartIconKey> get _flightTarget =>
      ref.read(homeTabIndexProvider) == searchTabIndex
          ? _searchCartKey
          : _cartKey;

  /// Whether the next search tab opens straight into the barcode scanner.
  bool _scanOnSearchOpen = false;

  void _openSearch({bool scan = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _scanOnSearchOpen = scan;
    ref.read(homeTabIndexProvider.notifier).state = searchTabIndex;
  }

  Future<void> _flyToCart(GlobalKey imageKey) =>
      flyToCart(imageKey: imageKey, cartKey: _flightTarget);

  void _handleBack() {
    final tabs = ref.read(homeTabIndexProvider.notifier);
    if (tabs.state != homeTabIndex) {
      _lastBackPress = null;
      tabs.state = homeTabIndex;
      return;
    }

    final now = DateTime.now();
    final last = _lastBackPress;
    if (last != null && now.difference(last) <= HomeScreen.exitWindow) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.exitHint),
          duration: HomeScreen.exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);
    final tabs = _tabs(AppLocalizations.of(context)!);
    final palette = context.palette;

    // The cart tab only pushes the cart route and is never selected, so its
    // AddToCartIcon (and the GlobalKey on it) is built exactly once. Only
    // the badge watches the cart: adding a product must not rebuild the
    // whole screen and every card on it.
    Widget tabIcon(int index, IconData icon) {
      if (index == cartTabIndex) {
        return AddToCartIcon(
          key: _cartKey,
          badgeOptions: const BadgeOptions(active: false),
          icon: _CartCountBadge(icon: icon),
        );
      }
      if (index == moreTabIndex) {
        return _SupportUnreadBadge(icon: icon);
      }
      return Icon(icon);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: MobileFrame(
        color: palette.page,
        child: Scaffold(
          backgroundColor: palette.page,
          drawer: tabIndex == homeTabIndex ? const CategoriesDrawer() : null,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              SafeArea(
                bottom: false,
                child: switch (tabIndex) {
                  searchTabIndex => SearchScreen(
                      cartKey: _searchCartKey,
                      onFlyToCart: _flyToCart,
                      scanOnOpen: _scanOnSearchOpen,
                    ),
                  walletTabIndex => const WalletScreen(),
                  moreTabIndex => const MoreScreen(),
                  _ => _HomeTab(
                      onFlyToCart: _flyToCart,
                      onSearch: _openSearch,
                      onScan: () => _openSearch(scan: true),
                    ),
                },
              ),
              // Physical far bottom-right (ignores RTL so it stays on the right).
              if (tabIndex == homeTabIndex)
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: HomeSupportSpeedDial(),
                ),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: palette.isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                currentIndex: tabIndex,
                elevation: 0,
                backgroundColor: palette.card,
                selectedLabelStyle: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
                onTap: (index) {
                  if (index == cartTabIndex) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.push(AppRoutes.cart);
                  } else {
                    _scanOnSearchOpen = false;
                    ref.read(homeTabIndexProvider.notifier).state = index;
                  }
                },
                items: [
                  for (final (index, tab) in tabs.indexed)
                    BottomNavigationBarItem(
                      icon: tabIcon(index, tab.icon),
                      activeIcon: index == cartTabIndex
                          ? null
                          : tabIcon(index, tab.active),
                      label: tab.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartCountBadge extends ConsumerWidget {
  const _CartCountBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    return Badge.count(
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: AppColors.secondary,
      textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
      child: Icon(icon),
    );
  }
}

/// Red unread badge on «المزيد» when خدمة العملاء has unread admin replies.
class _SupportUnreadBadge extends ConsumerWidget {
  const _SupportUnreadBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(customerSupportUnreadProvider).valueOrNull ?? 0;
    return Badge(
      key: const Key('more-support-badge'),
      isLabelVisible: count > 0,
      backgroundColor: Colors.red,
      label: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      child: Icon(icon),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({
    required this.onFlyToCart,
    required this.onSearch,
    required this.onScan,
  });

  final Future<void> Function(GlobalKey imageKey) onFlyToCart;
  final VoidCallback onSearch;
  final VoidCallback onScan;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _newProductsKey = GlobalKey();
  final _offersKey = GlobalKey();

  /// Scrolls to the section behind [anchor], or says why it isn't there.
  void _scrollTo(
    GlobalKey anchor,
    FutureProvider<List<Product>> section, {
    required String loading,
    required String empty,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final target = anchor.currentContext;
    if (target == null) {
      _showMessage(
        context,
        ref.read(section).isLoading ? loading : empty,
      );
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openAll(String title, FutureProvider<List<Product>> products) =>
      ProductListScreen.open(context, title: title, products: products);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(featuredProductsProvider);
    final onFlyToCart = widget.onFlyToCart;
    // Admins: «منتجات جديدة» lists every product that needs a photo.
    final missingImageCount = ref.watch(showProductsWithoutImageProvider)
        ? ref.watch(allNewProductsProvider).valueOrNull?.length
        : null;
    final allNewProductsTitle = missingImageCount == null
        ? l10n.newProducts
        : l10n.newProductsMissingImageCount('$missingImageCount');

    // Optional rows: a skeleton until the first load, then shown only when
    // they have products, so a failed or empty row leaves no gap.
    List<Widget> optionalSection(
      _SectionHeader header,
      AsyncValue<List<Product>> section,
    ) {
      final products = section.valueOrNull;
      if (products == null) {
        return section.isLoading
            ? [
                header,
                const SliverToBoxAdapter(child: _ProductsRowSkeleton()),
              ]
            : const [];
      }
      if (products.isEmpty) return const [];
      return [
        header,
        SliverToBoxAdapter(
          child: _ProductsRow(products: products, onFlyToCart: onFlyToCart),
        ),
      ];
    }

    return Column(
      children: [
        HomeAppBar(
          onNotificationsTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.push(AppRoutes.notifications);
          },
          onSearchTap: widget.onSearch,
          onScanTap: widget.onScan,
        ),
        Expanded(
          child: RefreshIndicator(
            color: context.palette.accent,
            onRefresh: () => Future.wait([
              ref.refresh(featuredProductsProvider.future),
              ref.refresh(allOfferProductsProvider.future),
              ref.refresh(ref.read(showProductsWithoutImageProvider)
                  ? productsWithoutImageProvider.future
                  : recentProductsProvider.future),
            ]),
            child: CustomScrollView(
              // Coming back from another tab lands where the user left off.
              key: const PageStorageKey('home-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                  sliver: SliverToBoxAdapter(
                    // The badges pulse and float forever: their own layer,
                    // so each of those frames repaints only them.
                    child: RepaintBoundary(
                      child: HomeQuickActions(
                        onNewProducts: () => _scrollTo(
                          _newProductsKey,
                          newProductsProvider,
                          loading: l10n.loadingLatestProducts,
                          empty: l10n.noNewProductsLast3Days,
                        ),
                        onOffers: () => _scrollTo(
                          _offersKey,
                          offerProductsProvider,
                          loading: l10n.loadingOffers,
                          empty: l10n.noOffersCurrently,
                        ),
                        onPlayAndWin: () async {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          final subscribed = await hasActivePaidPlan(ref);
                          if (!context.mounted) return;

                          if (!subscribed) {
                            // إظهار نافذة الترقية من الأسفل
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: context.palette.card,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars_rounded,
                                        color: Colors.amber, size: 70),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.subscribersExclusiveFeature,
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: context.palette.onSurface),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.playAndWinPaywallBody,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: context.palette.muted,
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          // Near-black vanishes on the dark
                                          // sheet; brand blue there.
                                          backgroundColor:
                                              context.palette.isDark
                                                  ? AppColors.primary
                                                  : const Color(0xFF1C1C1E),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(
                                              context); // قفل النافذة الحالية
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PaywallScreen()));
                                        },
                                        child: Text(l10n.upgradeAccountNow,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            context.push(AppRoutes.rewards);
                          }
                        },
                        onCategories: () => Scaffold.of(context).openDrawer(),
                        onMagazines: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          context.push(AppRoutes.magazines);
                        },
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 20),
                  // Its own layer: the deck's timer and swipes repaint only
                  // the deck, never the scroll view around it.
                  sliver: SliverToBoxAdapter(
                    child: RepaintBoundary(child: PromoCarousel()),
                  ),
                ),
                _SectionHeader(
                  title: l10n.exploreSafeer,
                  // Lines up with the centered desktop grid below.
                  sideInset: CategoriesLayout.sideInset(
                      MediaQuery.sizeOf(context).width),
                  onSeeAll: () => Scaffold.of(context).openDrawer(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: CategoriesGrid(
                    onCategoryTap: (category) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      context.push(AppRoutes.category(category.id));
                    },
                  ),
                ),
                _SectionHeader(
                  title: l10n.featuredProducts,
                  onSeeAll: productsAsync.valueOrNull?.isNotEmpty ?? false
                      ? () => _openAll(
                          l10n.featuredProducts, featuredProductsProvider)
                      : null,
                ),
                ...productsAsync.when(
                  loading: () => const [
                    SliverToBoxAdapter(child: _ProductsRowSkeleton()),
                  ],
                  error: (error, _) => [
                    _MessageSliver(
                      icon: Icons.wifi_off_rounded,
                      message: l10n.failedToLoadProducts,
                      onRetry: () => ref.invalidate(featuredProductsProvider),
                    ),
                  ],
                  data: (products) => [
                    if (products.isEmpty)
                      _MessageSliver(
                        icon: Icons.storefront_outlined,
                        message: l10n.noProductsCurrently,
                        onRetry: () => ref.invalidate(featuredProductsProvider),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _ProductsRow(
                          products: products,
                          onFlyToCart: onFlyToCart,
                        ),
                      ),
                  ],
                ),
                ...optionalSection(
                  _SectionHeader(
                    anchorKey: _offersKey,
                    title: l10n.trendingOffers,
                    onSeeAll: () =>
                        _openAll(l10n.trendingOffers, allOfferProductsProvider),
                  ),
                  ref.watch(offerProductsProvider),
                ),
                ...optionalSection(
                  _SectionHeader(
                    anchorKey: _newProductsKey,
                    title: l10n.newProducts,
                    alert: missingImageCount == null
                        ? null
                        : l10n.missingImageCountBadge('$missingImageCount'),
                    onSeeAll: () =>
                        _openAll(allNewProductsTitle, allNewProductsProvider),
                  ),
                  ref.watch(newProductsProvider),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductsRow extends ConsumerWidget {
  const _ProductsRow({
    required this.products,
    required this.onFlyToCart,
  });

  static const cardWidth = 170.0;
  static const gap = 14.0;
  static const rowHeight = 320.0;
  static const animatedCards = 4;
  // Room for the cards' shadows, which a horizontal list would clip.
  static const padding = EdgeInsets.fromLTRB(16, 4, 16, 18);

  final List<Product> products;
  final Future<void> Function(GlobalKey imageKey) onFlyToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = shownProducts(ref, this.products);
    return SizedBox(
      height: rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        // Fixed extent: scroll layout costs nothing per card.
        itemExtent: cardWidth + gap,
        addAutomaticKeepAlives: false,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final card = Padding(
            padding: const EdgeInsetsDirectional.only(end: gap),
            child: RepaintBoundary(
              child: ProductCard(
                product: product,
                onAdd: () => addToCartWithFeedback(context, ref, product),
                onFlyToCart: onFlyToCart,
              ),
            ),
          );
          // Only the cards in view on arrival animate in; the rest just
          // scroll in, so a fast swipe runs no entrance animations.
          if (index >= animatedCards) return card;
          return card
              .animate(delay: (60 * index).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1);
        },
      ),
    );
  }
}

class _ProductsRowSkeleton extends StatelessWidget {
  const _ProductsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ProductsRow.rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: _ProductsRow.padding,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => const SizedBox(
          width: _ProductsRow.cardWidth,
          child: ProductCardSkeleton(),
        ),
      ),
    );
  }
}

/// A section title at the start with an optional «عرض الكل» at the end.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onSeeAll,
    this.anchorKey,
    this.alert,
    this.sideInset = 0,
  });

  final String title;

  /// Extra space on both sides (desktop web, to match the centered grid).
  final double sideInset;
  final VoidCallback? onSeeAll;

  /// Short red note after the title, e.g. the admin's missing-image count.
  final String? alert;

  /// Lets the screen scroll this header into view.
  final GlobalKey? anchorKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(
          16 + sideInset, 26, 8 + sideInset, 8),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          key: anchorKey,
          height: 40,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: palette.onSurface,
                  ),
                ),
              ),
              if (alert case final alert?)
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    alert,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSecondary,
                    ),
                  ),
                ),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageSliver extends StatelessWidget {
  const _MessageSliver({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            Icon(icon, size: 44, color: palette.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: palette.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
