import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/address.dart';

IconData addressIcon(String title) => switch (title) {
      AddressDraft.homeTitle => Icons.home_rounded,
      AddressDraft.workTitle => Icons.work_rounded,
      _ => Icons.location_on_rounded,
    };

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final Address address;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final landmark = address.landmark;
    final palette = context.palette;

    return Material(
      color: selected ? palette.accent.withValues(alpha: 0.06) : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? palette.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  addressIcon(address.title),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.displayTitle(l10n),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.streetLine,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                    if (address.area.isNotEmpty)
                      Text(
                        address.area,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.muted,
                        ),
                      ),
                    if (landmark != null)
                      Text(
                        l10n.addressLandmarkLine(landmark),
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing case final trailing?) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
