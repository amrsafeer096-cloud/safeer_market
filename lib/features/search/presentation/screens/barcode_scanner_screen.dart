import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// In-app barcode camera. Expects camera permission to already be granted
/// before this route is pushed (request it in [barcodeScannerProvider]).
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  String? _initError;
  var _handled = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.qrCode,
        ],
      );
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e, st) {
      debugPrint('Barcode camera init failed: $e\n$st');
      if (mounted) {
        setState(() => _initError = e.toString());
      }
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      _handled = true;
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.vibrate();
      if (mounted) Navigator.of(context).pop(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.scanBarcode),
        actions: [
          if (controller != null)
            IconButton(
              tooltip: l10n.cancel,
              onPressed: () async {
                try {
                  await controller.toggleTorch();
                } catch (e, st) {
                  debugPrint('Torch toggle failed: $e\n$st');
                }
              },
              icon: const Icon(Icons.flash_on_rounded),
            ),
        ],
      ),
      body: _initError != null
          ? _ErrorBody(
              message: l10n.scanCameraFailed(_initError!),
              onClose: () => Navigator.of(context).pop(),
            )
          : controller == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => _ErrorBody(
                        message: l10n.scanCameraFailed(
                          error.errorDetails?.message ?? error.errorCode.name,
                        ),
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _ScanFramePainter(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onClose,
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.shortestSide * 0.7,
      height: size.shortestSide * 0.35,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) =>
      oldDelegate.color != color;
}
