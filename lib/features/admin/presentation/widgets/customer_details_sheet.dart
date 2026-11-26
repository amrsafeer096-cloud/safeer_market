import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/domain/egyptian_phone.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';

/// Customer phone helpers (Egyptian mobile + landline).
abstract final class _Phone {
  static String local(String raw) => EgyptianPhone.normalize(raw);

  static bool isValid(String raw) => EgyptianPhone.isValidCustomerPhone(raw);

  static bool isValidOrEmpty(String raw) =>
      EgyptianPhone.isValidCustomerPhoneOrEmpty(raw);
}

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
  late final _name = TextEditingController(text: widget.initial.fullName ?? '');
  late final _phone = TextEditingController(text: widget.initial.phone ?? '');
  late final _phone2 = TextEditingController(text: widget.initial.phone2 ?? '');
  late final _phone3 = TextEditingController(text: widget.initial.phone3 ?? '');
  late final _notes = TextEditingController(text: widget.initial.notes ?? '');

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
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _phone2, _phone3, _notes]) {
      c.dispose();
    }
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
        _phone.text = details.customer.phone ?? '';
        _phone2.text = details.customer.phone2 ?? '';
        _phone3.text = details.customer.phone3 ?? '';
        _notes.text = details.customer.notes ?? '';
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

  Future<void> _persistPhonesIfNeeded() async {
    final posId = _customer.posCustomerId;
    if (posId == null) return;
    final updated = await ref
        .read(phoneOrdersRepositoryProvider)
        .updateCustomerDetails(
          posCustomerId: posId,
          fullName: _name.text.trim(),
          phone: _Phone.local(_phone.text),
          phone2: _optional(_phone2) == null
              ? ''
              : _Phone.local(_phone2.text),
          phone3: _optional(_phone3) == null
              ? ''
              : _Phone.local(_phone3.text),
          notes: _notes.text,
        );
    _customer = updated;
  }

  Future<void> _confirm() async {
    if (_saving || !_form.currentState!.validate()) return;
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
      final confirmed = _customer.copyWith(
        fullName: _name.text.trim(),
        phone: _Phone.local(_phone.text),
        phone2: _optional(_phone2) == null
            ? null
            : _Phone.local(_phone2.text),
        phone3: _optional(_phone3) == null
            ? null
            : _Phone.local(_phone3.text),
        notes: _optional(_notes),
        clearPhone2: _optional(_phone2) == null,
        clearPhone3: _optional(_phone3) == null,
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
                          TextFormField(
                            key: const Key('customer-details-phone'),
                            controller: _phone,
                            enabled: _isPos,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'الموبايل الأساسي',
                              hintText: 'موبايل أو أرضي',
                            ),
                            validator: (v) => _Phone.isValid(v ?? '')
                                ? null
                                : 'رقم غير صالح',
                          ),
                          TextFormField(
                            key: const Key('customer-details-phone2'),
                            controller: _phone2,
                            enabled: _isPos,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'رقم إضافي 2',
                              hintText: 'موبايل أو أرضي',
                            ),
                            validator: (v) => _Phone.isValidOrEmpty(v ?? '')
                                ? null
                                : 'رقم غير صالح',
                          ),
                          TextFormField(
                            key: const Key('customer-details-phone3'),
                            controller: _phone3,
                            enabled: _isPos,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'رقم إضافي 3',
                              hintText: 'موبايل أو أرضي',
                            ),
                            validator: (v) => _Phone.isValidOrEmpty(v ?? '')
                                ? null
                                : 'رقم غير صالح',
                          ),
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
                                        label: const Text('افتراضي',
                                            style: TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: palette.accent
                                            .withValues(alpha: 0.12),
                                      )
                                    : null,
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

/// Compact add/edit address form used from «بيانات العميل».
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
  late final _building =
      TextEditingController(text: widget.existing?.building ?? '');
  late final _floor = TextEditingController(text: widget.existing?.floor ?? '');
  late final _apartment =
      TextEditingController(text: widget.existing?.apartment ?? '');
  late final _branch =
      TextEditingController(text: widget.existing?.branch ?? '');
  late final _addressLine =
      TextEditingController(text: widget.existing?.address ?? '');

  String? _governorate;
  String? _city;
  String? _area;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _governorate = widget.existing?.governorate;
    _city = widget.existing?.city;
    _area = widget.existing?.fujitsuZoneId ?? widget.existing?.zone;
  }

  @override
  void dispose() {
    for (final c in [_building, _floor, _apartment, _branch, _addressLine]) {
      c.dispose();
    }
    super.dispose();
  }

  ZoneGeo get _geo =>
      ref.read(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;

  String get _currentGovernorate {
    final geo = _geo;
    final chosen = _governorate;
    return chosen != null && geo.governorates.contains(chosen)
        ? chosen
        : geo.governorates.first;
  }

  PhoneOrderArea? get _selectedZone {
    final id = _area;
    if (id == null) return null;
    final zones =
        ref.read(phoneOrderAreasProvider(_city)).valueOrNull ?? const [];
    for (final z in zones) {
      if (z.id == id || z.name == id) return z;
    }
    return null;
  }

  String _composeLine() {
    final typed = _optional(_addressLine);
    if (typed != null) return typed;
    final zone = _selectedZone;
    final parts = [
      if (_optional(_building) case final b?) 'مبنى $b',
      if (_optional(_floor) case final f?) 'الدور $f',
      if (_optional(_apartment) case final a?) 'شقة $a',
      if (zone?.name != null) zone!.name,
      if (_city != null) _city,
      _currentGovernorate,
    ];
    return parts.join('، ');
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final line = _composeLine().trim();
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
      final saved = await ref.read(phoneOrdersRepositoryProvider).upsertCustomerAddress(
            posCustomerId: widget.customer.posCustomerId,
            userId: widget.customer.userId,
            addressId: widget.existing?.customerAddressId,
            address: line,
            zone: zone?.name ?? _city,
            branch: _optional(_branch),
            governorate: _currentGovernorate,
            city: _city,
            building: _optional(_building),
            floor: _optional(_floor),
            apartment: _optional(_apartment),
            fujitsuZoneId: zone?.fujitsuZoneId,
            isPrimary: widget.existing?.isPrimary ??
                true, // first / edited primary stays primary when none
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
    final zones = ref.watch(phoneOrderAreasProvider(_city)).valueOrNull ??
        const <PhoneOrderArea>[];
    final geo = ref.watch(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;
    final governorate = _currentGovernorate;
    final cities = geo.citiesOf(governorate);
    final fee = zones
        .where((z) => z.id == _area || z.name == _area)
        .map((z) => z.deliveryFee)
        .firstOrNull;

    return AlertDialog(
      key: const Key('customer-address-editor'),
      backgroundColor: palette.card,
      title: Text(widget.existing == null ? 'إضافة عنوان' : 'تعديل العنوان'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('addr-edit-line'),
                  controller: _addressLine,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    hintText: 'شارع / وصف مختصر (اختياري إن اخترت المبنى والمنطقة)',
                  ),
                ),
                TextFormField(
                  key: const Key('addr-edit-building'),
                  controller: _building,
                  decoration: const InputDecoration(labelText: 'المبنى'),
                ),
                TextFormField(
                  key: const Key('addr-edit-floor'),
                  controller: _floor,
                  decoration: const InputDecoration(labelText: 'الدور'),
                ),
                TextFormField(
                  key: const Key('addr-edit-apartment'),
                  controller: _apartment,
                  decoration: const InputDecoration(labelText: 'الشقة'),
                ),
                TextFormField(
                  key: const Key('addr-edit-branch'),
                  controller: _branch,
                  decoration: const InputDecoration(labelText: 'الفرع'),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('addr-edit-governorate'),
                  initialValue: governorate,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  items: [
                    for (final name in geo.governorates)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _governorate = v;
                      _city = null;
                      _area = null;
                    });
                  },
                ),
                KeyedSubtree(
                  key: ValueKey('cities-$governorate'),
                  child: DropdownButtonFormField<String>(
                    key: const Key('addr-edit-city'),
                    initialValue: cities.contains(_city) ? _city : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                    items: [
                      for (final city in cities)
                        DropdownMenuItem(value: city, child: Text(city)),
                    ],
                    onChanged: (v) => setState(() {
                      _city = v;
                      _area = null;
                    }),
                  ),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('area-$_city'),
                  initialValue: zones.any((z) => z.id == _area || z.name == _area)
                      ? _area
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'المنطقة'),
                  items: [
                    for (final z in zones)
                      DropdownMenuItem(
                        value: z.id,
                        child: Text(
                          z.deliveryFee == null
                              ? z.name
                              : '${z.name} (${AppCurrency.of(z.deliveryFee!)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: zones.isEmpty
                      ? null
                      : (v) => setState(() => _area = v),
                ),
                if (fee != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'رسوم التوصيل: ${AppCurrency.of(fee)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.secondary)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
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
    );
  }
}
