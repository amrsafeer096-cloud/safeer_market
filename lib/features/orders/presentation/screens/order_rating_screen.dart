import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../widgets/rate_order_dialog.dart';

/// Opened from the delivered-order push (`action: rate_order`). Shows the
/// rating dialog once, then returns to «طلباتي».
class OrderRatingScreen extends ConsumerStatefulWidget {
  const OrderRatingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends ConsumerState<OrderRatingScreen> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (_opened || !mounted) return;
    _opened = true;
    await showRateOrderDialog(context, orderId: widget.orderId);
    if (!mounted) return;
    context.go(AppRoutes.orders);
  }

  @override
  Widget build(BuildContext context) {
    return const MobileFrame(
      child: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
