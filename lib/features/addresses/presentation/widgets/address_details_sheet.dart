import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../domain/entities/address.dart';
import '../../domain/services/location_service.dart';
import '../providers/addresses_providers.dart';

/// Collects the text details for a pinned location and saves the address
/// with its exact coordinates. Resolves to the saved address, or null.
Future<Address?> showAddressDetailsSheet(
  BuildContext context,
  PickedLocation picked,
) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.card,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => AddressDetailsSheet(picked: picked),
  );
}

class AddressDetailsSheet extends ConsumerStatefulWidget {
  const AddressDetailsSheet({super.key, required this.picked});

  static const titleSuggestions = [
    AddressDraft.homeTitle,
    AddressDraft.workTitle,
    AddressDraft.otherTitle,
  ];

  final PickedLocation picked;

  @override
  ConsumerState<AddressDetailsSheet> createState() =>
      _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends ConsumerState<AddressDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  bool _titleInitialized = false;
  late final _area = TextEditingController(text: widget.picked.area);
  late final _street = TextEditingController(text: widget.picked.street);
  final _building = TextEditingController();
  final _floorApt = TextEditingController();
  final _landmark = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_titleInitialized) {
      _titleInitialized = true;
      _title.text =
          _suggestionLabel(AddressDetailsSheet.titleSuggestions.first);
    }
  }

  String _suggestionLabel(String suggestion) => AddressDraft.localizedTitle(
        suggestion,
        AppLocalizations.of(context)!,
      );

  /// Saves a picked suggestion under its stored (Arabic) value.
  String _storedTitle(String text) =>
      AddressDetailsSheet.titleSuggestions
          .where((suggestion) => _suggestionLabel(suggestion) == text)
          .firstOrNull ??
      text;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _area,
      _street,
      _building,
      _floorApt,
      _landmark,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final point = widget.picked.point;
      final address = await ref.read(addressesControllerProvider).add(
            AddressDraft(
              title: _storedTitle(_title.text.trim()),
              area: _area.text.trim(),
              street: _street.text.trim(),
              building: _building.text.trim(),
              floorApt: optional(_floorApt),
              landmark: optional(_landmark),
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          );
      if (mounted) Navigator.of(context).pop(address);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.add_location_alt_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.addressDetailsTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: Text(l10n.editLocation),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PinnedLocationNote(picked: widget.picked),
              const SizedBox(height: 14),
              ValueListenableBuilder(
                valueListenable: _title,
                builder: (context, value, child) => Wrap(
                  spacing: 8,
                  children: [
                    for (final suggestion in AddressDetailsSheet
                        .titleSuggestions
                        .map(_suggestionLabel))
                      ChoiceChip(
                        label: Text(suggestion),
                        selected: value.text.trim() == suggestion,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: value.text.trim() == suggestion
                              ? Colors.white
                              : palette.accent,
                        ),
                        onSelected: (_) => _title.text = suggestion,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _field(
                _title,
                l10n.addressTitleLabel,
                Icons.bookmark_border_rounded,
                hint: l10n.addressTitleHint,
                required: true,
              ),
              _field(
                _area,
                l10n.addressAreaLabel,
                Icons.map_outlined,
                hint: l10n.addressAreaHint,
                required: true,
              ),
              _field(
                _street,
                l10n.addressStreetLabel,
                Icons.signpost_outlined,
                required: true,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      _building,
                      l10n.addressBuildingNumberLabel,
                      Icons.apartment_rounded,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _floorApt,
                      l10n.addressFloorAptLabel,
                      Icons.stairs_outlined,
                    ),
                  ),
                ],
              ),
              _field(
                _landmark,
                l10n.addressLandmarkLabel,
                Icons.place_outlined,
                hint: l10n.addressLandmarkHint,
                done: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.addressSaveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool required = false,
    bool done = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textInputAction: done ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: done ? (_) => _save() : null,
        decoration: InputDecoration(
          labelText: required ? label : l10n.addressOptionalFieldLabel(label),
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
        validator: required
            ? (value) =>
                (value ?? '').trim().isEmpty ? l10n.addressFieldRequired : null
            : null,
      ),
    );
  }
}

class _PinnedLocationNote extends ConsumerWidget {
  const _PinnedLocationNote({required this.picked});

  final PickedLocation picked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = DeliveryPricing.quote(
      latitude: picked.point.latitude,
      longitude: picked.point.longitude,
      freeDelivery: ref.watch(hasPaidPlanProvider),
    );
    final l10n = AppLocalizations.of(context)!;
    final addressLine = picked.hasAddress
        ? l10n.addressReviewAndComplete
        : l10n.mapAddressReadFailedFillManually;
    final (text, ok) = switch (quote) {
      DeliveryAvailable(:final distanceKm, :final fee) => (
          '${l10n.mapDeliveryQuote(
            DeliveryPricing.formatDistance(distanceKm),
            AppCurrency.of(fee),
          )}\n$addressLine',
          picked.hasAddress,
        ),
      DeliveryOutOfRange(:final distanceKm) => (
          l10n.addressOutOfDeliveryRange(
            DeliveryPricing.formatDistance(distanceKm),
            DeliveryPricing.formatDistance(DeliveryPricing.maxDistanceKm),
          ),
          false,
        ),
      DeliveryLocationMissing() => (addressLine, false),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (ok ? AppColors.success : AppColors.secondary)
            .withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.where_to_vote_rounded,
            color: ok ? AppColors.success : AppColors.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ok ? AppColors.success : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
