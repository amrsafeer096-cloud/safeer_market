import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../providers/phone_order_providers.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';

/// «المناطق»: delivery zones (governorate → city → area + delivery fee).
/// The «Add address» dropdowns read these rows, and picking a zone there
/// sets the order's delivery fee.
class AdminZonesSection extends ConsumerWidget {
  const AdminZonesSection({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminZonesProvider);
    ref.invalidate(phoneOrderGeoProvider);
    ref.invalidate(phoneOrderAreasProvider);
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    DeliveryZone? zone,
    List<DeliveryZone> all,
  ) async {
    final result = await showDialog<_ZoneInput>(
      context: context,
      builder: (_) => _ZoneDialog(existing: zone, zones: all),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(systemAdminServiceProvider).saveZone(
            fujitsuZoneId: result.fujitsuZoneId,
            isNew: zone == null,
            governorate: result.governorate,
            city: result.city,
            name: result.name,
            deliveryFee: result.fee,
            isActive: result.active,
          );
      _refresh(ref);
      if (context.mounted) showAdminSnack(context, 'تم حفظ المنطقة');
    } catch (error) {
      if (context.mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, DeliveryZone zone) async {
    final ok = await confirmAdminAction(
      context,
      title: 'حذف المنطقة',
      message: 'سيتم حذف منطقة «${zone.name}». هل أنت متأكد؟',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(systemAdminServiceProvider).deleteZone(zone.fujitsuZoneId);
      _refresh(ref);
      if (context.mounted) showAdminSnack(context, 'تم حذف المنطقة');
    } catch (error) {
      if (context.mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, DeliveryZone zone) async {
    try {
      await ref.read(systemAdminServiceProvider).saveZone(
            fujitsuZoneId: zone.fujitsuZoneId,
            isNew: false,
            governorate: zone.governorate,
            city: zone.city,
            name: zone.name,
            deliveryFee: zone.deliveryFee,
            isActive: !zone.isActive,
          );
      _refresh(ref);
    } catch (error) {
      if (context.mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final canManage = ref.watch(adminCanProvider(AdminPermission.manageZones));
    final zones = ref.watch(adminZonesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            title: 'المناطق',
            actions: [
              if (canManage)
                FilledButton.icon(
                  key: const Key('zones-add'),
                  onPressed: () => _save(
                      context, ref, null, zones.valueOrNull ?? const []),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('إضافة منطقة'),
                ),
            ],
          ),
          Expanded(
            child: zones.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AdminMessage(describeAdminError(error),
                  icon: Icons.error_outline),
              data: (all) {
                if (all.isEmpty) {
                  return const AdminMessage('لا توجد مناطق بعد',
                      icon: Icons.map_outlined);
                }
                // governorate → city → zones, in the order they first appear.
                final tree = <String, Map<String, List<DeliveryZone>>>{};
                for (final zone in all) {
                  tree
                      .putIfAbsent(zone.governorate, () => {})
                      .putIfAbsent(zone.city, () => [])
                      .add(zone);
                }
                return ListView(
                  key: const Key('zones-list'),
                  children: [
                    for (final governorate in tree.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Text(governorate.key,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      for (final city in governorate.value.entries)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: palette.card,
                            border: Border.all(color: palette.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 12, 14, 4),
                                child: Text(city.key,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: palette.accent)),
                              ),
                              for (final zone in city.value)
                                ListTile(
                                  key: Key('zone-${zone.fujitsuZoneId}'),
                                  dense: true,
                                  title: Text(zone.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color:
                                            zone.isActive ? null : palette.muted,
                                      )),
                                  subtitle: Text(
                                    '${zone.deliveryFee == null ? 'بدون سعر توصيل' : 'التوصيل: ${AppCurrency.of(zone.deliveryFee!)}'}'
                                    ' • Fujitsu: ${zone.fujitsuZoneId}',
                                  ),
                                  trailing: canManage
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch(
                                              key: Key('zone-active-${zone.fujitsuZoneId}'),
                                              value: zone.isActive,
                                              onChanged: (_) =>
                                                  _toggle(context, ref, zone),
                                            ),
                                            IconButton(
                                              key: Key('zone-edit-${zone.fujitsuZoneId}'),
                                              tooltip: 'تعديل',
                                              icon: const Icon(
                                                  Icons.edit_outlined),
                                              onPressed: () =>
                                                  _save(context, ref, zone, all),
                                            ),
                                            IconButton(
                                              key: Key('zone-delete-${zone.fujitsuZoneId}'),
                                              tooltip: 'حذف',
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _delete(context, ref, zone),
                                            ),
                                          ],
                                        )
                                      : (zone.isActive
                                          ? null
                                          : const Text('متوقفة')),
                                ),
                              const SizedBox(height: 4),
                            ],
                          ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneInput {
  const _ZoneInput({
    required this.fujitsuZoneId,
    required this.governorate,
    required this.city,
    required this.name,
    required this.fee,
    required this.active,
  });

  final String fujitsuZoneId;
  final String governorate;
  final String city;
  final String name;
  final double? fee;
  final bool active;
}

class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({this.existing, required this.zones});

  final DeliveryZone? existing;
  final List<DeliveryZone> zones;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final _form = GlobalKey<FormState>();
  late final _zoneId =
      TextEditingController(text: widget.existing?.fujitsuZoneId ?? '');
  late final _governorate =
      TextEditingController(text: widget.existing?.governorate ?? '');
  late final _city = TextEditingController(text: widget.existing?.city ?? '');
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _fee = TextEditingController(
    text: widget.existing?.deliveryFee == null
        ? ''
        : '${widget.existing!.deliveryFee}'.replaceFirst(RegExp(r'\.0$'), ''),
  );
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _zoneId.dispose();
    _governorate.dispose();
    _city.dispose();
    _name.dispose();
    _fee.dispose();
    super.dispose();
  }

  Iterable<String> get _governorates =>
      widget.zones.map((z) => z.governorate).toSet();

  Iterable<String> get _cities => widget.zones
      .where((z) => z.governorate == _governorate.text.trim())
      .map((z) => z.city)
      .toSet();

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final fee = double.tryParse(_fee.text.trim().replaceAll(',', '.'));
    Navigator.pop(
      context,
      _ZoneInput(
        fujitsuZoneId: _zoneId.text.trim(),
        governorate: _governorate.text.trim(),
        city: _city.text.trim(),
        name: _name.text.trim(),
        fee: fee,
        active: _active,
      ),
    );
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'مطلوب' : null;

  Widget _suggestions(
      Iterable<String> values, TextEditingController controller) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: 6,
        children: [
          for (final value in values)
            ActionChip(
              label: Text(value),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => controller.text = value),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'إضافة منطقة' : 'تعديل المنطقة',
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('zone-fujitsu-id'),
                  controller: _zoneId,
                  // The Fujitsu id is the zone's key: fixed once saved.
                  readOnly: widget.existing != null,
                  enabled: widget.existing == null,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم المنطقة في Fujitsu',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'مطلوب';
                    final taken = widget.existing == null &&
                        widget.zones.any((z) => z.fujitsuZoneId == text);
                    return taken ? 'الرقم مستخدم لمنطقة أخرى' : null;
                  },
                ),
                TextFormField(
                  key: const Key('zone-governorate'),
                  controller: _governorate,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  validator: _required,
                  onChanged: (_) => setState(() {}),
                ),
                _suggestions(_governorates, _governorate),
                TextFormField(
                  key: const Key('zone-city'),
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                  validator: _required,
                ),
                _suggestions(_cities, _city),
                TextFormField(
                  key: const Key('zone-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'المنطقة'),
                  validator: _required,
                ),
                TextFormField(
                  key: const Key('zone-fee'),
                  controller: _fee,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'سعر التوصيل'),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final fee = double.tryParse(text.replaceAll(',', '.'));
                    return fee == null || fee < 0 ? 'سعر غير صالح' : null;
                  },
                ),
                SwitchListTile(
                  key: const Key('zone-active'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('المنطقة مفعّلة'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('zone-save'),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
