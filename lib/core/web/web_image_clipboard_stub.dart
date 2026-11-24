import 'dart:typed_data';

/// Non-web: image clipboard via ClipboardItem is unavailable.
Future<bool> copyImageBlobToWebClipboard(
  Uint8List bytes, {
  String mimeType = 'image/png',
}) async =>
    false;
