import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../l10n/app_localizations.dart';

/// Live camera that reads QR codes and reports each one's raw text.
class CustomerCodeCamera extends StatefulWidget {
  const CustomerCodeCamera({super.key, required this.onScan});

  final ValueChanged<String> onScan;

  @override
  State<CustomerCodeCamera> createState() => _CustomerCodeCameraState();
}

class _CustomerCodeCameraState extends State<CustomerCodeCamera> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        for (final code in capture.barcodes) {
          final raw = code.rawValue;
          if (raw != null && raw.isNotEmpty) {
            widget.onScan(raw);
            return;
          }
        }
      },
      errorBuilder: (context, error) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)!.scanCameraFailed(
                error.errorDetails?.message ?? error.errorCode.name,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
