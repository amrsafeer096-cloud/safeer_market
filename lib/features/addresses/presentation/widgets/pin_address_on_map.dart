import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/address.dart';
import '../../domain/services/location_service.dart';
import '../providers/addresses_providers.dart';

/// Opens the map for a saved address and stores the confirmed pin.
Future<void> pinAddressOnMap(
  BuildContext context,
  WidgetRef ref,
  Address address,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final picked = await context.push<PickedLocation>(
    AppRoutes.mapPicker,
    extra: address.hasLocation
        ? LatLng(address.latitude!, address.longitude!)
        : null,
  );
  if (picked == null) return;

  try {
    await ref.read(addressesControllerProvider).setLocation(
          address,
          latitude: picked.point.latitude,
          longitude: picked.point.longitude,
        );
  } catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(error.toString()),
        ),
      );
  }
}
