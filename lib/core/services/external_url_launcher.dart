import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in another app; resolves to false when nothing can handle it.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  },
);
