import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/domain/customer_phone.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';
import 'customer_phones_editor.dart';
import 'structured_address_fields.dart';

String? _optional(TextEditingController c) =>
    c.text.trim().isEmpty ? null : c.text.trim();

/// Opens «بيانات العميل» and returns the confirmed customer (with chosen
/// address / phones), or null if cancelled.
Future<PhoneOrderCustomer?> showCustomerDetailsSheet(
  BuildContext context, {
  required PhoneOrderCustomer customer,
}) {
  return showDialog<PhoneOrderCustomer>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CustomerDetailsSheet(initial: customer),
  );
}

class CustomerDetailsSheet extends ConsumerStatefulWidget {
  const CustomerDetailsSheet({super.key, required this.initial});

  final PhoneOrderCustomer initial;

  @override
  ConsumerState<CustomerDetailsSheet> createState() =>
      _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends ConsumerState<CustomerDetailsSheet> {
  final _form = GlobalKey<FormState>();
  final _phonesKey = GlobalKey<CustomerPhonesEditorState>();
  late final _name = TextEditingController(text: widget.initial.fullName ?? '');
  late final _notes = TextEditingController(text: widget.initial.notes ?? '');
  var _phoneSeed = <String?>[];

  var _loading = true;
  var _saving = false;
  String? _error;
  PhoneOrderCustomer _customer = const PhoneOrderCustomer(
    source: PhoneOrderCustomerSource.pos,
  );
  List<PhoneOrderCustomerAddress> _addresses = const [];
  String? _selectedAddressId;

  bool get _isPos => _customer.posCustomerId != null;

  @override
  void initState() {
    super.initState();
    _customer = widget.initial;
    _phoneSeed = [...widget.initial.phoneSlots];
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await ref
          .read(phoneOrdersRepositoryProvider)
          .fetchCustomerDetails(widget.initial);
      if (!mounted) return;
      final primary = details.addresses.where((a) => a.isPrimary).firstOrNull ??
          details.addresses.firstOrNull;
      setState(() {
        _customer = details.customer;
        _addresses = details.addresses;
        _selectedAddressId = widget.initial.selectedAddressId ?? primary?.id;
        _name.text = details.customer.fullName ?? '';
        _notes.text = details.customer.notes ?? '';
        _phoneSeed = [...details.customer.phoneSlots];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      // Migration may not be applied yet — still allow confirming search data.
      setState(() {
        _customer = widget.initial;
        _addresses = [
          if ((widget.initial.address ?? '').trim().isNotEmpty)
            PhoneOrderCustomerAddress(
              id: 'legacy',
              address: widget.initial.address!,
              zone: widget.initial.zone,
              fujitsuZoneId: widget.initial.fujitsuZoneId,
              isPrimary: true,
            ),
        ];
        _selectedAddressId = _addresses.isEmpty ? null : _addresses.first.id;
        _loading = false;
        _error = '$error';
      });
    }
  }

  PhoneOrderCustomerAddress? get _selected {
    final id = _selectedAddressId;
    if (id == null) return null;
    for (final a in _addresses) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<String?> _slotsFromEditor() {
    final editor = _phonesKey.currentState;
    if (editor == null) return CustomerPhone.fiveSlots(_phoneSeed);
    return editor.fiveSlots();
  }

  Future<void> _persistPhonesIfNeeded() async {
    final posId = _customer.posCustomerId;
    if (posId == null) return;
    final slots = _slotsFromEditor();
    final updated = await ref
        .read(phoneOrdersRepositoryProvider)
        .updateCustomerDetails(
          posCustomerId: posId,
          fullName: _name.text.trim(),
          phone: slots[0],
          phone2: slots[1] ?? '',
          phone3: slots[2] ?? '',
          phone4: slots[3] ?? '',
          phone5: slots[4] ?? '',
          notes: _notes.text,
        );
    _customer = updated;
  }

  Future<void> _confirm() async {
    if (_saving || !_form.currentState!.validate()) return;
    final phoneError = _phonesKey.currentState?.validate();
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    final selected = _selected;
    if (_addresses.isNotEmpty && selected == null) {
      setState(() => _error = 'اختر عنوان التوصيل لهذا الطلب');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isPos) {
        try {
          await _persistPhonesIfNeeded();
        } catch (_) {
          // Migration may be pending — still lock the draft with local edits.
        }
      }
      final slots = _slotsFromEditor();
      final confirmed = _customer.copyWith(
        fullName: _name.text.trim(),
        phone: slots[0],
        phone2: slots[1],
        phone3: slots[2],
        phone4: slots[3],
        phone5: slots[4],
        notes: _optional(_notes),
        clearPhone2: slots[1] == null,
        clearPhone3: slots[2] == null,
        clearPhone4: slots[3] == null,
        clearPhone5: slots[4] == null,
        clearNotes: _optional(_notes) == null,
        address: selected?.address ?? _customer.address,
        zone: selected?.zone ?? _customer.zone,
        fujitsuZoneId: selected?.fujitsuZoneId ?? _customer.fujitsuZoneId,
        fujitsuAddressId: selected?.fujitsuAddressId,
        clearFujitsuAddressId: selected?.fujitsuAddressId == null,
        selectedAddressId: selected?.id,
      );
      if (mounted) Navigator.of(context).pop(confirmed);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  Future<void> _addOrEditAddress({PhoneOrderCustomerAddress? existing}) async {
    final result = await showDialog<PhoneOrderCustomerAddress>(
      context: context,
      builder: (_) => _AddressEditorDialog(
        customer: _customer,
        existing: existing,
      ),
    );
    if (result == null || !mounted) return;
    await _load();
    if (!mounted) return;
    setState(() => _selectedAddressId = result.id);
  }

  Future<void> _setDefaultAddress(PhoneOrderCustomerAddress addr) async {
    if (addr.fromAppAddresses || addr.id == 'legacy') return;
    final id = addr.customerAddressId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(phoneOrdersRepositoryProvider).upsertCustomerAddress(
            posCustomerId: _customer.posCustomerId,
            userId: _customer.userId,
            addressId: id,
            address: addr.address,
            zone: addr.zone,
            branch: addr.branch,
            governorate: addr.governorate,
            city: addr.city,
            building: addr.building,
            street: addr.street,
            landmark: addr.landmark,
            floor: addr.floor,
            apartment: addr.apartment,
            notes: addr.notes,
            latitude: addr.latitude,
            longitude: addr.longitude,
            fujitsuZoneId: addr.fujitsuZoneId,
            isPrimary: true,
          );
      await _load();
      if (!mounted) return;
      setState(() {
        _selectedAddressId = addr.id;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Dialog(
      key: const Key('customer-details-sheet'),
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'بيانات العميل',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  if (_customer.fujitsuCustomerNo != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Text(
                        'رقم العميل: ${_customer.fujitsuCustomerNo}',
                        key: const Key('customer-details-fujitsu-no'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _form,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        children: [
                          TextFormField(
                            key: const Key('customer-details-name'),
                            controller: _name,
                            enabled: _isPos,
                            decoration: const InputDecoration(
                              labelText: 'اسم العميل',
                            ),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 8),
                          CustomerPhonesEditor(
                            key: _phonesKey,
                            initialPhones: _phoneSeed,
                            enabled: _isPos,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const Key('customer-details-notes'),
                            controller: _notes,
                            enabled: _isPos,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات العميل',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'العناوين',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: palette.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_addresses.isEmpty)
                            Text(
                              'لا توجد عناوين محفوظة — أضف عنواناً للتوصيل',
                              style: TextStyle(color: palette.muted),
                            )
                          else
                            for (final addr in _addresses)
                              RadioListTile<String>(
                                key: Key('customer-details-address-${addr.id}'),
                                value: addr.id,
                                groupValue: _selectedAddressId,
                                onChanged: (v) =>
                                    setState(() => _selectedAddressId = v),
                                title: Text(
                                  addr.address,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  [
                                    if ((addr.zone ?? '').isNotEmpty)
                                      'المنطقة: ${addr.zone}',
                                    if ((addr.branch ?? '').isNotEmpty)
                                      'الفرع: ${addr.branch}',
                                  ].join('  •  '),
                                  style: TextStyle(
                                      fontSize: 12, color: palette.muted),
                                ),
                                secondary: addr.isPrimary
                                    ? Chip(
                                        key: Key(
                                            'customer-details-default-${addr.id}'),
                                        label: const Text('افتراضي',
                                            style: TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: palette.accent
                                            .withValues(alpha: 0.12),
                                      )
                                    : TextButton(
                                        key: Key(
                                            'customer-details-make-default-${addr.id}'),
                                        onPressed: _saving
                                            ? null
                                            : () => _setDefaultAddress(addr),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          minimumSize: const Size(0, 28),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'تعيين كافتراضي',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                              ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style:
                                  const TextStyle(color: AppColors.secondary),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    key: const Key('customer-details-add-address'),
                    onPressed: _saving || _loading
                        ? null
                        : () => _addOrEditAddress(),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('إضافة عنوان'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('customer-details-edit-address'),
                    onPressed: _saving ||
                            _loading ||
                            _selected == null ||
                            _selected!.fromAppAddresses ||
                            _selected!.id == 'legacy'
                        ? null
                        : () => _addOrEditAddress(existing: _selected),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                    label: const Text('تعديل العنوان'),
                  ),
                  TextButton(
                    key: const Key('customer-details-cancel'),
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    key: const Key('customer-details-confirm'),
                    onPressed: _saving || _loading ? null : _confirm,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('موافق'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add/edit address form used from «بيانات العميل» — Fujitsu structured
/// fields with customer name/code pre-filled (read-only) at the top.
class _AddressEditorDialog extends ConsumerStatefulWidget {
  const _AddressEditorDialog({
    required this.customer,
    this.existing,
  });

  final PhoneOrderCustomer customer;
  final PhoneOrderCustomerAddress? existing;

  @override
  ConsumerState<_AddressEditorDialog> createState() =>
      _AddressEditorDialogState();
}

class _AddressEditorDialogState extends ConsumerState<_AddressEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final StructuredAddressControllers _address;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _address = StructuredAddressControllers(
      building: existing?.building,
      floor: existing?.floor,
      apartment: existing?.apartment,
      street: existing?.street,
      landmark: existing?.landmark,
      branch: existing?.branch ?? 'حي الزهور',
      notes: existing?.notes,
      composed: existing?.address,
      governorate: existing?.governorate ?? 'القاهرة',
      city: existing?.city ?? 'مدينة نصر',
      area: existing?.fujitsuZoneId ?? existing?.zone,
    );
    if ((existing?.address ?? '').trim().isNotEmpty) {
      _address.autoCompose = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_address.autoCompose) _syncComposed();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  ZoneGeo get _geo =>
      ref.read(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;

  String get _currentGovernorate {
    final geo = _geo;
    final chosen = _address.governorate;
    return chosen != null && geo.governorates.contains(chosen)
        ? chosen
        : geo.governorates.first;
  }

  PhoneOrderArea? get _selectedZone {
    final id = _address.area;
    if (id == null) return null;
    final zones = ref
            .read(phoneOrderAreasProvider(_address.city))
            .valueOrNull ??
        const [];
    for (final z in zones) {
      if (z.id == id || z.name == id) return z;
    }
    return null;
  }

  void _syncComposed() {
    _address.refreshComposed(
      zoneName: _selectedZone?.name,
      governorateFallback: _currentGovernorate,
    );
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    _syncComposed();
    final line = _address.composed.text.trim();
    if (line.isEmpty) {
      setState(() => _error = 'أدخل عنواناً أو اختر المنطقة');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final zone = _selectedZone;
      final saved =
          await ref.read(phoneOrdersRepositoryProvider).upsertCustomerAddress(
                posCustomerId: widget.customer.posCustomerId,
                userId: widget.customer.userId,
                addressId: widget.existing?.customerAddressId,
                address: line,
                zone: zone?.name ?? _address.city,
                branch: _address.optional(_address.branch),
                governorate: _currentGovernorate,
                city: _address.city,
                building: _address.optional(_address.building),
                street: _address.optional(_address.street),
                landmark: _address.optional(_address.landmark),
                floor: _address.optional(_address.floor),
                apartment: _address.optional(_address.apartment),
                notes: _address.optional(_address.notes),
                fujitsuZoneId: zone?.fujitsuZoneId,
                isPrimary: widget.existing?.isPrimary ?? true,
              );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final customerNo = widget.customer.fujitsuCustomerNo;
    final name = widget.customer.fullName?.trim() ?? '';

    return Dialog(
      key: const Key('customer-address-editor'),
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  widget.existing == null ? 'إضافة عنوان' : 'تعديل العنوان',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('addr-edit-customer-name'),
                        initialValue: name,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'اسم العميل',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('addr-edit-customer-no'),
                        initialValue: customerNo?.toString() ?? '—',
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'رقم العميل',
                        ),
                      ),
                      const SizedBox(height: 12),
                      StructuredAddressFields(
                        controllers: _address,
                        onChanged: _syncComposed,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style:
                                const TextStyle(color: AppColors.secondary)),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('addr-edit-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ'),
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
