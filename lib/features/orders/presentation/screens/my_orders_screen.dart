import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/customer_order.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_card.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  Stream<List<CustomerOrder>>? _live;
  int _generation = 0;
  int _liveGeneration = -1;
  String? _liveUserId;

  /// Opens a realtime subscription on `orders`. A new status from the driver
  /// (such as `out_for_delivery`) arrives on this stream and rebuilds the list.
  Stream<List<CustomerOrder>> _ordersStream() {
    final override = ref.watch(customerOrdersStreamOverrideProvider);
    if (override != null) return override;

    final currentUserId = ref.watch(currentUserProvider)?.id;
    if (_live != null &&
        _liveGeneration == _generation &&
        _liveUserId == currentUserId) {
      return _live!;
    }
    _liveGeneration = _generation;
    _liveUserId = currentUserId;
    if (currentUserId == null) {
      return _live = Stream.value(const []);
    }

    return _live = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) {
          final orders = rows.map(CustomerOrder.fromRow).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  @override
  Widget build(BuildContext context) {
    final ordersStream = _ordersStream();
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.myOrders)),
        body: RefreshIndicator(
          color: palette.accent,
          onRefresh: () async {
            setState(() => _generation++);
          },
          child: StreamBuilder<List<CustomerOrder>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _OrdersMessage(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.myOrdersLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => setState(() => _generation++),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snapshot.data!;
              if (orders.isEmpty) {
                return _OrdersMessage(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.myOrdersEmptyTitle,
                  subtitle: l10n.myOrdersEmptySubtitle,
                  actionLabel: l10n.shopNow,
                  onAction: () => goToHomeTab(context, ref),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    OrderCard(order: orders[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: palette.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: palette.muted,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
