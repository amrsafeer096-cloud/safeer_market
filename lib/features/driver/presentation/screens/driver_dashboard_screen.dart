import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/presentation/widgets/admin_status_chip.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/menu_tile.dart';
import '../../domain/entities/driver_order.dart';
import '../../domain/services/driver_location_service.dart';
import '../providers/driver_providers.dart';
import 'order_map_screen.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  StreamSubscription<Map<String, dynamic>>? _messages;
  late final DriverLocationTracker _tracker;

  @override
  void initState() {
    super.initState();
    _tracker = ref.read(driverLocationTrackerProvider)
      ..onFailure = _showTrackingError;
    // Share the GPS while any accepted order is out for delivery.
    ref.listenManual<AsyncValue<List<DriverOrder>>>(
      myDeliveriesProvider,
      (previous, next) {
        if (next case AsyncData(:final value)) _syncTracking(value);
      },
      fireImmediately: true,
    );
    // A push for a new order while the dashboard is open refreshes the list.
    _messages = ref
        .read(pushNotificationServiceProvider)
        .foregroundMessages
        .listen((data) {
      if (data['type'] != 'new_order' || !mounted) return;
      ref.invalidate(availableOrdersProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.driverNewOrderAvailable),
          ),
        );
    });
  }

  @override
  void dispose() {
    _messages?.cancel();
    _tracker
      ..onFailure = null
      ..stop();
    super.dispose();
  }

  void _showTrackingError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(message),
        ),
      );
  }

  Future<void> _syncTracking(List<DriverOrder> deliveries) async {
    final orderIds = {
      for (final order in deliveries)
        if (order.status == 'out_for_delivery') order.id,
    };
    try {
      await _tracker.track(orderIds);
    } on DriverLocationFailure catch (failure) {
      _showTrackingError(failure.message);
    } catch (error) {
      debugPrint('[Tracking] could not start location sharing: $error');
      if (!mounted) return;
      _showTrackingError(
        AppLocalizations.of(context)!
            .driverLocationSharingStartFailed('$error'),
      );
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOut,
      message: l10n.driverSignOutConfirm,
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
    final availableCount =
        ref.watch(availableOrdersProvider).valueOrNull?.length;
    final mineCount = ref.watch(myDeliveriesProvider).valueOrNull?.length;

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
                  l10n.driverDashboardTitle,
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
                onPressed: () => ref
                  ..invalidate(availableOrdersProvider)
                  ..invalidate(myDeliveriesProvider),
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
                  text: _tabLabel(
                    l10n.driverAvailableOrdersTab,
                    availableCount,
                  ),
                ),
                Tab(text: _tabLabel(l10n.myOrders, mineCount)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _OrdersTab(available: true),
              _OrdersTab(available: false),
            ],
          ),
        ),
      ),
    );
  }

  static String _tabLabel(String label, int? count) =>
      count == null || count == 0 ? label : '$label ($count)';
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = available ? availableOrdersProvider : myDeliveriesProvider;
    final ordersAsync = ref.watch(provider);

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: () => ref.refresh(provider.future),
      child: ordersAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.wifi_off_rounded,
          text: l10n.ordersLoadFailed('$error'),
        ),
        data: (orders) => orders.isEmpty
            ? _Message(
                icon: available
                    ? Icons.inbox_outlined
                    : Icons.delivery_dining_outlined,
                text: available
                    ? l10n.driverNoAvailableOrders
                    : l10n.driverNoActiveDeliveries,
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _DriverOrderCard(
                  order: orders[index],
                  available: available,
                ),
              ),
      ),
    );
  }
}

class _DriverOrderCard extends ConsumerStatefulWidget {
  const _DriverOrderCard({required this.order, required this.available});

  final DriverOrder order;
  final bool available;

  @override
  ConsumerState<_DriverOrderCard> createState() => _DriverOrderCardState();
}

class _DriverOrderCardState extends ConsumerState<_DriverOrderCard> {
  bool _busy = false;

  void _openMap() {
    final order = widget.order;
    final latitude = order.latitude;
    final longitude = order.longitude;
    if (!hasValidDeliveryCoordinates(latitude, longitude)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noLocationForOrder),
          ),
        );
      return;
    }
    context.push(
      AppRoutes.driverMapFor(latitude: latitude!, longitude: longitude!),
    );
  }

  Future<void> _navigate() => openCustomerInGoogleMaps(
        context,
        ref,
        latitude: widget.order.latitude,
        longitude: widget.order.longitude,
        address: widget.order.addressDetails,
      );

  /// Starts streaming the GPS into this order; failures are shown verbatim.
  static Future<void> _startSharing(
    DriverLocationTracker tracker,
    ScaffoldMessengerState messenger,
    String orderId,
  ) async {
    try {
      await tracker.start(orderId);
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(error.toString()),
          ),
        );
    }
  }

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final actions = ref.read(driverActionsProvider);
    final tracker = ref.read(driverLocationTrackerProvider);
    setState(() => _busy = true);
    try {
      if (widget.available) {
        await actions.accept(widget.order);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(l10n.driverOrderAccepted(widget.order.shortId)),
          ),
        );
        // The order is now out for delivery: start sharing the location.
        await _startSharing(tracker, messenger, widget.order.id);
      } else {
        await actions.markDelivered(widget.order);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(l10n.driverOrderDelivered(widget.order.shortId)),
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
    final distance = order.distanceKm;
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
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: l10n.customer,
              value: order.customerName ?? l10n.safeerCustomer,
            ),
            if (!widget.available && order.customerPhone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: l10n.driverPhoneLabel,
                value: order.customerPhone!,
                copyable: true,
              ),
            _DeliveryAddress(
              orderId: order.id,
              address: order.addressDetails,
              copyable: !widget.available,
            ),
            _InfoRow(
              icon: Icons.social_distance_rounded,
              label: l10n.driverDistanceLabel,
              value: distance == null
                  ? l10n.driverDistanceNotSpecified
                  : l10n.driverDistanceFromBranch(
                      DeliveryPricing.formatDistance(distance),
                    ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Amount(
                      label: l10n.deliveryFee,
                      value: AppCurrency.of(order.deliveryFee),
                    ),
                  ),
                  Expanded(
                    child: _Amount(
                      label: l10n.driverTotalToCollect,
                      value: AppCurrency.of(order.totalAmount),
                      emphasized: true,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValidDeliveryCoordinates(
                order.latitude, order.longitude)) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: Key('driver-navigate-${order.id}'),
                  onPressed: _navigate,
                  icon: const Icon(Icons.navigation_rounded, size: 26),
                  label: Text(l10n.driverNavigateViaMap),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _openMap,
                  icon: const Icon(Icons.map_rounded),
                  label: Text(l10n.driverViewMapAndLocation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            if (!widget.available) ...[
              const SizedBox(height: 8),
              _LocationSharingStatus(
                orderId: order.id,
                onStart: () => _startSharing(
                  ref.read(driverLocationTrackerProvider),
                  ScaffoldMessenger.of(context),
                  order.id,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        widget.available
                            ? Icons.check_circle_outline_rounded
                            : Icons.task_alt_rounded,
                      ),
                label: Text(
                  widget.available
                      ? l10n.driverAcceptOrder
                      : l10n.orderStatusDelivered,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.available
                      ? AppColors.secondary
                      : AppColors.success,
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

/// Shows whether this order is receiving the driver's live location, with a
/// button to (re)start it.
class _LocationSharingStatus extends ConsumerWidget {
  const _LocationSharingStatus({required this.orderId, required this.onStart});

  final String orderId;
  final VoidCallback onStart;

  static final _time = DateFormat('HH:mm:ss');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tracker = ref.watch(driverLocationTrackerProvider);

    if (tracker.isSharing(orderId)) {
      final lastSentAt = tracker.lastSentAt;
      return Row(
        key: const Key('location-sharing-live'),
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastSentAt == null
                  ? l10n.driverBroadcastingLocation
                  : l10n.driverBroadcastingLocationLastSent(
                      _time.format(lastSentAt),
                    ),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }
    if (tracker.status == TrackingStatus.starting) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 8),
          Text(l10n.driverRequestingLocationPermission),
        ],
      );
    }
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        key: const Key('start-location-sharing'),
        onPressed: onStart,
        icon: const Icon(Icons.my_location_rounded),
        label: Text(l10n.driverStartLocationSharing),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// The full written delivery address, on as many lines as it needs.
class _DeliveryAddress extends StatelessWidget {
  const _DeliveryAddress({
    required this.orderId,
    required this.address,
    required this.copyable,
  });

  final String orderId;
  final String? address;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final address = this.address?.trim();
    final hasAddress = address != null && address.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.driverDeliveryAddress,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  hasAddress ? address : l10n.notSpecified,
                  key: Key('driver-address-$orderId'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && hasAddress)
            IconButton(
              tooltip: l10n.driverCopyLabel(l10n.driverAddressLabel),
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content:
                        Text(l10n.driverCopiedLabel(l10n.driverAddressLabel)),
                  ));
              },
              icon: Icon(Icons.copy_rounded, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(color: palette.muted),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: AppLocalizations.of(context)!.driverCopyLabel(label),
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.driverCopiedLabel(label),
                      ),
                    ),
                  );
              },
              icon: Icon(Icons.copy_rounded, color: palette.muted),
            ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: palette.muted),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: emphasized ? palette.accent : palette.onSurface,
            ),
          ),
        ),
      ],
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
