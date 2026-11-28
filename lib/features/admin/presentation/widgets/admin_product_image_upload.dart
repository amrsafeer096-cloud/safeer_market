import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/repositories/supabase_product_image_repository.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../home/domain/entities/product.dart';

/// Same camera / gallery → Supabase Storage flow as the customer product page.
Future<void> showAdminProductImagePicker(
  BuildContext context, {
  required Product product,
  required ValueChanged<String> onUploaded,
}) {
  final l10n = AppLocalizations.of(context)!;
  final palette = context.palette;
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.updateProductImage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: palette.accent),
              title: Text(l10n.takePhotoWithCamera),
              onTap: () {
                Navigator.pop(sheetContext);
                pickAndUploadAdminProductImage(
                  context,
                  product: product,
                  source: ImageSource.camera,
                  onUploaded: onUploaded,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: palette.accent),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                pickAndUploadAdminProductImage(
                  context,
                  product: product,
                  source: ImageSource.gallery,
                  onUploaded: onUploaded,
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> pickAndUploadAdminProductImage(
  BuildContext context, {
  required Product product,
  required ImageSource source,
  required ValueChanged<String> onUploaded,
}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);
  if (pickedFile == null) return null;
  if (!context.mounted) return null;

  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(seconds: 30),
      content: Row(
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l10n.updateProductImage),
        ],
      ),
    ));

  try {
    final bytes = await pickedFile.readAsBytes();
    final imageUrl =
        await container.read(productImageRepositoryProvider).replaceImage(
              product: product,
              bytes: bytes,
              fileExtension: pickedFile.name.split('.').last,
            );
    refreshAfterImageChange(container, product.id, imageUrl);
    onUploaded(imageUrl);
    if (!context.mounted) return imageUrl;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.productImageUpdated),
        backgroundColor: AppColors.success,
      ));
    return imageUrl;
  } catch (error) {
    if (!context.mounted) return null;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error is ProductImageFailure
            ? error.message
            : l10n.productImageUploadFailed('$error')),
        backgroundColor: Colors.red,
      ));
    return null;
  }
}

/// Compact camera FAB overlaid on a product thumbnail (admins only).
class AdminProductCameraButton extends StatelessWidget {
  const AdminProductCameraButton({
    super.key,
    required this.onPressed,
    this.size = 32,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(Icons.camera_alt, size: size * 0.5, color: palette.accent),
        ),
      ),
    );
  }
}
