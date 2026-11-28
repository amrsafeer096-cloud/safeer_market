import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../addresses/domain/services/location_service.dart';
import '../../../auth/domain/customer_phone.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';
import 'customer_phones_editor.dart';
import 'structured_address_fields.dart';

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
  final _phonesKey = GlobalKey<CustomerPhonesEditorState>();
  late final _name = TextEditingController(text: widget.initialName);
  var _type = PhoneOrderCustomerType.regular;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String?> _slots() =>
      _phonesKey.currentState?.fiveSlots() ??
      CustomerPhone.fiveSlots([widget.initialPhone]);

  Future<void> _addAddress() async {
    if (_saving || !_form.currentState!.validate()) return;
    final phoneError = _phonesKey.currentState?.validate();
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    final slots = _slots();
    final customer = await showDialog<PhoneOrderCustomer>(
      context: context,
      builder: (_) => CustomerAddressDialog(
        name: _name.text.trim(),
        phone: slots[0] ?? '',
        phone2: slots[1],
        phone3: slots[2],
        phone4: slots[3],
        phone5: slots[4],
        type: _type,
      ),
    );
    if (customer != null && mounted) Navigator.of(context).pop(customer);
  }

  Future<void> _saveWithoutAddress() async {
    if (_saving || !_form.currentState!.validate()) return;
    final phoneError = _phonesKey.currentState?.validate();
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final slots = _slots();
      final customer =
          await ref.read(phoneOrdersRepositoryProvider).createCustomer(
                fullName: _name.text.trim(),
                phone: slots[0] ?? '',
                phone2: slots[1],
                phone3: slots[2],
                phone4: slots[3],
                phone5: slots[4],
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
                const SizedBox(height: 8),
                CustomerPhonesEditor(
                  key: _phonesKey,
                  initialPhones: [widget.initialPhone],
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
// Step 2: «إضافة عنوان» (new customer)
// ---------------------------------------------------------------------------

/// Name / phones (from step 1) plus Fujitsu structured address fields and a
/// live-composed full address. Saving creates the customer and pops it.
class CustomerAddressDialog extends ConsumerStatefulWidget {
  const CustomerAddressDialog({
    super.key,
    required this.name,
    required this.phone,
    this.phone2,
    this.phone3,
    this.phone4,
    this.phone5,
    this.type = PhoneOrderCustomerType.regular,
  });

  final String name;
  final String phone;
  final String? phone2;
  final String? phone3;
  final String? phone4;
  final String? phone5;
  final PhoneOrderCustomerType type;

  static const sideBySideMinWidth =
      StructuredAddressFields.sideBySideMinWidth;

  @override
  ConsumerState<CustomerAddressDialog> createState() =>
      _CustomerAddressDialogState();
}

class _CustomerAddressDialogState extends ConsumerState<CustomerAddressDialog> {
  final _form = GlobalKey<FormState>();
  final _phonesKey = GlobalKey<CustomerPhonesEditorState>();
  late final _name = TextEditingController(text: widget.name);
  late final _address = StructuredAddressControllers();
  LatLng? _location;
  bool _saving = false;
  String? _error;

  List<String?> get _initialPhones => [
        widget.phone,
        widget.phone2,
        widget.phone3,
        widget.phone4,
        widget.phone5,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncComposed());
  }

  @override
  void dispose() {
    _name.dispose();
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
    final zones = ref.read(phoneOrderAreasProvider(_address.city)).valueOrNull ??
        const [];
    for (final zone in zones) {
      if (zone.id == id || zone.name == id) return zone;
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

  Future<void> _pickLocation() async {
    final picked = await context.push<PickedLocation>(
      AppRoutes.mapPicker,
      extra: _location,
    );
    if (picked == null || !mounted) return;
    setState(() => _location = picked.point);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final phoneError = _phonesKey.currentState?.validate();
    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }
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
      final slots = _phonesKey.currentState?.fiveSlots() ??
          CustomerPhone.fiveSlots(_initialPhones);
      final zone = _selectedZone;
      final customer =
          await ref.read(phoneOrdersRepositoryProvider).createCustomer(
                fullName: _name.text.trim(),
                phone: slots[0] ?? '',
                address: line,
                zone: zone?.name ?? _address.city,
                fujitsuZoneId: zone?.fujitsuZoneId,
                phone2: slots[1],
                phone3: slots[2],
                phone4: slots[3],
                phone5: slots[4],
                notes: _address.optional(_address.notes),
                branch: _address.optional(_address.branch),
                type: widget.type,
                governorate: _currentGovernorate,
                city: _address.city,
                building: _address.optional(_address.building),
                street: _address.optional(_address.street),
                landmark: _address.optional(_address.landmark),
                floor: _address.optional(_address.floor),
                apartment: _address.optional(_address.apartment),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final location = _location;
    return Dialog(
      key: const Key('customer-address-dialog'),
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
                      TextFormField(
                        key: const Key('address-customer-name'),
                        controller: _name,
                        decoration: InputDecoration(
                            labelText: l10n.phoneOrderCustomerName),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? l10n.phoneOrderNameRequired
                            : null,
                      ),
                      const SizedBox(height: 8),
                      CustomerPhonesEditor(
                        key: _phonesKey,
                        initialPhones: _initialPhones,
                      ),
                      const SizedBox(height: 8),
                      StructuredAddressFields(
                        controllers: _address,
                        onChanged: _syncComposed,
                        showGps: true,
                        locationLabel: location == null
                            ? null
                            : '${location.latitude.toStringAsFixed(5)}, '
                                '${location.longitude.toStringAsFixed(5)}',
                        onPickGps: _saving ? null : _pickLocation,
                        onClearGps: () => setState(() => _location = null),
                      ),
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
