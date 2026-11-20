import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../addresses/domain/services/location_service.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';

/// Phone number helpers shared by both steps.
abstract final class _Phone {
  static final _mobile = RegExp(r'^01[0125]\d{8}$');

  /// 01XXXXXXXXX from what staff typed (+20…, spaces, dashes).
  static String local(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0020')) digits = '0${digits.substring(4)}';
    if (digits.startsWith('20') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('1')) digits = '0$digits';
    return digits;
  }

  static bool isValid(String raw) => _mobile.hasMatch(local(raw));
}

String? _optional(TextEditingController controller) =>
    controller.text.trim().isEmpty ? null : controller.text.trim();

// ---------------------------------------------------------------------------
// Step 1: «+ عميل جديد»
// ---------------------------------------------------------------------------

/// Name, phones and customer type. «إضافة عنوان» opens step 2 and, once the
/// address is saved, closes this dialog with the new customer. «حفظ العميل»
/// saves without an address.
class NewCustomerDialog extends ConsumerStatefulWidget {
  const NewCustomerDialog({
    super.key,
    required this.initialName,
    required this.initialPhone,
  });

  final String initialName;
  final String initialPhone;

  @override
  ConsumerState<NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends ConsumerState<NewCustomerDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _phone = TextEditingController(text: widget.initialPhone);
  final _phone2 = TextEditingController();
  var _type = PhoneOrderCustomerType.regular;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _phone2]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addAddress() async {
    if (_saving || !_form.currentState!.validate()) return;
    final customer = await showDialog<PhoneOrderCustomer>(
      context: context,
      builder: (_) => CustomerAddressDialog(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        phone2: _optional(_phone2),
        type: _type,
      ),
    );
    if (customer != null && mounted) Navigator.of(context).pop(customer);
  }

  Future<void> _saveWithoutAddress() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final phone2 = _optional(_phone2);
      final customer =
          await ref.read(phoneOrdersRepositoryProvider).createCustomer(
                fullName: _name.text.trim(),
                phone: _Phone.local(_phone.text),
                phone2: phone2 == null ? null : _Phone.local(phone2),
                type: _type,
              );
      if (mounted) Navigator.of(context).pop(customer);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return AlertDialog(
      key: const Key('new-customer-dialog'),
      backgroundColor: palette.card,
      title: Text(l10n.phoneOrderNewCustomer),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('new-customer-name'),
                  controller: _name,
                  autofocus: true,
                  decoration:
                      InputDecoration(labelText: l10n.phoneOrderCustomerName),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.phoneOrderNameRequired
                      : null,
                ),
                TextFormField(
                  key: const Key('new-customer-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف 1',
                    hintText: '01XXXXXXXXX',
                  ),
                  validator: (value) => _Phone.isValid(value ?? '')
                      ? null
                      : l10n.phoneOrderPhoneInvalid,
                ),
                TextFormField(
                  key: const Key('new-customer-phone2'),
                  controller: _phone2,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف 2 - اختياري',
                    hintText: '01XXXXXXXXX',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty || _Phone.isValid(value!)
                          ? null
                          : l10n.phoneOrderPhoneInvalid,
                ),
                const SizedBox(height: 16),
                Text('نوع العميل',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: palette.muted)),
                const SizedBox(height: 6),
                SegmentedButton<PhoneOrderCustomerType>(
                  key: const Key('new-customer-type'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: PhoneOrderCustomerType.regular,
                      label: Text('عادي'),
                    ),
                    ButtonSegment(
                      value: PhoneOrderCustomerType.vip,
                      label: Text('VIP'),
                      icon: Icon(Icons.workspace_premium_rounded, size: 16),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) =>
                      setState(() => _type = selection.first),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('new-customer-add-address'),
                  onPressed: _saving ? null : _addAddress,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text(
                    'إضافة عنوان',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('new-customer-save'),
          onPressed: _saving ? null : _saveWithoutAddress,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.phoneOrderSaveCustomer),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: «إضافة عنوان»
// ---------------------------------------------------------------------------

/// Name and phone (pre-filled from step 1), then the address in two sides:
/// building / floor / apartment, and governorate / city / zone. «إضافة موقع
/// العميل (GPS)» opens the customer app's map picker; the pin is saved in
/// Supabase for the driver app. Saving creates the customer and pops it.
class CustomerAddressDialog extends ConsumerStatefulWidget {
  const CustomerAddressDialog({
    super.key,
    required this.name,
    required this.phone,
    this.phone2,
    this.type = PhoneOrderCustomerType.regular,
  });

  final String name;
  final String phone;
  final String? phone2;
  final PhoneOrderCustomerType type;

  /// Below this width the two sides stack.
  static const sideBySideMinWidth = 520.0;

  @override
  ConsumerState<CustomerAddressDialog> createState() =>
      _CustomerAddressDialogState();
}

class _CustomerAddressDialogState extends ConsumerState<CustomerAddressDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  final _building = TextEditingController();
  final _floor = TextEditingController();
  final _apartment = TextEditingController();

  String? _governorate;
  String? _city;

  /// The chosen zone's [PhoneOrderArea.id] (its Fujitsu zone id).
  String? _area;
  LatLng? _location;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _phone, _building, _floor, _apartment]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The governorates and cities come from «المناطق» (Cairo when none).
  ZoneGeo get _geo => ref.read(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;

  String get _currentGovernorate {
    final geo = _geo;
    final chosen = _governorate;
    return chosen != null && geo.governorates.contains(chosen)
        ? chosen
        : geo.governorates.first;
  }

  Future<void> _pickLocation() async {
    final picked = await context.push<PickedLocation>(
      AppRoutes.mapPicker,
      extra: _location,
    );
    if (picked == null || !mounted) return;
    setState(() => _location = picked.point);
  }

  /// The zone picked in the dropdown (null when none is chosen).
  PhoneOrderArea? get _selectedZone {
    final id = _area;
    if (id == null) return null;
    final zones =
        ref.read(phoneOrderAreasProvider(_city)).valueOrNull ?? const [];
    for (final zone in zones) {
      if (zone.id == id) return zone;
    }
    return null;
  }

  String? get _addressLine {
    final area = _selectedZone?.name;
    final city = _city;
    final parts = [
      if (_optional(_building) case final building?) 'مبنى $building',
      if (_optional(_floor) case final floor?) 'الدور $floor',
      if (_optional(_apartment) case final apartment?) 'شقة $apartment',
      if (area != null) area,
      if (city != null) city,
    ];
    // The governorate alone isn't an address.
    return parts.isEmpty ? null : [...parts, _currentGovernorate].join('، ');
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final phone2 = widget.phone2;
      final zone = _selectedZone;
      final customer =
          await ref.read(phoneOrdersRepositoryProvider).createCustomer(
                fullName: _name.text.trim(),
                phone: _Phone.local(_phone.text),
                address: _addressLine,
                zone: zone?.name ?? _city,
                fujitsuZoneId: zone?.fujitsuZoneId,
                phone2: phone2 == null ? null : _Phone.local(phone2),
                type: widget.type,
                governorate: _currentGovernorate,
                city: _city,
                building: _optional(_building),
                floor: _optional(_floor),
                apartment: _optional(_apartment),
                latitude: _location?.latitude,
                longitude: _location?.longitude,
              );
      if (mounted) Navigator.of(context).pop(customer);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  Widget _field(
    Key key,
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      );

  /// Right side (the start, in Arabic): building, floor, apartment.
  Widget _buildingSide() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(const Key('address-building'), _building, 'المبنى'),
          _field(const Key('address-floor'), _floor, 'الدور'),
          _field(const Key('address-apartment'), _apartment, 'الشقة'),
        ],
      );

  /// Left side: governorate, city and zone dropdowns.
  Widget _areaSide() {
    final areas = ref.watch(phoneOrderAreasProvider(_city));
    final zones = areas.valueOrNull ?? const <PhoneOrderArea>[];
    final geo = ref.watch(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;
    final governorate = _currentGovernorate;
    final cities = geo.citiesOf(governorate);
    final fee = zones
        .where((zone) => zone.id == _area)
        .map((zone) => zone.deliveryFee)
        .firstOrNull;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('address-governorate'),
          initialValue: governorate,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'المحافظة'),
          items: [
            for (final name in geo.governorates)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _governorate = value;
              _city = null;
              _area = null;
            });
          },
        ),
        const SizedBox(height: 4),
        // Rebuilt per governorate so a stale city never stays selected.
        KeyedSubtree(
          key: ValueKey('cities-of-$governorate'),
          child: DropdownButtonFormField<String>(
            key: const Key('address-city'),
            initialValue: cities.contains(_city) ? _city : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المدينة'),
            items: [
              for (final city in cities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() {
              _city = value;
              _area = null;
            }),
          ),
        ),
        const SizedBox(height: 4),
        // Rebuilt per city so a stale zone never stays selected.
        DropdownButtonFormField<String>(
          key: ValueKey('address-area-$_city'),
          initialValue: zones.any((zone) => zone.id == _area) ? _area : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'المنطقة',
            helperText: zones.isEmpty ? 'لا توجد مناطق مسجلة بعد' : null,
          ),
          items: [
            for (final zone in zones)
              DropdownMenuItem(
                value: zone.id,
                child: Text(
                  zone.deliveryFee == null
                      ? zone.name
                      : '${zone.name} (${AppCurrency.of(zone.deliveryFee!)})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged:
              zones.isEmpty ? null : (value) => setState(() => _area = value),
        ),
        if (fee != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'رسوم التوصيل: ${AppCurrency.of(fee)}',
              key: const Key('address-zone-fee'),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success),
            ),
          ),
      ],
    );
  }

  Widget _gpsSection() {
    final palette = context.palette;
    final location = _location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('address-pick-gps'),
          onPressed: _saving ? null : _pickLocation,
          icon: Icon(location == null
              ? Icons.add_location_alt_rounded
              : Icons.edit_location_alt_rounded),
          label: Text(
            location == null
                ? 'إضافة موقع العميل (GPS)'
                : 'تغيير موقع العميل (GPS)',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (location != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              key: const Key('address-gps-set'),
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'تم تحديد الموقع: '
                    '${location.latitude.toStringAsFixed(5)}, '
                    '${location.longitude.toStringAsFixed(5)}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة الموقع',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _location = null),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Dialog(
      key: const Key('customer-address-dialog'),
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'إضافة عنوان',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('address-customer-name'),
                              controller: _name,
                              decoration: InputDecoration(
                                  labelText: l10n.phoneOrderCustomerName),
                              validator: (value) => (value ?? '').trim().isEmpty
                                  ? l10n.phoneOrderNameRequired
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const Key('address-customer-phone'),
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                  labelText: 'رقم الهاتف 1'),
                              validator: (value) => _Phone.isValid(value ?? '')
                                  ? null
                                  : l10n.phoneOrderPhoneInvalid,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth <
                              CustomerAddressDialog.sideBySideMinWidth - 40) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildingSide(),
                                const SizedBox(height: 4),
                                _areaSide(),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildingSide()),
                              const SizedBox(width: 16),
                              Expanded(child: _areaSide()),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _gpsSection(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
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
                      key: const Key('address-cancel'),
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('address-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.phoneOrderSaveCustomer),
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
