import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../home/presentation/widgets/product_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/presentation/providers/barcode_scanner_provider.dart';
import '../../domain/entities/receipt_line.dart';
import '../../domain/entities/receipt_product.dart';
import '../../domain/entities/receipt_type.dart';
import '../../domain/entities/supplier.dart';
import '../providers/goods_receipt_providers.dart';

/// Warehouse form that stages a draft goods receipt or return in
/// `app_receipts`.
class GoodsReceiptScreen extends ConsumerStatefulWidget {
  const GoodsReceiptScreen({super.key});

  @override
  ConsumerState<GoodsReceiptScreen> createState() => _GoodsReceiptScreenState();
}

class _GoodsReceiptScreenState extends ConsumerState<GoodsReceiptScreen> {
  static final _dateFormat = DateFormat('yyyy/MM/dd', 'en_US');

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _supplierController = TextEditingController();
  final _supplierFocus = FocusNode();
  final _invoiceNumberController = TextEditingController();
  final _invoiceDateController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _lines = <ReceiptLine>[];
  final _products = <String, Future<ReceiptProduct>>{};

  var _type = ReceiptType.receive;
  var _suppliers = const <Supplier>[];
  var _suppliersLoading = true;
  String? _suppliersError;
  Supplier? _supplier;
  DateTime? _invoiceDate;
  var _autovalidate = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _supplierController.dispose();
    _supplierFocus.dispose();
    _invoiceNumberController.dispose();
    _invoiceDateController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Not wrapped in setState so it can also run from [initState].
  void _loadSuppliers() {
    _suppliersLoading = true;
    _suppliersError = null;
    ref.read(goodsReceiptsRepositoryProvider).fetchSuppliers().then(
      (suppliers) {
        if (!mounted) return;
        setState(() {
          _suppliers = suppliers;
          _suppliersLoading = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _suppliersError = error.toString();
          _suppliersLoading = false;
        });
      },
    );
  }

  /// The supplier in the field: the one picked from the list, or a typed
  /// number or exact name that matches exactly one listed supplier.
  Supplier? _resolveSupplier() {
    final text = _supplierController.text.trim();
    final picked = _supplier;
    if (picked != null && text == picked.label) return picked;

    final number = int.tryParse(text);
    if (number != null) {
      return _suppliers.where((s) => s.number == number).firstOrNull;
    }

    final named = _suppliers
        .where((s) => s.name.toLowerCase() == text.toLowerCase())
        .toList();
    return named.length == 1 ? named.single : null;
  }

  Future<void> _scan() async {
    final result = await ref.read(barcodeScannerProvider)(context);
    if (!mounted || result == null) return;
    final barcode = result.trim();
    if (barcode.isEmpty || barcode == '-1') return;
    setState(() => _barcodeController.text = barcode);
  }

  Future<DateTime?> _pickDate(DateTime? current, String helpText) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      helpText: helpText,
    );
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await _pickDate(
      _invoiceDate,
      AppLocalizations.of(context)!.warehouseInvoiceDate,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _invoiceDate = picked;
      _invoiceDateController.text = _dateFormat.format(picked);
    });
  }

  void _clearInvoiceDate() => setState(() {
        _invoiceDate = null;
        _invoiceDateController.clear();
      });

  void _addLine() {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final barcode = _barcodeController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim());
    if (barcode.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.warehouseScanOrEnterBarcode)),
      );
      return;
    }
    if (quantity == null || quantity <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.warehouseEnterQuantityAboveZero)),
      );
      return;
    }

    _products.putIfAbsent(
      barcode,
      () => ref.read(goodsReceiptsRepositoryProvider).lookupProduct(barcode),
    );
    setState(() {
      final index = _lines.indexWhere((line) => line.barcode == barcode);
      if (index >= 0) {
        _lines[index] = _lines[index].copyWith(
          quantity: _lines[index].quantity + quantity,
        );
      } else {
        _lines.add(ReceiptLine(barcode: barcode, quantity: quantity));
      }
      _barcodeController.clear();
      _quantityController.text = '1';
    });
  }

  void _removeLine(int index) => setState(() => _lines.removeAt(index));

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = true);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.warehouseCompleteRequiredFields)),
      );
      return;
    }
    if (_lines.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneItem)),
      );
      return;
    }

    final type = _type;
    final supplier = _resolveSupplier()!;
    setState(() => _busy = true);
    try {
      await ref.read(goodsReceiptActionsProvider).submit(
            type: type,
            supplier: supplier,
            invoiceNumber: _invoiceNumberController.text,
            invoiceDate: _invoiceDate!,
            items: List<ReceiptLine>.unmodifiable(_lines),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(switch (type) {
            ReceiptType.receive => l10n.warehouseReceiptSaved,
            ReceiptType.supplierReturn => l10n.warehouseReturnSaved,
          }),
        ),
      );
      context.pop();
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
    final palette = context.palette;
    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          title: Text(
            switch (_type) {
              ReceiptType.receive => l10n.warehouseGoodsReceiptTitle,
              ReceiptType.supplierReturn => l10n.warehouseGoodsReturnTitle,
            },
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(child: _buildHeader()),
                    ),
                    if (_lines.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              l10n.warehouseNoItemsYet,
                              style: TextStyle(
                                color: palette.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        sliver: SliverList.separated(
                          itemCount: _lines.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _buildLine(index),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(switch (_type) {
                      ReceiptType.receive => l10n.warehouseSubmitReceipt,
                      ReceiptType.supplierReturn => l10n.warehouseSubmitReturn,
                    }),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTypeToggle(),
        const SizedBox(height: 16),
        _SectionTitle(l10n.warehouseDocumentDetails),
        const SizedBox(height: 8),
        _buildSupplierField(),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('goods-receipt-invoice-number'),
          controller: _invoiceNumberController,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.warehouseInvoiceNumberRequiredLabel,
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? l10n.invoiceNumberRequired
              : null,
        ),
        const SizedBox(height: 12),
        _DateField(
          fieldKey: const Key('goods-receipt-invoice-date'),
          controller: _invoiceDateController,
          label: l10n.warehouseInvoiceDateRequiredLabel,
          enabled: !_busy,
          onPick: _pickInvoiceDate,
          onClear: _invoiceDate == null ? null : _clearInvoiceDate,
          validator: (_) =>
              _invoiceDate == null ? l10n.warehouseInvoiceDateRequired : null,
        ),
        const SizedBox(height: 20),
        _SectionTitle(l10n.warehouseItems),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('goods-receipt-barcode'),
          controller: _barcodeController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.warehouseBarcode,
            prefixIcon: const Icon(Icons.qr_code_rounded),
            suffixIcon: IconButton(
              tooltip: l10n.scanBarcode,
              onPressed: _busy ? null : _scan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: TextFormField(
                key: const Key('goods-receipt-quantity'),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.warehouseQuantity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _addLine,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.warehouseAdd),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return SegmentedButton<ReceiptType>(
      key: const Key('goods-receipt-type'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ReceiptType.receive,
          label: Text(ReceiptType.receive.displayLabel(l10n)),
          icon: const Icon(Icons.move_to_inbox_rounded),
        ),
        ButtonSegment(
          value: ReceiptType.supplierReturn,
          label: Text(ReceiptType.supplierReturn.displayLabel(l10n)),
          icon: const Icon(Icons.assignment_return_outlined),
        ),
      ],
      selected: {_type},
      onSelectionChanged: _busy
          ? null
          : (selection) => setState(() => _type = selection.single),
      style: SegmentedButton.styleFrom(
        backgroundColor: palette.card,
        foregroundColor: palette.accent,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: AppColors.onPrimary,
        side: BorderSide(color: palette.accent.withValues(alpha: 0.2)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSupplierField() {
    final l10n = AppLocalizations.of(context)!;
    final Widget suffix;
    if (_suppliersLoading) {
      suffix = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    } else if (_suppliersError != null) {
      suffix = IconButton(
        tooltip: l10n.warehouseReloadSuppliers,
        onPressed: () => setState(_loadSuppliers),
        icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
      );
    } else {
      suffix = const Icon(Icons.search_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) => Autocomplete<Supplier>(
        textEditingController: _supplierController,
        focusNode: _supplierFocus,
        displayStringForOption: (supplier) => supplier.label,
        optionsBuilder: (value) =>
            _suppliers.where((supplier) => supplier.matches(value.text)),
        onSelected: (supplier) {
          setState(() => _supplier = supplier);
          FocusScope.of(context).unfocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return TextFormField(
            key: const Key('goods-receipt-supplier'),
            controller: controller,
            focusNode: focusNode,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: l10n.warehouseSupplierRequiredLabel,
              hintText: l10n.warehouseSupplierHint,
              prefixIcon: const Icon(Icons.storefront_outlined),
              suffixIcon: suffix,
              helperText: _suppliersError != null
                  ? _suppliersError
                  : (!_suppliersLoading && _suppliers.isEmpty)
                      ? l10n.warehouseSuppliersEmpty
                      : null,
              helperMaxLines: 3,
              helperStyle: _suppliersError == null
                  ? null
                  : const TextStyle(color: AppColors.secondary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.warehouseSelectSupplier;
              }
              if (_resolveSupplier() == null) {
                return l10n.warehouseSelectSupplierFromList;
              }
              return null;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) => _SupplierOptions(
          options: options.toList(),
          width: constraints.maxWidth,
          onSelected: onSelected,
        ),
      ),
    );
  }

  Widget _buildLine(int index) {
    final line = _lines[index];
    return FutureBuilder<ReceiptProduct>(
      future: _products[line.barcode],
      builder: (context, snapshot) => _ReceiptLineCard(
        line: line,
        product: snapshot.data,
        loading: snapshot.connectionState != ConnectionState.done,
        onRemove: _busy ? null : () => _removeLine(index),
      ),
    );
  }
}

/// Scrollable supplier suggestions under the supplier field.
class _SupplierOptions extends StatefulWidget {
  const _SupplierOptions({
    required this.options,
    required this.width,
    required this.onSelected,
  });

  final List<Supplier> options;
  final double width;
  final AutocompleteOnSelected<Supplier> onSelected;

  @override
  State<_SupplierOptions> createState() => _SupplierOptionsState();
}

class _SupplierOptionsState extends State<_SupplierOptions> {
  static const _itemExtent = 56.0;
  static const _maxHeight = 320.0;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final height = (options.length * _itemExtent).clamp(0.0, _maxHeight);
    final palette = context.palette;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Material(
          color: palette.card,
          elevation: palette.isDark ? 0 : 6,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: widget.width,
            height: height,
            // The form's scroll view hides the keyboard on any drag it hears
            // about, which unfocuses the field and closes this list.
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemExtent: _itemExtent,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final supplier = options[index];
                    return ListTile(
                      dense: true,
                      onTap: () => widget.onSelected(supplier),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: palette.accent.withValues(alpha: 0.08),
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              '${supplier.number}',
                              style: TextStyle(
                                color: palette.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        supplier.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptLineCard extends StatelessWidget {
  const _ReceiptLineCard({
    required this.line,
    required this.product,
    required this.loading,
    required this.onRemove,
  });

  final ReceiptLine line;
  final ReceiptProduct? product;
  final bool loading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = product?.name;
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 4, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 64,
                child: ColoredBox(
                  color: palette.card,
                  child: ProductImage(
                    imageUrl: product?.imageUrl,
                    iconSize: 28,
                    fit: BoxFit.contain,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ??
                        (loading
                            ? l10n.warehouseFetchingProductName
                            : l10n.warehouseUnregisteredProduct),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: name == null ? palette.muted : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_rounded,
                        size: 14,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          line.barcode,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        l10n.warehouseQuantityValue('${line.quantity}'),
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.accent,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

/// Read-only date input; tapping the field or its calendar icon calls [onPick].
/// When [onClear] is set, a clear button replaces the calendar icon.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onPick,
    this.onClear,
    this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clear = onClear;
    return TextFormField(
      key: fieldKey,
      controller: controller,
      readOnly: true,
      enabled: enabled,
      onTap: onPick,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: l10n.warehouseSelectDate,
        prefixIcon: const Icon(Icons.event_outlined),
        suffixIcon: clear == null
            ? IconButton(
                tooltip: label,
                onPressed: enabled ? onPick : null,
                icon: const Icon(Icons.calendar_month_rounded),
              )
            : IconButton(
                tooltip: l10n.warehouseClearDate,
                onPressed: enabled ? clear : null,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
