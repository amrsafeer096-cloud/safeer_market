import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/barcode_scanner_screen.dart';

/// Opens the scanner and resolves to the raw result: null or '-1' when the
/// user cancels. Overridden in tests, where there is no camera.
typedef BarcodeScan = Future<String?> Function(BuildContext context);

final barcodeScannerProvider = Provider<BarcodeScan>((ref) => _scanWithCamera);

/// Requests camera permission **before** pushing the scanner route, then
/// opens [BarcodeScannerScreen] with a safely initialized controller.
Future<String?> _scanWithCamera(BuildContext context) async {
  try {
    // 1) Resolve permission before any camera / route work.
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      throw PlatformException(
        code: 'camera_permission_denied',
        message: 'Camera permission permanently denied',
      );
    }
    if (!status.isGranted) {
      throw PlatformException(
        code: 'camera_permission_denied',
        message: 'Camera permission was denied',
      );
    }

    // Let the permission dialog / activity fully dismiss before pushing
    // the camera route (avoids the common Android crash after grant).
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!context.mounted) return null;

    // 2) Navigate only after permission is granted.
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result == null || result.isEmpty) return '-1';

    // Extra feedback if the scanner screen didn't already play it.
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.vibrate();

    return result;
  } on PlatformException {
    rethrow;
  } on MissingPluginException {
    rethrow;
  } catch (e, st) {
    debugPrint('Barcode scanner failed: $e\n$st');
    throw PlatformException(
      code: 'camera_open_failed',
      message: e.toString(),
    );
  }
}
