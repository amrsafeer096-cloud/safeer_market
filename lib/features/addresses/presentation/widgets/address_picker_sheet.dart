import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/addresses_providers.dart';
import '../screens/add_address_screen.dart';
import 'address_card.dart';

/// Lets the user choose (or add) the delivery address for checkout.
Future<void> showAddressPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.surface,
    constraints: const BoxConstraints(maxWidth: MobileFrame.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const AddressPickerSheet(),
  );
}

class AddressPickerSheet extends ConsumerWidget {
  const AddressPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final selectedId = ref.watch(selectedAddressIdProvider);
    final addresses = addressesAsync.valueOrNull ?? const [];
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    void select(String id) {
      ref.read(selectedAddressIdProvider.notifier).state = id;
      Navigator.of(context).pop();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addressPickerTitle,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.addresses);
                  },
                  child: Text(l10n.manageAddresses),
                ),
              ],
            ),
          ),
          if (addressesAsync.isLoading && addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                l10n.addressPickerEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: addresses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  final selected = address.id == selectedId;
                  return AddressCard(
                    address: address,
                    selected: selected,
                    onTap: () => select(address.id),
                    trailing: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? palette.accent : palette.muted,
                    ),
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final address = await openAddAddress(context);
                if (address != null && context.mounted) select(address.id);
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addNewAddress),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
