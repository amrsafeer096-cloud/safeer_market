import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/customer_phone.dart';
import '../../../cart/domain/weight_options.dart';
import '../../../cart/presentation/widgets/weight_picker_sheet.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../home/domain/entities/product.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/phone_order.dart';
import '../../domain/product_search_filter.dart';
import '../../domain/repositories/phone_orders_repository.dart';
import '../providers/order_alternatives_providers.dart';
import '../providers/phone_order_providers.dart';
import '../providers/system_admin_providers.dart';
import 'customer_details_sheet.dart';
import 'customer_purchase_history_dialog.dart';
import 'new_customer_dialogs.dart';
import 'payment_confirm_dialog.dart';
import 'phone_order_customer_history_panel.dart';
import 'phone_order_staged_review.dart';
import 'phone_order_today_panel.dart';
import 'product_details_dialog.dart';
import 'same_day_order_dialog.dart';
import 'staff_product_search_tile.dart';

/// «تلقي الطلبات»: find (or add) the caller, build their cart, and place
/// the order. [onPlaced] gets the new order's id.
///
/// When [splitLayout] is true (wide dashboard): RTL 3 columns —
/// far right «طلبات اليوم», center search+cart (search overlays cart),
/// far left customer history tabs.
class PhoneOrderColumn extends ConsumerWidget {
  const PhoneOrderColumn({
    super.key,
    this.onPlaced,
    this.splitLayout = false,
    this.onOpenPendingAlternatives,
  });

  /// How long typing pauses before a search runs.
  static const searchDebounce = Duration(milliseconds: 300);

  final ValueChanged<String>? onPlaced;
  final bool splitLayout;

  /// Opens «حالة الطلب» when the taker taps the pending-alternatives banner.
  final VoidCallback? onOpenPendingAlternatives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final hasCustomer = ref.watch(
      phoneOrderControllerProvider.select((state) => state.customer != null),
    );
    final hasLines = ref.watch(
      phoneOrderControllerProvider.select((state) => state.lines.isNotEmpty),
    );
    final canPark = ref.watch(
      phoneOrderControllerProvider
          .select((state) => !state.isBlank && !state.submitting),
    );
    final hasParked = ref.watch(
      phoneOrderControllerProvider.select((state) => state.parked.isNotEmpty),
    );

    Widget? customerChrome() {
      final controller = ref.read(phoneOrderControllerProvider.notifier);
      if (hasCustomer) {
        final state = ref.watch(phoneOrderControllerProvider);
        final customer = state.customer!;
        return _LockedCustomer(
          customer: customer,
          isSupplemental: state.isSupplemental,
          compact: true,
          onChange: controller.detachCustomer,
          onRemove: controller.detachCustomer,
          onEdit: () async {
            final confirmed =
                await showCustomerDetailsSheet(context, customer: customer);
            if (confirmed == null || !context.mounted) return;
            final hasToday = await ref
                .read(phoneOrdersRepositoryProvider)
                .hasOrderToday(confirmed);
            if (!context.mounted) return;
            if (hasToday) {
              final kind = await showSameDayOrderDialog(context);
              if (kind == null || !context.mounted) return;
              await controller.selectCustomerWithZoneFee(confirmed);
              if (kind == SameDayOrderKind.supplemental) {
                controller
                  ..setDeliveryFee(0)
                  ..setSupplemental(true);
              } else {
                controller.setSupplemental(false);
              }
            } else {
              await controller.selectCustomerWithZoneFee(confirmed);
              controller.setSupplemental(false);
            }
          },
          onShowHistory: () =>
              showCustomerPurchaseHistoryDialog(context, customer),
        );
      }
      // Cart kept after detach: empty slot; lookup sits above the cart.
      if (hasLines) return const _EmptyCustomerSlot();
      return null;
    }

    Widget header() {
      final chrome = customerChrome();
      return Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: palette.accent, size: 22),
            const SizedBox(width: 6),
            Text(
              l10n.adminMenuReceiveOrders,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(width: 8),
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
                side:
                    BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة طلب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              key: const Key('phone-order-cancel'),
              onPressed: () => _cancelOrder(context, ref),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text(
                'إلغاء الطلب',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (chrome != null) ...[
              const SizedBox(width: 10),
              Expanded(child: chrome),
            ] else
              const Spacer(),
          ],
        ),
      );
    }

    Widget orderWorkspace() {
      // Keep product search + cart when the caller was detached mid-basket.
      if (hasCustomer || hasLines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasCustomer) ...[
              const SizedBox(
                height: 220,
                child: _CustomerLookup(compact: true),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: _OrderBuilder(
                onPlaced: onPlaced,
                splitLayout: splitLayout,
              ),
            ),
          ],
        );
      }
      return const _CustomerLookup();
    }

    Widget pendingBanner() {
      final pending = ref.watch(pendingAlternativeOrderIdsProvider);
      final count = pending.valueOrNull?.length ?? 0;
      if (count == 0) return const SizedBox.shrink();
      return Material(
        color: Colors.deepOrange.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onOpenPendingAlternatives,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بدائل بانتظار المتلقي ($count) — افتح حالة الطلب',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                if (onOpenPendingAlternatives != null)
                  const Icon(Icons.chevron_left_rounded,
                      color: Colors.deepOrange),
              ],
            ),
          ),
        ),
      );
    }

    if (!splitLayout) {
      return Material(
        color: palette.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(),
            const Divider(height: 1),
            pendingBanner(),
            if (hasParked) const _OpenOrdersStrip(),
            Expanded(child: orderWorkspace()),
          ],
        ),
      );
    }

    // RTL Row: first child = far right.
    // Far right: طلبات اليوم | Center: search + cart (overlay) | Far left: history
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PhoneOrderTodayPanel(),
        const VerticalDivider(width: 1),
        if (hasParked) ...[
          const _OpenOrdersSidebar(),
          const VerticalDivider(width: 1),
        ],
        Expanded(
          flex: 5,
          child: Material(
            color: palette.card,
            child: orderWorkspace(),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          key: const Key('phone-order-history-panel'),
          width: 320,
          child: Material(
            color: palette.card,
            child: hasCustomer
                ? PhoneOrderCustomerHistoryPanel(
                    customer: ref.watch(phoneOrderControllerProvider).customer!,
                    onAddProduct: (product) =>
                        _addProduct(context, ref, product),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        l10n.adminSelectCustomerFirst,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: palette.muted,
                        ),
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
          pendingBanner(),
          Expanded(child: body),
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
  final controller = ref.read(phoneOrderControllerProvider.notifier);
  final current = ref.read(phoneOrderControllerProvider).paymentMethod;

  final confirmedPayment = await showPaymentConfirmDialog(
    context,
    current: current,
  );
  if (confirmedPayment == null || !context.mounted) return;
  controller.setPayment(confirmedPayment);

  // InstaPay: attach receipt here (payment UI was removed from the cart).
  if (confirmedPayment.needsReceipt &&
      !ref.read(phoneOrderControllerProvider).hasReceipt) {
    await _pickReceipt(context, ref);
    if (!context.mounted) return;
    if (!ref.read(phoneOrderControllerProvider).hasReceipt) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('أرفق صورة التحويل قبل تسجيل طلب إنستا باي'),
        ));
      return;
    }
  }

  void fail(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      backgroundColor: AppColors.secondary,
      content: Text(message),
    ));
  try {
    final orderId = await controller.submit();
    ref.invalidate(takerTodayOrdersProvider);
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

/// Unit products go straight into the cart; weight-based products open the
/// weight sheet first (same flow as the customer app).
Future<void> _addProduct(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  String? initialNotes,
}) async {
  final controller = ref.read(phoneOrderControllerProvider.notifier);
  if (!product.isWeightBased) {
    controller.add(product);
    if (initialNotes != null && initialNotes.trim().isNotEmpty) {
      controller.setLineNotes(product, initialNotes);
    }
    return;
  }
  final state = ref.read(phoneOrderControllerProvider);
  PhoneOrderLine? existing;
  for (final line in state.lines) {
    if (line.product.id == product.id) {
      existing = line;
      break;
    }
  }
  final pick = await showWeightPickerSheet(
    context,
    product: product,
    initialGrams: existing?.weightInGrams ?? state.weightOf(product.id),
    initialNotes: initialNotes ?? existing?.notes,
    title: 'اختر الوزن المطلوب',
    labelFor: WeightOptions.adminQuickPickLabel,
    fastAdminEntry: true,
  );
  if (pick == null || !context.mounted) return;
  controller.setWeight(product, pick.grams, notes: pick.notes);
}

// ---------------------------------------------------------------------------
// Customer lookup
// ---------------------------------------------------------------------------

class _CustomerLookup extends ConsumerStatefulWidget {
  const _CustomerLookup({this.compact = false});

  /// Compact strip above an existing cart after «إزالة العميل».
  final bool compact;

  @override
  ConsumerState<_CustomerLookup> createState() => _CustomerLookupState();
}

class _CustomerLookupState extends ConsumerState<_CustomerLookup> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(PhoneOrderColumn.searchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
  }

  Future<void> _confirmCustomer(PhoneOrderCustomer draft) async {
    final confirmed = await showCustomerDetailsSheet(context, customer: draft);
    if (confirmed == null || !mounted) return;
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    final hasToday = await ref
        .read(phoneOrdersRepositoryProvider)
        .hasOrderToday(confirmed);
    if (!mounted) return;
    if (hasToday) {
      final kind = await showSameDayOrderDialog(context);
      if (kind == null || !mounted) return;
      await controller.selectCustomerWithZoneFee(confirmed);
      if (kind == SameDayOrderKind.supplemental) {
        controller
          ..setDeliveryFee(0)
          ..setSupplemental(true);
      } else {
        controller.setSupplemental(false);
      }
    } else {
      await controller.selectCustomerWithZoneFee(confirmed);
      controller.setSupplemental(false);
    }
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
      await _confirmCustomer(customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final compact = widget.compact;
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'اختر / إضافة عميل للسلة الحالية',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: palette.accent,
                ),
              ),
            ),
          TextField(
            key: const Key('phone-order-customer-search'),
            controller: _search,
            focusNode: _searchFocus,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث بالهاتف أو الاسم أو رقم فوجيتسو',
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
                    child: Text(
                        compact
                            ? 'ابحث لإرفاق عميل دون فقدان السلة'
                            : l10n.phoneOrderTypeToSearch,
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
                                  onTap: () => _confirmCustomer(customer),
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
          if (customer.fujitsuCustomerNo != null)
            Text(
              'فوجيتسو: ${customer.fujitsuCustomerNo}',
              style: TextStyle(fontSize: 12, color: palette.accent),
            ),
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

/// Packaging filter chips beside «نتائج البحث».
enum _UnitPackFilter { all, piece, box, weight }

class _OrderBuilderState extends ConsumerState<_OrderBuilder> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  var _filter = ProductSearchFilterMode.inStock;
  var _unitPackFilter = _UnitPackFilter.all;
  var _popupOpen = false;

  /// Staged +/- picks inside the search popup (not yet in the cart).
  final Map<String, StagedCartItem> _staged = {};

  /// The cart and delivery fee panel; closed, it is one summary line so the
  /// product results keep the height.
  bool _cartOpen = false;

  PhoneOrderProductQuery get _productQuery => (
        text: _query,
        category: null,
        filter: _filter,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSearchFocus());
  }

  @override
  void deactivate() {
    ref.read(phoneOrderSearchOpenProvider.notifier).state = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _restoreSearchFocus() {
    if (!mounted) return;
    // Keep the search field ready whenever no dialog owns focus.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (_searchFocus.hasFocus) return;
    _searchFocus.requestFocus();
  }

  void _setPopupOpen(bool open) {
    if (_popupOpen == open) {
      ref.read(phoneOrderSearchOpenProvider.notifier).state = open;
      return;
    }
    setState(() => _popupOpen = open);
    ref.read(phoneOrderSearchOpenProvider.notifier).state = open;
  }

  /// Clears the search field / closes the popup.
  /// Staging is kept by default — cleared only after cart commit, explicit
  /// «إلغاء المحدد», or order/tab switch ([clearStaged]).
  void _dismissSearch({bool clearStaged = false}) {
    _debounce?.cancel();
    _search.clear();
    if (!mounted) return;
    setState(() {
      _query = '';
      _popupOpen = false;
      if (clearStaged) _staged.clear();
    });
    ref.read(phoneOrderSearchOpenProvider.notifier).state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSearchFocus());
  }

  void _clearStaging() {
    if (_staged.isEmpty) return;
    setState(() => _staged.clear());
    _restoreSearchFocus();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    // Open / rebuild from the first character so previous-products
    // filtering updates immediately (network search stays debounced).
    // Never wipe [_staged] when the query changes or becomes empty.
    setState(() {
      _popupOpen = trimmed.isNotEmpty;
      if (trimmed.isEmpty) _query = '';
    });
    ref.read(phoneOrderSearchOpenProvider.notifier).state = trimmed.isNotEmpty;
    _debounce = Timer(PhoneOrderColumn.searchDebounce, () {
      if (mounted) setState(() => _query = trimmed);
    });
  }

  /// Enter: staged review first; otherwise barcode → cart.
  Future<void> _onSubmitted(String text) async {
    if (_staged.isNotEmpty) {
      await _openStagedReview();
      return;
    }
    final code = text.trim();
    _debounce?.cancel();
    setState(() => _query = code);
    _setPopupOpen(code.isNotEmpty);
    if (code.isEmpty) return;
    try {
      final products = await ref.read(
          phoneOrderProductsProvider((
            text: code,
            category: null,
            filter: _filter,
          )).future);
      final match =
          products.where((product) => product.barcode?.trim() == code);
      if (match.length == 1 && mounted) {
        await _pickProduct(match.single);
      }
    } catch (_) {
      // The results list shows the error.
    }
  }

  Future<void> _openStagedReview() async {
    if (_staged.isEmpty) return;
    final snapshot = {
      for (final e in _staged.entries)
        e.key: StagedCartItem(
          product: e.value.product,
          quantity: e.value.quantity,
          weightInGrams: e.value.weightInGrams,
          notes: e.value.notes,
        ),
    };
    final confirmed = await showStagedReviewDialog(context, staged: snapshot);
    if (!mounted) return;
    if (confirmed == null) {
      // «رجوع» — keep staging intact.
      _restoreSearchFocus();
      return;
    }
    final controller = ref.read(phoneOrderControllerProvider.notifier);
    for (final item in confirmed.values) {
      if (item.weightInGrams != null) {
        controller.setWeight(
          item.product,
          item.weightInGrams!,
          notes: item.notes,
        );
      } else {
        controller.addQuantity(
          item.product,
          item.quantity,
          notes: item.notes,
        );
      }
    }
    // Commit → clear staging + search.
    _dismissSearch(clearStaged: true);
  }

  /// Upsert into the persistent staging buffer (does not touch the cart).
  void _stageItem(
    Product product, {
    int? quantity,
    int? weightInGrams,
    String? notes,
  }) {
    setState(() {
      final existing = _staged[product.id];
      final mergedNotes = notes ?? existing?.notes;
      if (product.isWeightBased || weightInGrams != null) {
        final grams = weightInGrams ?? existing?.weightInGrams;
        if (grams == null || grams <= 0) {
          _staged.remove(product.id);
          return;
        }
        _staged[product.id] = StagedCartItem(
          product: product,
          weightInGrams: grams,
          notes: mergedNotes,
        );
      } else {
        final qty = quantity ?? existing?.quantity ?? 1;
        if (qty < 1) {
          _staged.remove(product.id);
          return;
        }
        _staged[product.id] = StagedCartItem(
          product: product,
          quantity: qty.clamp(1, PhoneOrderState.maxQuantity),
          notes: mergedNotes,
        );
      }
    });
  }

  /// After a product-card confirm: stage the item, keep other staged lines,
  /// clear the search field for the next query, restore focus.
  void _stageFromCard(
    Product product, {
    int? quantity,
    int? weightInGrams,
    String? notes,
  }) {
    _stageItem(
      product,
      quantity: quantity,
      weightInGrams: weightInGrams,
      notes: notes,
    );
    _debounce?.cancel();
    _search.clear();
    if (!mounted) return;
    setState(() {
      _query = '';
      _popupOpen = false;
    });
    ref.read(phoneOrderSearchOpenProvider.notifier).state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSearchFocus());
  }

  /// `+` in the search list: stage only — keep popup open.
  void _stageInc(Product product) {
    setState(() {
      final existing = _staged[product.id];
      if (product.isWeightBased) {
        final grams = existing?.weightInGrams ?? 0;
        final next = WeightOptions.next(grams);
        _staged[product.id] = StagedCartItem(
          product: product,
          weightInGrams: next,
          notes: existing?.notes,
        );
      } else {
        final qty = (existing?.quantity ?? 0) + 1;
        if (qty > PhoneOrderState.maxQuantity) return;
        _staged[product.id] = StagedCartItem(
          product: product,
          quantity: qty,
          notes: existing?.notes,
        );
      }
    });
    _restoreSearchFocus();
  }

  /// `-` in the search list: decrement staged only.
  void _stageDec(Product product) {
    final existing = _staged[product.id];
    if (existing == null) return;
    setState(() {
      if (existing.weightInGrams != null) {
        final prev = WeightOptions.previous(existing.weightInGrams!);
        if (prev <= 0) {
          _staged.remove(product.id);
        } else {
          existing.weightInGrams = prev;
        }
      } else if (existing.quantity <= 1) {
        _staged.remove(product.id);
      } else {
        existing.quantity -= 1;
      }
    });
    _restoreSearchFocus();
  }

  /// Barcode Enter with a single exact match: add and clear search.
  Future<void> _pickProduct(Product product) async {
    await _addProduct(context, ref, product);
    if (!mounted) return;
    _dismissSearch(clearStaged: false);
  }

  /// Single tap opens the detail card; confirm stages into [_staged].
  Future<void> _openDetails(Product product) async {
    final staged = _staged[product.id];
    String? cartNotes;
    int? cartGrams;
    int? cartQty;
    for (final line in ref.read(phoneOrderControllerProvider).lines) {
      if (line.product.id == product.id) {
        cartNotes = line.notes;
        cartGrams = line.weightInGrams;
        cartQty = line.quantity;
        break;
      }
    }
    await showProductDetailsDialog(
      context,
      product: product,
      initialNotes: staged?.notes ?? cartNotes,
      initialGrams: staged?.weightInGrams ?? cartGrams,
      initialQuantity: staged?.quantity ?? cartQty,
      onAddQuantity: (quantity, notes) {
        _stageFromCard(product, quantity: quantity, notes: notes);
      },
      onConfirmWeight: (grams, notes) {
        _stageFromCard(product, weightInGrams: grams, notes: notes);
      },
    );
    if (mounted) _restoreSearchFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final state = ref.watch(phoneOrderControllerProvider);
    final customer = state.customer!;

    ref.listen(phoneOrderDismissSearchProvider, (prev, next) {
      // Order/tab switch — wipe staging with the search session.
      if (prev != next) _dismissSearch(clearStaged: true);
    });

    final historyAsync =
        ref.watch(phoneOrderCustomerHistoryProvider(customer.key));

    bool matchesUnitPack(Product product) => switch (_unitPackFilter) {
          _UnitPackFilter.all => true,
          _UnitPackFilter.piece => product.isPieceUnit,
          _UnitPackFilter.box => product.isBoxUnit,
          _UnitPackFilter.weight => product.isWeightBased,
        };

    Widget productTile(Product product) {
      final staged = _staged[product.id];
      final countLabel = switch (staged) {
        StagedCartItem(:final weightInGrams?) =>
          WeightOptions.compactLabel(weightInGrams),
        StagedCartItem(:final quantity) => '$quantity',
        null => '0',
      };
      return StaffProductSearchTile(
        product: product,
        quantityLabel: countLabel,
        inCart: staged != null,
        // Single tap on the row body opens the card / weight picker.
        // +/- IconButtons keep their own handlers and do not open it.
        openOnDoubleTap: false,
        keyPrefix: 'phone-order',
        showZeroStockInRed: _filter == ProductSearchFilterMode.allItems,
        onAdd: () => _stageInc(product),
        onOpen: () => _openDetails(product),
        onRemove: () => _stageDec(product),
      );
    }

    List<CustomerPurchaseItem> previousMatches(String q) {
      final history = historyAsync.valueOrNull;
      final needle = q.trim();
      // From the first character: normalized Arabic substring match.
      if (history == null || needle.isEmpty) return const [];
      return [
        for (final item in history.mostRecent)
          if ((arabicSearchContains(item.product.name, needle) ||
                  arabicSearchContains(item.product.barcode ?? '', needle)) &&
              matchesUnitPack(item.product))
            item,
      ];
    }

    void selectUnitPack(_UnitPackFilter next) {
      setState(() {
        // Tap active chip again → back to «الكل».
        _unitPackFilter =
            _unitPackFilter == next && next != _UnitPackFilter.all
                ? _UnitPackFilter.all
                : next;
      });
      _restoreSearchFocus();
    }

    Widget unitPackChip({
      required Key key,
      required String label,
      required _UnitPackFilter value,
    }) {
      final selected = _unitPackFilter == value;
      return FilterChip(
        key: key,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : null,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        selectedColor: palette.accent,
        onSelected: (_) => selectUnitPack(value),
      );
    }

    Widget searchPopup() {
      // Always use the live field text so 1-char typing filters immediately.
      final typed = _search.text.trim();
      final prev = previousMatches(typed);
      return Material(
        key: const Key('phone-order-search-popup'),
        elevation: 14,
        shadowColor: Colors.black54,
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 4),
              child: Row(
                children: [
                  const Text(
                    'نتائج البحث',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          unitPackChip(
                            key: const Key('phone-order-unit-filter-all'),
                            label: 'الكل',
                            value: _UnitPackFilter.all,
                          ),
                          const SizedBox(width: 4),
                          unitPackChip(
                            key: const Key('phone-order-unit-filter-piece'),
                            label: 'قطعة',
                            value: _UnitPackFilter.piece,
                          ),
                          const SizedBox(width: 4),
                          unitPackChip(
                            key: const Key('phone-order-unit-filter-box'),
                            label: 'علبة',
                            value: _UnitPackFilter.box,
                          ),
                          const SizedBox(width: 4),
                          unitPackChip(
                            key: const Key('phone-order-unit-filter-weight'),
                            label: 'وزن',
                            value: _UnitPackFilter.weight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('phone-order-search-dismiss'),
                    tooltip: 'إغلاق',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _dismissSearch(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (_staged.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Material(
                  key: const Key('phone-order-staged-banner'),
                  color: palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'مختار للتأكيد: ${_staged.length} أصناف',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: palette.accent,
                            ),
                          ),
                        ),
                        TextButton(
                          key: const Key('phone-order-staged-clear'),
                          onPressed: _clearStaging,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: palette.muted,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('إلغاء المحدد'),
                        ),
                        const SizedBox(width: 4),
                        FilledButton(
                          key: const Key('phone-order-staged-review-btn'),
                          onPressed: _openStagedReview,
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'مراجعة وتأكيد (Enter)',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // RTL: first child is on the right — previous products.
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: Text(
                            'المنتجات السابقة للعميل',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: palette.muted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: historyAsync.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : prev.isEmpty
                                  ? Center(
                                      child: Text(
                                        'لا توجد مشتريات مطابقة',
                                        style: TextStyle(color: palette.muted),
                                      ),
                                    )
                                  : ListView.separated(
                                      key: const Key(
                                          'phone-order-previous-products'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      itemCount: prev.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final item = prev[i];
                                        return productTile(item.product);
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(width: 1, color: palette.border),
                  // Main catalog results (left in RTL).
                  Expanded(
                    flex: 6,
                    child: _query.isEmpty
                        ? Center(
                            child: Text(
                              'جاري البحث…',
                              style: TextStyle(color: palette.muted),
                            ),
                          )
                        : ref
                            .watch(phoneOrderProductsProvider(_productQuery))
                            .when(
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (error, _) => Center(
                                child: Text('$error',
                                    textAlign: TextAlign.center),
                              ),
                              data: (products) {
                                final filtered = [
                                  for (final p in products)
                                    if (matchesUnitPack(p)) p,
                                ];
                                if (filtered.isEmpty) {
                                  return Center(
                                    child: Text(l10n.phoneOrderNoProducts,
                                        style: TextStyle(
                                            color: palette.muted)),
                                  );
                                }
                                return ListView.separated(
                                  key: const Key('phone-order-products'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) =>
                                      productTile(filtered[index]),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final showClear = _popupOpen || _search.text.trim().isNotEmpty;

    /// Visible when popup is closed but items remain staged across searches.
    Widget? stagingStrip;
    if (!_popupOpen && _staged.isNotEmpty) {
      stagingStrip = Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Material(
          key: const Key('phone-order-staged-strip'),
          color: palette.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'مختار للتأكيد: ${_staged.length} أصناف',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: palette.accent,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('phone-order-staged-strip-clear'),
                  onPressed: _clearStaging,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: palette.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('إلغاء المحدد'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  key: const Key('phone-order-staged-strip-review'),
                  onPressed: _openStagedReview,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'مراجعة وتأكيد (Enter)',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final searchField = Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: TextField(
        key: const Key('phone-order-product-search'),
        controller: _search,
        focusNode: _searchFocus,
        autofocus: true,
        enabled: true,
        readOnly: false,
        enableInteractiveSelection: true,
        onChanged: _onChanged,
        onSubmitted: _onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.phoneOrderProductSearchHint,
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showClear)
                TextButton(
                  key: const Key('phone-order-search-clear'),
                  onPressed: () => _dismissSearch(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'مسح',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ProductSearchFilterButton(
                mode: _filter,
                onChanged: (mode) => setState(() => _filter = mode),
              ),
            ],
          ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );

    // Wide layout: cart is the center base; product search overlays it.
    if (widget.splitLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          if (stagingStrip != null) stagingStrip,
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CartPanel(
                  open: true,
                  alwaysOpen: true,
                  onToggle: () {},
                  onPlaced: widget.onPlaced,
                  title: 'سلة العميل',
                ),
                if (_popupOpen)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                      child: searchPopup(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        if (stagingStrip != null) stagingStrip,
        const SizedBox(height: 4),
        Expanded(
          child: _popupOpen
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  child: searchPopup(),
                )
              : Center(
                  child: Text(l10n.phoneOrderSearchProductsPrompt,
                      style: TextStyle(color: palette.muted)),
                ),
        ),
        _CartPanel(
          open: _cartOpen,
          onToggle: () => setState(() => _cartOpen = !_cartOpen),
          onPlaced: widget.onPlaced,
        ),
      ],
    );
  }
}

/// Empty customer slot after detach — cart stays below.
class _EmptyCustomerSlot extends StatelessWidget {
  const _EmptyCustomerSlot();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('phone-order-empty-customer'),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded,
              color: palette.muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'اختر / إضافة عميل',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The caller (name, phone, address) in one compact bar, with the button
/// for their usual and past purchases.
class _LockedCustomer extends StatelessWidget {
  const _LockedCustomer({
    required this.customer,
    required this.onChange,
    required this.onRemove,
    required this.onEdit,
    required this.onShowHistory,
    this.isSupplemental = false,
    this.compact = false,
  });

  final PhoneOrderCustomer customer;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onShowHistory;
  final bool isSupplemental;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final place = [customer.address, customer.zone]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');
    final phones = CustomerPhone.formatPhones(customer.phoneSlots, empty: '');
    final iconSize = compact ? 18.0 : 22.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('phone-order-locked-customer'),
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: compact ? EdgeInsets.zero : const EdgeInsets.fromLTRB(10, 8, 10, 4),
          padding: EdgeInsetsDirectional.fromSTEB(
              compact ? 8 : 10, compact ? 4 : 6, 2, compact ? 4 : 6),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.person_pin_rounded,
                  color: palette.accent, size: iconSize),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: customer.fullName ?? l10n.adminNoName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 14 : 15,
                            color: const Color(0xFF111827),
                            height: 1.25,
                          ),
                        ),
                        TextSpan(
                          text: '  •  ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 13 : 13.5,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        TextSpan(
                          text: phones.isEmpty
                              ? l10n.adminNoPhoneNumber
                              : phones,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 13 : 13.5,
                            color: const Color(0xFF111827),
                            height: 1.25,
                          ),
                        ),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      place.isEmpty ? l10n.phoneOrderNoAddress : place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSupplemental)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Chip(
                    key: const Key('phone-order-supplemental-badge'),
                    label: const Text('طلب ملحق',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.orange.shade100,
                    side: BorderSide(color: Colors.orange.shade400),
                    padding: EdgeInsets.zero,
                  ),
                ),
              IconButton(
                key: const Key('phone-order-customer-history'),
                tooltip: 'مشتريات العميل المعتادة والسابقة',
                visualDensity: VisualDensity.compact,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 34, height: 34)
                    : null,
                onPressed: onShowHistory,
                icon: Icon(Icons.history_rounded,
                    color: palette.accent, size: iconSize),
              ),
              IconButton(
                key: const Key('phone-order-edit-customer'),
                tooltip: 'بيانات العميل',
                visualDensity: VisualDensity.compact,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 34, height: 34)
                    : null,
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded,
                    color: palette.accent, size: iconSize),
              ),
              IconButton(
                key: const Key('phone-order-change-customer'),
                tooltip: l10n.phoneOrderChangeCustomer,
                visualDensity: VisualDensity.compact,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 34, height: 34)
                    : null,
                onPressed: onChange,
                icon: Icon(Icons.swap_horiz_rounded,
                    color: palette.accent, size: iconSize),
              ),
              IconButton(
                key: const Key('phone-order-remove-customer'),
                tooltip: 'إزالة العميل',
                visualDensity: VisualDensity.compact,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 34, height: 34)
                    : null,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  hoverColor: Colors.red.shade100,
                ),
                onPressed: onRemove,
                icon: Icon(
                  Icons.person_remove_rounded,
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
            ],
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
    this.title,
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

  /// Optional header shown in the always-open center cart.
  final String? title;

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
    Future<void> onEditLine(PhoneOrderLine line) async {
      await showCartLineEditDialog(
        context,
        line: line,
        onSetQuantity: (q, notes) =>
            controller.setQuantity(line.product, q, notes: notes),
        onSetWeightGrams: (g, notes) =>
            controller.setWeight(line.product, g, notes: notes),
        onRemove: () {
          if (line.weightInGrams != null) {
            controller.setWeight(line.product, 0);
          } else {
            controller.setQuantity(line.product, 0);
          }
        },
      );
    }

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
              onEdit: () => onEditLine(line),
            ),
        ],
      );
    }

    final canSetFee =
        ref.watch(adminCanProvider(AdminPermission.canSetDeliveryFee));
    final showFeeChips = canSetFee && !state.isSupplemental;

    final feeAndTotals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 10),
        if (showFeeChips) ...[
          Row(
            children: [
              Expanded(
                child: Text(l10n.deliveryFee,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: palette.muted)),
              ),
              if (state.isSupplemental)
                const Chip(
                  key: Key('phone-order-cart-supplemental'),
                  label: Text('طلب ملحق',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
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
        ] else if (state.isSupplemental)
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
              key: Key('phone-order-cart-supplemental'),
              label: Text('طلب ملحق',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
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

    final needsCustomer =
        state.customer == null && state.lines.isNotEmpty && !state.submitting;
    final confirm = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (needsCustomer)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'اختر عميلاً أولاً',
                key: const Key('phone-order-need-customer-hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          SizedBox(
            height: 48,
            width: double.infinity,
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
        ],
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
            title ?? l10n.phoneOrderCartTitle,
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
    required this.onEdit,
  });

  final PhoneOrderLine line;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final id = line.product.id;
    final weightLabel = line.weightInGrams == null
        ? null
        : WeightOptions.phoneOrderLabel(line.weightInGrams!);
    final qtyLabel = weightLabel ?? '${line.quantity}';
    return InkWell(
      key: Key('phone-order-cart-line-$id'),
      onDoubleTap: onEdit,
      child: Padding(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  Text(
                    '${AppCurrency.of(line.product.effectivePrice)} / ${line.product.displayUnit}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (line.product.hasActiveOffer)
                    ProductOfferBadge(product: line.product),
                  if (weightLabel != null)
                    Text(
                      'الوزن: $weightLabel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                  if (line.trimmedNotes case final note?)
                    Text(
                      'ملاحظة: $note',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
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
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
