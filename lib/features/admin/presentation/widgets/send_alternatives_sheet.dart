import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../search/presentation/providers/barcode_scanner_provider.dart';
import '../../data/order_alternatives_service.dart';
import '../../domain/entities/admin_order.dart';
import '../../domain/order_item_alternative.dart';
import '../providers/order_alternatives_providers.dart';
import '../providers/staff_session_providers.dart';

/// Opens the «إرسال بدائل» flow for [item] on [orderId].
Future<bool> showSendAlternativesSheet(
  BuildContext context, {
  required String orderId,
  required AdminOrderItem item,
  required bool notifyCustomer,
  String? customerUserId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SendAlternativesSheet(
      orderId: orderId,
      item: item,
      notifyCustomer: notifyCustomer,
      customerUserId: customerUserId,
    ),
  );
  return result == true;
}

class _SendAlternativesSheet extends ConsumerStatefulWidget {
  const _SendAlternativesSheet({
    required this.orderId,
    required this.item,
    required this.notifyCustomer,
    this.customerUserId,
  });

  final String orderId;
  final AdminOrderItem item;
  final bool notifyCustomer;
  final String? customerUserId;

  @override
  ConsumerState<_SendAlternativesSheet> createState() =>
      _SendAlternativesSheetState();
}

class _SendAlternativesSheetState extends ConsumerState<_SendAlternativesSheet> {
  final _search = TextEditingController();
  final _picked = <AlternativeProduct>[];
  var _searching = false;
  var _submitting = false;
  List<AlternativeProduct> _matches = const [];
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (kIsWeb) {
      setState(() => _error = 'امسح يدوياً بالبحث عن الباركود على الويب');
      return;
    }
    try {
      final code = await ref.read(barcodeScannerProvider)(context);
      if (code == null || code == '-1' || !mounted) return;
      await _addByBarcode(code);
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر فتح الماسح: $error');
    }
  }

  Future<void> _addByBarcode(String code) async {
    setState(() {
      _error = null;
      _searching = true;
    });
    try {
      final product = await ref
          .read(orderAlternativesServiceProvider)
          .findProductByBarcode(code);
      if (!mounted) return;
      if (product == null) {
        setState(() => _error = 'لا يوجد منتج بهذا الباركود');
        return;
      }
      _addProduct(product);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _matches = const []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final matches = await ref
          .read(orderAlternativesServiceProvider)
          .searchProducts(query);
      if (mounted) setState(() => _matches = matches);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _addProduct(AlternativeProduct product) {
    if (_picked.any((p) => p.productId == product.productId)) {
      setState(() => _error = 'هذا المنتج مضاف بالفعل');
      return;
    }
    if (product.productId == widget.item.productId) {
      setState(() => _error = 'لا يمكن إضافة نفس المنتج الأصلي');
      return;
    }
    if (_picked.length >= 3) {
      setState(() => _error = 'الحد الأقصى 3 بدائل');
      return;
    }
    setState(() {
      _picked.add(product);
      _error = null;
      _matches = const [];
      _search.clear();
    });
  }

  Future<void> _submit() async {
    if (_picked.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final staff = ref.read(staffSessionProvider);
      await ref.read(orderAlternativesServiceProvider).submitAlternatives(
            orderId: widget.orderId,
            orderItemId: widget.item.id,
            products: _picked,
            staffId: staff?.id,
            notifyCustomer: widget.notifyCustomer,
            customerUserId: widget.customerUserId,
          );
      if (mounted) Navigator.pop(context, true);
    } on OrderAlternativesFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'إرسال بدائل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'الأصل: ${widget.item.productName}',
            style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: _runSearch,
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو الباركود',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('مسح'),
              ),
            ],
          ),
          if (_searching) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          if (_matches.isNotEmpty)
            SizedBox(
              height: 140,
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final p = _matches[index];
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: ProductImage(imageUrl: p.imageUrl, iconSize: 18),
                    ),
                    title: Text(p.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      [
                        if (p.barcode != null) p.barcode!,
                        AppCurrency.of(p.price),
                      ].join(' • '),
                      textDirection: TextDirection.ltr,
                    ),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addProduct(p),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'البدائل المختارة (${_picked.length}/3)',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (_picked.isEmpty)
            Text('امسح أو ابحث لإضافة حتى 3 منتجات بديلة',
                style: TextStyle(color: palette.muted))
          else
            for (final p in _picked)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 44,
                  height: 44,
                  child: ProductImage(imageUrl: p.imageUrl, iconSize: 18),
                ),
                title: Text(p.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    if (p.barcode != null) p.barcode!,
                    AppCurrency.of(p.price),
                  ].join(' • '),
                  textDirection: TextDirection.ltr,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _picked.remove(p)),
                ),
              ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _picked.isEmpty || _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.notifyCustomer
                        ? 'إرسال البدائل للعميل'
                        : 'إرسال البدائل للمتلقي',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }
}
