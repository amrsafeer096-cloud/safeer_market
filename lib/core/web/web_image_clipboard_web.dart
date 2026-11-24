// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// Writes an image to the system clipboard as `image/png` via the browser
/// `ClipboardItem` API (JS interop — `dart:html` has no usable ClipboardItem).
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
  // dart:html's toBlob is non-nullable on current SDKs.
  return canvas.toBlob('image/png');
}

Future<bool> _writeClipboardItem(html.Blob pngBlob) async {
  try {
    final clipboard = js_util.getProperty(
      html.window.navigator,
      'clipboard',
    );
    if (clipboard == null) return false;

    final ctor = js_util.getProperty(html.window, 'ClipboardItem');
    if (ctor == null) return false;

    // navigator.clipboard.write([new ClipboardItem({'image/png': blob})])
    // Use JS interop only — dart:html has no ClipboardItem constructor and
    // its Clipboard.write expects DataTransfer, not a list of items.
    final item = js_util.callConstructor(
      ctor,
      [js_util.jsify({'image/png': pngBlob})],
    );
    final arrayCtor = js_util.getProperty(html.window, 'Array');
    final items = js_util.callConstructor(arrayCtor, [item]);
    await js_util.promiseToFuture(
      js_util.callMethod(clipboard, 'write', [items]),
    );
    return true;
  } catch (_) {
    return false;
  }
}
