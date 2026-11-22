import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driver/presentation/screens/order_map_screen.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../orders/presentation/widgets/cancel_order_dialog.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_status.dart';
import '../providers/admin_providers.dart';
import 'admin_status_chip.dart';
import 'admin_transfer_receipt_dialog.dart';

// ------------------------------------------------------------ order fields

double? orderCoordinate(Object? value) => switch (value) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text),
      _ => null,
    };

/// The order's saved Google Maps pin link, if any.
Uri? orderMapPinUri(Map<String, dynamic> order) =>
    savedMapPinUri(order['delivery_map_url']);

/// Whether the order was placed with a GPS pin (or a saved map link). Legacy
/// imported customers only have a written building / apartment address, and
/// get no «التوجه عبر الخريطة» button.
bool orderHasMapPin(Map<String, dynamic> order) =>
    hasValidDeliveryCoordinates(
      orderCoordinate(order['delivery_latitude']),
      orderCoordinate(order['delivery_longitude']),
    ) ||
    orderMapPinUri(order) != null;

String? orderReceiptUrl(Map<String, dynamic> order) {
  final raw = order['receipt_url'] ?? order['receiptUrl'];
  final text = raw?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// Google Maps directions to the order's delivery pin, else its saved map
/// link. Does nothing for orders without either ([orderHasMapPin]); the
/// coordinates arrive as numbers or text.
Future<void> navigateToOrder(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> order,
) async {
  if (!orderHasMapPin(order)) return;
  await openCustomerInGoogleMaps(
    context,
    ref,
    latitude: orderCoordinate(order['delivery_latitude']),
    longitude: orderCoordinate(order['delivery_longitude']),
    mapPinUri: orderMapPinUri(order),
  );
}

/// «كاش عند الاستلام» / «فيزا عند الاستلام» / «ائتمان» / «إنستا باي».

String orderPaymentLabel(String? method) => switch (method) {
      'cash' || 'cash_on_delivery' => 'كاش عند الاستلام',
      'visa_on_delivery' => 'فيزا عند الاستلام',
      'card' || 'visa' => 'ائتمان',
      'instapay' => 'إنستا باي',
      _ => paymentMethodLabel(method),
    };

/// «مدفوع» / «غير مدفوع»… for orders.payment_status.
String orderPaymentStatusLabel(String status) => switch (status) {
      'paid' => 'مدفوع',
      'unpaid' => 'غير مدفوع',
      'pending' => 'قيد الانتظار',
      'pending_verification' => 'بانتظار التحقق',
      'failed' => 'فشل الدفع',
      _ => status,
    };

// ----------------------------------------------------------------- badges

class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({super.key, required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isCredit = method == 'visa' || method == 'card';
    final isInstaPay = method == 'instapay';
    final color = isCredit
        ? AppColors.success
        : isInstaPay
            ? const Color(0xFF5A2D82)
            : method == 'visa_on_delivery'
                ? Colors.indigo
                : Colors.blueGrey;
    return Container(
      key: Key('payment-method-$method'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        orderPaymentLabel(method),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class DashboardStatusBadge extends StatelessWidget {
  const DashboardStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The live stream and the staff screens mix snake_case and camelCase.
    final normalized = OrderStatus.normalize(status);
    final (Color c, String l) = switch (normalized) {
      'pending' => (Colors.blue, l10n.statusNew),
      'preparing' => (Colors.orange, l10n.adminStatusPreparingShort),
      'ready_for_delivery' => (
          Colors.purple,
          l10n.adminStatusReadyForDriverShort
        ),
      'out_for_delivery' => (Colors.blueAccent, l10n.orderStatusOutForDelivery),
      'delivered' => (AppColors.success, l10n.adminStatusCompletedShort),
      'cancelled' => (Colors.red, l10n.orderStatusCancelled),
      _ => (Colors.grey, l10n.adminStatusUnknown),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(l, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }
}

// ----------------------------------------------------------------- panels

/// A titled card, for the products and actions panels.
class OrderPanel extends StatelessWidget {
  const OrderPanel({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: palette.accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: palette.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A read-only product line of an order.
class OrderProductTile extends StatelessWidget {
  const OrderProductTile({super.key, required this.item});

  final AdminOrderItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final barcode = item.barcode?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: ProductImage(imageUrl: item.imageUrl, iconSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (item.isWeighted)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.quantityLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
                      ),
                    ),
                  ),
                if (barcode != null && barcode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: barcode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ الباركود'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 14, color: palette.muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              barcode,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                color: palette.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded,
                              size: 12, color: palette.muted),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  AppCurrency.of(item.price),
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.quantityLabel,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every product of an order, read-only.
class OrderProductsList extends ConsumerWidget {
  const OrderProductsList({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(adminOrderItemsProvider(orderId));
    return items.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(l10n.failedToLoadProducts),
      data: (items) => items.isEmpty
          ? Text(l10n.adminNoItemsInOrder)
          : Column(children: [
              for (final item in items) OrderProductTile(item: item),
            ]),
    );
  }
}

// -------------------------------------------------------------- info card

/// The complete order details: customer, address, amounts, staff and
/// payment.
class OrderInfoCard extends ConsumerWidget {
  const OrderInfoCard({
    super.key,
    required this.order,
    this.customerName,
    this.customerPhone,
  });

  final Map<String, dynamic> order;
  final String? customerName;
  final String? customerPhone;

  Future<void> _call(BuildContext context, String phone) async {
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.adminCallFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    final id = '${order['id']}';
    final shortId = id.length > 6 ? id.substring(0, 6) : id;
    final status = '${order['status'] ?? ''}';
    final rawPhone = _text(customerPhone);
    final name = _text(customerName) ?? l10n.adminNoName;
    final address = order['address_details'] ??
        order['addressDetails'] ??
        l10n.adminAddressNotSet;
    final fee = _toDouble(order['delivery_fee']);
    final total = _toDouble(order['total_amount']);
    final created = DateTime.tryParse('${order['created_at'] ?? ''}')?.toLocal();
    final isPhoneOrder = order['order_source'] == 'phone';
    final receiver =
        _text(order['taker_name']) ?? (isPhoneOrder ? null : 'التطبيق');
    final method = _text(order['payment_method']);
    final paymentStatus = _text(order['payment_status']);
    final receiptUrl = orderReceiptUrl(order);
    final cancelled = OrderStatus.normalize(status) == 'cancelled';
    final reason = order['cancellation_reason']?.toString().trim();

    Widget cell({
      required IconData icon,
      required String label,
      required Widget value,
      Color? iconColor,
    }) =>
        _InfoCell(
          icon: icon,
          iconColor: iconColor ?? palette.accent,
          label: label,
          value: value,
        );

    Widget boldText(String text, {Key? key}) => Text(
          text,
          key: key,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        );

    Widget staffText(String? value) => boldText(value ?? '—');

    return Container(
      key: const Key('order-info-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        const gap = 16.0;
        final columns = constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : constraints.maxWidth >= 360
                    ? 2
                    : 1;
        final cellWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        Widget sized(Widget child, {int span = 1}) => SizedBox(
              width: cellWidth * span + gap * (span - 1),
              child: child,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '#$shortId',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                DashboardStatusBadge(status: status),
                if (isPhoneOrder)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.phoneOrderBadge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: gap,
              runSpacing: 14,
              children: [
                sized(cell(
                  icon: Icons.person,
                  label: l10n.adminCustomerInfo,
                  value: boldText(name, key: const Key('order-customer-name')),
                )),
                sized(cell(
                  icon: Icons.phone,
                  label: 'رقم الهاتف',
                  value: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              rawPhone ?? l10n.adminNoPhoneNumber,
                              key: const Key('order-customer-phone'),
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      if (rawPhone != null)
                        InkWell(
                          onTap: () => _call(context, rawPhone),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.call,
                                size: 20, color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                )),
                sized(cell(
                  icon: Icons.delivery_dining,
                  label: 'رسوم التوصيل',
                  value: boldText(AppCurrency.of(fee),
                      key: const Key('order-delivery-fee')),
                )),
                sized(cell(
                  icon: Icons.receipt_long,
                  label: 'إجمالي الطلب',
                  value: Text(
                    AppCurrency.of(total),
                    key: const Key('order-total'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: palette.accent,
                    ),
                  ),
                )),
                sized(
                  cell(
                    icon: Icons.location_on,
                    iconColor: Colors.red,
                    label: 'العنوان',
                    value: SelectableText(
                      '$address',
                      key: const Key('order-delivery-address'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  span: columns >= 2 ? 2 : 1,
                ),
                sized(cell(
                  icon: Icons.schedule,
                  label: 'وقت الطلب',
                  value: boldText(
                    created == null ? '—' : adminDateFormat.format(created),
                    key: const Key('order-time'),
                  ),
                )),
                sized(cell(
                  icon: Icons.support_agent,
                  label: 'المتلقي',
                  value: staffText(receiver),
                )),
                sized(cell(
                  icon: Icons.inventory_2_outlined,
                  label: 'المحضر',
                  value: staffText(_text(order['preparer_name'])),
                )),
                sized(cell(
                  icon: Icons.motorcycle_rounded,
                  label: 'الطيار',
                  value: staffText(_text(order['driver_name'])),
                )),
                sized(
                  cell(
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.success,
                    label: 'طريقة الدفع',
                    value: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (method == null)
                          boldText(l10n.notSpecified)
                        else
                          PaymentMethodBadge(method: method),
                        if (paymentStatus != null)
                          Text(
                            orderPaymentStatusLabel(paymentStatus),
                            style:
                                TextStyle(fontSize: 12, color: palette.muted),
                          ),
                        if (receiptUrl != null)
                          OutlinedButton.icon(
                            key: const Key('order-view-instapay-receipt'),
                            onPressed: () => showAdminTransferReceiptDialog(
                                context, receiptUrl),
                            icon: const Icon(Icons.receipt_long_outlined,
                                size: 18),
                            label: Text(l10n.adminViewTransferReceipt),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5A2D82),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: const Color(0xFF5A2D82)
                                    .withValues(alpha: 0.45),
                              ),
                              textStyle: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ),
                  span: columns >= 2 ? 2 : 1,
                ),
              ],
            ),
            if (cancelled) ...[
              const SizedBox(height: 14),
              Container(
                key: const Key('order-cancellation-reason'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.cancellationReasonLine(
                          cancellationReasonLabel(l10n, reason),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (orderHasMapPin(order)) ...[
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const Key('order-navigate'),
                  onPressed: () => navigateToOrder(context, ref, order),
                  icon: const Icon(Icons.navigation_rounded),
                  label: Text(l10n.driverNavigateViaMap),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  static double _toDouble(Object? value) => switch (value) {
        final num number => number.toDouble(),
        final String text => double.tryParse(text) ?? 0,
        _ => 0,
      };
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}
