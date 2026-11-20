import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../checkout/domain/instapay_details.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';
import '../../domain/subscription.dart';
import '../providers/subscription_providers.dart';
import 'subscription_success_screen.dart';

/// InstaPay + mandatory receipt upload for a Pro/Prime subscription upgrade.
class SubscriptionInstaPayScreen extends ConsumerStatefulWidget {
  const SubscriptionInstaPayScreen({super.key, required this.tier});

  final PaidTier tier;

  @override
  ConsumerState<SubscriptionInstaPayScreen> createState() =>
      _SubscriptionInstaPayScreenState();
}

class _SubscriptionInstaPayScreenState
    extends ConsumerState<SubscriptionInstaPayScreen> {
  InstaPayReceiptDraft? _receipt;
  var _submitting = false;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openInstaPay() async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(
      const ClipboardData(text: InstaPayDetails.ipa),
    );
    final ok = await launchUrl(
      Uri.parse(InstaPayDetails.deepLink),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      _toast(l10n.paymentPageOpenFailed);
    }
  }

  Future<void> _pickReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhotoWithCamera),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseFromGallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return;
      final name = picked.name.trim().isEmpty
          ? 'instapay_receipt.jpg'
          : picked.name.trim();
      final lower = name.toLowerCase();
      final contentType = switch (null) {
        _ when lower.endsWith('.png') => 'image/png',
        _ when lower.endsWith('.webp') => 'image/webp',
        _ when lower.endsWith('.gif') => 'image/gif',
        _ when lower.endsWith('.heic') => 'image/heic',
        _ => 'image/jpeg',
      };
      setState(() {
        _receipt = InstaPayReceiptDraft(
          bytes: Uint8List.fromList(bytes),
          fileName: name,
          contentType: contentType,
        );
      });
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.cameraOpenFailed);
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final receipt = _receipt;
    if (receipt == null) {
      _toast(l10n.instaPayReceiptRequired);
      return;
    }
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      _toast(l10n.paywallSignInToSubscribe);
      return;
    }

    setState(() => _submitting = true);
    try {
      final service = ref.read(paymobServiceProvider);
      final url = await service.uploadSubscriptionReceipt(
        userId: userId,
        bytes: receipt.bytes,
        fileName: receipt.fileName,
        contentType: receipt.contentType,
      );
      await service.submitInstaPaySubscription(
        tier: widget.tier,
        receiptUrl: url,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const SubscriptionSuccessScreen(
            pendingVerification: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Subscription InstaPay submit failed: $error');
      if (mounted) _toast('$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final receipt = _receipt;
    final canConfirm = receipt != null && !_submitting;
    final planName = switch (widget.tier) {
      PaidTier.vip => l10n.paywallProTitle,
      PaidTier.prime => l10n.paywallPrimeTitle,
    };

    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.card,
        elevation: 0,
        title: Text(
          l10n.paymentMethodInstaPayLabel,
          style: TextStyle(
            color: palette.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            planName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: palette.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.instaPayConfirmHint,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _SubscriptionInstaPayCard(
            receipt: receipt,
            onOpenApp: _openInstaPay,
            onPick: _pickReceipt,
            onClear: () => setState(() => _receipt = null),
            onReplace: _pickReceipt,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              key: const Key('subscription-instapay-confirm'),
              onPressed: canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      l10n.subscriptionConfirmInstaPay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionInstaPayCard extends StatelessWidget {
  const _SubscriptionInstaPayCard({
    required this.receipt,
    required this.onOpenApp,
    required this.onPick,
    required this.onClear,
    required this.onReplace,
  });

  final InstaPayReceiptDraft? receipt;
  final VoidCallback onOpenApp;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF5A2D82).withValues(alpha: 0.25),
        ),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF5A2D82).withValues(alpha: 0.06),
            const Color(0xFFF37021).withValues(alpha: 0.05),
            palette.card,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Image.asset(
              InstaPayDetails.logoAsset,
              height: 32,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onOpenApp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A2D82),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(
                l10n.instaPayOpenApp,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.instaPayReceiptTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: palette.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.instaPayReceiptHint,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (receipt == null)
            _ReceiptPicker(onPick: onPick)
          else
            _ReceiptPreview(
              bytes: receipt!.bytes,
              onClear: onClear,
              onReplace: onReplace,
            ),
        ],
      ),
    );
  }
}

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    const accent = Color(0xFF5A2D82);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: accent.withValues(alpha: 0.45),
            radius: 14,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: accent, size: 28),
                const SizedBox(height: 8),
                Text(
                  l10n.instaPayReceiptPick,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({
    required this.bytes,
    required this.onClear,
    required this.onReplace,
  });

  final Uint8List bytes;
  final VoidCallback onClear;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Stack(
      children: [
        GestureDetector(
          onTap: onReplace,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 8,
          end: 8,
          child: Material(
            color: palette.card.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
