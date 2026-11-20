import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/address.dart';
import '../providers/addresses_providers.dart';
import '../widgets/address_card.dart';
import 'add_address_screen.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(title: Text(l10n.savedAddresses)),
        bottomNavigationBar: signedIn
            ? SafeArea(
                minimum: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _addAddress(context),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(l10n.addNewAddress),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: !signedIn
            ? _AddressesMessage(
                message: l10n.signInToManageAddresses,
                actionLabel: l10n.signIn,
                onAction: () => context.push(AppRoutes.auth),
              )
            : RefreshIndicator(
                color: palette.accent,
                onRefresh: () => ref.refresh(addressesProvider.future),
                child: addressesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _AddressesMessage(
                    message: l10n.addressesLoadFailed,
                    actionLabel: l10n.retry,
                    onAction: () => ref.invalidate(addressesProvider),
                  ),
                  data: (addresses) => addresses.isEmpty
                      ? _AddressesMessage(
                          message: l10n.addressesEmptyTitle,
                          hint: l10n.addressesEmptyHint,
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: addresses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return AddressCard(
                              address: address,
                              trailing: IconButton(
                                tooltip: l10n.addressDeleteTitle,
                                onPressed: () =>
                                    _confirmDelete(context, ref, address),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.secondary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
      ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final address = await openAddAddress(context);
    if (address == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(l10n.addressSaved(address.displayTitle(l10n))),
        ),
      );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.addressDeleteTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(l10n.addressDeleteConfirm(address.displayTitle(l10n))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(addressesControllerProvider).delete(address);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(l10n.addressDeleteFailed),
        ),
      );
    }
  }
}

class _AddressesMessage extends StatelessWidget {
  const _AddressesMessage({
    required this.message,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (hint != null)
                    Text(
                      hint!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.muted,
                      ),
                    ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
