import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../cart/presentation/widgets/cart_flight.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/main_categories.dart';
import '../category_labels.dart';
import '../providers/category_providers.dart';
import '../widgets/main_category_image.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.mainCategoryId});
  final String mainCategoryId;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final GlobalKey<CartIconKey> _cartKey = GlobalKey<CartIconKey>();

  Future<void> _flyToCart(GlobalKey imageKey) =>
      flyToCart(imageKey: imageKey, cartKey: _cartKey);

  @override
  Widget build(BuildContext context) {
    final category = MainCategories.byId(widget.mainCategoryId);
    if (category == null) return const _UnknownCategory();
    final l10n = AppLocalizations.of(context)!;

    final tabs = <String?>[null, ...category.subCategories];
    final palette = context.palette;
    final titleStyle = Theme.of(context)
        .appBarTheme
        .titleTextStyle
        ?.copyWith(color: palette.onSurface);

    return DefaultTabController(
      length: tabs.length,
      child: MobileFrame(
        child: Scaffold(
          backgroundColor: palette.surface,
          appBar: AppBar(
            backgroundColor: palette.card,
            surfaceTintColor: Colors.transparent,
            foregroundColor: palette.onSurface,
            titleTextStyle: titleStyle,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: mainCategoryDecoration(
                    category,
                    borderRadius: BorderRadius.circular(10),
                    backdrop: context.palette.imageBackdrop,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(localizedCategoryName(l10n, category.name)),
                ),
              ],
            ),
            actions: [
              AddToCartIcon(
                key: _cartKey,
                badgeOptions: const BadgeOptions(active: false),
                icon: const CartIconButton(),
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              dividerColor: Colors.transparent,
              indicator: const BoxDecoration(),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                for (final (index, sub) in tabs.indexed)
                  _SubCategoryTab(
                    label: sub == null
                        ? l10n.all
                        : localizedCategoryName(l10n, sub),
                    index: index,
                  ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              for (final sub in tabs)
                _CategoryProductsTab(
                  query: (mainCategoryId: category.id, subCategory: sub),
                  onFlyToCart: _flyToCart,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryTab extends StatelessWidget {
  const _SubCategoryTab({required this.label, required this.index});
  static const accent = AppColors.primary;
  final String label;
  final int index;
  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final palette = context.palette;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.index == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent : palette.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? accent : palette.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : palette.onSurface,
            ),
          ),
        );
      },
    );
  }
}

class _CategoryProductsTab extends ConsumerStatefulWidget {
  const _CategoryProductsTab({required this.query, required this.onFlyToCart});
  final CategoryQuery query;
  final Future<void> Function(GlobalKey) onFlyToCart;
  @override
  ConsumerState<_CategoryProductsTab> createState() =>
      _CategoryProductsTabState();
}

class _CategoryProductsTabState extends ConsumerState<_CategoryProductsTab>
    with AutomaticKeepAliveClientMixin {
  static const _loadMoreExtent = 800.0;
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scroll.hasClients) return;
    final state = ref.read(categoryProductsProvider(widget.query)).valueOrNull;
    if (state == null ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.loadMoreError != null) {
      return;
    }
    if (_scroll.position.extentAfter < _loadMoreExtent) {
      ref.read(categoryProductsProvider(widget.query).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final query = widget.query;
    final productsAsync = ref.watch(categoryProductsProvider(query));
    final palette = context.palette;

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());

    return RefreshIndicator(
      color: palette.accent,
      onRefresh: () => ref.refresh(categoryProductsProvider(query).future),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...productsAsync.when(
            skipLoadingOnReload: true,
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              _StatusSliver(
                icon: Icons.wifi_off_rounded,
                color: palette.accent,
                title: l10n.failedToLoadProducts,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(categoryProductsProvider(query)),
              ),
            ],
            data: (state) {
              final products = shownProducts(ref, state.products);
              return [
                if (products.isEmpty && !state.hasMore)
                  _StatusSliver(
                    icon: Icons.storefront_outlined,
                    color: palette.accent,
                    title: l10n.categoryNoProductsNow,
                    actionLabel: l10n.shopFromHome,
                    onAction: () => goToHomeTab(context, ref),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.categoryProductCount('${state.total}'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.muted,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver:
                        SliverLayoutBuilder(builder: (context, constraints) {
                      // تحديد عدد الأعمدة بناءً على عرض الشاشة المتاح
                      // إذا كانت الشاشة كبيرة (كمبيوتر)، نعرض 4 أو 5 أو أكثر
                      // إذا كانت صغيرة (موبايل)، نعرض 2 فقط
                      int crossAxisCount =
                          (constraints.crossAxisExtent / 180).floor();
                      if (crossAxisCount < 2)
                        crossAxisCount = 2; // الحد الأدنى عمودين للموبايل

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // تعديل نسبة الطول للعرض عشان الكارت ميتمطش زيادة في الشاشات العريضة
                          childAspectRatio: 0.65,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = products[index];
                            return RepaintBoundary(
                              child: ProductCard(
                                product: product,
                                onAdd: () => addToCartWithFeedback(
                                    context, ref, product),
                                onFlyToCart: widget.onFlyToCart,
                              ),
                            );
                          },
                          childCount: products.length,
                          addAutomaticKeepAlives: false,
                        ),
                      );
                    }),
                  ),
                  SliverToBoxAdapter(
                    child: _LoadMoreFooter(
                      state: state,
                      onRetry: () => ref
                          .read(categoryProductsProvider(query).notifier)
                          .loadMore(),
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onRetry});
  final CategoryProductsState state;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Center(
        child: switch (state) {
          CategoryProductsState(loadMoreError: _?) => TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.loadMoreFailedRetry),
            ),
          CategoryProductsState(isLoadingMore: true) =>
            const CircularProgressIndicator(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _UnknownCategory extends ConsumerWidget {
  const _UnknownCategory();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.categoryTitle)),
        body: CustomScrollView(
          slivers: [
            _StatusSliver(
              icon: Icons.category_outlined,
              color: palette.accent,
              title: l10n.categoryNotFound,
              actionLabel: l10n.shopFromHome,
              onAction: () => goToHomeTab(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSliver extends StatelessWidget {
  const _StatusSliver({
    required this.icon,
    required this.color,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
