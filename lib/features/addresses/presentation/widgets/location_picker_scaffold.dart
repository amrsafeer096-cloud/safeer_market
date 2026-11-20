import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/store_location.dart';
import '../../../../core/constants/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../checkout/domain/delivery_pricing.dart';
import '../../../subscriptions/presentation/providers/subscription_providers.dart';
import '../../domain/services/location_service.dart';
import '../providers/addresses_providers.dart';
import 'center_pin_map.dart';
import 'place_search_bar.dart';

/// Full-screen map with a fixed center pin. The user drags the map under the
/// pin; confirming reverse-geocodes the center and hands it to [onConfirm].
class LocationPickerScaffold extends ConsumerStatefulWidget {
  const LocationPickerScaffold({
    super.key,
    required this.title,
    required this.onConfirm,
    this.initialCenter,
    this.locateOnOpen = false,
  });

  /// The store, so the map opens over the delivery area.
  static const defaultCenter =
      LatLng(StoreLocation.latitude, StoreLocation.longitude);

  final String title;
  final LatLng? initialCenter;

  /// Quietly jumps to the device location when the screen opens.
  final bool locateOnOpen;
  final Future<void> Function(PickedLocation picked) onConfirm;

  @override
  ConsumerState<LocationPickerScaffold> createState() =>
      _LocationPickerScaffoldState();
}

class _LocationPickerScaffoldState
    extends ConsumerState<LocationPickerScaffold> {
  late LatLng _center =
      widget.initialCenter ?? LocationPickerScaffold.defaultCenter;
  CenterPinMapController? _map;
  bool _locating = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (widget.locateOnOpen && widget.initialCenter == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _locateMe(quiet: true);
      });
    }
  }

  Future<void> _locateMe({bool quiet = false}) async {
    final service = ref.read(locationServiceProvider);
    setState(() => _locating = true);
    try {
      final position = await service.currentPosition();
      if (!mounted) return;
      setState(() => _center = position);
      await _map?.moveTo(position, zoom: 17);
    } on LocationFailure catch (failure) {
      if (!mounted || quiet) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.secondary,
            action: failure.isFixableInSettings
                ? SnackBarAction(
                    label: AppLocalizations.of(context)!.settings,
                    textColor: Colors.white,
                    onPressed: () => service.openSettingsFor(failure),
                  )
                : null,
          ),
        );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// A place picked in the search bar: the map flies there, putting it under
  /// the pin.
  Future<void> _showPlace(LatLng point) async {
    setState(() => _center = point);
    await _map?.moveTo(point, zoom: 17);
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    final center = _center;
    setState(() => _confirming = true);
    PickedLocation picked;
    try {
      picked = await ref.read(locationServiceProvider).reverseGeocode(center);
    } on LocationFailure {
      picked = PickedLocation(point: center);
    }
    if (!mounted) return;
    // The spinner covers geocoding only; onConfirm may keep a sheet open.
    setState(() => _confirming = false);
    await widget.onConfirm(picked);
  }

  @override
  Widget build(BuildContext context) {
    final buildMap = ref.watch(centerPinMapBuilderProvider);
    final busy = _locating || _confirming;
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(widget.title)),
        floatingActionButton: FloatingActionButton(
          tooltip: l10n.mapMyCurrentLocation,
          backgroundColor: palette.card,
          foregroundColor: palette.accent,
          onPressed: busy ? null : _locateMe,
          child: _locating
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.my_location_rounded),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _confirming ? null : _confirm,
              icon: _confirming
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(l10n.mapConfirmLocation),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor:
                    AppColors.secondary.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: buildMap(
                CenterPinMapConfig(
                  initialCenter: _center,
                  initialZoom: widget.initialCenter == null ? 14 : 17,
                  onCenterChanged: (center) => setState(() => _center = center),
                  onCreated: (controller) => _map = controller,
                ),
              ),
            ),
            const IgnorePointer(child: Center(child: _CenterPin())),
            PositionedDirectional(
              top: 12,
              start: 12,
              end: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlaceSearchBar(near: _center, onPicked: _showPlace),
                  const SizedBox(height: 8),
                  _MapHint(center: _center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  static const _size = 52.0;

  @override
  Widget build(BuildContext context) {
    // The glyph's tip sits ~0.42 of its height below the icon's center, so
    // lift it until the tip lands exactly on the map center.
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 10,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -_size * 0.42),
            child: const Icon(
              Icons.location_on_rounded,
              key: Key('map-center-pin'),
              size: _size,
              color: AppColors.secondary,
              shadows: [
                Shadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Instructions plus a live delivery quote for the point under the pin.
class _MapHint extends ConsumerWidget {
  const _MapHint({required this.center});

  final LatLng center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = DeliveryPricing.quote(
      latitude: center.latitude,
      longitude: center.longitude,
      freeDelivery: ref.watch(hasPaidPlanProvider),
    );
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final (text, color) = switch (quote) {
      DeliveryAvailable(:final distanceKm, :final fee) => (
          l10n.mapDeliveryQuote(
            DeliveryPricing.formatDistance(distanceKm),
            AppCurrency.of(fee),
          ),
          AppColors.success,
        ),
      DeliveryOutOfRange(:final distanceKm) => (
          l10n.mapOutOfDeliveryRange(
            DeliveryPricing.formatDistance(distanceKm),
          ),
          AppColors.secondary,
        ),
      DeliveryLocationMissing() => ('', palette.muted),
    };

    return Material(
      color: palette.card,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mapPinHint,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (text.isNotEmpty)
                    Text(
                      text,
                      key: const Key('map-delivery-quote'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
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
