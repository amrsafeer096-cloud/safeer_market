import 'dart:async';

/// No-op outside the browser; [AppLifecycleListener] covers mobile resume.
StreamSubscription<void>? listenPageBecameVisible(void Function() onVisible) =>
    null;
