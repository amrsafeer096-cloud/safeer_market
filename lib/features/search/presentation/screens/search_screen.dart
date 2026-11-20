import 'dart:async';

import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/barcode_scan_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/weight_options.dart'; // تم إضافة مكتبة الأوزان
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_feedback.dart';
import '../../../catalog/domain/product_search.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/providers/products_providers.dart';
import '../../../home/presentation/providers/product_visibility_provider.dart';
import '../../../home/presentation/widgets/app_list_item.dart';
import '../../../home/presentation/widgets/missing_image_badge.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../home/presentation/widgets/product_image_canvas.dart';
import '../../../home/presentation/widgets/product_price.dart';
import '../providers/barcode_scanner_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    this.cartKey,
    this.onFlyToCart,
    this.scanOnOpen = false,
  });

  final GlobalKey<CartIconKey>? cartKey;
  final Future<void> Function(GlobalKey imageKey)? onFlyToCart;

  /// Opens the barcode scanner as soon as the screen appears.
  final bool scanOnOpen;

  static const debounce = Duration(milliseconds: 300);

  /// Arabic search terms, matched against Arabic product names.
  static const suggestions = ['لبن', 'جبنة', 'أرز', 'زيت', 'سكر', 'شاي'];
  static String suggestionLabel(AppLocalizations l10n, String suggestion) =>
      switch (suggestion) {
        'لبن' => l10n.searchSuggestionMilk,
        'جبنة' => l10n.searchSuggestionCheese,
        'أرز' => l10n.searchSuggestionRice,
        'زيت' => l10n.searchSuggestionOil,
        'سكر' => l10n.searchSuggestionSugar,
        'شاي' => l10n.searchSuggestionTea,
        _ => suggestion,
      };

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _beepPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  Timer? _debounce;
  String _query = '';
  bool _isBarcode = false;
  List<Product> _lastResults = const [];

  @override
  void initState() {
    super.initState();
    if (widget.scanOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanBarcode();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _beepPlayer.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _query = '';
        _isBarcode = false;
      });
      return;
    }
    _debounce = Timer(SearchScreen.debounce, () {
      if (mounted) {
        setState(() {
          _query = query;
          _isBarcode = false;
        });
      }
    });
  }

  void _search(String text, {bool isBarcode = false}) {
    _controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _debounce?.cancel();
    setState(() {
      _query = text.trim();
      _isBarcode = isBarcode;
    });
  }

  Future<void> _scanBarcode() async {
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
    String? result;
    try {
      result = await ref.read(barcodeScannerProvider)(context);
    } on PlatformException {
      _showScanError(l10n.cameraOpenFailed);
      return;
    } on MissingPluginException {
      _showScanError(l10n.barcodeScanUnsupported);
      return;
    }

    if (!mounted || result == null) return;
    final barcode = result.trim();
    if (barcode.isEmpty || barcode == '-1') return;

    _playScanFeedback();
    _search(barcode, isBarcode: true);
  }

  void _playScanFeedback() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.vibrate();
    _beepPlayer
        .play(AssetSource('sounds/beep.mp3'), mode: PlayerMode.lowLatency)
        .catchError((Object _) {});
  }

  List<Product> _localMatches() {
    // Only what is already in memory: reading productsProvider here would
    // pull the whole catalog down just to pre-fill a search.
    final loaded = [
      ..._lastResults,
      ...?ref.read(featuredProductsProvider).valueOrNull,
      if (ref.exists(productsProvider))
        ...?ref.read(productsProvider).valueOrNull,
    ];
    return ProductSearch.filter(loaded, _query);
  }

  void _showScanError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchHeader(
          cartKey: widget.cartKey,
          controller: _controller,
          onChanged: _onChanged,
          onSubmitted: _search,
          onClear: () => _search(''),
          onScan: _scanBarcode,
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_query.isEmpty) {
      _lastResults = const [];
      return _SearchIntro(onSuggestionTap: _search);
    }

    final provider = productSearchProvider(_query);
    final resultsAsync = ref.watch(provider);
    if (resultsAsync.hasError && !resultsAsync.isLoading) {
      return _SearchMessage(
        icon: Icons.wifi_off_rounded,
        message: l10n.searchFailedCheckConnection,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(provider),
      );
    }

    if (resultsAsync.valueOrNull case final results?) _lastResults = results;
    final matches = resultsAsync.valueOrNull ?? _localMatches();
    final results = shownProducts(ref, matches.available);
    final loading = resultsAsync.isLoading;

    if (results.isEmpty && _isBarcode) {
      final scanned = matches
          .where((p) => ProductSearch.matchesBarcode(p, _query))
          .firstOrNull;
      if (scanned != null) {
        return _SearchMessage(
          icon: Icons.remove_shopping_cart_outlined,
          message: l10n.productUnavailableNow,
          hint: scanned.name,
          actionLabel: l10n.scanAnotherProduct,
          onAction: _scanBarcode,
        );
      }
    }

    if (!loading && results.isEmpty && _isBarcode) {
      return _SearchMessage(
        icon: Icons.search_off_rounded,
        message: l10n.noProductWithBarcode(_query),
        hint: l10n.productMayBeUnavailable,
        actionLabel: l10n.scanAgain,
        onAction: _scanBarcode,
      );
    }

    if (!loading && results.isEmpty) {
      return _SearchMessage(
        icon: Icons.search_off_rounded,
        message: l10n.noSearchResultsFor(_query),
        hint: l10n.searchTryAnotherWord,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 3,
          child: loading ? const LinearProgressIndicator() : null,
        ),
        if (!loading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.searchResultsCount('${results.length}', _query),
                style: TextStyle(fontSize: 13, color: context.palette.muted),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _SearchResultTile(
              product: results[index],
              query: _query,
              onFlyToCart: widget.onFlyToCart,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.cartKey,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onScan,
  });

  final GlobalKey<CartIconKey>? cartKey;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final line = palette.isDark ? palette.border : const Color(0xFFE3E6EB);
    final soft =
        palette.isDark ? palette.muted : const Color(0xFF8A919C);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.isDark ? palette.surface : const Color(0xFFF3F7FC),
            palette.card,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.searchInSafeer,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: palette.onSurface,
                    ),
                  ),
                ),
                _HeaderCartButton(cartKey: cartKey),
              ],
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: palette.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Material(
                color: palette.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: line),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchProductHint,
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: soft,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: palette.accent,
                      ),
                      suffixIcon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, value, child) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (value.text.isNotEmpty)
                              IconButton(
                                tooltip: l10n.clearSearch,
                                onPressed: onClear,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: soft,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: Material(
                                color: palette.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(13),
                                child: IconButton(
                                  tooltip: l10n.scanBarcode,
                                  onPressed: onScan,
                                  icon: BarcodeScanIcon(
                                    size: 22,
                                    color: palette.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCartButton extends ConsumerWidget {
  const _HeaderCartButton({required this.cartKey});

  final GlobalKey<CartIconKey>? cartKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final count = ref.watch(cartItemCountProvider);
    final icon = Badge.count(
      count: count,
      isLabelVisible: count > 0,
      backgroundColor: AppColors.secondary,
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
      child: Icon(
        Icons.shopping_cart_outlined,
        color: palette.onSurface,
        size: 26,
      ),
    );
    final key = cartKey;

    return Material(
      color: palette.card.withValues(alpha: 0.85),
      shape: CircleBorder(
        side: BorderSide(
          color: palette.isDark ? palette.border : const Color(0xFFE3E6EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: AppLocalizations.of(context)!.cart,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          context.push(AppRoutes.cart);
        },
        icon: key == null
            ? icon
            : AddToCartIcon(
                key: key,
                badgeOptions: const BadgeOptions(active: false),
                icon: icon,
              ),
      ),
    );
  }
}

class _SearchResultTile extends ConsumerStatefulWidget {
  const _SearchResultTile({
    required this.product,
    required this.query,
    required this.onFlyToCart,
  });

  static const imageSize = 65.0;

  final Product product;
  final String query;
  final Future<void> Function(GlobalKey imageKey)? onFlyToCart;

  @override
  ConsumerState<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends ConsumerState<_SearchResultTile> {
  final _imageKey = GlobalKey();

  Future<void> _increment(int? grams) async {
    Future<void>? flight;
    if (grams != null) {
      flight = widget.onFlyToCart?.call(_imageKey);
      ref
          .read(cartProvider.notifier)
          .setWeight(widget.product, WeightOptions.next(grams));
    } else {
      await addToCartWithFeedback(
        context,
        ref,
        widget.product,
        onAdding: () => flight = widget.onFlyToCart?.call(_imageKey),
      );
    }
    await flight;
  }

  void _decrement(int quantity, int? grams) {
    final cart = ref.read(cartProvider.notifier);
    if (grams != null) {
      cart.setWeight(widget.product, WeightOptions.previous(grams));
    } else {
      cart.updateQuantity(widget.product.id, quantity - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final query = widget.query;

    final inCart = ref.watch(
      cartProvider.select((items) => items
          .where((item) => item.product.id == product.id)
          .map((item) => (item.quantity, item.selectedWeightInGrams))
          .firstOrNull),
    );
    final quantity = inCart?.$1 ?? 0;
    final grams = inCart?.$2;
    final canAdd = switch (grams) {
      final grams? => WeightOptions.next(grams) != grams,
      null => quantity == 0 || quantity < product.stockQuantity,
    };

    final missingImage = flagsMissingImage(ref, product);
    final brokenImages = ref.read(brokenImageProductsProvider.notifier);
    final palette = context.palette;

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: missingImage
            ? BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.55),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          FocusScope.of(context).unfocus();
          context.push(AppRoutes.product(product.id), extra: product);
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: _SearchResultTile.imageSize,
                height: _SearchResultTile.imageSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // Photos are shot on white: a white canvas in both themes.
                  color: ProductImageCanvas.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: palette.accent.withValues(alpha: 0.06),
                  ),
                ),
                child: AppListItem(
                  flightKey: _imageKey,
                  imageUrl: product.imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: ColoredBox(
                      color: ProductImageCanvas.color,
                      child: FittedBox(
                        child: SizedBox.square(
                          dimension: _SearchResultTile.imageSize,
                          child: ProductImage(
                            // Known-broken links aren't requested again.
                            imageUrl: productLacksImage(ref, product)
                                ? null
                                : product.imageUrl,
                            iconSize: 26,
                            fit: BoxFit.contain,
                            padding: const EdgeInsets.all(4),
                            placeholderBackground: false,
                            onLoadFailed: (_) => brokenImages.report(product),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedName(name: product.name, query: query),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ProductPrice(product: product, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        OfferBadge(product: product),
                      ],
                    ),
                    if (missingImage) ...[
                      const SizedBox(height: 4),
                      MissingImageBadge(product: product),
                    ],
                  ],
                ),
              ),

              // العداد الذكي بدل الزرار الثابت
              if (quantity == 0)
                IconButton.filled(
                  tooltip: AppLocalizations.of(context)!.addToCart,
                  onPressed: canAdd ? () => _increment(grams) : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _decrement(quantity, grams),
                        style: IconButton.styleFrom(
                          backgroundColor: palette.card,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.square(32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.remove_rounded,
                            size: 18, color: AppColors.secondary),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          grams == null
                              ? '$quantity'
                              : WeightOptions.label(grams),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: canAdd ? () => _increment(grams) : null,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.square(32),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_rounded,
                            size: 18, color: Colors.white),
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

class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.name, required this.query});

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: palette.onSurface,
      height: 1.4,
    );
    final start = name.toLowerCase().indexOf(query.toLowerCase());
    if (start < 0 || query.isEmpty) {
      return Text(name,
          maxLines: 2, overflow: TextOverflow.ellipsis, style: base);
    }
    final end = start + query.length;

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: name.substring(0, start)),
          TextSpan(
            text: name.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: palette.accent,
            ),
          ),
          TextSpan(text: name.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchIntro extends StatelessWidget {
  const _SearchIntro({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final line = palette.isDark ? palette.border : const Color(0xFFE3E6EB);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          l10n.popularSearches,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: palette.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in SearchScreen.suggestions)
              ActionChip(
                avatar: Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: palette.accent,
                ),
                label: Text(
                  SearchScreen.suggestionLabel(l10n, suggestion),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                  ),
                ),
                backgroundColor: palette.isDark
                    ? palette.surface
                    : const Color(0xFFF3F7FC),
                side: BorderSide(color: line),
                shape: const StadiumBorder(),
                elevation: palette.isDark ? 0 : 1,
                shadowColor: AppColors.primary.withValues(alpha: 0.08),
                onPressed: () => onSuggestionTap(suggestion),
              ),
          ],
        ),
        const SizedBox(height: 48),
        Icon(
          Icons.manage_search_rounded,
          size: 72,
          color: palette.accent.withValues(alpha: 0.22),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.searchIntroSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14, color: palette.muted),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: palette.accent.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (hint != null)
              Text(
                hint!,
                style: TextStyle(fontSize: 14, color: palette.muted),
              ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
