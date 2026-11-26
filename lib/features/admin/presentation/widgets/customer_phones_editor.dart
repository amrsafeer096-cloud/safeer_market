import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../auth/domain/customer_phone.dart';

/// Dynamic customer phones: 2 visible by default, expand to 5 with `+`.
///
/// Each row has a country-code chip + local input. Typing `+` / `00…`
/// auto-detects the country and strips the duplicated prefix.
class CustomerPhonesEditor extends StatefulWidget {
  const CustomerPhonesEditor({
    super.key,
    this.initialPhones = const [],
    this.enabled = true,
    this.maxPhones = 5,
    this.minVisible = 2,
  });

  final List<String?> initialPhones;
  final bool enabled;
  final int maxPhones;
  final int minVisible;

  @override
  State<CustomerPhonesEditor> createState() => CustomerPhonesEditorState();
}

class CustomerPhonesEditorState extends State<CustomerPhonesEditor> {
  late List<_PhoneRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildInitialRows(widget.initialPhones);
  }

  @override
  void didUpdateWidget(covariant CustomerPhonesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when parent pushes freshly fetched customer phones.
    if (!_samePhones(oldWidget.initialPhones, widget.initialPhones)) {
      for (final r in _rows) {
        r.dispose();
      }
      _rows = _buildInitialRows(widget.initialPhones);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  bool _samePhones(List<String?> a, List<String?> b) {
    final aa = CustomerPhone.uniqueStorage(a);
    final bb = CustomerPhone.uniqueStorage(b);
    if (aa.length != bb.length) return false;
    for (var i = 0; i < aa.length; i++) {
      if (CustomerPhone.compareKey(aa[i]) != CustomerPhone.compareKey(bb[i])) {
        return false;
      }
    }
    return true;
  }

  List<_PhoneRow> _buildInitialRows(List<String?> phones) {
    final stored = CustomerPhone.uniqueStorage(phones);
    final count = stored.isEmpty
        ? widget.minVisible
        : stored.length.clamp(widget.minVisible, widget.maxPhones);
    return [
      for (var i = 0; i < count; i++)
        _PhoneRow.fromStorage(i < stored.length ? stored[i] : null),
    ];
  }

  /// Deduped storage values (primary first). Empty slots omitted.
  List<String> storagePhones() {
    final raw = <String?>[
      for (final r in _rows) r.toStorage(),
    ];
    return CustomerPhone.uniqueStorage(raw);
  }

  /// Exactly 5 slots for RPC payloads.
  List<String?> fiveSlots() => CustomerPhone.fiveSlots(storagePhones());

  String? validate() {
    if (_rows.isEmpty) return 'أدخل رقم الهاتف الأساسي';
    final primary = _rows.first;
    if (primary.controller.text.trim().isEmpty) {
      return 'أدخل رقم الهاتف الأساسي';
    }
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      final text = r.controller.text.trim();
      if (text.isEmpty) {
        if (i == 0) return 'أدخل رقم الهاتف الأساسي';
        continue;
      }
      if (!CustomerPhone.isValid(
          country: r.country, nationalRaw: r.controller.text)) {
        return 'رقم غير صالح';
      }
    }
    final keys = <String>{};
    for (final r in _rows) {
      final s = r.toStorage();
      if (s == null || s.isEmpty) continue;
      final key = CustomerPhone.compareKey(s);
      if (!keys.add(key)) {
        return 'لا تكرر نفس رقم الهاتف';
      }
    }
    return null;
  }

  void _addRow() {
    if (_rows.length >= widget.maxPhones) return;
    setState(() => _rows.add(_PhoneRow.empty()));
  }

  void _removeRow(int index) {
    if (index < widget.minVisible || _rows.length <= widget.minVisible) return;
    setState(() {
      _rows.removeAt(index).dispose();
    });
  }

  void _onChanged(_PhoneRow row) {
    final detected = CustomerPhone.detectWhileTyping(
      current: row.country,
      input: row.controller.text,
    );
    if (detected.country.dialCode != row.country.dialCode ||
        detected.national != row.controller.text) {
      setState(() {
        row.country = detected.country;
        if (detected.national != row.controller.text) {
          final c = row.controller;
          c.value = TextEditingValue(
            text: detected.national,
            selection:
                TextSelection.collapsed(offset: detected.national.length),
          );
        }
      });
    }
  }

  String _labelFor(int index) {
    if (index == 0) return 'الرقم الأساسي';
    return 'رقم إضافي ${index + 1}';
  }

  Future<void> _pickCountry(_PhoneRow row) async {
    if (!widget.enabled) return;
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CountryPickerSheet(current: row.country),
    );
    if (selected == null || !mounted) return;
    setState(() => row.country = selected);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildRow(i, palette),
        ],
        if (widget.enabled && _rows.length < widget.maxPhones) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('customer-phones-add'),
              onPressed: _addRow,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ إضافة رقم آخر'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(int index, AppPalette palette) {
    final row = _rows[index];
    final canRemove = widget.enabled && index >= widget.minVisible;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: Key('customer-phone-country-$index'),
          onTap: widget.enabled ? () => _pickCountry(row) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(8),
              color: palette.surface,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(row.country.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  row.country.dialLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded,
                    size: 18, color: palette.muted),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            key: Key('customer-phone-field-$index'),
            controller: row.controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: (_) => _onChanged(row),
            decoration: InputDecoration(
              labelText: _labelFor(index),
              hintText: row.country.dialCode == '20'
                  ? 'موبايل أو أرضي'
                  : 'رقم الهاتف',
            ),
            validator: (value) {
              final raw = (value ?? '').trim();
              if (raw.isEmpty) {
                return index == 0 ? 'مطلوب' : null;
              }
              if (!CustomerPhone.isValid(
                  country: row.country, nationalRaw: raw)) {
                return 'رقم غير صالح';
              }
              return null;
            },
          ),
        ),
        if (canRemove)
          IconButton(
            key: Key('customer-phone-remove-$index'),
            tooltip: 'حذف الرقم',
            onPressed: () => _removeRow(index),
            icon: Icon(Icons.close_rounded, color: palette.muted),
          ),
      ],
    );
  }
}

class _PhoneRow {
  _PhoneRow({required this.country, required String national})
      : controller = TextEditingController(text: national);

  factory _PhoneRow.empty() =>
      _PhoneRow(country: CustomerPhone.egypt, national: '');

  factory _PhoneRow.fromStorage(String? stored) {
    final parsed = CustomerPhone.parse(stored);
    return _PhoneRow(country: parsed.country, national: parsed.national);
  }

  PhoneCountry country;
  final TextEditingController controller;

  String? toStorage() {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = CustomerPhone.toStorage(country, text);
    return value.isEmpty ? null : value;
  }

  void dispose() => controller.dispose();
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.current});

  final PhoneCountry current;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final filtered = CustomerPhone.countries.where((c) {
      if (q.isEmpty) return true;
      return c.name.contains(q) ||
          c.dialCode.contains(q) ||
          c.dialLabel.contains(q) ||
          c.iso2.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'ابحث بالدولة أو كود الاتصال…',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final selected = c.dialCode == widget.current.dialCode &&
                      c.iso2 == widget.current.iso2;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(c.name),
                    subtitle: Text(c.dialLabel, textDirection: TextDirection.ltr),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green)
                        : null,
                    selected: selected,
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
