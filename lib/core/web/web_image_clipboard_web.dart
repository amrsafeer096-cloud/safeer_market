// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// Writes an image to the system clipboard as `image/png` via
/// `ClipboardItem` so Chrome can paste into WhatsApp Desktop (`Ctrl+V`).
Future<bool> copyImageBlobToWebClipboard(
  Uint8List bytes, {
  String mimeType = 'image/png',
}) async {
  if (bytes.isEmpty) return false;
  try {
    final png = await _ensurePngBlob(bytes, mimeType);
    return await _writeClipboardItem(png);
  } catch (_) {
    return false;
  }
}

Future<html.Blob> _ensurePngBlob(Uint8List bytes, String mime) async {
  if (mime == 'image/png') {
    return html.Blob([bytes], 'image/png');
  }
  final source = html.Blob([bytes], mime);
  final objectUrl = html.Url.createObjectUrlFromBlob(source);
  final img = html.ImageElement();
  final loaded = Completer<void>();
  late StreamSubscription<html.Event> ok;
  late StreamSubscription<html.Event> fail;
  ok = img.onLoad.listen((_) {
    ok.cancel();
    fail.cancel();
    if (!loaded.isCompleted) loaded.complete();
  });
  fail = img.onError.listen((_) {
    ok.cancel();
    fail.cancel();
    if (!loaded.isCompleted) {
      loaded.completeError(StateError('image decode failed'));
    }
  });
  img.src = objectUrl;
  try {
    await loaded.future.timeout(const Duration(seconds: 8));
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
  final w = img.naturalWidth;
  final h = img.naturalHeight;
  if (w <= 0 || h <= 0) {
    throw StateError('empty image');
  }
  final canvas = html.CanvasElement(width: w, height: h);
  canvas.context2D.drawImage(img, 0, 0);
  final blob = await canvas.toBlob('image/png');
  if (blob == null) throw StateError('toBlob failed');
  return blob;
}

Future<bool> _writeClipboardItem(html.Blob pngBlob) async {
  try {
    final item = html.ClipboardItem({'image/png': pngBlob});
    final clipboard = html.window.navigator.clipboard;
    if (clipboard == null) return false;
    await clipboard.write([item]);
    return true;
  } catch (_) {
    try {
      final ctor = js_util.getProperty(html.window, 'ClipboardItem');
      final item = js_util.callConstructor(
        ctor,
        [js_util.jsify({'image/png': pngBlob})],
      );
      final navClipboard =
          js_util.getProperty(html.window.navigator, 'clipboard');
      await js_util.promiseToFuture(
        js_util.callMethod(navClipboard, 'write', [
          js_util.jsify([item]),
        ]),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
