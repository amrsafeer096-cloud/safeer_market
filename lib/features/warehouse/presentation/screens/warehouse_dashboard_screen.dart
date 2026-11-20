import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/widgets/admin_status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_role.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/menu_tile.dart';
import '../../domain/entities/warehouse_order.dart';
import '../providers/warehouse_providers.dart';

class WarehouseDashboardScreen extends ConsumerStatefulWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  ConsumerState<WarehouseDashboardScreen> createState() =>
      _WarehouseDashboardScreenState();
}

class _WarehouseDashboardScreenState
    extends ConsumerState<WarehouseDashboardScreen> {
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    // New orders and updates from other devices refresh the queue live.
    _changes =
        ref.read(warehouseOrdersRepositoryProvider).changes().listen((_) {
      if (mounted) ref.invalidate(warehouseQueueProvider);
    }, onError: (Object error) {
      debugPrint('Warehouse realtime error: $error');
    });
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOut,
      message: l10n.warehouseSignOutConfirm,
      confirmLabel: l10n.signOut,
    );
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = ref.watch(userProfileProvider).valueOrNull?.displayName;
    final isWarehouse =
        ref.watch(userRoleProvider).valueOrNull == UserRole.warehouse;
    final queue = ref.watch(warehouseQueueProvider).valueOrNull;
    final pendingCount = queue?.where((o) => o.isPending).length;
    final preparingCount = queue?.where((o) => o.isPreparing).length;

    return MobileFrame(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: context.palette.surface,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.warehouseDashboardTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (name != null)
                  Text(
                    l10n.helloName(name),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: l10n.refresh,
                onPressed: () => ref.invalidate(warehouseQueueProvider),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: l10n.signOut,
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
            bottom: TabBar(
              indicatorColor: AppColors.secondary,
              indicatorWeight: 3,
              labelColor: AppColors.onPrimary,
              unselectedLabelColor: AppColors.onPrimary.withValues(alpha: 0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: [
                Tab(
                  text: _tabLabel(l10n.warehouseNewOrdersTab, pendingCount),
                ),
                Tab(
                  text: _tabLabel(
                    l10n.warehousePreparingTab,
                    preparingCount,
                  ),
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _QueueTab(pending: true),
              _QueueTab(pending: false),
            ],
          ),
          floatingActionButton: isWarehouse
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'item-inquiry-fab',
                      onPressed: () => scanAndCheckItem(context),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      icon: const Icon(Icons.barcode_reader),
                      label: Text(
                        l10n.warehouseItemInquiry,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.extended(
                      heroTag: 'goods-receipt-fab',
                      onPressed: () => context.push(AppRoutes.goodsReceipt),
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        l10n.warehouseGoodsReceiptTitle,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  static String _tabLabel(String label, int? count) =>
      count == null || count == 0 ? label : '$label ($count)';
}

Future<void> scanAndCheckItem(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  String? barcodeScanRes = await SimpleBarcodeScanner.scanBarcode(
    context,
    barcodeAppBar: BarcodeAppBar(
      appBarTitle: l10n.scanBarcode,
      centerTitle: true,
      enableBackButton: true,
      backButtonIcon: const Icon(Icons.arrow_back),
    ),
    isShowFlashIcon: true,
    delayMillis: 500,
    cameraFace: CameraFace.back,
  );
  if (barcodeScanRes == null || barcodeScanRes == '-1') return;

  final barcode = barcodeScanRes.trim();
  if (barcode.isEmpty || !context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  Map<String, dynamic>? product;
  Object? error;
  try {
    product = await Supabase.instance.client
        .from('products')
        .select('name, image_url, barcode, stock_quantity')
        .eq('barcode', barcode)
        .maybeSingle();
  } catch (e) {
    error = e;
  } finally {
    navigator.pop();
  }

  if (error != null) {
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text(
          l10n.warehouseItemInquiryFailed('$error'),
          style: GoogleFonts.cairo(color: AppColors.onPrimary),
        ),
      ),
    );
    return;
  }

  if (product == null) {
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.secondary,
        content: Text(
          l10n.warehouseItemNotRegistered,
          style: GoogleFonts.cairo(color: AppColors.onPrimary),
        ),
      ),
    );
    return;
  }

  if (!context.mounted) return;
  final name = (product['name'] ?? '').toString();
  final imageUrl = product['image_url']?.toString();
  final stock = product['stock_quantity'] ?? 0;
  final palette = context.palette;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        name,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          color: palette.accent,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: palette.muted,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.warehouseBarcodeValue('${product!['barcode'] ?? barcode}'),
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.warehouseAvailableQuantity('$stock'),
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            l10n.close,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _QueueTab extends ConsumerWidget {
  const _QueueTab({required this.pending});

  /// `pending` orders when true, `preparing` orders otherwise.
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final queueAsync = ref.watch(warehouseQueueProvider);

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: () => ref.refresh(warehouseQueueProvider.future),
      child: queueAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.wifi_off_rounded,
          text: l10n.ordersLoadFailed('$error'),
        ),
        data: (queue) {
          final orders = queue
              .where((order) => pending ? order.isPending : order.isPreparing)
              .toList();
          if (orders.isEmpty) {
            return _Message(
              icon: pending ? Icons.inbox_outlined : Icons.inventory_2_outlined,
              text: pending
                  ? l10n.warehouseNoNewOrders
                  : l10n.warehouseNoPreparingOrders,
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _WarehouseOrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _WarehouseOrderCard extends ConsumerStatefulWidget {
  const _WarehouseOrderCard({required this.order});

  final WarehouseOrder order;

  @override
  ConsumerState<_WarehouseOrderCard> createState() =>
      _WarehouseOrderCardState();
}

class _WarehouseOrderCardState extends ConsumerState<_WarehouseOrderCard> {
  bool _busy = false;

  Future<void> _advance() async {
    final order = widget.order;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final actions = ref.read(warehouseActionsProvider);
    setState(() => _busy = true);
    try {
      if (order.isPending) {
        await actions.startPreparing(order);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              l10n.warehousePreparingStarted(order.shortId),
            ),
          ),
        );
      } else {
        await actions.markReady(order);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              l10n.warehouseOrderReady(order.shortId),
            ),
          ),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;
    final pending = order.isPending;
    final palette = context.palette;

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      elevation: palette.isDark ? 0 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.orderNumber(order.shortId),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.accent,
                    ),
                  ),
                ),
                AdminStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              adminDateFormat.format(order.createdAt),
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
            const Divider(height: 22),
            Text(
              l10n.warehouseProductsCount('${order.itemCount}'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.warehouseCustomerValue(
                order.customerName ?? l10n.safeerCustomer,
              ),
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            if (order.addressDetails != null)
              Text(
                l10n.warehouseAddressValue(order.addressDetails!),
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            Text(
              l10n.warehouseTotalValue(AppCurrency.of(order.totalAmount)),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _busy ? null : _advance,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        pending
                            ? Icons.play_circle_outline_rounded
                            : Icons.local_shipping_outlined,
                      ),
                label: Text(
                  pending
                      ? l10n.startPreparing
                      : l10n.orderStatusReadyForDelivery,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      pending ? AppColors.secondary : AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Scrollable so pull-to-refresh works on empty and error states.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: palette.muted),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
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
