import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/location_picker_scaffold.dart';

/// Re-pins a saved address; pops with a [PickedLocation].
class MapPickerScreen extends StatelessWidget {
  const MapPickerScreen({super.key, this.initialCenter});

  final LatLng? initialCenter;

  static const defaultCenter = LocationPickerScaffold.defaultCenter;

  @override
  Widget build(BuildContext context) {
    return LocationPickerScaffold(
      title: AppLocalizations.of(context)!.mapSetDeliveryLocation,
      initialCenter: initialCenter,
      onConfirm: (picked) async => context.pop(picked),
    );
  }
}
