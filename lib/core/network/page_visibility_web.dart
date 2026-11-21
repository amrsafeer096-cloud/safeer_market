// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

/// Fires [onVisible] when a background / sleeping Chrome tab is focused again.
StreamSubscription<void>? listenPageBecameVisible(void Function() onVisible) {
  return html.document.onVisibilityChange.listen((_) {
    if (html.document.visibilityState == 'visible') onVisible();
  });
}
