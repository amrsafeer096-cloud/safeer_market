import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/fujitsu_address_composer.dart';
import '../../domain/phone_order.dart';
import '../providers/phone_order_providers.dart';

/// Controllers + dropdown state for the Fujitsu structured address form.
class StructuredAddressControllers {
  StructuredAddressControllers({
    String? building,
    String? floor,
    String? apartment,
    String? street,
    String? landmark,
    String? branch,
    String? notes,
    String? composed,
    String? governorate,
    String? city,
    String? area,
  })  : building = TextEditingController(text: building ?? ''),
        floor = TextEditingController(text: floor ?? ''),
        apartment = TextEditingController(text: apartment ?? ''),
        street = TextEditingController(text: street ?? ''),
        landmark = TextEditingController(text: landmark ?? ''),
        branch = TextEditingController(text: branch ?? 'حي الزهور'),
        notes = TextEditingController(text: notes ?? ''),
        composed = TextEditingController(text: composed ?? ''),
        governorate = governorate ?? 'القاهرة',
        city = city ?? 'مدينة نصر',
        area = area;

  final TextEditingController building;
  final TextEditingController floor;
  final TextEditingController apartment;
  final TextEditingController street;
  final TextEditingController landmark;
  final TextEditingController branch;
  final TextEditingController notes;
  final TextEditingController composed;

  String? governorate;
  String? city;

  /// Selected zone id (`fujitsu_zone_id`) or name fallback.
  String? area;

  /// When true, structured-field edits overwrite [composed].
  bool autoCompose = true;

  void dispose() {
    for (final c in [
      building,
      floor,
      apartment,
      street,
      landmark,
      branch,
      notes,
      composed,
    ]) {
      c.dispose();
    }
  }

  String? optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  String compose({String? zoneName, required String governorateFallback}) {
    return composeFujitsuAddress(
      building: optional(building),
      street: optional(street),
      landmark: optional(landmark),
      floor: optional(floor),
      apartment: optional(apartment),
      zone: zoneName,
      city: city,
      governorate: governorate ?? governorateFallback,
    );
  }

  void refreshComposed({
    String? zoneName,
    required String governorateFallback,
  }) {
    if (!autoCompose) return;
    final line = compose(
      zoneName: zoneName,
      governorateFallback: governorateFallback,
    );
    if (composed.text != line) {
      composed.value = TextEditingValue(
        text: line,
        selection: TextSelection.collapsed(offset: line.length),
      );
    }
  }
}

/// Fujitsu-layout structured fields + live full-address box.
class StructuredAddressFields extends ConsumerWidget {
  const StructuredAddressFields({
    super.key,
    required this.controllers,
    required this.onChanged,
    this.showGps = false,
    this.locationLabel,
    this.onPickGps,
    this.onClearGps,
  });

  final StructuredAddressControllers controllers;
  final VoidCallback onChanged;
  final bool showGps;
  final String? locationLabel;
  final VoidCallback? onPickGps;
  final VoidCallback? onClearGps;

  static const sideBySideMinWidth = 520.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo =
        ref.watch(phoneOrderGeoProvider).valueOrNull ?? ZoneGeo.fallback;
    final governorate = () {
      final chosen = controllers.governorate;
      return chosen != null && geo.governorates.contains(chosen)
          ? chosen
          : geo.governorates.first;
    }();
    final cities = geo.citiesOf(governorate);
    final zones =
        ref.watch(phoneOrderAreasProvider(controllers.city)).valueOrNull ??
            const <PhoneOrderArea>[];
    PhoneOrderArea? selectedZone;
    final areaId = controllers.area;
    if (areaId != null) {
      for (final z in zones) {
        if (z.id == areaId || z.name == areaId) {
          selectedZone = z;
          break;
        }
      }
    }
    final fee = selectedZone?.deliveryFee;

    Widget field(
      Key key,
      TextEditingController controller,
      String label, {
      int maxLines = 1,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: TextFormField(
            key: key,
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(labelText: label),
            onChanged: (_) {
              controllers.autoCompose = true;
              onChanged();
            },
          ),
        );

    final buildingSide = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(const Key('address-building'), controllers.building, 'المبنى'),
        field(const Key('address-floor'), controllers.floor, 'الدور'),
        field(const Key('address-apartment'), controllers.apartment, 'شقة'),
        field(const Key('address-street'), controllers.street, 'الشارع'),
        field(const Key('address-landmark'), controllers.landmark, 'علامة مميزة'),
      ],
    );

    final areaSide = Column(
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
            controllers.governorate = value;
            controllers.city = null;
            controllers.area = null;
            controllers.autoCompose = true;
            onChanged();
          },
        ),
        const SizedBox(height: 4),
        KeyedSubtree(
          key: ValueKey('cities-of-$governorate'),
          child: DropdownButtonFormField<String>(
            key: const Key('address-city'),
            initialValue:
                cities.contains(controllers.city) ? controllers.city : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المدينة'),
            items: [
              for (final city in cities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) {
              controllers.city = value;
              controllers.area = null;
              controllers.autoCompose = true;
              onChanged();
            },
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey('address-area-${controllers.city}'),
          initialValue: zones.any(
                  (z) => z.id == controllers.area || z.name == controllers.area)
              ? controllers.area
              : null,
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
          onChanged: zones.isEmpty
              ? null
              : (value) {
                  controllers.area = value;
                  controllers.autoCompose = true;
                  onChanged();
                },
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
                color: AppColors.success,
              ),
            ),
          ),
        const SizedBox(height: 4),
        field(const Key('address-branch'), controllers.branch, 'أقرب فرع'),
        field(
          const Key('address-notes'),
          controllers.notes,
          'ملاحظات',
          maxLines: 2,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < sideBySideMinWidth - 40) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildingSide,
                  const SizedBox(height: 4),
                  areaSide,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: buildingSide),
                const SizedBox(width: 16),
                Expanded(child: areaSide),
              ],
            );
          },
        ),
        if (showGps) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('address-pick-gps'),
            onPressed: onPickGps,
            icon: Icon(locationLabel == null
                ? Icons.add_location_alt_rounded
                : Icons.edit_location_alt_rounded),
            label: Text(
              locationLabel == null
                  ? 'إضافة موقع العميل (GPS)'
                  : 'تغيير موقع العميل (GPS)',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (locationLabel != null)
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
                      'تم تحديد الموقع: $locationLabel',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إزالة الموقع',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: onClearGps,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('address-composed'),
          controller: controllers.composed,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'العنوان الكامل',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            // Manual tweak — keep until a structured field changes.
            controllers.autoCompose = false;
          },
        ),
      ],
    );
  }
}
