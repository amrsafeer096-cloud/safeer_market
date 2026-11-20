import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/address.dart';
import '../widgets/address_details_sheet.dart';
import '../widgets/location_picker_scaffold.dart';

/// Opens the add-address flow; resolves to the saved address, or null.
Future<Address?> openAddAddress(BuildContext context) =>
    context.push<Address>(AppRoutes.addAddress);

/// Step 1: pin the exact spot on the map. Step 2: a sheet for the building,
/// floor and so on. Pops with the saved [Address].
class AddAddressScreen extends StatelessWidget {
  const AddAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationPickerScaffold(
      title: AppLocalizations.of(context)!.addNewAddress,
      locateOnOpen: true,
      onConfirm: (picked) async {
        final address = await showAddressDetailsSheet(context, picked);
        if (address != null && context.mounted) context.pop(address);
      },
    );
  }
}
