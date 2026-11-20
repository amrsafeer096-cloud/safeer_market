import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/resizable_columns.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../cart/presentation/widgets/weight_picker_sheet.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../home/domain/entities/product.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../domain/phone_order.dart';
import '../../domain/repositories/phone_orders_repository.dart';
import '../providers/phone_order_providers.dart';
import 'customer_purchase_history_dialog.dart';
import 'new_customer_dialogs.dart';
import 'product_details_dialog.dart';

/// «تلقي الطلبات»: find (or add) the caller, build their cart, and place
/// the order. [onPlaced] gets the new order's id.
///
/// When [splitLayout] is true, customer/products sit beside a full-height
/// cart column (RTL: products on the right, cart on the left).
class PhoneOrderColumn extends ConsumerWidget {
  const PhoneOrderColumn({
    super.key,
    this.onPlaced,
    this.splitLayout = false,
  });

  /// How long typing pauses before a search runs.
  static const searchDebounce = Duration(milliseconds: 300);

  final ValueChanged<String>? onPlaced;
  final bool splitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final hasCustomer = ref.watch(
      phoneOrderControllerProvider.select((state) => state.customer != null),
    );
    final canPark = ref.watch(
      phoneOrderControllerProvider
          .select((state) => !state.isBlank && !state.submitting),
    );
    final hasParked = ref.watch(
      phoneOrderControllerProvider.select((state) => state.parked.isNotEmpty),
    );

    Widget header() => Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: AlignmentDirectional.centerStart,
          child: Row(children: [
            Icon(Icons.headset_mic_rounded, color: palette.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.adminMenuReceiveOrders,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            // Parks this order (caller, cart, fee, payment, receipt) and
            // opens a blank one.
            OutlinedButton.icon(
              key: const Key('phone-order-add-order'),
              onPressed: canPark
                  ? ref.read(phoneOrderControllerProvider.notifier).parkAndNew
                  : null,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: palette.accent,
                side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة طلب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Spacer(),
          ]),
        );

    if (!splitLayout) {
      return Material(
        color: palette.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(),
            const Divider(height: 1),
            if (hasParked) const _OpenOrdersStrip(),
            Expanded(
              child: hasCustomer
                  ? _OrderBuilder(onPlaced: onPlaced, splitLayout: false)
                  : const _CustomerLookup(),
            ),
          ],
        ),
      );
    }

    final columns = ResizableColumns(
      layoutId: 'admin-receive-orders',
      columns: [
        ResizableColumn(
          flex: 5,
          minWidth: 320,
          child: Material(
            color: palette.card,
            child: hasCustomer
                ? _OrderBuilder(onPlaced: onPlaced, splitLayout: true)
                : const _CustomerLookup(),
          ),
        ),
        ResizableColumn(
          flex: 4,
          minWidth: 280,
          child: Material(
            color: palette.card,
            child: hasCustomer
                ? _CartPanel(
                    open: true,
                    alwaysOpen: true,
                    onToggle: () {},
                    onPlaced: onPlaced,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.adminSelectCustomerFirst,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: palette.muted),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );

    return Material(
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(color: palette.card, child: header()),
          const Divider(height: 1),
          Expanded(
            // RTL: the open-orders list is the far-right column, next to
            // the products.
            child: hasParked
                ? Row(children: [
                    const _OpenOrdersSidebar(),
                    const VerticalDivider(width: 1),
                    Expanded(child: columns),
                  ])
                : columns,
          ),
        ],
      ),
    );
  }
}

/// «طلب جديد» for an order with no caller yet.
String _openOrderTitle(PhoneOrderState order) {
  final name = order.customer?.fullName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final phone = order.customer?.phone?.trim();
  if (phone != null && phone.isNotEmpty) return phone;
  return order.customer == null ? 'طلب جديد' : 'عميل بدون اسم';
}

/// One open (active or parked) order: caller, item count and total.
class _OpenOrderCard extends StatelessWidget {
  const _OpenOrderCard({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final PhoneOrderState order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected
          ? palette.accent.withValues(alpha: 0.12)
          : palette.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('phone-order-open-${order.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _openOrderTitle(order),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: selected ? palette.accent : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.itemCount} منتج',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
              Text(
                AppCurrency.of(order.total),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All open orders as a compact vertical list (wide layout).
class _OpenOrdersSidebar extends ConsumerWidget {
  const _OpenOrdersSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final state = ref.watch(phoneOrderControllerProvider);
    return Material(
      color: palette.card,
      child: SizedBox(
        key: const Key('phone-order-open-orders'),
        width: 148,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
              child: Text(
                'الطلبات المفتوحة (${state.openOrders.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.muted,
                ),
              ),
            ),
            for (final order in state.openOrders)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _OpenOrderCard(
                  order: order,
                  selected: order.id == state.id,
                  onTap: () => ref
                      .read(phoneOrderControllerProvider.notifier)
                      .switchTo(order.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The same list as a horizontal strip (narrow layout).
class _OpenOrdersStrip extends ConsumerWidget {
  const _OpenOrdersStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(phoneOrderControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const Key('phone-order-open-orders'),
          height: 86,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            children: [
              for (final order in state.openOrders)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: SizedBox(
                    width: 132,
                    child: _OpenOrderCard(
                      order: order,
                      selected: order.id == state.id,
                      onTap: () => ref
                          .read(phoneOrderControllerProvider.notifier)
                          .switchTo(order.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Places the active order; failures show as a message and keep the draft.
Future<void> _confirmOrder(
  BuildContext context,
  WidgetRef ref,
  ValueChanged<String>? onPlaced,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  void fail(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.secondary,
      content: Text(message),
    ));
  try {
    final orderId =
        await ref.read(phoneOrderControllerProvider.notifier).submit();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(l10n.phoneOrderPlaced(_shortId(orderId))),
      ));
    onPlaced?.call(orderId);
  } on PhoneOrderFailure catch (failure) {
    fail(failure.message);
  } catch (error) {
    fail(l10n.phoneOrderFailed('$error'));
  }
}

/// «إلغاء الطلب»: drops the active draft (asks first when it has items).
Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(phoneOrderControllerProvider.notifier);
  if (ref.read(phoneOrderControllerProvider).lines.isNotEmpty) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('phone-order-cancel-dialog'),
        title: const Text('إلغاء الطلب'),
        content: const Text(
          'سيتم حذف السلة والعميل ورسوم التوصيل وطريقة الدفع لهذا الطلب. '
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            key: const Key('phone-order-cancel-dismiss'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            key: const Key('phone-order-cancel-confirm'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  controller.cancelCurrent();
  if (context.mounted) _showMessage(context, 'تم إلغاء الطلب', ok: true);
}

/// Picks the InstaPay transfer screenshot for the active order.
Future<void> _pickReceipt(BuildContext context, WidgetRef ref) async {
  try {
    final receipt = await ref.read(phoneOrderReceiptPickerProvider)();
    if (receipt == null) return;
    ref.read(phoneOrderControllerProvider.notifier).setReceipt(receipt);
  } catch (_) {
    if (context.mounted) _showMessage(context, 'تعذّر اختيار الصورة');
  }
}

String _shortId(String id) => id.length >= 6 ? id.substring(0, 6) : id;

void _showMessage(BuildContext context, String message, {bool ok = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: ok ? AppColors.success : AppColors.secondary,
      content: Text(message),
    ));
}

/// Tapping a product row (not its − / +) opens its details: image, barcode,
/// stock and the bulk «إضافة كمية بالجملة».
Future<void> _openProductDetails(
  BuildContext context,
  WidgetRef ref,
  Product product,
) {
  return showProductDetailsDialog(
    context,
    product: product,
    onAddQuantity: (quantity) => ref
        .read(phoneOrderControllerProvider.notifier)
        .addQuantity(product, quantity),
    onPickWeight: () => _addProduct(context, ref, product),
  );
}

/// Unit products go straight into the cart; weight-based products open the
/// weight sheet first (same flow as the customer app).
Future<void> _addProduct(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final controller = ref.read(phoneOrderControllerProvider.notifier);
  if (!product.isWeightBased) {
    controller.add(product);
    return;
  }
  final grams = await showWeightPickerSheet(
    context,
    product: product,
    initialGrams: ref.read(phoneOrderControllerProvider).weightOf(product.id),
    title: 'اختر الوزن المطلوب',
    labelFor: WeightOptions.phoneOrderLabel,
  );
  if (grams == null || !context.mounted) return;
  controller.setWeight(product, grams);
}

// ---------------------------------------------------------------------------
// Customer lookup
// ---------------------------------------------------------------------------

class _CustomerLookup extends ConsumerStatefulWidget {
  const _CustomerLookup();

  @override
  ConsumerState<_CustomerLookup> createState() => _CustomerLookupState();
}

class _CustomerLookupState extends ConsumerState<_CustomerLookup> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(PhoneOrderColumn.searchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  Future<void> _addCustomer() async {
    final typed = _search.text.trim();
    final looksLikePhone = RegExp(r'^[\d\s+()-]+$').hasMatch(typed);
    final customer = await showDialog<PhoneOrderCustomer>(
      context: context,
      builder: (_) => NewCustomerDialog(
        initialName: looksLikePhone ? '' : typed,
        initialPhone: looksLikePhone ? typed : '',
      ),
    );
    if (customer != null) {
      ref
          .read(phoneOrderControllerProvider.notifier)
          .selectCustomerWithZoneFee(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('phone-order-customer-search'),
            controller: _search,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.phoneOrderSearchHint,
              prefixIcon: const Icon(Icons.person_search_rounded),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton(
              key: const Key('phone-order-new-customer'),
              onPressed: _addCustomer,
              child: Text(l10n.phoneOrderNewCustomer),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _query.length < 2
                ? Center(
                    child: Text(l10n.phoneOrderTypeToSearch,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted)),
                  )
                : ref.watch(phoneOrderCustomersProvider(_query)).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text('$error', textAlign: TextAlign.center),
                      ),
                      data: (customers) => customers.isEmpty
                          ? Center(
                              child: Text(l10n.phoneOrderNoCustomers,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: palette.muted)),
                            )
                          : ListView.separated(
                              itemCount: customers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                return _CustomerTile(
                                  customer: customer,
                                  onTap: () => ref
                                      .read(
                                          phoneOrderControllerProvider.notifier)
                                      .selectCustomerWithZoneFee(customer),
                                );
                              },
                            ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final PhoneOrderCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final isApp = customer.source == PhoneOrderCustomerSource.app;
    return ListTile(
      key: Key('phone-order-customer-${customer.key}'),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor:
            (isApp ? palette.accent : Colors.orange).withValues(alpha: 0.15),
        child: Icon(
          isApp ? Icons.phone_iphone_rounded : Icons.point_of_sale_rounded,
          color: isApp ? palette.accent : Colors.orange.shade800,
        ),
      ),
      title: Text(customer.fullName ?? l10n.adminNoName,
          style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.phone ?? l10n.adminNoPhoneNumber,
              textDirection: TextDirection.ltr),
          Text(
            customer.address ?? l10n.phoneOrderNoAddress,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ],
      ),
      trailing: Text(
        isApp ? l10n.phoneOrderAppCustomer : l10n.phoneOrderPosCustomer,
        style: TextStyle(fontSize: 11, color: palette.muted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Products, cart and confirmation
// ---------------------------------------------------------------------------

class _OrderBuilder extends ConsumerStatefulWidget {
  const _OrderBuilder({required this.onPlaced, this.splitLayout = false});

  final ValueChanged<String>? onPlaced;
  final bool splitLayout;

  @override
  ConsumerState<_OrderBuilder> createState() => _OrderBuilderState();
}

class _OrderBuilderState extends ConsumerState<_OrderBuilder> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  /// The cart and delivery fee panel; closed, it is one summary line so the
  /// product results keep the height.
  bool _cartOpen = false;

  PhoneOrderProductQuery get _productQuery => (text: _query, category: null);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(PhoneOrderColumn.searchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  /// A barcode scanner types the code and Enter: an exact barcode match goes
  /// straight into the cart.
  Future<void> _onSubmitted(String text) async {
    final code = text.trim();
    _debounce?.cancel();
    setState(() => _query = code);
    if (code.isEmpty) return;
    try {
      final products = await ref.read(
          phoneOrderProductsProvider((text: code, category: null)).future);
      final match =
          products.where((product) => product.barcode?.trim() == code);
      if (match.length == 1 && mounted) {
        await _addProduct(context, ref, match.single);
        if (!mounted) return;
        _search.clear();
        setState(() => _query = '');
      }
    } catch (_) {
      // The results list shows the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final state = ref.watch(phoneOrderControllerProvider);
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    final customer = state.customer!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LockedCustomer(
          customer: customer,
          onChange: controller.clear,
          onShowHistory: () =>
              showCustomerPurchaseHistoryDialog(context, customer),
        ),
        // The product search sits right under the customer bar; no category
        // chips, so results start immediately below it.
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
          child: TextField(
            key: const Key('phone-order-product-search'),
            controller: _search,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.phoneOrderProductSearchHint,
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Everything not taken by the search above and the cart bar below.
        Expanded(
          child: _query.isEmpty
              ? Center(
                  child: Text(l10n.phoneOrderSearchProductsPrompt,
                      style: TextStyle(color: palette.muted)),
                )
              : ref.watch(phoneOrderProductsProvider(_productQuery)).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text('$error', textAlign: TextAlign.center),
                    ),
                    data: (products) => products.isEmpty
                        ? Center(
                            child: Text(l10n.phoneOrderNoProducts,
                                style: TextStyle(color: palette.muted)),
                          )
                        : ListView.separated(
                            key: const Key('phone-order-products'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 12),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final line = state.lineOf(product.id);
                              return _ProductTile(
                                product: product,
                                line: line,
                                onAdd: () =>
                                    _addProduct(context, ref, product),
                                onOpen: () =>
                                    _openProductDetails(context, ref, product),
                                onRemove: () => controller.remove(product),
                              );
                            },
                          ),
                  ),
        ),
        if (!widget.splitLayout)
          _CartPanel(
            open: _cartOpen,
            onToggle: () => setState(() => _cartOpen = !_cartOpen),
            onPlaced: widget.onPlaced,
          ),
      ],
    );
  }
}

/// The caller (name, phone, address) in one compact bar, with the button
/// for their usual and past purchases.
class _LockedCustomer extends StatelessWidget {
  const _LockedCustomer({
    required this.customer,
    required this.onChange,
    required this.onShowHistory,
  });

  final PhoneOrderCustomer customer;
  final VoidCallback onChange;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final place = [customer.address, customer.zone]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');
    return Container(
      key: const Key('phone-order-locked-customer'),
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 2, 6),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin_rounded, color: palette.accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: customer.fullName ?? l10n.adminNoName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const TextSpan(text: '  •  '),
                    TextSpan(
                      text: customer.phone ?? l10n.adminNoPhoneNumber,
                      style: TextStyle(color: palette.muted),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  place.isEmpty ? l10n.phoneOrderNoAddress : place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('phone-order-customer-history'),
            tooltip: 'مشتريات العميل المعتادة والسابقة',
            visualDensity: VisualDensity.compact,
            onPressed: onShowHistory,
            icon: Icon(Icons.history_rounded, color: palette.accent),
          ),
          IconButton(
            key: const Key('phone-order-change-customer'),
            tooltip: l10n.phoneOrderChangeCustomer,
            visualDensity: VisualDensity.compact,
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

/// Stock at or below this is shown in orange.
const _lowStock = 5;

/// Product rows narrower than this stack the stock and − / + under the name.
const _narrowTileWidth = 480.0;

/// The barcode, tap to copy (small copy icon and «تم نسخ الباركود»).
class _BarcodeCopy extends StatelessWidget {
  const _BarcodeCopy({required this.productId, required this.barcode});

  final String productId;
  final String barcode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: 'نسخ الباركود',
      child: InkWell(
        key: Key('phone-order-barcode-$productId'),
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(ClipboardData(text: barcode.trim()));
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              duration: Duration(seconds: 2),
              content: Text('تم نسخ الباركود'),
            ));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.copy_rounded, size: 13, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.line,
    required this.onAdd,
    required this.onOpen,
    required this.onRemove,
  });

  final Product product;
  final PhoneOrderLine? line;

  /// The + button: one more.
  final VoidCallback onAdd;

  /// Anywhere else on the row: product details and bulk add.
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final inCart = line != null;
    final countLabel = switch (line) {
      PhoneOrderLine(:final weightInGrams?) =>
        WeightOptions.phoneOrderLabel(weightInGrams),
      PhoneOrderLine(:final quantity) => '$quantity',
      null => '0',
    };

    // RTL: image sits on the right (start).
    final image = SizedBox.square(
      dimension: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: Colors.white,
          child: ProductImage(
            imageUrl: product.hasValidImageUrl ? product.imageUrl : null,
            iconSize: 22,
            fit: BoxFit.contain,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppCurrency.of(product.effectivePrice)} / '
          '${product.displayUnit}',
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
        if (product.barcode case final barcode?
            when barcode.trim().isNotEmpty)
          _BarcodeCopy(productId: product.id, barcode: barcode),
      ],
    );

    // Stock on hand, right before the − / + buttons.
    final stock = Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
      child: Text(
        'المخزون: ${product.stockQuantity}',
        key: Key('phone-order-stock-${product.id}'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: product.stockQuantity <= _lowStock
              ? Colors.orange.shade800
              : palette.muted,
        ),
      ),
    );

    // RTL: quantity controls sit on the left (end).
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('phone-order-dec-product-${product.id}'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: inCart ? onRemove : null,
          icon: Icon(
            Icons.remove_circle_outline,
            color: inCart ? palette.accent : palette.muted,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 30),
          child: Text(
            countLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: inCart ? palette.accent : palette.muted,
              fontSize: 13,
            ),
          ),
        ),
        IconButton(
          key: Key('phone-order-add-${product.id}'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_rounded, color: palette.accent),
        ),
      ],
    );

    return Material(
      color: palette.card,
      child: InkWell(
        key: Key('phone-order-product-${product.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 4, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Narrow column: the stock and − / + move under the name so
              // the name and barcode keep their width.
              if (constraints.maxWidth < _narrowTileWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        image,
                        const SizedBox(width: 10),
                        Expanded(child: info),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [stock, controls],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  image,
                  const SizedBox(width: 10),
                  Expanded(child: info),
                  stock,
                  controls,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The bottom bar: always the cart count, the total and «تأكيد وتسجيل الطلب»;
/// opened, also the cart lines and the delivery fee.
class _CartPanel extends ConsumerWidget {
  const _CartPanel({
    required this.open,
    required this.onToggle,
    required this.onPlaced,
    this.alwaysOpen = false,
  });

  /// Cart lines shown before the list scrolls (collapsible bar mode).
  static const maxLinesHeight = 180.0;

  static final _fees = [
    0.0,
    for (final bracket in DeliveryPricing.brackets) bracket.fee,
  ];

  final bool open;
  final bool alwaysOpen;
  final VoidCallback onToggle;
  final ValueChanged<String>? onPlaced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final expanded = alwaysOpen || open;
    final state = ref.watch(phoneOrderControllerProvider);
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    void onAdd(Product product) => _addProduct(context, ref, product);
    void onRemove(Product product) => controller.remove(product);
    void onFee(double fee) => controller.setDeliveryFee(fee);
    void onConfirm() => _confirmOrder(context, ref, onPlaced);

    Widget summaryRow(String label, String value,
            {Key? valueKey, bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              key: valueKey,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                fontSize: strong ? 15 : 13,
                color: strong ? palette.accent : null,
              ),
            ),
          ]),
        );
    Widget amount(String label, double value, {bool strong = false}) =>
        summaryRow(label, AppCurrency.of(value), strong: strong);

    Widget linesList({required bool shrinkWrap}) {
      if (state.lines.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(l10n.phoneOrderCartEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted)),
        );
      }
      return ListView(
        shrinkWrap: shrinkWrap,
        children: [
          for (final line in state.lines)
            _CartLine(
              line: line,
              onAdd: () => onAdd(line.product),
              onRemove: () => onRemove(line.product),
            ),
        ],
      );
    }

    // طريقة الدفع: cash (default), visa on delivery (the driver brings the
    // POS machine) or InstaPay with the transfer screenshot attached here.
    final receipt = state.receipt;
    final payment = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('طريقة الدفع',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: palette.muted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final method in PhoneOrderPayment.values)
              ChoiceChip(
                key: Key('phone-order-payment-${method.value}'),
                visualDensity: VisualDensity.compact,
                label: Text(method.label),
                selected: state.paymentMethod == method,
                onSelected: state.submitting
                    ? null
                    : (_) => controller.setPayment(method),
              ),
          ],
        ),
        if (state.paymentMethod.needsReceipt) ...[
          const SizedBox(height: 6),
          Row(children: [
            if (receipt != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  receipt.bytes,
                  key: const Key('phone-order-receipt-thumb'),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.square(
                    dimension: 40,
                    child: Icon(Icons.image_not_supported_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('phone-order-receipt-pick'),
                onPressed:
                    state.submitting ? null : () => _pickReceipt(context, ref),
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(receipt == null
                      ? 'إرفاق صورة التحويل'
                      : 'تغيير صورة التحويل'),
                ),
              ),
            ),
            if (receipt != null)
              IconButton(
                key: const Key('phone-order-receipt-remove'),
                tooltip: 'إزالة الصورة',
                visualDensity: VisualDensity.compact,
                onPressed:
                    state.submitting ? null : () => controller.setReceipt(null),
                icon: const Icon(Icons.close_rounded),
              ),
          ]),
          if (receipt == null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'صورة التحويل مطلوبة لإتمام طلب إنستا باي',
                key: Key('phone-order-receipt-required'),
                style: TextStyle(fontSize: 12, color: AppColors.secondary),
              ),
            ),
        ],
      ],
    );

    final feeAndTotals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 10),
        Text(l10n.deliveryFee,
            style:
                TextStyle(fontWeight: FontWeight.w800, color: palette.muted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final fee in _fees)
              ChoiceChip(
                key: Key('phone-order-fee-${fee.toInt()}'),
                visualDensity: VisualDensity.compact,
                label: Text(fee == 0
                    ? l10n.phoneOrderFreeDelivery
                    : AppCurrency.of(fee)),
                selected: state.deliveryFee == fee,
                onSelected: (_) => onFee(fee),
              ),
          ],
        ),
        payment,
        const SizedBox(height: 8),
        // Totals table: item count first, then items, delivery, grand total.
        summaryRow(
          'عدد المنتجات',
          '${state.itemCount}',
          valueKey: const Key('phone-order-items-count'),
        ),
        amount(l10n.phoneOrderItemsTotal, state.itemsTotal),
        amount(l10n.deliveryFee, state.deliveryFee),
        const Divider(height: 10),
        amount('الإجمالي (سلة العميل)', state.total, strong: true),
      ],
    );

    final collapsedDetails = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.55,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.lines.isEmpty)
                linesList(shrinkWrap: true)
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: maxLinesHeight),
                  child: linesList(shrinkWrap: true),
                ),
              feeAndTotals,
            ],
          ),
        ),
      ),
    );

    final confirm = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: 48,
        child: Row(children: [
          // Slightly narrower than before to make room for «إلغاء الطلب».
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              key: const Key('phone-order-confirm'),
              onPressed: state.canSubmit ? onConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: state.submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.phoneOrderConfirm,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              key: const Key('phone-order-cancel'),
              onPressed:
                  state.submitting ? null : () => _cancelOrder(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cancel_rounded),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'إلغاء الطلب',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ]),
      ),
    );

    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(children: [
        Badge(
          isLabelVisible: state.itemCount > 0,
          label: Text('${state.itemCount}'),
          child: Icon(Icons.shopping_cart_rounded, color: palette.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.phoneOrderCartTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        Text(
          AppCurrency.of(state.total),
          key: const Key('phone-order-total'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: palette.accent,
          ),
        ),
        if (!alwaysOpen)
          Icon(
            open
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            semanticLabel:
                open ? l10n.phoneOrderHideCart : l10n.phoneOrderShowCart,
          ),
      ]),
    );

    if (alwaysOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              // Fee, payment and totals scroll on short screens so the
              // cart lines keep some room.
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: linesList(shrinkWrap: false)),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.7,
                      ),
                      child: SingleChildScrollView(child: feeAndTotals),
                    ),
                  ],
                ),
              ),
            ),
          ),
          confirm,
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('phone-order-cart-toggle'),
            onTap: onToggle,
            child: titleRow,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : collapsedDetails,
          ),
          confirm,
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.line,
    required this.onAdd,
    required this.onRemove,
  });

  final PhoneOrderLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final id = line.product.id;
    final weightLabel = line.weightInGrams == null
        ? null
        : WeightOptions.phoneOrderLabel(line.weightInGrams!);
    final qtyLabel = weightLabel ?? '${line.quantity}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (weightLabel != null)
                  Text(
                    'الوزن: $weightLabel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('phone-order-dec-$id'),
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              weightLabel == null ? qtyLabel : '×1',
              key: Key('phone-order-qty-$id'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          IconButton(
            key: Key('phone-order-inc-$id'),
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
          SizedBox(
            width: 84,
            child: Text(
              AppCurrency.of(line.total),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
